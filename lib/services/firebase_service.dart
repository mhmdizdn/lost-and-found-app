import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/lost_found_item.dart';
import 'auth_service.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'items';

  // Add new item to Firestore
  static Future<void> addItem(LostFoundItem item) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    await _firestore.collection(_collectionName).add({
      'title': item.title,
      'description': item.description,
      'category': item.category,
      'location': item.location,
      'date': item.date.toIso8601String(),
      'isLost': item.isLost,
      'isApproved': item.isApproved,
      'isFound': item.isFound, // Add the new field
      'lat': item.coordinates?.latitude,
      'lng': item.coordinates?.longitude,
      'photoUrl': item.photoUrl,
      'reporterId': currentUser.uid, // Track who reported this item
    });
  }

  // Get stream of approved items (for general public view)
  static Stream<List<LostFoundItem>> getApprovedItemsStream() {
    return _firestore
        .collection(_collectionName)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LostFoundItem(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          category: data['category'] ?? '',
          location: data['location'] ?? '',
          photoUrl: data['photoUrl'],
          date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
          isLost: data['isLost'] ?? true,
          isApproved: data['isApproved'] ?? false,
          isFound: data['isFound'] ?? false, // Add the new field
          coordinates: (data['lat'] != null && data['lng'] != null)
              ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble())
              : null,
          reporterId: data['reporterId'] ?? '',
        );
      }).toList();
    });
  }

  // Get stream of user's own items (approved and pending)
  static Stream<List<LostFoundItem>> getUserItemsStream() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('reporterId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LostFoundItem(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          category: data['category'] ?? '',
          location: data['location'] ?? '',
          photoUrl: data['photoUrl'],
          date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
          isLost: data['isLost'] ?? true,
          isApproved: data['isApproved'] ?? false,
          isFound: data['isFound'] ?? false, // Add the new field
          coordinates: (data['lat'] != null && data['lng'] != null)
              ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble())
              : null,
          reporterId: data['reporterId'] ?? '',
        );
      }).toList();
    });
  }

  // Get combined stream for home screen (approved items + user's own pending items)
  static Stream<List<LostFoundItem>> getItemsStream() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return getApprovedItemsStream();
    }

    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return LostFoundItem(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              category: data['category'] ?? '',
              location: data['location'] ?? '',
              photoUrl: data['photoUrl'],
              date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
              isLost: data['isLost'] ?? true,
              isApproved: data['isApproved'] ?? false,
              isFound: data['isFound'] ?? false, // Add the new field
              coordinates: (data['lat'] != null && data['lng'] != null)
                  ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble())
                  : null,
              reporterId: data['reporterId'] ?? '',
            );
          })
          .where((item) {
            // Show approved items to everyone
            if (item.isApproved) return true;
            // Show pending items only to the reporter
            return item.reporterId == currentUser.uid;
          })
          .toList();
    });
  }

  // Update item (for user's own items)
  static Future<void> updateItem(String itemId, LostFoundItem item) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    // Verify the user owns this item
    final doc = await _firestore.collection(_collectionName).doc(itemId).get();
    if (!doc.exists) throw 'Item not found';
    
    final data = doc.data()!;
    if (data['reporterId'] != currentUser.uid) {
      throw 'You can only edit your own items';
    }

    await _firestore.collection(_collectionName).doc(itemId).update({
      'title': item.title,
      'description': item.description,
      'category': item.category,
      'location': item.location,
      'isLost': item.isLost,
      'isFound': item.isFound, // Add the new field
      'lat': item.coordinates?.latitude,
      'lng': item.coordinates?.longitude,
      'photoUrl': item.photoUrl,
      // Note: Don't allow changing isApproved or reporterId
    });
  }

  // Mark item as found (for user's own lost items)
  static Future<void> markItemAsFound(String itemId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    // Verify the user owns this item
    final doc = await _firestore.collection(_collectionName).doc(itemId).get();
    if (!doc.exists) throw 'Item not found';
    
    final data = doc.data()!;
    if (data['reporterId'] != currentUser.uid) {
      throw 'You can only mark your own items as found';
    }

    // Only allow marking lost items as found
    if (!(data['isLost'] ?? true)) {
      throw 'You can only mark lost items as found';
    }

    await _firestore.collection(_collectionName).doc(itemId).update({
      'isFound': true,
    });
  }

  // Delete item (for user's own items)
  static Future<void> deleteItem(String itemId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    // Verify the user owns this item
    final doc = await _firestore.collection(_collectionName).doc(itemId).get();
    if (!doc.exists) throw 'Item not found';
    
    final data = doc.data()!;
    if (data['reporterId'] != currentUser.uid) {
      throw 'You can only delete your own items';
    }

    await _firestore.collection(_collectionName).doc(itemId).delete();
  }
} 