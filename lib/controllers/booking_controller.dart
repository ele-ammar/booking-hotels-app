// lib/controllers/booking_controller.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/reservation.dart';

class BookingController extends ChangeNotifier {
  final String _baseUrl = 'http://192.168.1.198:3000/api';

  bool _isLoading = false;
  String? _error;
  List<Reservation> _bookings = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Reservation> get bookings => _bookings;

  // ✅ Sans token — seul user.id est utilisé côté backend
  // lib/controllers/booking_controller.dart

  Future<Reservation?> saveBooking({
    required String userId,
    required String hotelId,
    required String hotelName,     // ✅ Nouveau
    required String hotelImageUrl, // ✅ Nouveau
    required String hotelLocation, // ✅ Nouveau
    required int hotelStars,       // ✅ Nouveau
    required String roomType,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required double totalPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = {
        'userId': userId,
        'hotelId': hotelId,
        'hotelName': hotelName,       // ✅
        'hotelImageUrl': hotelImageUrl, // ✅
        'hotelLocation': hotelLocation, // ✅
        'hotelStars': hotelStars,     // ✅
        'roomType': roomType,
        'checkIn': checkIn.toIso8601String().split('T')[0],
        'checkOut': checkOut.toIso8601String().split('T')[0],
        'guests': guests,
        'totalPrice': totalPrice.toStringAsFixed(2), // ✅ Toujours 2 décimales
      };

      print('📤 Sending hotel data: ${hotelName}, ${hotelImageUrl}'); // Pour debug

      final response = await http.post(
        Uri.parse('$_baseUrl/reservations/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      _isLoading = false;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final reservation = Reservation.fromJson(data['reservation']);
        _bookings.insert(0, reservation);
        notifyListeners();
        return reservation;
      } else {
        _error = 'Server error: ${response.statusCode}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  // Chargement des réservations — utilise userId
  Future<void> loadUserBookings(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_baseUrl/reservations/user/$userId'));
      _isLoading = false;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _bookings = data.map((json) => Reservation.fromJson(json)).toList();
        notifyListeners();
      } else {
        _error = 'Failed to load bookings';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String reservationId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/reservations/$reservationId'));
      if (response.statusCode == 200) {
        _bookings.removeWhere((r) => r.id == reservationId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }


  // lib/controllers/booking_controller.dart

// ✅ Mettre à jour le statut d'une réservation
  Future<bool> updateReservationStatus(String reservationId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/reservations/$reservationId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        // ✅ Mettre à jour localement
        final updatedReservation = Reservation.fromJson(jsonDecode(response.body)['reservation']);
        final index = _bookings.indexWhere((r) => r.id == reservationId);
        if (index != -1) {
          _bookings[index] = updatedReservation;
          notifyListeners();
        }
        return true;
      }
      _error = 'Server error: ${response.statusCode}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }





}