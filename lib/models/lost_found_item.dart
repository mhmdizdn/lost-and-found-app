import 'package:google_maps_flutter/google_maps_flutter.dart';

// Item model
class LostFoundItem {
  final String? id; // Document ID from Firestore
  final String title;
  final String description;
  final String category;
  final String location;
  final String? photoUrl;  // Changed from File to URL string
  final DateTime date;
  final bool isLost;
  bool isApproved;
  bool isFound; // New field to track if lost item has been found
  final LatLng? coordinates;
  final String reporterId; // ID of the user who reported this item

  LostFoundItem({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.photoUrl,  // Changed from photo to photoUrl
    required this.date,
    required this.isLost,
    this.isApproved = false,
    this.isFound = false, // Default to false
    this.coordinates,
    required this.reporterId,
  });
} 