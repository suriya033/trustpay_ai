import '../core/constants/api_constants.dart';
import '../models/ai_review_model.dart';
import '../models/milestone_model.dart';
import '../models/project_model.dart';
import '../models/submission_model.dart';
import 'api_service.dart';

class ProjectService {
  static Future<ProjectModel> createProject({
    required String title,
    required String description,
    String category = 'General',
    required double totalBudget,
    String currency = 'USD',
    String duration = '2-4 weeks',
    DateTime? deadline,
    String technicalRequirements = '',
    String additionalInstructions = '',
    String invitedFreelancerEmail = '',
    required List<Map<String, dynamic>> milestones,
  }) async {
    final response = await ApiService.post(
      ApiConstants.projects,
      body: {
        'title': title,
        'description': description,
        'category': category,
        'totalBudget': totalBudget,
        'currency': currency,
        'duration': duration,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        'technicalRequirements': technicalRequirements,
        'additionalInstructions': additionalInstructions,
        'invitedFreelancerEmail': invitedFreelancerEmail,
        'milestones': milestones,
      },
    );

    return ProjectModel.fromJson(response);
  }

  static Future<List<ProjectModel>> getProjects({String status = 'all'}) async {
    final url = '${ApiConstants.projects}?status=$status';
    final response = await ApiService.get(url);

    if (response is List) {
      return response
          .map((p) => ProjectModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<ProjectModel> getProjectById(String id) async {
    final response = await ApiService.get(ApiConstants.projectById(id));
    return ProjectModel.fromJson(response);
  }

  static Future<ProjectModel> inviteFreelancer(
    String id, {
    String? freelancerId,
    String? email,
  }) async {
    final response = await ApiService.post(
      ApiConstants.inviteFreelancer(id),
      body: {
        if (freelancerId != null) 'freelancerId': freelancerId,
        if (email != null) 'email': email,
      },
    );
    return ProjectModel.fromJson(response['project']);
  }

  static Future<ProjectModel> freelancerAgreementRespond(
    String id, {
    required String action, // 'accept' | 'request_changes'
    String? changeRequest,
  }) async {
    final response = await ApiService.post(
      ApiConstants.freelancerAgreementRespond(id),
      body: {
        'action': action,
        if (changeRequest != null) 'changeRequest': changeRequest,
      },
    );
    return ProjectModel.fromJson(response['project']);
  }

  static Future<ProjectModel> clientAgreementConfirm(
    String id, {
    String? updatedTerms,
  }) async {
    final response = await ApiService.post(
      ApiConstants.clientAgreementConfirm(id),
      body: {
        if (updatedTerms != null) 'updatedTerms': updatedTerms,
      },
    );
    return ProjectModel.fromJson(response['project']);
  }

  static Future<MilestoneModel> updateMilestone({
    required String projectId,
    required String milestoneId,
    String? title,
    String? description,
    double? amount,
    List<String>? deliverables,
    List<String>? acceptanceCriteria,
  }) async {
    final response = await ApiService.put(
      ApiConstants.updateMilestone(projectId, milestoneId),
      body: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (amount != null) 'amount': amount,
        if (deliverables != null) 'deliverables': deliverables,
        if (acceptanceCriteria != null) 'acceptanceCriteria': acceptanceCriteria,
      },
    );
    return MilestoneModel.fromJson(response['milestone']);
  }

  static Future<SubmissionModel> submitWork({
    required String projectId,
    required String milestoneId,
    required String description,
    String githubUrl = '',
    String liveDemoUrl = '',
    String notes = '',
  }) async {
    final response = await ApiService.post(
      ApiConstants.submitWork(projectId, milestoneId),
      body: {
        'description': description,
        'githubUrl': githubUrl,
        'liveDemoUrl': liveDemoUrl,
        'notes': notes,
      },
    );
    return SubmissionModel.fromJson(response['submission']);
  }

  static Future<AiReviewModel> requestAiReview({
    required String projectId,
    required String milestoneId,
  }) async {
    final response = await ApiService.post(
      ApiConstants.milestoneAiReview(projectId, milestoneId),
    );
    return AiReviewModel.fromJson(response['review']);
  }

  static Future<MilestoneModel> clientDecision({
    required String projectId,
    required String milestoneId,
    required String decision, // 'approved' | 'revision_requested'
    String feedback = '',
  }) async {
    final response = await ApiService.post(
      ApiConstants.milestoneClientDecision(projectId, milestoneId),
      body: {
        'decision': decision,
        'feedback': feedback,
      },
    );
    return MilestoneModel.fromJson(response['milestone']);
  }
}
