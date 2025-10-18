import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Pour SocketException

class AdminHotelEditScreen extends StatefulWidget {
  final String? hotelId; // MongoDB utilise des String (ObjectId)

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
  late TextEditingController _facilitiesCtrl; // ← Ajouté
  late int _stars = 5;
  bool _isLoading = false;

  // 🔁 URL avec ton IP locale (de ipconfig)
  final String _baseUrl = 'http://192.168.1.25:3000/api/hotels';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _priceCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _imageUrlCtrl = TextEditingController();
    _facilitiesCtrl = TextEditingController(); // ← Initialisé

    if (widget.hotelId != null) {
      _loadHotel();
    }
  }

  Future<void> _loadHotel() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/${widget.hotelId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _nameCtrl.text = data['name'] ?? '';
        _locationCtrl.text = data['location'] ?? '';
        _priceCtrl.text = (data['price_per_month'] ?? 0).toString();
        _descCtrl.text = data['description'] ?? '';
        _imageUrlCtrl.text = data['image_url'] ?? '';
        _stars = data['stars'] ?? 5;
        // Charger les facilities sous forme de chaîne "item1, item2"
        _facilitiesCtrl.text = (data['facilities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .join(', ') ?? '';
        setState(() {});
      } else {
        throw Exception('Hôtel non trouvé');
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pas de connexion internet')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prix invalide')));
      return;
    }

    // Convertir "Free parking, TV" → ["Free parking", "TV"]
    final facilities = _facilitiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final payload = {
      'name': _nameCtrl.text,
      'location': _locationCtrl.text,
      'price_per_month': price,
      'description': _descCtrl.text,
      'stars': _stars,
      'image_url': _imageUrlCtrl.text,
      'facilities': facilities, // ← Inclus dans le payload
    };

    setState(() => _isLoading = true);
    try {
      http.Response response;
      if (widget.hotelId == null) {
        response = await http.post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      } else {
        response = await http.put(
          Uri.parse('$_baseUrl/${widget.hotelId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.hotelId == null ? 'Créé avec succès !' : 'Mis à jour !')),
        );
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pas de connexion internet')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
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

    if (confirm == true) {
      try {
        final response = await http.delete(Uri.parse('$_baseUrl/${widget.hotelId}'));
        if (response.statusCode == 200) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Supprimé !')));
        } else {
          throw Exception('Erreur suppression');
        }
      } on SocketException {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pas de connexion internet')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Widget _buildImage(String imageUrl) {
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: Icon(Icons.favorite_border, color: Colors.red),
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
              // 🔥 CHAMP FACILITIES AJOUTÉ ICI
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
      ),
    );
  }
}