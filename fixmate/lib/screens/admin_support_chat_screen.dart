// lib/screens/admin_support_chat_screen.dart
// MODIFIED VERSION - Updated colors for customer and admin chat bubbles
// Added soft light-green and white gradient background
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userType; // 'customer' or 'worker'

  const AdminSupportChatScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userType,
  }) : super(key: key);

  @override
  State<AdminSupportChatScreen> createState() => _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState extends State<AdminSupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _supportChatId;

  @override
  void initState() {
    super.initState();
    _createOrGetSupportChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createOrGetSupportChat() async {
    try {
      // Check if support chat already exists
      QuerySnapshot existingChat = await FirebaseFirestore.instance
          .collection('support_chats')
          .where('user_id', isEqualTo: widget.userId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        setState(() {
          _supportChatId = existingChat.docs.first.id;
        });
      } else {
        // Create new support chat
        DocumentReference chatRef =
            await FirebaseFirestore.instance.collection('support_chats').add({
          'user_id': widget.userId,
          'user_name': widget.userName,
          'user_type': widget.userType,
          'last_message': 'Chat started',
          'last_message_time': FieldValue.serverTimestamp(),
          'unread_count_user': 0,
          'unread_count_admin': 0,
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          _supportChatId = chatRef.id;
        });

        // Send welcome message
        await _sendMessage(
          'Hello! How can we help you today?',
          isAdmin: true,
        );
      }

      // Mark admin messages as read when opening chat
      _markMessagesAsRead();
    } catch (e) {
      print('Error creating support chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading support chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_supportChatId == null) return;

    try {
      // Get all unread messages from admin
      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .collection('messages')
          .where('is_read', isEqualTo: false)
          .where('is_admin', isEqualTo: true)
          .get();

      // Mark them as read
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'is_read': true});
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
      }

      // Reset unread count
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .update({'unread_count_user': 0});

      print('✅ Marked ${unreadMessages.docs.length} messages as read');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage(String message, {bool isAdmin = false}) async {
    if (_supportChatId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .collection('messages')
          .add({
        'message': message,
        'sender_id': isAdmin ? 'admin' : widget.userId,
        'sender_name': isAdmin ? 'Admin Support' : widget.userName,
        'is_admin': isAdmin,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      // Update last message in parent chat
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .update({
        'last_message':
            message.length > 50 ? message.substring(0, 50) + '...' : message,
        'last_message_time': FieldValue.serverTimestamp(),
        if (!isAdmin) 'unread_count_admin': FieldValue.increment(1),
      });

      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSendMessage() {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    _sendMessage(message);
    _messageController.clear();

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_supportChatId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Admin Support'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFE8F5E9), // Light green
              ],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Support'),
            Text(
              'Get help from our team',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFE8F5E9), // Light green at bottom
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('support_chats')
                    .doc(_supportChatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading messages: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet.\nStart the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.all(16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;

                      bool isAdmin = data['is_admin'] ?? false;
                      String message = data['message'] ?? '';
                      String senderName = data['sender_name'] ?? 'Unknown';
                      Timestamp? timestamp = data['timestamp'] as Timestamp?;

                      // MODIFIED: Customer = Green, Admin = Light Green
                      Color bubbleColor = isAdmin
                          ? Color(0xFFC8E6C9) // Light green for admin
                          : Color(0xFF66BB6A); // Green for customer

                      Color textColor = isAdmin ? Colors.black87 : Colors.white;

                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: isAdmin ? 0 : 60,
                            right: isAdmin ? 60 : 0,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isAdmin
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              Text(
                                senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withOpacity(0.8),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                              if (timestamp != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  _formatTime(timestamp.toDate()),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
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
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
