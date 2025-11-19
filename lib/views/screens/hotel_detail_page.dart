// lib/screens/user/hotel_detail_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../models/hotel.dart';

class HotelDetailPage extends StatefulWidget {
  final String hotelId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;

  const HotelDetailPage({
    Key? key,
    required this.hotelId,
    this.checkIn,
    this.checkOut,
    this.guests = 2,
  }) : super(key: key);

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  Hotel? _hotel;
  bool _isLoading = true;
  String? _error;

  final String _baseUrl = 'http://192.168.1.198:3000/api/hotels';

  @override
  void initState() {
    super.initState();
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/${widget.hotelId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _hotel = Hotel.fromJson(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Hôtel non trouvé (HTTP ${response.statusCode})');
      }
    } on SocketException {
      setState(() {
        _error = 'Pas de connexion internet';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur: ${e.toString()}';
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
    final nights = widget.checkIn != null && widget.checkOut != null
        ? widget.checkOut!.difference(widget.checkIn!).inDays
        : 0;
    final estimatedPrice = hotel.calculateEstimatedPrice(
      checkIn: widget.checkIn,
      checkOut: widget.checkOut,
      guests: widget.guests,
    );

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
                  child: _buildImage(hotel.imageUrl),
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
                          '${hotel.stars}',
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

            // Nom + Localisation
            Text(
              hotel.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              hotel.location.toLowerCase(),
              style: TextStyle(color: Colors.grey),
            ),

            // 🔹 Dates & guests sélectionnés
            if (widget.checkIn != null && widget.checkOut != null)
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.checkIn!.toLocal().day}/${widget.checkIn!.toLocal().month} → '
                      '${widget.checkOut!.toLocal().day}/${widget.checkOut!.toLocal().month} • '
                      '${widget.guests} guest${widget.guests > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),

            SizedBox(height: 24),

            // Description
            Text(
              hotel.description,
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
              children: hotel.facilities.map(_buildFacilityTag).toList(),
            ),

            SizedBox(height: 40),

            // 🔹 Pricing + Bouton
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
                          'Total TND ${(estimatedPrice ?? 0.0).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (nights > 0)
                          Text(
                            'for $nights night${nights > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Text(
                            'Select dates to see price',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.checkIn == null || widget.checkOut == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Veuillez sélectionner des dates.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      Navigator.pushNamed(
                        context,
                        '/hotel-rooms',
                        arguments: {
                          'hotel': hotel,
                          'checkIn': widget.checkIn,
                          'checkOut': widget.checkOut,
                          'guests': widget.guests,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00AEEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Select rooms',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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