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
  factory Hotel.fromJson(Map<dynamic, dynamic> json) {
    // Convertit dynamiquement les clés en String (sécurité)
    Map<String, dynamic> safeJson = {};
    json.forEach((key, value) {
      safeJson[key.toString()] = value;
    });

    return Hotel(
      id: safeJson['id']?.toString() ?? '',
      name: safeJson['name']?.toString() ?? '',
      location: safeJson['location']?.toString() ?? '',
      pricePerMonth: (safeJson['price_per_month'] as num?)?.toDouble() ?? 0.0,
      stars: safeJson['stars'] is int ? safeJson['stars'] as int : (safeJson['stars'] as num?)?.toInt() ?? 5,
      imageUrl: safeJson['image_url']?.toString() ?? '',
      description: safeJson['description']?.toString() ?? '',
      facilities: (safeJson['facilities'] as List<dynamic>?)
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

  double calculateEstimatedPrice({
    required DateTime? checkIn,
    required DateTime? checkOut,
    required int guests,
  }) {
    if (checkIn == null || checkOut == null || checkOut.isBefore(checkIn)) {
      return 0.0;
    }

    int nights = checkOut.difference(checkIn).inDays;
    if (nights <= 0) return 0.0;

    // Prix par nuit (basé sur 30 jours/mois)
    double pricePerNight = pricePerMonth / 30;

    // Prix de base
    double basePrice = pricePerNight * nights;

    // Supplément après 2 personnes (+10 TND/nuit/personne)
    const double extraPerGuest = 10.0;
    int extraGuests = (guests - 2).clamp(0, 10);
    double extraPrice = extraGuests * extraPerGuest * nights;

    // +10% taxe
    const double taxRate = 0.1;
    double total = (basePrice + extraPrice) * (1 + taxRate);

    return total;
  }
}