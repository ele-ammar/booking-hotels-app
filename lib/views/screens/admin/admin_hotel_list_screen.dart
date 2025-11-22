import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../models/hotel.dart';
import '/../controllers/hotel_controller.dart';
import '../hotel_detail_page.dart';
import 'AdminRoomListScreen.dart';
import 'admin_hotel_edit_screen.dart';

class AdminHotelListScreen extends StatelessWidget {
  const AdminHotelListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hotelController = Provider.of<HotelController>(context);

    // Charger les données au premier build (comme initState)
    if (hotelController.hotels.isEmpty && !hotelController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        hotelController.loadHotels();
      });
    }

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
      body: Consumer<HotelController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.hotels.isEmpty) {
            return Center(child: Text('Aucun hôtel trouvé'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.hotels.length,
            itemBuilder: (context, index) {
              final hotel = controller.hotels[index];
              return _buildHotelCard(context, hotel, controller);
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
            MaterialPageRoute(builder: (_) => AdminHotelEditScreen()),
          ).then((_) => hotelController.loadHotels());
        },
      ),
    );
  }

  Widget _buildHotelCard(BuildContext context, Hotel hotel, HotelController controller) {
    final bool isNetworkImage = hotel.imageUrl.startsWith('http');

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
                  hotel.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
                    : Image.asset(
                  hotel.imageUrl,
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
                    hotel.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    hotel.location,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 16),
                      Text('${hotel.stars}', style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text(
                        '${hotel.pricePerMonth.toStringAsFixed(0)} TND',
                        style: TextStyle(color: Color(0xFF00AEEF), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 🔥 Boutons d'action
            Column(
              children: [
                // 👁️ Voir
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.grey[700]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelDetailPage(hotelId: hotel.id),
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
                        builder: (_) => AdminHotelEditScreen(hotelId: hotel.id),
                      ),
                    ).then((_) => controller.loadHotels());
                  },
                ),
                // 🗑️ Supprimer
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Supprimer ?'),
                        content: Text('Voulez-vous supprimer "${hotel.name}" ?'),
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
                      final success = await controller.deleteHotel(hotel.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Hôtel supprimé' : 'Erreur suppression'),
                        ),
                      );
                    }
                  },
                ),

                // 🔹 Ajoute ce IconButton dans la colonne des actions (juste après le bouton "Modifier")
                IconButton(
                  icon: Icon(Icons.hotel, color: Colors.teal),
                  tooltip: 'Gérer les chambres',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminRoomListScreen(
                          hotelId: hotel.id,
                          hotelName: hotel.name,
                        ),
                      ),
                    );
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