import '../core/constants/api_constants.dart';
import '../models/ai_review_model.dart';
import '../models/milestone_model.dart';
import 'api_service.dart';

class AiService {
  static Future<List<MilestoneModel>> generateMilestones({
    required String title,
    required String description,
    String category = 'General',
    required double totalBudget,
    String currency = 'USD',
    String duration = '4 weeks',
    String technicalRequirements = '',
    String additionalInstructions = '',
  }) async {
    final response = await ApiService.post(
      ApiConstants.generateMilestones,
      body: {
        'title': title,
        'description': description,
        'category': category,
        'totalBudget': totalBudget,
        'currency': currency,
        'duration': duration,
        'technicalRequirements': technicalRequirements,
        'additionalInstructions': additionalInstructions,
      },
    );

    if (response['milestones'] is List) {
      return (response['milestones'] as List)
          .map((m) => MilestoneModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<AiReviewModel> reviewSubmission({
    required String milestoneTitle,
    required String milestoneDescription,
    required List<String> deliverables,
    required List<String> acceptanceCriteria,
    required String submissionDescription,
    String githubUrl = '',
    String liveDemoUrl = '',
    String notes = '',
  }) async {
    final response = await ApiService.post(
      ApiConstants.reviewSubmission,
      body: {
        'milestoneTitle': milestoneTitle,
        'milestoneDescription': milestoneDescription,
        'deliverables': deliverables,
        'acceptanceCriteria': acceptanceCriteria,
        'submissionDescription': submissionDescription,
        'githubUrl': githubUrl,
        'liveDemoUrl': liveDemoUrl,
        'notes': notes,
      },
    );

    if (response['report'] != null) {
      return AiReviewModel.fromJson(response['report']);
    }
    throw ApiException('Failed to parse AI review report');
  }
}
