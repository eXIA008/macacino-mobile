import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['username'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  ApiService? _apiService;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  
  ApiService get apiService {
    _apiService ??= ApiService(_token);
    return _apiService!;
  }

  AuthProvider() {
    _loadStoredAuth();
  }

  // Load active token & user details from storage
  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');

    if (token != null && userJson != null) {
      _token = token;
      _user = User.fromJson(json.decode(userJson));
      _apiService = ApiService(_token);
      notifyListeners();
    }
  }

  // Login action
  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tempApi = ApiService(null);
      final response = await tempApi.post(ApiConstants.loginUrl, {
        'username': username,
        'password': password,
      });

      if (response != null && response['token'] != null) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _apiService = ApiService(_token);

        // Persist local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', json.encode(_user!.toJson()));
      } else {
        throw Exception('Format response login tidak valid.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register action
  Future<void> register(String username, String email, String password, String passwordConfirmation) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tempApi = ApiService(null);
      final response = await tempApi.post(ApiConstants.registerUrl, {
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      if (response != null && response['token'] != null) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        _apiService = ApiService(_token);

        // Persist local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', json.encode(_user!.toJson()));
      } else {
        throw Exception('Format response registrasi tidak valid.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout action
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await apiService.post(ApiConstants.logoutUrl, {});
      }
    } catch (e) {
      // Allow logout even if API call fails (network issues, etc.)
    } finally {
      _token = null;
      _user = null;
      _apiService = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');

      _isLoading = false;
      notifyListeners();
    }
  }
}
