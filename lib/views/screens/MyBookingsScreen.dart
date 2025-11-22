import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/reservation.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late BookingController _bookingController;
  late AuthController _authController;

  @override
  void initState() {
    super.initState();
    _bookingController = Provider.of<BookingController>(context, listen: false);
    _authController = Provider.of<AuthController>(context, listen: false);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final user = _authController.currentUser;
    if (user != null) {
      await _bookingController.loadUserBookings(user.id.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('My Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: Consumer<BookingController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final bookings = controller.bookings;
            if (bookings.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) => _buildBookingCard(bookings[index], controller),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border, size: 48, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'No saved bookings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Save Booking" to store your reservations.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Reservation reservation, BookingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ Image de l'hôtel (web ou placeholder)
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImage(reservation.hotelImageUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏨 Nom de l'hôtel + localisation
                Text(
                  reservation.hotelName ?? 'Hotel #${reservation.hotelId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (reservation.hotelLocation != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    reservation.hotelLocation!,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // 📅 Dates
                Text(
                  '${_formatDate(reservation.checkInDate)} → ${_formatDate(reservation.checkOutDate)}',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                // 💰 Prix
                Text(
                  '${reservation.totalPrice.toStringAsFixed(0)} DT',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00AEEF),
                  ),
                ),
                const SizedBox(height: 8),
                // 🛏️ Chambre + Guests
                Text('${reservation.guests} guest${reservation.guests > 1 ? 's' : ''} • ${reservation.roomType}'),

                const SizedBox(height: 16),

                // 🔘 Statut + Boutons
                Row(
                  children: [
                    // PENDING
                    if (reservation.status != 'cancelled')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await controller.updateReservationStatus(reservation.id, 'pending');
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Status: PENDING')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: reservation.status == 'pending'
                                ? Colors.orange
                                : Colors.orange.withOpacity(0.3),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('PENDING', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    if (reservation.status != 'cancelled') const SizedBox(width: 8),

                    // CONFIRMED
                    if (reservation.status != 'cancelled')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await controller.updateReservationStatus(reservation.id, 'confirmed');
                            if (success) {
                              Navigator.pushNamed(context, '/payment');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: reservation.status == 'confirmed'
                                ? Colors.green
                                : Colors.green.withOpacity(0.3),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('CONFIRMED', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    if (reservation.status != 'cancelled') const SizedBox(width: 8),

                    // CANCELLED
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await controller.updateReservationStatus(reservation.id, 'cancelled');
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reservation cancelled'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: reservation.status == 'cancelled'
                              ? Colors.red
                              : Colors.red.withOpacity(0.3),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('CANCELLED', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Gestion robuste des images
  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.hotel, size: 40, color: Colors.grey)),
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
        progress == null ? child : Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Center(child: Text('Image\nnot\nfound')),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}