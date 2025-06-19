import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // List of admin emails - only admin@gmail.com has admin access
  static const List<String> adminEmails = [
    'admin@gmail.com',
  ];
  
  // Check if current user is admin
  static bool isCurrentUserAdmin() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    return adminEmails.contains(currentUser.email);
  }
  
  // Get all pending items (for admin approval)
  static Stream<List<Map<String, dynamic>>> getPendingItemsStream() {
    return _firestore
        .collection('items')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    });
  }
  
  // Approve an item
  static Future<void> approveItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).update({
      'isApproved': true,
    });
  }
  
  // Reject/Delete an item
  static Future<void> rejectItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }
  
  // Get all items (approved and pending) - for admin overview
  static Stream<List<Map<String, dynamic>>> getAllItemsStream() {
    return _firestore
        .collection('items')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    });
  }
} 