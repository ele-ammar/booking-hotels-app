class Reservation {
  final String id;
  final String userId;
  final int hotelId;
  final String roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  // ✅ CHAMPS SUPPLÉMENTAIRES (de la jointure SQL)
  final String? hotelName;
  final String? hotelLocation;
  final String? hotelImageUrl;

  Reservation({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.hotelName,        // ✅
    this.hotelLocation,    // ✅
    this.hotelImageUrl,    // ✅
  });

  // ✅ Constructeur corrigé — gère String et num + champs supplémentaires
  factory Reservation.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final clean = value.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
        return double.tryParse(clean) ?? 0.0;
      }
      return 0.0;
    }

    int _parseInt(dynamic value) {
      if (value == null) return 1;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 1;
      return 1;
    }

    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Reservation(
      id: json['id']?.toString() ?? '0',
      userId: json['user_id']?.toString() ?? '0',
      hotelId: _parseInt(json['hotel_id']),
      roomType: json['room_type']?.toString() ?? 'Standard',
      checkInDate: _parseDate(json['check_in_date']),
      checkOutDate: _parseDate(json['check_out_date']),
      guests: _parseInt(json['guests']),
      totalPrice: _parseDouble(json['total_price']),
      status: (json['status'] as String?)?.toLowerCase() ?? 'pending',
      createdAt: _parseDate(json['created_at']),
      // ✅ Récupération des champs joints (de votre requête SQL)
      hotelName: json['hotel_name']?.toString(),
      hotelLocation: json['hotel_location']?.toString(),
      hotelImageUrl: json['hotel_image_url']?.toString(),
    );
  }

  // ✅ Convertir en JSON pour l'envoi
  Map<String, dynamic> toJson() => {
    'hotelId': hotelId,
    'roomType': roomType,
    'checkIn': checkInDate.toIso8601String().split('T')[0],
    'checkOut': checkOutDate.toIso8601String().split('T')[0],
    'guests': guests,
    'totalPrice': totalPrice.toStringAsFixed(2),
  };
}