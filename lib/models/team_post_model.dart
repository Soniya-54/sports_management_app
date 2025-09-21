// lib/models/team_post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TeamPost {
  final String id;
  final String venueName;
  final String venueId;
  final String sportType;
  final DateTime gameDate;
  final String gameTime;
  final int playersNeeded;
  final String postedByUserId;
  final String postedByUserEmail;
  final Timestamp createdAt;
  // We can add a list of players who have joined later.

  TeamPost({
    required this.id,
    required this.venueName,
    required this.venueId,
    required this.sportType,
    required this.gameDate,
    required this.gameTime,
    required this.playersNeeded,
    required this.postedByUserId,
    required this.postedByUserEmail,
    required this.createdAt,
  });
}