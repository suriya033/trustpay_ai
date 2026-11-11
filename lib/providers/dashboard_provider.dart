import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Client Dashboard Stats
  int clientTotalProjects = 0;
  int clientActiveProjects = 0;
  int clientCompletedProjects = 0;
  int clientPendingApprovals = 0;
  double clientTotalBudget = 0.0;
  double clientApprovedMilestoneValue = 0.0;
  double clientCompletedSandboxPayments = 0.0;
  List<dynamic> clientRecentActivities = [];

  // Freelancer Dashboard Stats
  int freelancerAssignedProjects = 0;
  int freelancerActiveMilestones = 0;
  int freelancerPendingSubmissions = 0;
  int freelancerRevisionRequests = 0;
  int freelancerApprovedWork = 0;
  double freelancerTotalPaidSandbox = 0.0;
  List<dynamic> freelancerUpcomingDeadlines = [];
  List<TransactionModel> freelancerPaymentHistory = [];
  List<dynamic> freelancerRecentNotifications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStats(String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (role == 'client') {
        final res = await ApiService.get(ApiConstants.clientStats);
        clientTotalProjects = (res['totalProjects'] as num?)?.toInt() ?? 0;
        clientActiveProjects = (res['activeProjects'] as num?)?.toInt() ?? 0;
        clientCompletedProjects =
            (res['completedProjects'] as num?)?.toInt() ?? 0;
        clientPendingApprovals =
            (res['pendingApprovals'] as num?)?.toInt() ?? 0;
        clientTotalBudget =
            (res['totalProjectBudget'] as num?)?.toDouble() ?? 0.0;
        clientApprovedMilestoneValue =
            (res['approvedMilestoneValue'] as num?)?.toDouble() ?? 0.0;
        clientCompletedSandboxPayments =
            (res['completedSandboxPayments'] as num?)?.toDouble() ?? 0.0;
        clientRecentActivities =
            res['recentActivities'] is List ? res['recentActivities'] : [];
      } else {
        final res = await ApiService.get(ApiConstants.freelancerStats);
        freelancerAssignedProjects =
            (res['assignedProjects'] as num?)?.toInt() ?? 0;
        freelancerActiveMilestones =
            (res['activeMilestones'] as num?)?.toInt() ?? 0;
        freelancerPendingSubmissions =
            (res['pendingSubmissions'] as num?)?.toInt() ?? 0;
        freelancerRevisionRequests =
            (res['revisionRequests'] as num?)?.toInt() ?? 0;
        freelancerApprovedWork = (res['approvedWork'] as num?)?.toInt() ?? 0;
        freelancerTotalPaidSandbox =
            (res['totalPaidSandboxTransactionValue'] as num?)?.toDouble() ??
                0.0;
        freelancerUpcomingDeadlines =
            res['upcomingDeadlines'] is List ? res['upcomingDeadlines'] : [];
        freelancerRecentNotifications =
            res['recentNotifications'] is List
                ? res['recentNotifications']
                : [];

        if (res['paymentHistory'] is List) {
          freelancerPaymentHistory = (res['paymentHistory'] as List)
              .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
