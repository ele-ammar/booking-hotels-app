import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/room.dart';

class RoomController extends ChangeNotifier {
  final String _baseUrl = 'http://192.168.1.198:3000/api/rooms'; // 🔁 à configurer

  List<Room> _rooms = [];
  Room? _selectedRoom;
  bool _isLoading = false;
  String? _error;

  List<Room> get rooms => _rooms;
  Room? get selectedRoom => _selectedRoom;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRoomsForHotel(String hotelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_baseUrl?hotelId=$hotelId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _rooms = data.map((r) => Room.fromJson(r)).toList();
      } else {
        _error = 'Erreur: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Room?> getRoomById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$id'));
      if (response.statusCode == 200) {
        return Room.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<Room?> createRoom(Room room) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(room.toJson()),
      );
      if (response.statusCode == 201) {
        final newRoom = Room.fromJson(jsonDecode(response.body));
        _rooms.add(newRoom);
        notifyListeners();
        return newRoom;
      }
    } catch (_) {}
    return null;
  }

  Future<Room?> updateRoom(Room room) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${room.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(room.toJson()),
      );
      if (response.statusCode == 200) {
        final updated = Room.fromJson(jsonDecode(response.body));
        final i = _rooms.indexWhere((r) => r.id == updated.id);
        if (i != -1) _rooms[i] = updated;
        notifyListeners();
        return updated;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteRoom(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id'));
      if (response.statusCode == 200) {
        _rooms.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}