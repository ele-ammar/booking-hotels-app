import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../models/hotel.dart';
import '/../controllers/hotel_controller.dart';

class AdminHotelEditScreen extends StatefulWidget {
  final String? hotelId;

  const AdminHotelEditScreen({Key? key, this.hotelId}) : super(key: key);

  @override
  State<AdminHotelEditScreen> createState() => _AdminHotelEditScreenState();
}

class _AdminHotelEditScreenState extends State<AdminHotelEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _facilitiesCtrl;
  late int _stars;

  late HotelController _controller;
  Hotel? _existingHotel;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<HotelController>(context, listen: false);

    _nameCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _imageUrlCtrl = TextEditingController();
    _facilitiesCtrl = TextEditingController();
    _stars = 5;

    if (widget.hotelId != null) {
      _loadHotel();
    }
  }

  Future<void> _loadHotel() async {
    final hotel = await _controller.getHotelById(widget.hotelId!);
    if (hotel != null) {
      setState(() {
        _existingHotel = hotel;
        _nameCtrl.text = hotel.name;
        _locationCtrl.text = hotel.location;
        _priceCtrl.text = hotel.pricePerMonth.toString();
        _descCtrl.text = hotel.description;
        _imageUrlCtrl.text = hotel.imageUrl;
        _stars = hotel.stars;
        _facilitiesCtrl.text = hotel.facilities.join(', ');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hôtel non trouvé')));
    }
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prix invalide')));
      return;
    }

    final facilities = _facilitiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final hotel = Hotel(
      id: widget.hotelId ?? '',
      name: _nameCtrl.text,
      location: _locationCtrl.text,
      pricePerMonth: price,
      description: _descCtrl.text,
      stars: _stars,
      imageUrl: _imageUrlCtrl.text,
      facilities: facilities,
    );

    bool success;
    if (widget.hotelId == null) {
      success = await _controller.createHotel(hotel) != null;
    } else {
      success = await _controller.updateHotel(hotel) != null;
    }

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.hotelId == null ? 'Hôtel créé !' : 'Hôtel mis à jour !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    }
  }

  Future<void> _deleteHotel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer cet hôtel ?'),
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

    if (confirm == true && widget.hotelId != null) {
      final success = await _controller.deleteHotel(widget.hotelId!);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hôtel supprimé !')));
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
          if (widget.hotelId != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteHotel,
            ),
          IconButton(
            icon: Icon(Icons.save, color: Color(0xFF00AEEF)),
            onPressed: _saveHotel,
          ),
        ],
      ),
      body: Consumer<HotelController>(
        builder: (context, controller, child) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
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
                              Text('$_stars', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nom de l’hôtel',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: InputDecoration(
                      labelText: 'Localisation',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Prix par mois (TND)',
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
                          value: _stars,
                          underline: SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                          items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('$e★', style: TextStyle(fontWeight: FontWeight.bold)),
                          )).toList(),
                          onChanged: (v) => setState(() => _stars = v!),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
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
                  TextFormField(
                    controller: _imageUrlCtrl,
                    decoration: InputDecoration(
                      labelText: 'URL de l’image',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                    onChanged: (value) => setState(() {}),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _facilitiesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Facilities (séparés par des virgules)',
                      helperText: 'Ex: Free parking, TV, WiFi',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00AEEF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveHotel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00AEEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.hotelId == null ? 'Créer' : 'Mettre à jour',
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