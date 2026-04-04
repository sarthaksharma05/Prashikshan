class AnalysisResult {
  final int score;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  final List<String> projectFeedback;
  final String overallScoreReason;

  AnalysisResult({
    required this.score,
    required this.matchedSkills,
    required this.missingSkills,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.projectFeedback,
    required this.overallScoreReason,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // 🧩 Safe JSON Handling: Robust casting from backend dynamic lists
    return AnalysisResult(
      score: json['score'] ?? 0,
      matchedSkills: _toList(json['matched_skills']),
      missingSkills: _toList(json['missing_skills']),
      strengths: _toList(json['strengths']),
      weaknesses: _toList(json['weaknesses']),
      suggestions: _toList(json['suggestions']),
      projectFeedback: _toList(json['project_feedback']),
      overallScoreReason: json['overall_score_reason'] ?? "Analysis complete.",
    );
  }

  static List<String> _toList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    // Handle cases where backend accidentally sends a single string instead of a list
    if (data is String && data.isNotEmpty) {
      return [data];
    }
    return [];
  }
}
