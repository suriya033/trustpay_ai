import 'submission_model.dart';

class MilestonePayment {
  final String paypalOrderId;
  final String paypalCaptureId;
  final DateTime? paidAt;
  final double amount;
  final String currency;
  final String receiptId;
  final String status;
  final String payerEmail;

  MilestonePayment({
    this.paypalOrderId = '',
    this.paypalCaptureId = '',
    this.paidAt,
    this.amount = 0.0,
    this.currency = 'USD',
    this.receiptId = '',
    this.status = '',
    this.payerEmail = '',
  });

  bool get isCompleted => status == 'COMPLETED';

  factory MilestonePayment.fromJson(Map<String, dynamic> json) {
    return MilestonePayment(
      paypalOrderId: json['paypalOrderId'] ?? '',
      paypalCaptureId: json['paypalCaptureId'] ?? '',
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      receiptId: json['receiptId'] ?? '',
      status: json['status'] ?? '',
      payerEmail: json['payerEmail'] ?? '',
    );
  }
}

class MilestoneModel {
  final String id;
  final String title;
  final String description;
  final List<String> deliverables;
  final List<String> acceptanceCriteria;
  final double amount;
  final String currency;
  final String suggestedDuration;
  final List<String> dependencies;
  final List<String> potentialRisks;
  final DateTime? deadline;
  final String status;
  final List<SubmissionModel> submissions;
  final MilestonePayment? payment;

  MilestoneModel({
    required this.id,
    required this.title,
    this.description = '',
    this.deliverables = const [],
    this.acceptanceCriteria = const [],
    required this.amount,
    this.currency = 'USD',
    this.suggestedDuration = '',
    this.dependencies = const [],
    this.potentialRisks = const [],
    this.deadline,
    this.status = 'pending',
    this.submissions = const [],
    this.payment,
  });

  bool get isPaid => status == 'paid';
  bool get isApproved => status == 'approved';
  bool get isInProgress => status == 'in_progress';
  bool get isSubmitted => status == 'submitted';
  bool get isUnderAiReview => status == 'under_ai_review';
  bool get isNeedsRevision => status == 'needs_revision';
  bool get isPaymentPending => status == 'payment_pending';
  bool get isPending => status == 'pending';

  SubmissionModel? get latestSubmission =>
      submissions.isNotEmpty ? submissions.last : null;

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      deliverables: json['deliverables'] != null
          ? List<String>.from(json['deliverables'])
          : const [],
      acceptanceCriteria: json['acceptanceCriteria'] != null
          ? List<String>.from(json['acceptanceCriteria'])
          : const [],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      suggestedDuration: json['suggestedDuration'] ?? '',
      dependencies: json['dependencies'] != null
          ? List<String>.from(json['dependencies'])
          : const [],
      potentialRisks: json['potentialRisks'] != null
          ? List<String>.from(json['potentialRisks'])
          : const [],
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      status: json['status'] ?? 'pending',
      submissions: json['submissions'] != null
          ? (json['submissions'] as List)
              .map((s) => SubmissionModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : const [],
      payment: json['payment'] != null
          ? MilestonePayment.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }
}
