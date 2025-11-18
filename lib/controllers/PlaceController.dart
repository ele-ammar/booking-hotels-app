// lib/controllers/place_controller.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/place.dart';

class PlaceController with ChangeNotifier {
  List<Place> _places = [];
  bool _isLoading = false;
  String? _error;

  List<Place> get places => _places;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 🔹 ADAPTEZ CETTE URL À VOTRE IP
  static const String _baseUrl = 'http://192.168.1.198:3000/api/places';

  // 🔹 Pour la page utilisateur : filtrage par location
  Future<void> loadPlaces({String? location}) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // 👈 Cela peut interférer si déjà notifié

    debugPrint('🔍 loadPlaces appelé avec location: $location');

    try {
      final uri = location != null && location.toLowerCase() != 'tout'
          ? Uri.parse('$_baseUrl?location=$location')
          : Uri.parse(_baseUrl);

      final response = await http.get(uri);
      debugPrint('📡 Places response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('✅ Places reçues: $data');
        _places = data.map((json) => Place.fromJson(json)).toList();
      } else {
        _error = 'Erreur serveur (${response.statusCode})';
        debugPrint('❌ Places erreur: ${response.body}');
      }
    } catch (e) {
      _error = 'Erreur réseau';
      debugPrint('💥 loadPlaces exception: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
  // 🔹 Pour l'admin : charger TOUTES les places (sans filtre)
  Future<void> loadAllPlaces() async {
    await loadPlaces(); // équivalent à loadPlaces(location: null)
  }

  // 🔹 Méthodes admin (CRUD)
  Future<Place?> getPlaceById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$id'));
      if (response.statusCode == 200) {
        return Place.fromJson(json.decode(response.body));
      }
    } catch (e) {
      _error = 'Erreur chargement place';
    }
    return null;
  }

  Future<Place?> createPlace(Place place) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(place.toJson()),
      );
      if (response.statusCode == 201) {
        final newPlace = Place.fromJson(json.decode(response.body));
        _places.add(newPlace);
        notifyListeners();
        return newPlace;
      } else {
        _error = 'Erreur création (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Erreur réseau';
    }
    return null;
  }

  Future<bool> updatePlace(Place place) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${place.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(place.toJson()),
      );
      if (response.statusCode == 200) {
        final index = _places.indexWhere((p) => p.id == place.id);
        if (index != -1) {
          _places[index] = place;
          notifyListeners();
        }
        return true;
      } else {
        _error = 'Erreur mise à jour (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Erreur réseau';
    }
    return false;
  }

  Future<bool> deletePlace(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id'));
      if (response.statusCode == 204 || response.statusCode == 200) {
        _places.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur suppression (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Erreur réseau';
    }
    return false;
  }
}