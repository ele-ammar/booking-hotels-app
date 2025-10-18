// lib/screens/admin/admin_hotel_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../hotel_detail_page.dart';
import 'admin_hotel_edit_screen.dart';


class AdminHotelListScreen extends StatefulWidget {
  const AdminHotelListScreen({Key? key}) : super(key: key);

  @override
  State<AdminHotelListScreen> createState() => _AdminHotelListScreenState();
}

class _AdminHotelListScreenState extends State<AdminHotelListScreen> {
  List<dynamic> _hotels = [];
  bool _isLoading = true;
  final String _baseUrl = 'http://192.168.1.25:3000/api/hotels';

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        setState(() {
          _hotels = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHotel(String id, String name) async { // ← Changé en String
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer "$name" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(Uri.parse('$_baseUrl/$id'));
        if (response.statusCode == 200) {
          _loadHotels();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hôtel supprimé')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Gestion des Hôtels',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hotels.isEmpty
          ? Center(child: Text('Aucun hôtel trouvé'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _hotels.length,
        itemBuilder: (context, index) {
          final hotel = _hotels[index];
          return _buildHotelCard(hotel);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF00AEEF),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminHotelEditScreen()),
          ).then((_) => _loadHotels());
        },
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final String imageUrl = hotel['image_url'] ?? '';
    final bool isNetworkImage = imageUrl.startsWith('http');

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 100,
                child: isNetworkImage
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
                    : Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Center(child: Text('Img')),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel['name'] ?? 'Sans nom',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    hotel['location'] ?? '',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 16),
                      Text('${hotel['stars'] ?? 0}', style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text(
                        '${hotel['price_per_month']?.toStringAsFixed(0) ?? '0'} TND',
                        style: TextStyle(color: Color(0xFF00AEEF), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 🔥 NOUVEAU : Boutons d'action (3 icônes)
            Column(
              children: [
                // 👁️ Voir (Preview)
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.grey[700]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelDetailPage(hotelId: hotel['id']),
                      ),
                    );
                  },
                ),
                // ✏️ Modifier
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminHotelEditScreen(hotelId: hotel['id']),
                      ),
                    ).then((_) => _loadHotels());
                  },
                ),
                // 🗑️ Supprimer
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteHotel(hotel['id'], hotel['name']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}