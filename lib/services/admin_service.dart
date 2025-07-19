import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_found_item.dart';
import 'auth_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'items';
  
  // Admin emails whitelist
  static const List<String> _adminEmails = [
    'admin@gmail.com',
  ];

  // Check if current user is admin
  static bool isCurrentUserAdmin() {
    final user = AuthService.currentUser;
    return user != null && _adminEmails.contains(user.email);
  }

  // Get stream of pending items (for admin approval)
  static Stream<List<LostFoundItem>> getPendingItemsStream() {
    if (!isCurrentUserAdmin()) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('isApproved', isEqualTo: false)
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
          isReturned: data['isReturned'] ?? false, // Add the new field
          coordinates: (data['lat'] != null && data['lng'] != null)
              ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble())
              : null,
          reporterId: data['reporterId'] ?? '',
        );
      }).toList();
    });
  }

  // Get stream of all items (for admin view)
  static Stream<List<LostFoundItem>> getAllItemsStream() {
    if (!isCurrentUserAdmin()) {
      return Stream.value([]);
    }

    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
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
          isReturned: data['isReturned'] ?? false, // Add the new field
          coordinates: (data['lat'] != null && data['lng'] != null)
              ? LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble())
              : null,
          reporterId: data['reporterId'] ?? '',
        );
      }).toList();
    });
  }

  // Approve an item
  static Future<void> approveItem(String itemId) async {
    if (!isCurrentUserAdmin()) {
      throw 'Only admins can approve items';
    }

    await _firestore.collection(_collectionName).doc(itemId).update({
      'isApproved': true,
    });
  }

  // Reject an item (delete it)
  static Future<void> rejectItem(String itemId) async {
    if (!isCurrentUserAdmin()) {
      throw 'Only admins can reject items';
    }

    await _firestore.collection(_collectionName).doc(itemId).delete();
  }

  // Admin edit item (for approved items)
  static Future<void> adminEditItem(String itemId, LostFoundItem item) async {
    if (!isCurrentUserAdmin()) {
      throw 'Only admins can edit items';
    }

    await _firestore.collection(_collectionName).doc(itemId).update({
      'title': item.title,
      'description': item.description,
      'category': item.category,
      'location': item.location,
      'isLost': item.isLost,
      'isFound': item.isFound, // Add the new field
      'isReturned': item.isReturned, // Add the new field
      'lat': item.coordinates?.latitude,
      'lng': item.coordinates?.longitude,
      'photoUrl': item.photoUrl,
      'isApproved': item.isApproved, // allow admin to update approval status
    });
  }

  // Admin delete item (for approved items)
  static Future<void> adminDeleteItem(String itemId) async {
    if (!isCurrentUserAdmin()) {
      throw 'Only admins can delete items';
    }

    await _firestore.collection(_collectionName).doc(itemId).delete();
  }

  // Get user info for reporter
  static Future<Map<String, dynamic>?> getReporterInfo(String reporterId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(reporterId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      
      // If user data doesn't exist in Firestore, but it's the current user, get from auth
      final currentUser = AuthService.currentUser;
      if (currentUser != null && currentUser.uid == reporterId) {
        // Try to create/save user data in Firestore
        final userData = {
          'name': currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User',
          'email': currentUser.email ?? '',
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        try {
          await _firestore.collection('users').doc(reporterId).set(userData);
          return userData;
        } catch (e) {
          print('Error saving user data to Firestore: $e');
          return userData; // Return data even if saving fails
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting reporter info: $e');
      return null;
    }
  }
} 