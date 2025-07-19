import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lost_found_item.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final LostFoundItem item;

  const ChatScreen({super.key, required this.item});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _roomId;
  ChatRoom? _chatRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Create or get existing chat room
      final roomId = await ChatService.createOrGetChatRoom(widget.item);
      final chatRoom = await ChatService.getChatRoom(roomId);
      
      setState(() {
        _roomId = roomId;
        _chatRoom = chatRoom;
        _isLoading = false;
      });

      // Mark messages as read when entering chat
      if (roomId != null) {
        await ChatService.markMessagesAsRead(roomId);
      }
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && _roomId != null) {
      try {
        await ChatService.sendMessage(_roomId!, _messageController.text.trim());
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
                Icon(
                  widget.item.isLost ? Icons.search_off : Icons.search,
                  color: widget.item.isLost ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chatting about: ${widget.item.title}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: _roomId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load chat',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.getMessages(_roomId!),
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