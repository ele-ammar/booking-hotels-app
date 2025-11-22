// lib/models/user.dart
class User {
  String id;
  String username;
  String email;
  String role; // 👈 plus "final" → mutable

  User({required this.id, required this.username, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return User(
      id: id is String ? id : id.toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: (json['role'] as String?)?.toLowerCase() ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';



  // ✅ Optionnel : mettre à jour proprement
  void updateRole(String newRole) {
    role = newRole.toLowerCase();
  }
}