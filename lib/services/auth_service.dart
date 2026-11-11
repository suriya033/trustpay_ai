import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConstants.login,
      body: {'email': email.trim(), 'password': password},
    );

    final user = UserModel.fromJson(response['user']);
    await StorageService.saveAuthData(
      accessToken: response['accessToken'] ?? '',
      refreshToken: response['refreshToken'] ?? '',
      role: user.role,
      userId: user.id,
      name: user.name,
      email: user.email,
    );

    return user;
  }

  static Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await ApiService.post(
      ApiConstants.register,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
      },
    );

    final user = UserModel.fromJson(response['user']);
    await StorageService.saveAuthData(
      accessToken: response['accessToken'] ?? '',
      refreshToken: response['refreshToken'] ?? '',
      role: user.role,
      userId: user.id,
      name: user.name,
      email: user.email,
    );

    return user;
  }

  static Future<UserModel?> getMe() async {
    try {
      final response = await ApiService.get(ApiConstants.me);
      if (response['user'] != null) {
        return UserModel.fromJson(response['user']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<UserModel> updateProfile({
    String? name,
    String? bio,
    List<String>? skills,
    String? avatar,
  }) async {
    final response = await ApiService.put(
      ApiConstants.profile,
      body: {
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (skills != null) 'skills': skills,
        if (avatar != null) 'avatar': avatar,
      },
    );

    return UserModel.fromJson(response['user']);
  }

  static Future<String?> forgotPassword(String email) async {
    final response = await ApiService.post(
      ApiConstants.forgotPassword,
      body: {'email': email.trim()},
    );
    return response['resetCode']?.toString();
  }

  static Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    await ApiService.post(
      ApiConstants.resetPassword,
      body: {
        'email': email.trim(),
        'resetCode': resetCode.trim(),
        'newPassword': newPassword,
      },
    );
  }

  static Future<List<UserModel>> getFreelancers() async {
    final response = await ApiService.get(ApiConstants.freelancers);
    if (response is List) {
      return response
          .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConstants.logout);
    } catch (_) {}
    await StorageService.clearAuthData();
  }
}
