// lib/screens/admin/admin_place_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/PlaceController.dart';
import '../../../models/place.dart';
import '../../../models/hotel.dart';
import '../../../controllers/hotel_controller.dart';

class AdminPlaceEditScreen extends StatefulWidget {
  final String? placeId;

  const AdminPlaceEditScreen({Key? key, this.placeId}) : super(key: key);

  @override
  State<AdminPlaceEditScreen> createState() => _AdminPlaceEditScreenState();
}

class _AdminPlaceEditScreenState extends State<AdminPlaceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _tagCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _descCtrl;

  // 🔹 Nouveaux contrôleurs pour la location
  late List<String> _hotelLocations;
  String? _selectedLocation;
  late bool _isOtherLocation;
  late TextEditingController _otherLocationCtrl;

  late PlaceController _placeController;
  Place? _existingPlace;

  @override
  void initState() {
    super.initState();
    _placeController = Provider.of<PlaceController>(context, listen: false);

    _nameCtrl = TextEditingController();
    _imageUrlCtrl = TextEditingController(text: 'https://via.placeholder.com/300x200');
    _tagCtrl = TextEditingController(text: 'Hot Deal');
    _badgeCtrl = TextEditingController(text: '2N/3D');
    _descCtrl = TextEditingController();

    // 🔹 Initialisation location
    _hotelLocations = [];
    _selectedLocation = null;
    _isOtherLocation = false;
    _otherLocationCtrl = TextEditingController();

    // Charger les locations depuis les hôtels
    _loadHotelLocations();

    // Charger la place si édition
    if (widget.placeId != null) {
      _loadPlace();
    }
  }

  Future<void> _loadHotelLocations() async {
    final hotelController = Provider.of<HotelController>(context, listen: false);

    // Charger les hôtels si pas encore fait
    if (hotelController.hotels.isEmpty && !hotelController.isLoading) {
      await hotelController.loadHotels();
    }

    // Extraire locations uniques, triées
    final locations = hotelController.hotels
        .map((h) => h.location.trim())
        .where((loc) => loc.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _hotelLocations = locations;
      // Si création et il y a des villes, pré-sélectionner la première
      if (widget.placeId == null && locations.isNotEmpty && _selectedLocation == null) {
        _selectedLocation = locations.first;
      }
    });
  }

  Future<void> _loadPlace() async {
    final place = await _placeController.getPlaceById(widget.placeId!);
    if (place != null) {
      setState(() {
        _existingPlace = place;
        _nameCtrl.text = place.name;
        _imageUrlCtrl.text = place.imageUrl;
        _tagCtrl.text = place.tag;
        _badgeCtrl.text = place.badge;
        _descCtrl.text = place.description;

        // 🔹 Gérer la location : existe-t-elle dans la liste ?
        if (_hotelLocations.contains(place.location)) {
          _selectedLocation = place.location;
          _isOtherLocation = false;
        } else {
          _selectedLocation = null;
          _isOtherLocation = true;
          _otherLocationCtrl.text = place.location;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Place non trouvée')));
    }
  }

  String? _getLocationValue() {
    if (_isOtherLocation) {
      final val = _otherLocationCtrl.text.trim();
      return val.isEmpty ? null : val;
    }
    return _selectedLocation;
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) return;

    final location = _getLocationValue();
    if (location == null || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez sélectionner ou entrer une localisation')));
      return;
    }

    final place = Place(
      id: widget.placeId ?? '',
      name: _nameCtrl.text,
      location: location, // ✅ valeur cohérente
      imageUrl: _imageUrlCtrl.text,
      tag: _tagCtrl.text,
      badge: _badgeCtrl.text,
      description: _descCtrl.text,
    );

    bool success;
    if (widget.placeId == null) {
      success = await _placeController.createPlace(place) != null;
    } else {
      success = await _placeController.updatePlace(place);
    }

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.placeId == null ? 'Place créée !' : 'Place mise à jour !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    }
  }

  Future<void> _deletePlace() async {
    if (widget.placeId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer cette place ?'),
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
      final success = await _placeController.deletePlace(widget.placeId!);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Place supprimée !')));
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

  // 🔹 Widget réutilisable pour la sélection de location
  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation *',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF00AEEF)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLocation,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              hint: Text('Sélectionnez une ville', style: TextStyle(color: Colors.grey)),
              items: [
                // ✅ Villes depuis les hôtels
                if (_hotelLocations.isEmpty)
                  DropdownMenuItem(
                    value: null,
                    enabled: false,
                    child: Text('Aucune ville disponible', style: TextStyle(color: Colors.grey)),
                  ),
                for (final loc in _hotelLocations)
                  DropdownMenuItem(
                    value: loc,
                    child: Text(loc),
                  ),
                // ➕ Option "Autre..."
                DropdownMenuItem(
                  value: '__OTHER__',
                  child: Text('➕ Ajouter une autre ville', style: TextStyle(color: Colors.blue)),
                ),
              ],
              onChanged: (value) {
                if (value == '__OTHER__') {
                  setState(() {
                    _isOtherLocation = true;
                    _selectedLocation = null;
                  });
                } else {
                  setState(() {
                    _isOtherLocation = false;
                    _selectedLocation = value;
                  });
                }
              },
            ),
          ),
        ),
        // ✏️ Champ texte si "Autre..."
        if (_isOtherLocation)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: TextFormField(
              controller: _otherLocationCtrl,
              decoration: InputDecoration(
                labelText: 'Nom de la nouvelle ville',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF00AEEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF00AEEF), width: 2),
                ),
              ),
              validator: (value) {
                final val = value?.trim();
                if (val == null || val.isEmpty) return 'Requis';
                return null;
              },
            ),
          ),
      ],
    );
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
          if (widget.placeId != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deletePlace,
            ),
          IconButton(
            icon: Icon(Icons.save, color: Color(0xFF00AEEF)),
            onPressed: _savePlace,
          ),
        ],
      ),
      body: Padding(
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
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(_tagCtrl.text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _badgeCtrl.text,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom de la place *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00AEEF)),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              SizedBox(height: 16),

              // 🔹 LOCATION FIELD — remplace l'ancien TextFormField
              _buildLocationField(),
              SizedBox(height: 16),

              TextFormField(
                controller: _imageUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'URL de l’image *',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00AEEF)),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
                onChanged: (value) => setState(() {}),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tag (ex: Hot Deal)',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00AEEF)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _badgeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Badge (ex: 2N/3D)',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00AEEF)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description (optionnelle)',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00AEEF)),
                  ),
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _savePlace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00AEEF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.placeId == null ? 'Créer la place' : 'Mettre à jour',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}