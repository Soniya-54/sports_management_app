// lib/models/venue_model.dart

class Venue {
  final String id;
  final String name;
  final String location;
  final String sportType;
  final double pricePerHour;
  final String imageUrl;

  // This is a constructor for the class
  const Venue({
    required this.id,
    required this.name,
    required this.location,
    required this.sportType,
    required this.pricePerHour,
    required this.imageUrl,
  });
}