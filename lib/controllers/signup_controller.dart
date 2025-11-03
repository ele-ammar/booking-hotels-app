// lib/controllers/signup_controller.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupController extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// Envoie les données d'inscription à l'API
  /// Retourne true si succès (statusCode 201), false sinon
  Future<bool> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners(); // 👈 Informe la vue que isLoading a changé

    try {
      // 🔁 Utilise la même IP que dans ton LoginScreen
      final response = await http.post(
        Uri.parse('http://192.168.1.198:3000/api/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      // ✅ Succès : 201 Created
      if (response.statusCode == 201) {
        return true;
      }

      // ❌ Erreur serveur : on tente de lire le message
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('message')) {
          debugPrint('Erreur inscription : ${body['message']}');
        }
      } catch (e) {
        debugPrint('Réponse serveur invalide : ${response.body}');
      }

      return false;
    } catch (e) {
      // ❌ Erreur réseau (pas de connexion, timeout, etc.)
      debugPrint('Erreur réseau lors de l\'inscription : $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // 👈 Informe la vue que le chargement est terminé
    }
  }
}