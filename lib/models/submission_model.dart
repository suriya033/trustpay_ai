import 'ai_review_model.dart';

class ClientReview {
  final DateTime? reviewedAt;
  final String decision; // 'approved' | 'revision_requested'
  final String feedback;

  ClientReview({
    this.reviewedAt,
    this.decision = '',
    this.feedback = '',
  });

  bool get isApproved => decision == 'approved';
  bool get isRevisionRequested => decision == 'revision_requested';

  factory ClientReview.fromJson(Map<String, dynamic> json) {
    return ClientReview(
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      decision: json['decision'] ?? '',
      feedback: json['feedback'] ?? '',
    );
  }
}

class SubmissionModel {
  final String id;
  final String description;
  final String githubUrl;
  final String liveDemoUrl;
  final String notes;
  final int version;
  final DateTime submittedAt;
  final AiReviewModel? aiReview;
  final ClientReview? clientReview;

  SubmissionModel({
    required this.id,
    required this.description,
    this.githubUrl = '',
    this.liveDemoUrl = '',
    this.notes = '',
    this.version = 1,
    required this.submittedAt,
    this.aiReview,
    this.clientReview,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['_id'] ?? json['id'] ?? '',
      description: json['description'] ?? '',
      githubUrl: json['githubUrl'] ?? '',
      liveDemoUrl: json['liveDemoUrl'] ?? '',
      notes: json['notes'] ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      aiReview: json['aiReview'] != null && json['aiReview']['score'] != null
          ? AiReviewModel.fromJson(json['aiReview'] as Map<String, dynamic>)
          : null,
      clientReview: json['clientReview'] != null &&
              json['clientReview']['decision'] != null &&
              (json['clientReview']['decision'] as String).isNotEmpty
          ? ClientReview.fromJson(json['clientReview'] as Map<String, dynamic>)
          : null,
    );
  }
}
