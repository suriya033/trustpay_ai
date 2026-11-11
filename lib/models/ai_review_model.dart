class CriteriaCheck {
  final String criterion;
  final bool satisfied;
  final String explanation;

  CriteriaCheck({
    required this.criterion,
    required this.satisfied,
    required this.explanation,
  });

  factory CriteriaCheck.fromJson(Map<String, dynamic> json) {
    return CriteriaCheck(
      criterion: json['criterion'] ?? '',
      satisfied: json['satisfied'] == true,
      explanation: json['explanation'] ?? '',
    );
  }
}

class DeliverableCheck {
  final String deliverable;
  final bool satisfied;
  final String explanation;

  DeliverableCheck({
    required this.deliverable,
    required this.satisfied,
    required this.explanation,
  });

  factory DeliverableCheck.fromJson(Map<String, dynamic> json) {
    return DeliverableCheck(
      deliverable: json['deliverable'] ?? '',
      satisfied: json['satisfied'] == true,
      explanation: json['explanation'] ?? '',
    );
  }
}

class AiReviewModel {
  final DateTime? reviewedAt;
  final int score;
  final bool passed;
  final String verdict;
  final String summary;
  final List<CriteriaCheck> criteriaChecks;
  final List<DeliverableCheck> deliverablesChecks;
  final List<String> identifiedRisks;
  final List<String> recommendations;

  AiReviewModel({
    this.reviewedAt,
    required this.score,
    required this.passed,
    required this.verdict,
    required this.summary,
    this.criteriaChecks = const [],
    this.deliverablesChecks = const [],
    this.identifiedRisks = const [],
    this.recommendations = const [],
  });

  factory AiReviewModel.fromJson(Map<String, dynamic> json) {
    return AiReviewModel(
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      score: (json['score'] as num?)?.toInt() ?? 0,
      passed: json['passed'] == true,
      verdict: json['verdict'] ?? (json['passed'] == true ? 'PASSED' : 'NEEDS_IMPROVEMENT'),
      summary: json['summary'] ?? '',
      criteriaChecks: json['criteriaChecks'] != null
          ? (json['criteriaChecks'] as List)
              .map((c) => CriteriaCheck.fromJson(c as Map<String, dynamic>))
              .toList()
          : const [],
      deliverablesChecks: json['deliverablesChecks'] != null
          ? (json['deliverablesChecks'] as List)
              .map((d) => DeliverableCheck.fromJson(d as Map<String, dynamic>))
              .toList()
          : const [],
      identifiedRisks: json['identifiedRisks'] != null
          ? List<String>.from(json['identifiedRisks'])
          : const [],
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : const [],
    );
  }
}
