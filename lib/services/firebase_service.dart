import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/lost_found_item.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'items';

  // Add new item to Firestore
  static Future<void> addItem(LostFoundItem item) async {
    await _firestore.collection(_collectionName).add({
      'title': item.title,
      'description': item.description,
      'category': item.category,
      'location': item.location,
      'date': item.date.toIso8601String(),
      'isLost': item.isLost,
      'isApproved': item.isApproved,
      'lat': item.coordinates?.latitude,
      'lng': item.coordinates?.longitude,
      'photoUrl': item.photoUrl,  // Save the photo URL
    });
  }

  // Get stream of items from Firestore
  static Stream<List<LostFoundItem>> getItemsStream() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LostFoundItem(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          category: data['category'] ?? '',
          location: data['location'] ?? '',
          photoUrl: data['photoUrl'], // Load photo URL from Firestore
          date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
          isLost: data['isLost'] ?? true,
          isApproved: data['isApproved'] ?? false,
          coordinates: (data['lat'] != null && data['lng'] != null)
              ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble())
              : null,
        );
      }).toList();
    });
  }
} 