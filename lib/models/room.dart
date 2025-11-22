class Room {
  final String id;
  final String hotelId;
  final String name;
  final String description;
  final double pricePerNight;
  final String imageUrl;
  final int maxGuests;
  final String bedType;
  final List<String> amenities;
  final bool hasBreakfast;
  final bool isNonRefundable;
  final bool hasFreeCancellation;

  Room({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.description,
    required this.pricePerNight,
    required this.imageUrl,
    required this.maxGuests,
    required this.bedType,
    required this.amenities,
    this.hasBreakfast = false,
    this.isNonRefundable = false,
    this.hasFreeCancellation = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hotelId': hotelId,
    'name': name,
    'description': description,
    'pricePerNight': pricePerNight,
    'imageUrl': imageUrl,
    'maxGuests': maxGuests,
    'bedType': bedType,
    'amenities': amenities,
    'hasBreakfast': hasBreakfast,
    'isNonRefundable': isNonRefundable,
    'hasFreeCancellation': hasFreeCancellation,
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] ?? '',
    hotelId: json['hotelId'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['imageUrl'] ?? '',
    maxGuests: json['maxGuests'] ?? 2,
    bedType: json['bedType'] ?? '1 bed',
    amenities: List<String>.from(json['amenities'] ?? []),
    hasBreakfast: json['hasBreakfast'] ?? false,
    isNonRefundable: json['isNonRefundable'] ?? false,
    hasFreeCancellation: json['hasFreeCancellation'] ?? true,
  );
}