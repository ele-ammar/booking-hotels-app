// lib/screens/user/booking_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hotel.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/auth_controller.dart';
import 'MyBookingsScreen.dart';


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

  double get pricePerNight => nights > 0 ? price / nights : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Booking Summary'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header : Image + Hotel Name + Price/Night
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(hotel.imageUrl),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${hotel.location} • ${hotel.stars}★',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${pricePerNight.toStringAsFixed(0)} TND / night',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00AEEF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // 🔹 Section "Booking Date"
            Text(
              'Booking Date',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            _buildDetailRow('Check-in', '${checkIn?.toLocal().day}/${checkIn?.toLocal().month}'),
            _buildDetailRow('Check-out', '${checkOut?.toLocal().day}/${checkOut?.toLocal().month}'),
            _buildDetailRow('Guests', '$guests'),
            _buildDetailRow('Room', roomType),
            SizedBox(height: 24),

            Divider(height: 32, thickness: 1, color: Colors.grey[300]),

            // 🔹 Section "Amount"
            Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            _buildDetailRow('TND ${pricePerNight.toStringAsFixed(0)} x $nights', '${price.toStringAsFixed(0)} TND'),
            _buildDetailRow('Tax', 'TND 30'),
            Divider(height: 8, thickness: 1, color: Colors.grey[300]),
            _buildDetailRow('Total', '${price.toStringAsFixed(0)} TND'),

            Spacer(),

            // 🔵 Deux boutons
            Consumer<BookingController>(  // ✅ Utilisez Consumer pour accéder à l'instance
              builder: (context, bookingController, _) {
                return Row(
                  children: [
                    // 🔖 Bouton "Save Booking"
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final authController = Provider.of<AuthController>(context, listen: false);
                          final user = authController.currentUser;

                          if (user == null) {
                            Navigator.pushNamed(context, '/login');
                            return;
                          }

                          if (checkIn == null || checkOut == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select dates')),
                            );
                            return;
                          }

                          final reservation = await bookingController.saveBooking(
                            userId: user.id,
                            hotelId: hotel.id,
                            hotelName: hotel.name,         // ✅
                            hotelImageUrl: hotel.imageUrl, // ✅
                            hotelLocation: hotel.location, // ✅
                            hotelStars: hotel.stars,       // ✅
                            roomType: roomType,
                            checkIn: checkIn!,
                            checkOut: checkOut!,
                            guests: guests,
                            totalPrice: price,
                          );
                          if (reservation != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Saved to My Bookings!')),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(bookingController.error ?? 'Failed to save')),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF00AEEF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: bookingController.isLoading
                            ? CircularProgressIndicator(color: Color(0xFF00AEEF))
                            : Text(
                          'SAVE BOOKING',
                          style: TextStyle(color: Color(0xFF00AEEF), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // 💳 Bouton "Continue to Payment"
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/payment');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00AEEF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'CONTINUE TO PAYMENT',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: const Icon(Icons.hotel, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Center(child: Text('Image\nnot\nfound')),
        ),
      );
    }
  }
}