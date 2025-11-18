// lib/models/HotelCardData.dart
class HotelCardData {
  final String id;
  final String? hotelId; // 👈 nullable
  final String name;
  final String location;
  final double pricePerMonth;
  final int stars;
  final String imageUrl;
  final List<String> facilitiesPreview;
  final bool isFavorite;

  HotelCardData({
    required this.id,
    this.hotelId, // 👈 pas required
    required this.name,
    required this.location,
    required this.pricePerMonth,
    required this.stars,
    required this.imageUrl,
    required this.facilitiesPreview,
    this.isFavorite = false,
  });

  HotelCardData copyWith({
    String? id,
    String? hotelId,
    String? name,
    String? location,
    double? pricePerMonth,
    int? stars,
    String? imageUrl,
    List<String>? facilitiesPreview,
    bool? isFavorite,
  }) {
    return HotelCardData(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      location: location ?? this.location,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      stars: stars ?? this.stars,
      imageUrl: imageUrl ?? this.imageUrl,
      facilitiesPreview: facilitiesPreview ?? this.facilitiesPreview,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory HotelCardData.fromJson(Map<String, dynamic> json) {
    final facilities = (json['facilities_preview'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? ['WiFi', 'Parking'];

    return HotelCardData(
      id: (json['id'] ?? '').toString(),
      hotelId: json['hotel_id'] != null
          ? json['hotel_id'].toString()
          : null, // ✅ propre gestion de null
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      pricePerMonth: (json['price_per_month'] as num?)?.toDouble() ?? 0.0,
      stars: json['stars'] as int? ?? 5,
      imageUrl: json['image_url'] ?? '',
      facilitiesPreview: facilities,
    );
  }
}