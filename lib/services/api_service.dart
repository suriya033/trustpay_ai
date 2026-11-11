import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode = 500, this.data});

  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request failed with status ${response.statusCode}';

    throw ApiException(message, statusCode: response.statusCode, data: body);
  }

  static Future<dynamic> get(String url) async {
    try {
      final headers = await _headers();
      debugPrint('[API GET] $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 25));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('[API GET ERROR] $url: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network or connection error. Please verify backend is running: $e');
    }
  }

  static Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _headers();
      debugPrint('[API POST] $url');
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 35));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('[API POST ERROR] $url: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network or connection error. Please verify backend is running: $e');
    }
  }

  static Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _headers();
      debugPrint('[API PUT] $url');
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 25));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('[API PUT ERROR] $url: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network or connection error: $e');
    }
  }

  static Future<dynamic> delete(String url) async {
    try {
      final headers = await _headers();
      debugPrint('[API DELETE] $url');
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 25));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }
}
