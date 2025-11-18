// lib/models/place.dart
class Place {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final String tag;
  final String badge;
  final String description; // ajouté pour admin (optionnel mais utile)

  Place({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.tag,
    required this.badge,
    this.description = '',
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      tag: json['tag'] ?? 'Deal',
      badge: json['badge'] ?? '3D/2N',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'image_url': imageUrl, // 👈 PostgreSQL: snake_case
      'tag': tag,
      'badge': badge,
      'description': description,
    };
  }

  // ✅ AJOUTEZ CETTE MÉTHODE :
  String get fullImageUrl {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;

    // ✅ Construit l'URL complète en fonction de votre serveur
    const serverBaseUrl = 'http://192.168.1.198:3000';
    final path = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    return '$serverBaseUrl$path';
  }




}