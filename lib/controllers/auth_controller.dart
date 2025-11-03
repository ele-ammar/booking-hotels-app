// lib/controllers/auth_controller.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _authError; // ← Pour gérer les erreurs de login ET forgot password

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  final String baseUrl = 'http://192.168.1.198:3000/api';

  // 🔐 LOGIN
  Future<bool> login(String username, String password) async {
    _authError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        notifyListeners();
        return true;
      } else {
        final message = jsonDecode(response.body)['message'] ?? 'Identifiants invalides';
        _authError = message;
        return false;
      }
    } catch (e) {
      _authError = 'Erreur réseau';
      debugPrint('Network error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔄 FORGOT PASSWORD
  Future<bool> forgotPassword(String email) async {
    _authError = null;
    _isLoading = true;
    notifyListeners();

    try {
      // 🔁 Appel à /api/forgot-password (à créer dans ton backend)
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final message = jsonDecode(response.body)['message'] ?? 'Échec de la réinitialisation';
        _authError = message;
        return false;
      }
    } catch (e) {
      _authError = 'Erreur réseau';
      debugPrint('Forgot password error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }



  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _authError = null;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) return true;
      final message = jsonDecode(response.body)['message'] ?? 'Échec';
      _authError = message;
      return false;
    } catch (e) {
      _authError = 'Erreur réseau';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}