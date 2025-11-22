// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static Future<Map<String, dynamic>?> getJson(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erreur GET: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> postJson(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erreur POST: $e');
    }
    return null;
  }

  static Future<bool> delete(String url) async {
    try {
      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur DELETE: $e');
      return false;
    }
  }

  static Future getUserReservations(String string) async {}
}