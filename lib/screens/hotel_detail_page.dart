// lib/screens/user/hotel_detail_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class HotelDetailPage extends StatefulWidget {
  final String hotelId; // ← Requis : ID MongoDB de l'hôtel

  const HotelDetailPage({Key? key, required this.hotelId}) : super(key: key);

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  Map<String, dynamic>? _hotel;
  bool _isLoading = true;
  String? _error;

  final String _baseUrl = 'http://192.168.1.25:3000/api/hotels'; // ← Ton IP locale

  @override
  void initState() {
    super.initState();
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/${widget.hotelId}'));
      if (response.statusCode == 200) {
        setState(() {
          _hotel = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Hôtel non trouvé');
      }
    } on SocketException {
      setState(() {
        _error = 'Pas de connexion internet';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[200],
          child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[200],
          child: Center(child: Text('Image\nnon trouvée', textAlign: TextAlign.center)),
        ),
      );
    }
  }

  Widget _buildFacilityTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }

  @override

  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: BackButton()),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: BackButton()),
        body: Center(child: Text(_error!)),
      );
    }

    final hotel = _hotel!;
    final imageUrl = hotel['image_url'] ?? 'assets/images/default.jpg';

    // 🔧 Gestion sécurisée des facilities
    List<String> facilities = [];
    if (hotel['facilities'] is List) {
      facilities = hotel['facilities'].map<String>((e) => e.toString()).toList();
    } else {
      facilities = ['Free parking', 'WiFi'];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Étoiles + Cœur
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImage(imageUrl),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        Text(
                          '${hotel['stars'] ?? 5}',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: Icon(Icons.favorite_border, color: Colors.red),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Nom + Localisation + Prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel['name'] ?? 'Sans nom',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        hotel['location']?.toLowerCase() ?? 'Localisation inconnue',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(hotel['price_per_month'] ?? 0).toStringAsFixed(0)} TND',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF)),
                    ),
                    Text(
                      'per month',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 24),

            // Description
            Text(
              hotel['description'] ?? 'Aucune description disponible.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            SizedBox(height: 32),

            // Facilities
            Text(
              'HOTEL FACILITIES',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: facilities.map((f) => _buildFacilityTag(f)).toList(),
            ),

            SizedBox(height: 40),

            // Total + Bouton Réservation
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total TND ${(hotel['price_per_month'] ?? 0) * 2}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'for 2 months',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Réservation en cours...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00AEEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Reservation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}