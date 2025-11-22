import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/RoomController.dart';
import '../../../models/room.dart';
import 'AdminRoomEditScreen.dart';


class AdminRoomListScreen extends StatelessWidget {
  final String hotelId;
  final String hotelName;

  const AdminRoomListScreen({
    Key? key,
    required this.hotelId,
    required this.hotelName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roomController = Provider.of<RoomController>(context);

    if (roomController.rooms.isEmpty && !roomController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        roomController.loadRoomsForHotel(hotelId);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chambres — $hotelName',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<RoomController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (controller.error != null) {
            return Center(child: Text('❌ ${controller.error}'));
          }
          if (controller.rooms.isEmpty) {
            return Center(child: Text('Aucune chambre'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.rooms.length,
            itemBuilder: (context, index) {
              final room = controller.rooms[index];
              return _buildRoomCard(context, room, controller);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF00AEEF),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminRoomEditScreen(hotelId: hotelId),
            ),
          ).then((_) => roomController.loadRoomsForHotel(hotelId));
        },
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, Room room, RoomController controller) {
    Widget buildImage() {
      final url = room.imageUrl.trim();

      // ✅ Cas 1 : URL réseau (http/https)
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
            );
          },
        );
      }

      // ✅ Cas 2 : Asset local (assets/...)
      if (url.startsWith('assets/') || url.contains('.')) {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.image, color: Colors.grey)),
            );
          },
        );
      }

      // ✅ Cas 3 : URL vide ou invalide → placeholder
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel, size: 30, color: Colors.grey),
              Text('Room', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

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
                child: buildImage(), // ✅ Utilise la logique améliorée
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text('${room.bedType} • max ${room.maxGuests} pers', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.bed, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text('${room.amenities.length} équipements'),
                      Spacer(),

                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.grey[700]),
                  onPressed: () {
                    // Optionnel : prévisualisation
                  },
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminRoomEditScreen(
                          hotelId: room.hotelId,
                          roomId: room.id,
                        ),
                      ),
                    ).then((_) => controller.loadRoomsForHotel(room.hotelId));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Supprimer ?'),
                        content: Text('Supprimer "${room.name}" ?'),
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
                      await controller.deleteRoom(room.id);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}