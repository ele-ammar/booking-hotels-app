// lib/screens/admin/admin_place_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/PlaceController.dart';

import '../../../models/place.dart';
import 'AdminPlaceEditScreen.dart';


class AdminPlaceListScreen extends StatelessWidget {
  const AdminPlaceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final placeController = Provider.of<PlaceController>(context);

    if (placeController.places.isEmpty && !placeController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        placeController.loadPlaces();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Gestion des Places',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PlaceController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.places.isEmpty) {
            return Center(child: Text('Aucune place trouvée'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.places.length,
            itemBuilder: (context, index) {
              final place = controller.places[index];
              return _buildPlaceCard(context, place, controller);
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
            MaterialPageRoute(builder: (_) => AdminPlaceEditScreen()),
          ).then((_) => placeController.loadPlaces());
        },
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, Place place, PlaceController controller) {
    final bool isNetworkImage = place.imageUrl.startsWith('http');

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
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
                    : Image.asset(
                  place.imageUrl,
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
                    place.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    place.location,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                      SizedBox(width: 4),
                      Text(place.tag, style: TextStyle(color: Colors.orange, fontSize: 12)),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          place.badge,
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminPlaceEditScreen(placeId: place.id),
                      ),
                    ).then((_) => controller.loadPlaces());
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Supprimer ?'),
                        content: Text('Voulez-vous supprimer "${place.name}" ?'),
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
                      final success = await controller.deletePlace(place.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Place supprimée' : 'Erreur suppression'),
                        ),
                      );
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