class TransactionModel {
  final String id;
  final String receiptId;
  final String projectId;
  final String projectTitle;
  final String milestoneId;
  final String milestoneTitle;
  final String clientName;
  final String clientEmail;
  final String freelancerName;
  final String freelancerEmail;
  final double amount;
  final String currency;
  final String paypalOrderId;
  final String paypalCaptureId;
  final String paymentStatus;
  final bool isSandbox;
  final DateTime paidAt;

  TransactionModel({
    required this.id,
    required this.receiptId,
    required this.projectId,
    required this.projectTitle,
    required this.milestoneId,
    required this.milestoneTitle,
    this.clientName = 'Client',
    this.clientEmail = '',
    this.freelancerName = 'Freelancer',
    this.freelancerEmail = '',
    required this.amount,
    this.currency = 'USD',
    required this.paypalOrderId,
    required this.paypalCaptureId,
    this.paymentStatus = 'COMPLETED',
    this.isSandbox = true,
    required this.paidAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? '',
      receiptId: json['receiptId'] ?? '',
      projectId: json['projectId'] is Map
          ? json['projectId']['_id'] ?? ''
          : json['projectId']?.toString() ?? '',
      projectTitle: json['projectTitle'] ?? 'Project Milestone',
      milestoneId: json['milestoneId']?.toString() ?? '',
      milestoneTitle: json['milestoneTitle'] ?? 'Milestone Payment',
      clientName: json['clientName'] ?? 'Client',
      clientEmail: json['clientEmail'] ?? '',
      freelancerName: json['freelancerName'] ?? 'Freelancer',
      freelancerEmail: json['freelancerEmail'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      paypalOrderId: json['paypalOrderId'] ?? '',
      paypalCaptureId: json['paypalCaptureId'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'COMPLETED',
      isSandbox: json['isSandbox'] != false,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
