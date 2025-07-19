import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/lost_found_item.dart';
import 'auth_service.dart';
import 'admin_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatRoomsCollection = 'chat_rooms';
  static const String _messagesCollection = 'messages';

  // Create or get existing chat room
  static Future<String> createOrGetChatRoom(LostFoundItem item) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    // Generate a unique room ID based on item ID and participants
    final roomId = '${item.id}_${currentUser.uid}_${item.reporterId}';
    
    // Check if room already exists
    final roomDoc = await _firestore.collection(_chatRoomsCollection).doc(roomId).get();
    
    if (!roomDoc.exists) {
      // Get other user's info
      Map<String, dynamic> otherUserInfo = {};
      try {
        if (currentUser.uid == item.reporterId) {
          // Current user is the reporter, so we need to get info for the person contacting them
          // For now, we'll use basic info since we don't have the other user's details
          otherUserInfo = {
            'uid': 'unknown',
            'name': 'Anonymous User',
            'email': 'anonymous@example.com',
          };
        } else {
          // Current user is contacting the reporter
          final reporterInfo = await AdminService.getReporterInfo(item.reporterId);
          if (reporterInfo != null) {
            otherUserInfo = reporterInfo;
          } else {
            // Fallback if we can't get user info
            otherUserInfo = {
              'uid': item.reporterId,
              'name': 'Unknown User',
              'email': 'unknown@example.com',
            };
          }
        }
      } catch (e) {
        // Fallback if we can't get user info
        otherUserInfo = {
          'uid': item.reporterId,
          'name': 'Unknown User',
          'email': 'unknown@example.com',
        };
      }

      // Create new chat room
      await _firestore.collection(_chatRoomsCollection).doc(roomId).set({
        'roomId': roomId,
        'itemId': item.id,
        'itemTitle': item.title,
        'participants': [currentUser.uid, item.reporterId],
        'otherUser': otherUserInfo,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    return roomId;
  }

  // Get chat room info
  static Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final doc = await _firestore.collection(_chatRoomsCollection).doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  // Get user's chat rooms
  static Stream<List<ChatRoom>> getUserChatRooms() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatRoom.fromJson(data);
      }).toList();
    });
  }

  // Send a message
  static Future<void> sendMessage(String roomId, String message) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    // Get chat room to determine receiver
    final room = await getChatRoom(roomId);
    if (room == null) throw 'Chat room not found';

    // Determine receiver ID (the other person in the chat)
    String receiverId;
    final participants = room.participants;
    if (participants.length >= 2) {
      receiverId = participants.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => room.otherUser['uid'] ?? '',
      );
    } else {
      receiverId = room.otherUser['uid'] ?? '';
    }

    // Create message document
    final messageDoc = _firestore.collection(_messagesCollection).doc();
    final chatMessage = ChatMessage(
      id: messageDoc.id,
      roomId: roomId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'Unknown User',
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
    );

    // Save message
    await messageDoc.set(chatMessage.toJson());

    // Update chat room with last message info
    await _firestore.collection(_chatRoomsCollection).doc(roomId).update({
      'lastMessage': message,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastMessageSender': currentUser.uid,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get messages for a chat room - FIXED VERSION
  static Stream<List<ChatMessage>> getMessages(String roomId) {
    try {
      print('Getting messages for room: $roomId');
      return _firestore
          .collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .snapshots()
          .map((snapshot) {
        print('Received ${snapshot.docs.length} messages for room $roomId');
        final messages = snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            return ChatMessage.fromJson(data);
          } catch (e) {
            print('Error parsing message ${doc.id}: $e');
            print('Message data: ${doc.data()}');
            rethrow;
          }
        }).toList();
        
        // Sort messages by timestamp locally instead of using orderBy in query
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      }).handleError((error) {
        print('Error in getMessages stream: $error');
        throw error;
      });
    } catch (e) {
      print('Error setting up getMessages stream: $e');
      rethrow;
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String roomId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    try {
      final messages = await _firestore
          .collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
} 