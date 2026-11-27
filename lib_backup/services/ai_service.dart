import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/analysis_result.dart';

class AiService {
  Future<AnalysisResult> analyze({
    required String resumeText,
    required String targetRole,
  }) async {
    final text = resumeText.length > 12000
        ? resumeText.substring(0, 12000)
        : resumeText;

    if (AppConfig.hasGeminiKey) {
      try {
        return await _analyzeWithGemini(text, targetRole);
      } catch (e) {
        final r = _analyzeOffline(text, targetRole);
        return AnalysisResult(
          score: r.score,
          summary: r.summary,
          targetRole: r.targetRole,
          strengths: r.strengths,
          detectedSkills: r.detectedSkills,
          missingSkills: r.missingSkills,
          improvements: r.improvements,
          source: 'Offline analyzer (Gemini failed: ${_short(e)})',
        );
      }
    }
    return _analyzeOffline(text, targetRole);
  }

  String _short(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}...' : s;
  }

  // ---------------------------------------------------------------- Gemini
  Future<AnalysisResult> _analyzeWithGemini(String text, String role) async {
    final roleLine = role.isEmpty
        ? 'No specific target role was given; judge it as a general professional resume.'
        : 'Target job role: $role';

    final prompt = '''
You are an expert resume reviewer and career coach.
$roleLine

Analyze the resume below and reply ONLY with a JSON object with exactly these keys:
{
  "score": integer 0-100 (overall quality and fit for the role),
  "summary": string (2-3 sentences, honest overall assessment),
  "strengths": array of 3-5 short strings,
  "detectedSkills": array of skills actually found in the resume,
  "missingSkills": array of 5-10 important skills for the role that are NOT in the resume,
  "improvements": array of 5-8 specific, actionable suggestions (formatting, wording, metrics, sections)
}
Do not invent experience the candidate does not have.

RESUME:
"""
$text
"""
''';

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent');

    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AppConfig.geminiApiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.3,
            },
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    var out = data['candidates'][0]['content']['parts'][0]['text'] as String;
    out = out.replaceAll('```json', '').replaceAll('```', '').trim();

    final json = jsonDecode(out) as Map<String, dynamic>;
    json['targetRole'] = role;
    json['source'] = 'Gemini AI';
    return AnalysisResult.fromJson(json);
  }

  // --------------------------------------------------------------- Offline
  static const Map<String, List<String>> _roleSkills = {
    'flutter developer': [
      'flutter', 'dart', 'firebase', 'rest api', 'state management',
      'provider', 'bloc', 'git', 'sqlite', 'testing', 'ci/cd', 'ui/ux'
    ],
    'web developer': [
      'html', 'css', 'javascript', 'typescript', 'react', 'node.js', 'git',
      'rest api', 'responsive design', 'sql', 'testing'
    ],
    'data analyst': [
      'sql', 'excel', 'python', 'pandas', 'power bi', 'tableau',
      'statistics', 'data visualization', 'data cleaning', 'reporting'
    ],
    'data scientist': [
      'python', 'machine learning', 'pandas', 'numpy', 'scikit-learn',
      'sql', 'statistics', 'deep learning', 'tensorflow', 'data visualization'
    ],
    'android developer': [
      'kotlin', 'java', 'android', 'jetpack compose', 'mvvm', 'room',
      'retrofit', 'git', 'firebase', 'testing'
    ],
    'software developer': [
      'git', 'data structures', 'algorithms', 'oop', 'sql', 'rest api',
      'testing', 'agile', 'docker', 'linux', 'ci/cd'
    ],
  };

  static const List<String> _actionVerbs = [
    'developed', 'built', 'designed', 'led', 'implemented', 'created',
    'managed', 'improved', 'optimized', 'launched', 'delivered', 'automated'
  ];

  bool _has(String lower, String skill) {
    final re = RegExp('(^|[^a-z0-9])${RegExp.escape(skill)}(\$|[^a-z0-9])');
    return re.hasMatch(lower);
  }

  AnalysisResult _analyzeOffline(String text, String role) {
    final lower = text.toLowerCase();
    final r = role.toLowerCase().trim();

    var roleKey = 'software developer';
    for (final k in _roleSkills.keys) {
      if (r.isNotEmpty && (r.contains(k) || k.contains(r))) {
        roleKey = k;
        break;
      }
    }
    final needed = _roleSkills[roleKey]!;
    final detected = needed.where((s) => _has(lower, s)).toList();
    final missing = needed.where((s) => !_has(lower, s)).toList();

    // All known skills found anywhere in the resume
    final allKnown = _roleSkills.values.expand((e) => e).toSet();
    final detectedAll = allKnown.where((s) => _has(lower, s)).toList()..sort();

    // Sections
    const sections = ['summary', 'education', 'experience', 'projects', 'skills'];
    final presentSections = sections.where((s) => lower.contains(s)).toList();
    final missingSections =
        sections.where((s) => !lower.contains(s)).toList();

    // Contact info
    final hasEmail = RegExp(r'[\w.\-]+@[\w\-]+\.[\w.]+').hasMatch(text);
    final hasPhone = RegExp(r'\+?\d[\d\s\-]{8,}\d').hasMatch(text);
    final hasLinks = lower.contains('linkedin') || lower.contains('github');

    // Metrics / action verbs / length
    final hasMetrics = RegExp(
            r'\d+\s?%|\$\s?\d|\d+\+?\s?(users|customers|projects|clients|apps)')
        .hasMatch(lower);
    final usesVerbs = _actionVerbs.where((v) => lower.contains(v)).length >= 3;
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    var score = 0.0;
    score += (detected.length / needed.length) * 45;
    score += (presentSections.length / sections.length) * 20;
    score += (hasEmail ? 5 : 0) + (hasPhone ? 5 : 0) + (hasLinks ? 5 : 0);
    score += hasMetrics ? 10 : 0;
    score += (words >= 250 && words <= 900) ? 10 : (words >= 150 ? 5 : 0);
    final finalScore = score.round().clamp(0, 100).toInt();

    final strengths = <String>[
      if (detected.length >= needed.length / 2)
        'Covers ${detected.length} of ${needed.length} key skills for $roleKey',
      if (hasMetrics) 'Uses numbers/percentages to show impact',
      if (usesVerbs) 'Uses strong action verbs',
      if (hasEmail && hasPhone) 'Clear contact details',
      if (hasLinks) 'Includes LinkedIn/GitHub profile',
      if (presentSections.length >= 4) 'Well structured with standard sections',
    ];
    if (strengths.isEmpty) {
      strengths.add('Resume text was readable and could be analyzed');
    }

    final improvements = <String>[
      if (missing.isNotEmpty)
        'Learn and add these skills if you really have them: ${missing.take(6).join(', ')}',
      if (missingSections.isNotEmpty)
        'Add missing sections: ${missingSections.join(', ')}',
      if (!hasMetrics)
        'Add measurable results (e.g. "reduced load time by 30%", "used by 500+ users")',
      if (!usesVerbs)
        'Start bullet points with action verbs (developed, built, implemented...)',
      if (!hasLinks) 'Add your LinkedIn and/or GitHub link',
      if (!hasEmail || !hasPhone) 'Add a professional email and phone number',
      if (words < 150)
        'Resume is very short; describe projects and experience in more detail',
      if (words > 900) 'Resume is long; keep it to 1-2 pages',
    ];

    return AnalysisResult(
      score: finalScore,
      summary:
          'Offline keyword analysis for "$roleKey": ${detected.length} of ${needed.length} key skills found. '
          'Add a Gemini API key in lib/config.dart for a deeper AI review.',
      targetRole: role,
      strengths: strengths,
      detectedSkills: detectedAll,
      missingSkills: missing,
      improvements: improvements,
      source: 'Offline analyzer',
    );
  }
}
