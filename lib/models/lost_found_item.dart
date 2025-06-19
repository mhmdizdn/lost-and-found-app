import 'package:google_maps_flutter/google_maps_flutter.dart';

// Item model
class LostFoundItem {
  final String title;
  final String description;
  final String category;
  final String location;
  final String? photoUrl;  // Changed from File to URL string
  final DateTime date;
  final bool isLost;
  bool isApproved;
  final LatLng? coordinates;

  LostFoundItem({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.photoUrl,  // Changed from photo to photoUrl
    required this.date,
    required this.isLost,
    this.isApproved = false,
    this.coordinates,
  });
} 