import 'dart:convert';

class ChatRoom {
  final String roomId;
  final String itemId;
  final String itemTitle;
  final Map<String, dynamic> otherUser;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.roomId,
    required this.itemId,
    required this.itemTitle,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomId: json['roomId'] ?? '',
      itemId: json['itemId'] ?? '',
      itemTitle: json['itemTitle'] ?? '',
      otherUser: json['otherUser'] ?? {},
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      lastMessageSender: json['lastMessageSender'],
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'otherUser': otherUser,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 