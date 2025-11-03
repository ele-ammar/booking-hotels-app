// lib/models/hotel.dart
class Hotel {
  final String id;
  final String name;
  final String location;
  final double pricePerMonth;
  final int stars;
  final String imageUrl;
  final String description;
  final List<String> facilities;

  Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerMonth,
    required this.stars,
    required this.imageUrl,
    required this.description,
    required this.facilities,
  });

  // Factory pour créer un Hotel depuis JSON
  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'].toString(), // Convertir en String si nécessaire
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      pricePerMonth: (json['price_per_month'] as num?)?.toDouble() ?? 0.0,
      stars: json['stars'] as int? ?? 5,
      imageUrl: json['image_url'] ?? '',
      description: json['description'] ?? '',
      facilities: (json['facilities'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }

  // Méthode pour convertir en Map (pour envoyer à l'API)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'price_per_month': pricePerMonth,
      'description': description,
      'stars': stars,
      'image_url': imageUrl,
      'facilities': facilities,
    };
  }
}