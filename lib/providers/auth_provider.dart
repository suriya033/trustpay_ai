import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isClient => _user?.isClient ?? false;
  bool get isFreelancer => _user?.isFreelancer ?? false;

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        _user = await AuthService.getMe();
        if (_user == null) {
          final info = await StorageService.getUserInfo();
          if (info['id']!.isNotEmpty) {
            _user = UserModel(
              id: info['id']!,
              name: info['name']!,
              email: info['email']!,
              role: info['role']!,
            );
          }
        }
      }
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await AuthService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await AuthService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    List<String>? skills,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await AuthService.updateProfile(
        name: name,
        bio: bio,
        skills: skills,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
