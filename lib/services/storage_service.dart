import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'trustpay_access_token';
  static const String _keyRefreshToken = 'trustpay_refresh_token';
  static const String _keyUserRole = 'trustpay_user_role';
  static const String _keyUserId = 'trustpay_user_id';
  static const String _keyUserName = 'trustpay_user_name';
  static const String _keyUserEmail = 'trustpay_user_email';
  static const String _keyCustomHost = 'trustpay_custom_host';

  static Future<void> saveCustomHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    if (host.isEmpty) {
      await prefs.remove(_keyCustomHost);
    } else {
      await prefs.setString(_keyCustomHost, host);
    }
  }

  static Future<String?> getCustomHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomHost);
  }

  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_keyUserId) ?? '',
      'name': prefs.getString(_keyUserName) ?? '',
      'email': prefs.getString(_keyUserEmail) ?? '',
      'role': prefs.getString(_keyUserRole) ?? '',
    };
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
  }
}
