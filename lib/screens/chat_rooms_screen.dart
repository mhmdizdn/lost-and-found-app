import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../models/lost_found_item.dart';
import '../services/auth_service.dart'; // Added missing import
import '../models/chat_message.dart'; // Added missing import

class ChatRoomsScreen extends StatelessWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats', style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: ChatService.getUserChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data!;
          
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation from an item detail page',
                    style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple[100],
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    chatRoom.otherUser['name'] ?? 'Unknown User',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chatRoom.itemTitle,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (chatRoom.lastMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          chatRoom.lastMessage!,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  trailing: chatRoom.lastMessageTime != null
                      ? Text(
                          _formatTime(chatRoom.lastMessageTime!),
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                        )
                      : null,
                  onTap: () {
                    // Navigate to chat screen with the existing room ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreenWithRoomId(roomId: chatRoom.roomId, itemTitle: chatRoom.itemTitle),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// New chat screen that accepts a room ID directly
class ChatScreenWithRoomId extends StatefulWidget {
  final String roomId;
  final String itemTitle;

  const ChatScreenWithRoomId({super.key, required this.roomId, required this.itemTitle});

  @override
  State<ChatScreenWithRoomId> createState() => _ChatScreenWithRoomIdState();
}

class _ChatScreenWithRoomIdState extends State<ChatScreenWithRoomId> {
  final TextEditingController _messageController = TextEditingController();
  ChatRoom? _chatRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
  }

  Future<void> _loadChatRoom() async {
    try {
      final chatRoom = await ChatService.getChatRoom(widget.roomId);
      setState(() {
        _chatRoom = chatRoom;
        _isLoading = false;
      });

      // Mark messages as read when entering chat
      await ChatService.markMessagesAsRead(widget.roomId);
    } catch (e) {
      print('Error loading chat room: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      try {
        await ChatService.sendMessage(widget.roomId, _messageController.text.trim());
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getOtherUserName() {
    if (_chatRoom == null) return 'Unknown User';
    return _chatRoom!.otherUser['name'] ?? 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat', style: GoogleFonts.poppins()),
          backgroundColor: Colors.deepPurple[100],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat', style: GoogleFonts.poppins()),
            Text(
              _getOtherUserName(),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: Column(
        children: [
          // Chat info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chatting about: ${widget.itemTitle}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Chat screen error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUser = AuthService.currentUser;
                    final isMe = currentUser?.uid == message.senderId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.deepPurple : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.message,
                              style: GoogleFonts.poppins(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 