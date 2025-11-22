import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/RoomController.dart';
import '../../../models/room.dart';


class AdminRoomEditScreen extends StatefulWidget {
  final String hotelId;
  final String? roomId;

  const AdminRoomEditScreen({
    Key? key,
    required this.hotelId,
    this.roomId,
  }) : super(key: key);

  @override
  State<AdminRoomEditScreen> createState() => _AdminRoomEditScreenState();
}

class _AdminRoomEditScreenState extends State<AdminRoomEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _amenitiesCtrl;
  late TextEditingController _bedTypeCtrl;
  late int _maxGuests;

  late bool _hasBreakfast;
  late bool _isNonRefundable;
  late bool _hasFreeCancellation;

  late RoomController _controller;
  Room? _existingRoom;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<RoomController>(context, listen: false);

    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _priceCtrl = TextEditingController(text: '50.0');
    _imageUrlCtrl = TextEditingController();
    _amenitiesCtrl = TextEditingController();
    _bedTypeCtrl = TextEditingController(text: '1 bed');
    _maxGuests = 2;

    _hasBreakfast = false;
    _isNonRefundable = false;
    _hasFreeCancellation = true;

    if (widget.roomId != null) {
      _loadRoom();
    }
  }

  Future<void> _loadRoom() async {
    final room = await _controller.getRoomById(widget.roomId!);
    if (room != null) {
      setState(() {
        _existingRoom = room;
        _nameCtrl.text = room.name;
        _descCtrl.text = room.description;
        _priceCtrl.text = room.pricePerNight.toString();
        _imageUrlCtrl.text = room.imageUrl;
        _amenitiesCtrl.text = room.amenities.join(', ');
        _bedTypeCtrl.text = room.bedType;
        _maxGuests = room.maxGuests;
        _hasBreakfast = room.hasBreakfast;
        _isNonRefundable = room.isNonRefundable;
        _hasFreeCancellation = room.hasFreeCancellation;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chambre non trouvée')));
    }
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prix invalide')));
      return;
    }

    final amenities = _amenitiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 🔍 DEBUG: Affiche les données envoyées
    print('📤 Envoi room:');
    print('- hotelId: ${widget.hotelId}');
    print('- name: ${_nameCtrl.text}');
    print('- price: $price');
    print('- amenities: $amenities');
    print('- hasBreakfast: $_hasBreakfast');

    final room = Room(
      id: _existingRoom?.id ?? '',
      hotelId: widget.hotelId,
      name: _nameCtrl.text,
      description: _descCtrl.text,
      pricePerNight: price,
      imageUrl: _imageUrlCtrl.text,
      bedType: _bedTypeCtrl.text,
      maxGuests: _maxGuests,
      amenities: amenities,
      hasBreakfast: _hasBreakfast,
      isNonRefundable: _isNonRefundable,
      hasFreeCancellation: _hasFreeCancellation,
    );

    bool success;
    try {
      if (_existingRoom == null) {
        final created = await _controller.createRoom(room);
        success = created != null;
        if (!success) {
          // 🔍 Affiche l'erreur du contrôleur
          print('❌ Erreur création: ${_controller.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur création : ${_controller.error ?? "inconnue"}')),
          );
          return;
        }
      } else {
        final updated = await _controller.updateRoom(room);
        success = updated != null;
        if (!success) {
          print('❌ Erreur mise à jour: ${_controller.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur mise à jour : ${_controller.error ?? "inconnue"}')),
          );
          return;
        }
      }

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_existingRoom == null ? 'Chambre créée !' : 'Chambre mise à jour !')),
        );
      }
    } catch (e) {
      print('🔥 Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exception: $e')));
    }
  }

  Future<void> _deleteRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer cette chambre ?'),
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

    if (confirm == true && widget.roomId != null) {
      final success = await _controller.deleteRoom(widget.roomId!);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chambre supprimée !')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression')));
      }
    }
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(child: Text('Aperçu\nimage', textAlign: TextAlign.center)),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: Center(child: Text('Image\nnon trouvée', textAlign: TextAlign.center)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (widget.roomId != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteRoom,
            ),
          IconButton(
            icon: Icon(Icons.save, color: Color(0xFF00AEEF)),
            onPressed: _saveRoom,
          ),
        ],
      ),
      body: Consumer<RoomController>(
        builder: (context, controller, child) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 🔹 Image + badge (comme hôtel)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: _buildImage(_imageUrlCtrl.text),
                        ),
                      ),
                      // Pas d'étoiles pour les chambres → on met un badge "Room"
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[700], // changé en bleu pour différencier
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hotel, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // 🔹 Nom
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nom de la chambre',
                      helperText: 'ex: Deluxe Suite, Standard Double',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  SizedBox(height: 16),

                  // 🔹 Type de lit
                  TextFormField(
                    controller: _bedTypeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Type de lit',
                      helperText: 'ex: 1 king bed, 2 single beds',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // 🔹 Prix + max guests
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Prix par nuit (TND)',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00AEEF)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (double.tryParse(v) == null) return 'Doit être un nombre';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          value: _maxGuests,
                          underline: SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                          items: [1, 2, 3, 4].map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('$e pers'),
                          )).toList(),
                          onChanged: (v) => setState(() => _maxGuests = v!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // 🔹 Description
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // 🔹 URL image
                  TextFormField(
                    controller: _imageUrlCtrl,
                    decoration: InputDecoration(
                      labelText: 'URL de l’image',
                      helperText: 'Lien direct vers une image (https://...)',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                    onChanged: (value) => setState(() {}),
                  ),
                  SizedBox(height: 16),

                  // 🔹 Amenities
                  TextFormField(
                    controller: _amenitiesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Équipements (séparés par des virgules)',
                      helperText: 'ex: Free WiFi, TV, Minibar, Clim',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // 🔹 Options (toggle)
                  SwitchListTile(
                    title: Text('Petit-déjeuner inclus'),
                    value: _hasBreakfast,
                    onChanged: (v) => setState(() => _hasBreakfast = v),
                    activeColor: Color(0xFF00AEEF),
                  ),
                  SwitchListTile(
                    title: Text('Non remboursable'),
                    value: _isNonRefundable,
                    onChanged: (v) => setState(() => _isNonRefundable = v),
                    activeColor: Colors.red,
                  ),
                  SwitchListTile(
                    title: Text('Annulation gratuite'),
                    value: _hasFreeCancellation,
                    onChanged: (v) => setState(() => _hasFreeCancellation = v),
                    activeColor: Colors.green,
                  ),
                  SizedBox(height: 32),

                  // 🔹 Bouton sauvegarder (en bas, comme hôtel)
                  ElevatedButton(
                    onPressed: _saveRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00AEEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _existingRoom == null ? 'Créer la chambre' : 'Mettre à jour',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}