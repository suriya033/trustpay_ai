import 'milestone_model.dart';
import 'user_model.dart';

class ProjectAgreement {
  final String terms;
  final bool clientAccepted;
  final DateTime? clientAcceptedAt;
  final bool freelancerAccepted;
  final DateTime? freelancerAcceptedAt;
  final String freelancerChangeRequest;
  final dynamic acceptedSnapshot;

  ProjectAgreement({
    required this.terms,
    this.clientAccepted = false,
    this.clientAcceptedAt,
    this.freelancerAccepted = false,
    this.freelancerAcceptedAt,
    this.freelancerChangeRequest = '',
    this.acceptedSnapshot,
  });

  bool get isMutuallyAccepted => clientAccepted && freelancerAccepted;

  factory ProjectAgreement.fromJson(Map<String, dynamic> json) {
    return ProjectAgreement(
      terms: json['terms'] ?? '',
      clientAccepted: json['clientAccepted'] == true,
      clientAcceptedAt: json['clientAcceptedAt'] != null
          ? DateTime.tryParse(json['clientAcceptedAt'].toString())
          : null,
      freelancerAccepted: json['freelancerAccepted'] == true,
      freelancerAcceptedAt: json['freelancerAcceptedAt'] != null
          ? DateTime.tryParse(json['freelancerAcceptedAt'].toString())
          : null,
      freelancerChangeRequest: json['freelancerChangeRequest'] ?? '',
      acceptedSnapshot: json['acceptedSnapshot'],
    );
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String currency;
  final double totalBudget;
  final String duration;
  final DateTime? deadline;
  final String technicalRequirements;
  final String additionalInstructions;
  final UserModel? client;
  final UserModel? freelancer;
  final String invitedFreelancerEmail;
  final String status;
  final ProjectAgreement? agreement;
  final List<MilestoneModel> milestones;
  final int progress;
  final DateTime? createdAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'General',
    this.currency = 'USD',
    required this.totalBudget,
    this.duration = '2-4 weeks',
    this.deadline,
    this.technicalRequirements = '',
    this.additionalInstructions = '',
    this.client,
    this.freelancer,
    this.invitedFreelancerEmail = '',
    this.status = 'pending_agreement',
    this.agreement,
    this.milestones = const [],
    this.progress = 0,
    this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPendingAgreement => status == 'pending_agreement';

  int get paidMilestonesCount =>
      milestones.where((m) => m.status == 'paid').length;

  double get paidAmount => milestones
      .where((m) => m.status == 'paid')
      .fold(0.0, (sum, m) => sum + m.amount);

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedClient;
    if (json['client'] != null && json['client'] is Map) {
      parsedClient = UserModel.fromJson(json['client'] as Map<String, dynamic>);
    }

    UserModel? parsedFreelancer;
    if (json['freelancer'] != null && json['freelancer'] is Map) {
      parsedFreelancer =
          UserModel.fromJson(json['freelancer'] as Map<String, dynamic>);
    }

    final milestonesList = json['milestones'] != null
        ? (json['milestones'] as List)
            .map((m) => MilestoneModel.fromJson(m as Map<String, dynamic>))
            .toList()
        : <MilestoneModel>[];

    // Compute progress
    int calculatedProgress = 0;
    if (milestonesList.isNotEmpty) {
      final completed =
          milestonesList.where((m) => m.status == 'paid').length;
      calculatedProgress =
          ((completed / milestonesList.length) * 100).round();
    }

    return ProjectModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      currency: json['currency'] ?? 'USD',
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] ?? '2-4 weeks',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      technicalRequirements: json['technicalRequirements'] ?? '',
      additionalInstructions: json['additionalInstructions'] ?? '',
      client: parsedClient,
      freelancer: parsedFreelancer,
      invitedFreelancerEmail: json['invitedFreelancerEmail'] ?? '',
      status: json['status'] ?? 'pending_agreement',
      agreement: json['agreement'] != null
          ? ProjectAgreement.fromJson(json['agreement'] as Map<String, dynamic>)
          : null,
      milestones: milestonesList,
      progress: json['progress'] != null
          ? (json['progress'] as num).toInt()
          : calculatedProgress,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
