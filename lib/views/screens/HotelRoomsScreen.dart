// lib/screens/user/hotel_rooms_screen.dart
import 'package:flutter/material.dart';
import '../../models/hotel.dart';

class HotelRoomsScreen extends StatelessWidget {
  final Hotel hotel;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;

  const HotelRoomsScreen({
    Key? key,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nights = checkIn != null && checkOut != null
        ? checkOut!.difference(checkIn!).inDays
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(hotel.name),
        actions: [
          IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            Container(
              height: 160,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(hotel.imageUrl),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),

            // Dates & guests
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${checkIn?.toLocal().day}/${checkIn?.toLocal().month} → '
                    '${checkOut?.toLocal().day}/${checkOut?.toLocal().month} • $guests guest${guests > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),

            Text('Available Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 🔹 Liste des chambres (simulée — à remplacer par API plus tard)
            ...List.generate(3, (index) => _buildRoomCard(context, index, nights)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, int index, int nights) {
    final roomTypes = ['Standard Double', 'Twin Room', 'Deluxe Suite'];
    final beds = ['1 double bed', '2 single beds', '1 king bed + sofa'];
    final prices = [45.0, 50.0, 85.0];
    final amenities = [
      ['Free WiFi', 'TV', 'Air conditioning'],
      ['Free WiFi', 'TV', 'Ensuite bathroom', 'Desk'],
      ['Free WiFi', 'TV', 'Minibar', 'Balcony', 'Bathrobe', 'Slippers'],
    ];
    final discounts = [null, 'Genius discount: 10% off', 'Last room!'];
    final breakfast = [false, true, true];
    final policies = [
      [true, false], // [non-refundable, flexible]
      [false, true],
      [true, true],
    ];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roomTypes[index], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [Icon(Icons.bed, size: 16), Text('  ${beds[index]}')]),
                    const SizedBox(height: 4),
                    Row(children: [Icon(Icons.person, size: 16), Text('  Up to ${index == 2 ? 3 : 2} guests')]),
                  ],
                ),
              ),
              Image.network(
                'https://via.placeholder.com/100x70?text=Room',
                width: 100,
                height: 70,
                fit: BoxFit.cover,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: amenities[index].map((a) => Chip(label: Text(a))).toList(),
          ),
          const SizedBox(height: 16),

          // Price
          if (discounts[index] != null)
            Container(
              padding: EdgeInsets.all(6),
              color: Colors.green[100],
              child: Text(discounts[index]!, style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                '${(prices[index] * nights).toStringAsFixed(0)} TND',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF)),
              ),
              const SizedBox(width: 8),
              if (breakfast[index])
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                  child: Text('Breakfast included', style: TextStyle(color: Colors.green[800], fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('per stay • ${prices[index].toStringAsFixed(0)} TND/night', style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 12),

          // Policies
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (policies[index][0]) Chip(label: Text('Non-refundable'), backgroundColor: Colors.red[100]),
              if (policies[index][1]) Chip(label: Text('Free cancellation before check-in'), backgroundColor: Colors.blue[100]),
            ],
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/booking-summary',
                arguments: {
                  'hotel': hotel,
                  'roomType': roomTypes[index],
                  'price': prices[index] * nights,
                  'checkIn': checkIn,
                  'checkOut': checkOut,
                  'guests': guests,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF00AEEF),
              side: BorderSide(color: Color(0xFF00AEEF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}