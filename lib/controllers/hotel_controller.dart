// lib/controllers/hotel_controller.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/hotel.dart';

class HotelController extends ChangeNotifier {
  List<Hotel> _hotels = [];
  List<Hotel> get hotels => _hotels;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final String baseUrl = 'http://192.168.1.198:3000/api/hotels';

  Future<void> loadHotels() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _hotels = data.map((json) => Hotel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erreur chargement hôtels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteHotel(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        _hotels.removeWhere((hotel) => hotel.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Erreur suppression: $e');
    }
    return false;
  }

  Future<Hotel?> createHotel(Hotel hotel) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(hotel.toJson()),
      );
      if (response.statusCode == 201) {
        final newHotel = Hotel.fromJson(jsonDecode(response.body));
        _hotels.add(newHotel);
        notifyListeners();
        return newHotel;
      }
    } catch (e) {
      debugPrint('Erreur création: $e');
    }
    return null;
  }

  Future<Hotel?> updateHotel(Hotel hotel) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${hotel.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(hotel.toJson()),
      );
      if (response.statusCode == 200) {
        final updated = Hotel.fromJson(jsonDecode(response.body));
        final index = _hotels.indexWhere((h) => h.id == hotel.id);
        if (index != -1) {
          _hotels[index] = updated;
          notifyListeners();
        }
        return updated;
      }
    } catch (e) {
      debugPrint('Erreur mise à jour: $e');
    }
    return null;
  }


  Future<Hotel?> getHotelById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        return Hotel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Erreur récupération hôtel: $e');
    }
    return null;
  }
}