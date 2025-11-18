// lib/controllers/user_management_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserManagementController {
  final String _baseUrl = 'http://192.168.1.198:3000/api';

  Future<List<User>> loadUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load users (status ${response.statusCode})');
    }
  }

  Future<bool> updateUserRole(int userId, String newRole) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId/role'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': newRole}),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteUser(int userId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/users/$userId'));
    return response.statusCode == 200;
  }
}