import 'package:flutter/foundation.dart';
import '../models/ai_review_model.dart';
import '../models/project_model.dart';
import '../models/submission_model.dart';
import '../services/payment_service.dart';
import '../services/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  ProjectModel? _currentProject;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'all';

  List<ProjectModel> get projects => _projects;
  ProjectModel? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  void setFilter(String filter) {
    _currentFilter = filter;
    fetchProjects(status: filter);
  }

  Future<void> fetchProjects({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final filter = status ?? _currentFilter;
      _projects = await ProjectService.getProjects(status: filter);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProjectById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentProject = await ProjectService.getProjectById(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProjectModel?> createProject({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final project = await ProjectService.createProject(
        title: title,
        description: description,
        category: category,
        totalBudget: totalBudget,
        currency: currency,
        duration: duration,
        deadline: deadline,
        technicalRequirements: technicalRequirements,
        additionalInstructions: additionalInstructions,
        invitedFreelancerEmail: invitedFreelancerEmail,
        milestones: milestones,
      );

      _projects.insert(0, project);
      _currentProject = project;
      _isLoading = false;
      notifyListeners();
      return project;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> inviteFreelancer(
    String projectId, {
    String? freelancerId,
    String? email,
  }) async {
    try {
      final updated = await ProjectService.inviteFreelancer(
        projectId,
        freelancerId: freelancerId,
        email: email,
      );
      _currentProject = updated;
      _updateProjectInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> respondToAgreement(
    String projectId, {
    required String action,
    String? changeRequest,
  }) async {
    try {
      final updated = await ProjectService.freelancerAgreementRespond(
        projectId,
        action: action,
        changeRequest: changeRequest,
      );
      _currentProject = updated;
      _updateProjectInList(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<SubmissionModel?> submitWork({
    required String projectId,
    required String milestoneId,
    required String description,
    String githubUrl = '',
    String liveDemoUrl = '',
    String notes = '',
  }) async {
    try {
      final submission = await ProjectService.submitWork(
        projectId: projectId,
        milestoneId: milestoneId,
        description: description,
        githubUrl: githubUrl,
        liveDemoUrl: liveDemoUrl,
        notes: notes,
      );

      // Refresh project to get updated milestone state
      await fetchProjectById(projectId);
      return submission;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<AiReviewModel?> requestAiReview({
    required String projectId,
    required String milestoneId,
  }) async {
    try {
      final review = await ProjectService.requestAiReview(
        projectId: projectId,
        milestoneId: milestoneId,
      );
      await fetchProjectById(projectId);
      return review;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> clientDecision({
    required String projectId,
    required String milestoneId,
    required String decision,
    String feedback = '',
  }) async {
    try {
      await ProjectService.clientDecision(
        projectId: projectId,
        milestoneId: milestoneId,
        decision: decision,
        feedback: feedback,
      );
      await fetchProjectById(projectId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> processPayPalPayment({
    required String projectId,
    required String milestoneId,
  }) async {
    try {
      // 1. Create PayPal Order
      final order = await PaymentService.createPayPalOrder(
        projectId: projectId,
        milestoneId: milestoneId,
      );

      final orderId = order['orderId'] as String;

      // 2. Capture PayPal Payment (backend server-side capture)
      final captureResult = await PaymentService.capturePayPalOrder(
        projectId: projectId,
        milestoneId: milestoneId,
        orderId: orderId,
      );

      // Refresh current project
      await fetchProjectById(projectId);
      return captureResult;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _updateProjectInList(ProjectModel updated) {
    final index = _projects.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _projects[index] = updated;
    }
  }
}
