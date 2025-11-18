import 'package:flutter/material.dart';
import '../../../controllers/user_management_controller.dart';
import '../../../models/user.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementController _controller = UserManagementController();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _controller.loadUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(User user, String newRole) async {
    if (newRole == user.role) return;

    final success = await _controller.updateUserRole(int.parse(user.id), newRole);
    if (success) {
      setState(() {
        user.role = newRole; // Mutation directe (autoréeactive car StatefulWidget)
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rôle mis à jour')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la mise à jour')),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${user.username} ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.deleteUser(int.parse(user.id));
      if (success) {
        setState(() {
          _users.remove(user);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.username} supprimé')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des comptes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Aucun utilisateur'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: user.role == 'admin' ? Colors.orange : Colors.blue,
              child: Icon(
                user.role == 'admin'
                    ? Icons.admin_panel_settings
                    : Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔁 Changer rôle (sauf super-admin id = '1')
                if (user.id != '1')
                  PopupMenuButton<String>(
                    onSelected: (value) => _updateUserRole(user, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'user',
                        child: const Row(
                          children: [Icon(Icons.person_outline, size: 16), SizedBox(width: 8), Text('Utilisateur')],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'admin',
                        child: const Row(
                          children: [Icon(Icons.admin_panel_settings, size: 16), SizedBox(width: 8), Text('Admin')],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                // 🗑️ Supprimer
                if (user.id != '1')
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _deleteUser(user),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}