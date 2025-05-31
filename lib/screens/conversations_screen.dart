import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/message_service.dart';
import 'chat_page.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessageService _messageService = MessageService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  // Real-time subscriptions
  late Stream<List<Map<String, dynamic>>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    _messageService.initialize();
    _setupRealTimeConversations();
    _loadUnreadCount();
  }

  void _setupRealTimeConversations() {
    // Use the real-time conversations stream from MessageService
    _conversationsStream = _messageService.getConversationsStream();

    // Listen to the stream and update UI
    _conversationsStream.listen((conversations) {
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
        _loadUnreadCount();
      }
    });
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _messageService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _messageService.getUnreadMessagesCount();
      setState(() => _unreadCount = count);
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _refreshConversations() async {
    await _loadConversations();
    await _loadUnreadCount();
  }

  void _openChat(
    String otherUserId,
    String otherUserName,
    String otherUserImage,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              otherUserImage: otherUserImage,
            ),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _refreshConversations();
    });
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final otherUserId =
        conversation['sender_id'] ==
                Supabase.instance.client.auth.currentUser?.id
            ? conversation['receiver_id']
            : conversation['sender_id'];

    final lastMessage = conversation['content'] ?? '';
    final createdAt = DateTime.parse(conversation['created_at']);
    final isUnread =
        conversation['is_read'] == false &&
        conversation['receiver_id'] ==
            Supabase.instance.client.auth.currentUser?.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.grey[900],
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[700],
              backgroundImage: AssetImage('assets/images/player1.jpeg'),
              child: Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          'User $otherUserId',
          style: TextStyle(
            color: Colors.white,
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          lastMessage.length > 50
              ? '${lastMessage.substring(0, 50)}...'
              : lastMessage,
          style: TextStyle(
            color: Colors.grey[400],
            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeago.format(createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap:
            () => _openChat(
              otherUserId,
              'User $otherUserId',
              'assets/images/player1.jpeg',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshConversations,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              )
              : _conversations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation by messaging someone!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _refreshConversations,
                color: Colors.yellow,
                backgroundColor: Colors.grey[900],
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    return _buildConversationTile(_conversations[index]);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow,
        onPressed: () {
          // TODO: Navigate to user search/selection screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User search feature coming soon!')),
          );
        },
        child: const Icon(Icons.add_comment, color: Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    _messageService.dispose();
    super.dispose();
  }
}
