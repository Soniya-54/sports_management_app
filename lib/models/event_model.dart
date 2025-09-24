// lib/models/event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String venueName;
  final Timestamp eventDate;
  final double entryFee;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.venueName,
    required this.eventDate,
    required this.entryFee,
  });
}