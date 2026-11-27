import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/analysis_result.dart';
import '../models/improved_resume.dart';

/// Asks Gemini to rewrite the resume (using only facts from the original).
class ResumeWriterService {
  Future<ImprovedResume> improve({
    required String resumeText,
    required String targetRole,
    required AnalysisResult analysis,
  }) async {
    if (!AppConfig.hasGeminiKey) {
      throw Exception(
          'Add your Gemini API key in lib/config.dart to create an improved resume.');
    }
    final text = resumeText.length > 12000
        ? resumeText.substring(0, 12000)
        : resumeText;

    Object? lastError;
    for (final model in AppConfig.geminiModels) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          return await _callGemini(text, targetRole, analysis, model);
        } catch (e) {
          lastError = e;
          final msg = e.toString();
          if (msg.contains('HTTP 400') ||
              msg.contains('HTTP 401') ||
              msg.contains('HTTP 403')) {
            rethrow;
          }
          final busy = msg.contains('HTTP 503') || msg.contains('HTTP 429');
          if (busy && attempt == 0) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          break; // next model
        }
      }
    }
    throw lastError ?? Exception('All Gemini models failed');
  }

  Future<ImprovedResume> _callGemini(String text, String role,
      AnalysisResult analysis, String model) async {
    final roleLine = role.isEmpty
        ? 'No specific target role was given; write a strong general resume.'
        : 'Target job role: $role';
    final feedback = analysis.improvements.map((e) => '- $e').join('\n');
    final missing = analysis.missingSkills.join(', ');

    final prompt = '''
You are a professional resume writer.
$roleLine

Rewrite the resume below into an improved, ATS-friendly resume. Reply ONLY with JSON in exactly this shape:
{
  "name": "full name",
  "headline": "short professional title",
  "contact": "one line: email | phone | city | LinkedIn | GitHub (only what appears in the original)",
  "summary": "2-3 sentence professional summary",
  "skills": ["Category: skill, skill, skill"],
  "experience": [{"title": "", "organization": "", "dates": "", "bullets": [""]}],
  "projects": [{"name": "", "bullets": [""]}],
  "education": ["Degree - Institution (years). Extra details"],
  "certifications": [""]
}

Rules:
- Use ONLY facts from the original resume. Never invent employers, job titles, dates, degrees, skills, tools or numbers.
- Keep every number that exists in the original (percentages, user counts, team sizes).
- Improve wording: start each bullet with a strong action verb, be specific and concise, remove filler.
- Order and emphasize content to fit the target role when one is given.
- Do NOT add the missing skills listed below; they are only learning suggestions for the candidate.
- Plain text only, no markdown. Use simple characters (letters, digits and - , . ( ) : ; / @ + #).
- Use an empty list [] when the original has no such information.

Reviewer feedback to apply (wording and structure only):
$feedback

Missing skills (do NOT add to the resume): $missing

ORIGINAL RESUME:
"""
$text
"""
''';

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');

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
              'temperature': 0.4,
              'maxOutputTokens': 4096,
            },
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini returned no answer for this resume.');
    }
    final parts = candidates[0]['content']?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw Exception('Gemini returned an empty answer.');
    }
    var out = parts.map((p) => (p['text'] ?? '').toString()).join();
    out = out.replaceAll('```json', '').replaceAll('```', '').trim();

    final json = jsonDecode(out) as Map<String, dynamic>;
    final resume = ImprovedResume.fromJson(json);
    if (resume.name.isEmpty && resume.summary.isEmpty && resume.experience.isEmpty) {
      throw Exception('Gemini returned an incomplete resume. Try again.');
    }
    return resume;
  }
}
