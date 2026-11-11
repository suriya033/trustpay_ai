import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';

class ApiConstants {
  static String customHost = '';

  static Future<void> init() async {
    final saved = await StorageService.getCustomHost();
    if (saved != null && saved.isNotEmpty) {
      customHost = saved;
    }
  }

  static String get baseUrl {
    if (customHost.isNotEmpty) {
      return customHost;
    }
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Local network IP of host machine for physical Android devices
      return 'http://192.168.1.160:5000';
    }
    // Windows, macOS, Linux desktop
    return 'http://localhost:5000';
  }

  // Auth Endpoints
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';
  static String get refreshToken => '$baseUrl/api/auth/refresh-token';
  static String get forgotPassword => '$baseUrl/api/auth/forgot-password';
  static String get resetPassword => '$baseUrl/api/auth/reset-password';
  static String get me => '$baseUrl/api/auth/me';
  static String get profile => '$baseUrl/api/auth/profile';
  static String get freelancers => '$baseUrl/api/auth/freelancers';
  static String get logout => '$baseUrl/api/auth/logout';

  // Project Endpoints
  static String get projects => '$baseUrl/api/projects';
  static String projectById(String id) => '$baseUrl/api/projects/$id';
  static String inviteFreelancer(String id) => '$baseUrl/api/projects/$id/invite-freelancer';
  static String freelancerAgreementRespond(String id) =>
      '$baseUrl/api/projects/$id/agreement/freelancer-respond';
  static String clientAgreementConfirm(String id) =>
      '$baseUrl/api/projects/$id/agreement/client-confirm';

  // Milestone Endpoints
  static String updateMilestone(String projectId, String milestoneId) =>
      '$baseUrl/api/projects/$projectId/milestones/$milestoneId';
  static String submitWork(String projectId, String milestoneId) =>
      '$baseUrl/api/projects/$projectId/milestones/$milestoneId/submit';
  static String milestoneAiReview(String projectId, String milestoneId) =>
      '$baseUrl/api/projects/$projectId/milestones/$milestoneId/ai-review';
  static String milestoneClientDecision(String projectId, String milestoneId) =>
      '$baseUrl/api/projects/$projectId/milestones/$milestoneId/client-decision';

  // AI Endpoints
  static String get generateMilestones => '$baseUrl/api/ai/generate-milestones';
  static String get reviewSubmission => '$baseUrl/api/ai/review-submission';

  // Payment Endpoints
  static String createPayPalOrder(String projectId, String milestoneId) =>
      '$baseUrl/api/payments/$projectId/milestones/$milestoneId/create-paypal-order';
  static String capturePayPalOrder(String projectId, String milestoneId) =>
      '$baseUrl/api/payments/$projectId/milestones/$milestoneId/capture-paypal-order';
  static String get transactions => '$baseUrl/api/payments/transactions';
  static String receipt(String id) => '$baseUrl/api/payments/transactions/$id/receipt';

  // Dashboard Endpoints
  static String get clientStats => '$baseUrl/api/dashboard/client-stats';
  static String get freelancerStats => '$baseUrl/api/dashboard/freelancer-stats';
}
