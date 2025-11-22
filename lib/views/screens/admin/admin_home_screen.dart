import 'package:booking/views/screens/admin/AdminPlaceListScreen.dart';
import 'package:booking/views/screens/admin/UserManagementScreen.dart';
import 'package:flutter/material.dart';
import '../admin/admin_hotel_list_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Icon(Icons.menu, color: Colors.black),
        title: Text(
          'Tableau de bord',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF00AEEF).withOpacity(0.15),
            child: Icon(Icons.person, color: Color(0xFF00AEEF), size: 20),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 Bienvenue
            Text(
              'Bonjour, Admin !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Gérez votre plateforme en un clin d’œil.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),

            // 🔲 Statistiques (valeurs fixes – gérées par le contrôleur plus tard)
            Row(
              children: [
                _buildStatCard('12', 'Hôtels', Icons.hotel_outlined, Colors.blue[50]!),
                SizedBox(width: 16),
                _buildStatCard('248', 'Utilisateurs', Icons.group_outlined, Colors.green[50]!),
              ],
            ),
            SizedBox(height: 30),

            // 🧭 Actions rapides
            Text(
              'Actions rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Grille des actions
            Expanded(
              child: GridView.count(
                crossAxisCount:2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1,
                children: [
                  _buildActionCard(
                    context,
                    'Gérer les hôtels',
                    Icons.hotel,
                    Color(0xFF00AEEF),
                        () => _navigateTo(context, AdminHotelListScreen()),
                  ),
                  _buildActionCard(
                    context,
                    'Gérer les comptes',
                    Icons.people,
                    Color(0xFFF5A623),
                        () => _navigateTo(context, UserManagementScreen()),


                  ),
                  _buildActionCard(
                    context,
                    'Gérer les places',
                    Icons.place_sharp,

                    Color(0xFFEFC3CA),
                        () => _navigateTo(context, AdminPlaceListScreen()),


                  ),
                  _buildActionCard(
                    context,
                    'Gèrer les chambres',
                    Icons.settings,
                    Color(0xFF6A5ACD),
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Paramètres à venir')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte de statistique (view only)
  Widget _buildStatCard(String value, String label, IconData icon, Color bgColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black54, size: 24),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(label, style: TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // Carte d'action (view only)
  Widget _buildActionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}