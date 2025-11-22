import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/RoomController.dart';
import '../../models/hotel.dart';
import '../../models/room.dart';
import 'booking_summary_screen.dart';

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

    return ChangeNotifierProvider<RoomController>(
      create: (_) => RoomController()..loadRoomsForHotel(hotel.id),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(hotel.name),
        ),
        body: Consumer<RoomController>(
          builder: (context, roomController, child) {
            if (roomController.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (roomController.error != null) {
              return Center(child: Text('❌ Erreur: ${roomController.error}'));
            }

            final rooms = roomController.rooms
                .where((room) => room.maxGuests >= guests)
                .toList();

            return SingleChildScrollView(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Image de l'hôtel + Étoiles
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

                    ],
                  ),
                  SizedBox(height: 24),

                  // 🔹 Dates & guests
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '${checkIn?.toLocal().day}/${checkIn?.toLocal().month} → ${checkOut?.toLocal().day}/${checkOut?.toLocal().month}',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.person_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('$guests guest${guests > 1 ? 's' : ''}', style: TextStyle(color: Colors.blue, fontSize: 14)),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // 🔹 Title "Available Rooms"
                  Text(
                    'Available Rooms',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF)),
                  ),
                  SizedBox(height: 16),

                  // 🔹 Liste des chambres — style carte du template
                  ...rooms.map((room) => _buildRoomCard(context, room, nights)).toList(),

                  SizedBox(height: 80), // espace en bas
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ⭐ Méthode robuste pour charger une image (web ou asset)
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

  Widget _buildRoomCard(BuildContext context, Room room, int nights) {
    final totalPrice = room.pricePerNight * nights;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.8),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ Image de la chambre (web ou asset)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: room.imageUrl.isNotEmpty
                  ? _buildImage(room.imageUrl) // ✅ Utilise la même méthode robuste
                  : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hotel, color: Colors.grey, size: 40),
                      SizedBox(height: 4),
                      Text('No image', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // ⭐ Étoiles + Nom
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.yellow[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 12),
                    SizedBox(width: 1),
                    Text(
                      '${hotel.stars}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  room.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // 🛏️ Type de lit + max guests
          Row(
            children: [
              Icon(Icons.bed, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(room.bedType, style: TextStyle(color: Colors.grey, fontSize: 12)),
              Spacer(),
              Icon(Icons.person_outline, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text('${room.maxGuests} guests', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          SizedBox(height: 12),

          // 📍 Description
          if (room.description.isNotEmpty)
            Text(
              room.description,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(height: 12),

          // 🔹 Equipements (chips)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: room.amenities.map((a) => Chip(label: Text(a))).toList(),
          ),
          SizedBox(height: 16),

          // 💰 Prix + breakfast
          Row(
            children: [
              Text(
                '${totalPrice.toStringAsFixed(0)} TND',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AEEF)),
              ),
              SizedBox(width: 8),
              if (room.hasBreakfast)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Breakfast included', style: TextStyle(color: Colors.green[800], fontSize: 12)),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'per stay • ${room.pricePerNight.toStringAsFixed(0)} TND/night',
            style: TextStyle(color: Colors.grey),
          ),

          SizedBox(height: 24),

          // 🚫 Politiques
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (room.isNonRefundable)
                Chip(
                  label: Text('Non-refundable'),
                  backgroundColor: Colors.red[100],
                ),
              if (room.hasFreeCancellation)
                Chip(
                  label: Text('Free cancellation'),
                  backgroundColor: Colors.blue[100],
                ),
            ],
          ),

          SizedBox(height: 24),

          // 🔵 Bouton "Select"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingSummaryScreen(
                      hotel: hotel,
                      roomType: room.name,
                      price: totalPrice,
                      checkIn: checkIn,
                      checkOut: checkOut,
                      guests: guests,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00AEEF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Select',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}