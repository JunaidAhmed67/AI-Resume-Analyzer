class AnalysisResult {
  final int score;
  final String summary;
  final String targetRole;
  final List<String> strengths;
  final List<String> detectedSkills;
  final List<String> missingSkills;
  final List<String> improvements;
  final String source;

  const AnalysisResult({
    required this.score,
    required this.summary,
    required this.targetRole,
    required this.strengths,
    required this.detectedSkills,
    required this.missingSkills,
    required this.improvements,
    required this.source,
  });

  static List<String> _list(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : <String>[];

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    final raw = j['score'];
    final s = raw is num ? raw.toInt() : 0;
    return AnalysisResult(
      score: s.clamp(0, 100).toInt(),
      summary: (j['summary'] ?? '').toString(),
      targetRole: (j['targetRole'] ?? '').toString(),
      strengths: _list(j['strengths']),
      detectedSkills: _list(j['detectedSkills']),
      missingSkills: _list(j['missingSkills']),
      improvements: _list(j['improvements']),
      source: (j['source'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'summary': summary,
        'targetRole': targetRole,
        'strengths': strengths,
        'detectedSkills': detectedSkills,
        'missingSkills': missingSkills,
        'improvements': improvements,
        'source': source,
      };
}
