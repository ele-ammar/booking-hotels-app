// lib/screens/user/booking_summary_screen.dart
import 'package:flutter/material.dart';
import '../../models/hotel.dart';

class BookingSummaryScreen extends StatelessWidget {
  final Hotel hotel;
  final String roomType;
  final double price;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;

  const BookingSummaryScreen({
    Key? key,
    required this.hotel,
    required this.roomType,
    required this.price,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
  }) : super(key: key);

  int get nights => checkIn != null && checkOut != null
      ? checkOut!.difference(checkIn!).inDays
      : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Summary')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(hotel.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hotel.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(hotel.location, style: TextStyle(color: Colors.grey)),
                      Text('$roomType • $guests guest${guests > 1 ? 's' : ''}'),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 32),
            _buildRow('Check-in', '${checkIn?.toLocal().day}/${checkIn?.toLocal().month}'),
            _buildRow('Check-out', '${checkOut?.toLocal().day}/${checkOut?.toLocal().month}'),
            _buildRow('Nights', '$nights'),
            _buildRow('Total', '${price.toStringAsFixed(0)} TND'),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/payment');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00AEEF),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('CONTINUE TO PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    ),
  );
}