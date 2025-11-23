import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {'email': email, 'password': password});
      // response is already decoded JSON map
      final loginResponse = LoginResponse.fromJson(response);
      if (loginResponse.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', loginResponse.token!);
        if (loginResponse.roles != null) {
          await prefs.setStringList('roles', loginResponse.roles!);
        }
        _isAuthenticated = true;
        notifyListeners();
      }
      return loginResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? dob,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? zip,
  }) async {
    try {
      final Map<String, String> fields = {
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'password': password,
        'role': 'USER',
      };
      if (dob != null) fields['dob'] = dob;
      if (phone != null) fields['phone'] = phone;
      if (address != null) fields['address'] = address;
      if (city != null) fields['city'] = city;
      if (country != null) fields['country'] = country;
      if (zip != null) fields['zip'] = zip;
      await _apiService.postMultipart('/auth/register', fields);
    } catch (e) {
      rethrow;
    }
  }

  // Fetch current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      // response is already a decoded JSON map
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('roles');
    _isAuthenticated = false;
    notifyListeners();
  }
}
