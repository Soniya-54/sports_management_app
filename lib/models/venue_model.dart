// lib/models/venue_model.dart

class Venue {
  final String id;
  final String name;
  final String location;
  final String sportType;
  final double pricePerHour;
  final String imageUrl;
  final String description;

  // NEW: Properties for dynamic time slots
  final String openingTime;   // e.g., "09:00"
  final String closingTime;   // e.g., "21:00"
  final int slotDuration;     // e.g., 60 (for 60 minutes)

  const Venue({
    required this.id,
    required this.name,
    required this.location,
    required this.sportType,
    required this.pricePerHour,
    required this.imageUrl,
    required this.description,
    
    // NEW: Add new properties to the constructor
    required this.openingTime,
    required this.closingTime,
    required this.slotDuration,
  });
}