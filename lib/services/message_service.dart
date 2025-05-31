import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MessageService {
  final _client = Supabase.instance.client;
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  // Real-time subscriptions
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _typingChannel;

  // Stream controllers
  final _messagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineUsersController = StreamController<List<String>>.broadcast();
  final _conversationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Cache for messages
  final Map<String, List<Map<String, dynamic>>> _messagesCache = {};

  /// Initialize real-time messaging service
  Future<void> initialize() async {
    await _setupRealtimeSubscriptions();
  }

  /// Setup real-time subscriptions for messages and typing indicators
  Future<void> _setupRealtimeSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Subscribe to messages
    _messagesChannel = _client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            _handleNewMessage(payload.newRecord as Map<String, dynamic>);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            _handleMessageUpdate(payload.newRecord as Map<String, dynamic>);
          },
        );

    // Subscribe to typing indicators
    _typingChannel = _client
        .channel('public:typing_status')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'typing_status',
          callback: (payload) {
            _typingController.add(payload.newRecord as Map<String, dynamic>);
          },
        );

    _messagesChannel?.subscribe();
    _typingChannel?.subscribe();
  }

  /// Handle new message received
  void _handleNewMessage(Map<String, dynamic> message) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final senderId = message['sender_id'] as String;
    final receiverId = message['receiver_id'] as String;

    // Determine the conversation partner
    final otherUserId = senderId == userId ? receiverId : senderId;

    // Update cache
    if (_messagesCache.containsKey(otherUserId)) {
      _messagesCache[otherUserId]!.add(message);

      // Check if controller is still open before adding
      if (!_messagesController.isClosed) {
        _messagesController.add(_messagesCache[otherUserId]!);
      }
    }

    // Update conversations list
    _updateConversationsList();
  }

  /// Handle message updates (read status, reactions, etc.)
  void _handleMessageUpdate(Map<String, dynamic> message) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final senderId = message['sender_id'] as String;
    final receiverId = message['receiver_id'] as String;
    final otherUserId = senderId == userId ? receiverId : senderId;

    // Update message in cache
    if (_messagesCache.containsKey(otherUserId)) {
      final messages = _messagesCache[otherUserId]!;
      final index = messages.indexWhere((m) => m['id'] == message['id']);
      if (index != -1) {
        messages[index] = message;

        // Check if controller is still open before adding
        if (!_messagesController.isClosed) {
          _messagesController.add(messages);
        }
      }
    }
  }

  /// Get real-time messages stream with a specific user
  Stream<List<Map<String, dynamic>>> getMessagesWithUser(String otherUserId) {
    final userId = _client.auth.currentUser!.id;

    // Initialize empty cache for this user if not exists
    if (!_messagesCache.containsKey(otherUserId)) {
      _messagesCache[otherUserId] = [];
    }

    // Create a stream controller for this specific conversation
    final conversationController =
        StreamController<List<Map<String, dynamic>>>();

    // Immediately emit empty list to prevent loading state
    if (!conversationController.isClosed) {
      conversationController.add(_messagesCache[otherUserId]!);
    }

    // Load initial messages and update stream
    _loadInitialMessages(otherUserId).then((_) {
      if (!conversationController.isClosed) {
        conversationController.add(_messagesCache[otherUserId]!);
      }
    });

    // Listen to global message updates and filter for this conversation
    final subscription = _messagesController.stream.listen((allMessages) {
      if (_messagesCache.containsKey(otherUserId) &&
          !conversationController.isClosed) {
        conversationController.add(_messagesCache[otherUserId]!);
      }
    });

    // Clean up when stream is cancelled
    conversationController.onCancel = () {
      subscription.cancel();
    };

    return conversationController.stream;
  }

  /// Load initial messages from database
  Future<void> _loadInitialMessages(String otherUserId) async {
    final userId = _client.auth.currentUser!.id;

    try {
      final response = await _client
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)',
          )
          .order('created_at', ascending: true);

      _messagesCache[otherUserId] = List<Map<String, dynamic>>.from(response);

      // Check if controller is still open before adding
      if (!_messagesController.isClosed) {
        _messagesController.add(_messagesCache[otherUserId]!);
      }
    } catch (e) {
      print('Error loading initial messages: $e');
      // Ensure we always have an empty list even if loading fails
      if (!_messagesCache.containsKey(otherUserId)) {
        _messagesCache[otherUserId] = [];
      }

      // Check if controller is still open before adding
      if (!_messagesController.isClosed) {
        _messagesController.add(_messagesCache[otherUserId]!);
      }
    }
  }

  /// Send a text message
  Future<void> sendMessage(
    String receiverId,
    String content, {
    String? messageType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      print('Attempting to send message to $receiverId: $content');
      print('Current user ID: ${user.id}');
      print('Current user email: ${user.email}');

      // Skip user registration check since you don't use the profiles table approach
      // The foreign key should reference auth.users directly

      // Use only the most basic fields first
      final result = await _client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': receiverId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Message sent successfully: $result');
    } catch (e) {
      print('Detailed error sending message: $e');

      // Check for specific error types
      if (e.toString().contains('relation "messages" does not exist') ||
          e.toString().contains('table "messages" does not exist')) {
        throw Exception(
          'Messages table not found. Please run the database setup script first.',
        );
      }

      // Check for foreign key constraint violation
      if (e.toString().contains('violates foreign key constraint') &&
          e.toString().contains('messages_sender_id_fkey')) {
        throw Exception(
          'User authentication issue. Your user ID (${user.id}) is not properly registered in the database. The foreign key constraint is failing. Please check your database setup.',
        );
      }

      if (e.toString().contains('violates foreign key constraint') &&
          e.toString().contains('messages_receiver_id_fkey')) {
        throw Exception(
          'Receiver user not found. The user you are trying to message may not exist.',
        );
      }

      throw Exception('Failed to send message: $e');
    }
  }

  /// Send a media message (image, video, file)
  Future<void> sendMediaMessage(
    String receiverId,
    String mediaUrl,
    String messageType,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Send message with media URL
      await sendMessage(receiverId, mediaUrl, messageType: messageType);
    } catch (e) {
      throw Exception('Failed to send media message: $e');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// Mark all messages from a user as read
  Future<void> markAllMessagesAsRead(String otherUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('sender_id', otherUserId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Add reaction to a message
  Future<void> addReaction(String messageId, String emoji) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get current reactions
      final response =
          await _client
              .from('messages')
              .select('reactions')
              .eq('id', messageId)
              .single();

      List<dynamic> reactions = response['reactions'] ?? [];

      // Add new reaction
      reactions.add({
        'user_id': userId,
        'emoji': emoji,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update message
      await _client
          .from('messages')
          .update({'reactions': reactions})
          .eq('id', messageId);
    } catch (e) {
      print('Error adding reaction: $e');
    }
  }

  /// Update typing status
  Future<void> updateTypingStatus(bool isTyping) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('typing_status').upsert({
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  /// Get typing status stream
  Stream<Map<String, dynamic>> get typingStatusStream =>
      _typingController.stream;

  /// Get conversations list
  Future<List<Map<String, dynamic>>> getConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('messages')
          .select('''
            *,
            sender:sender_id(id, full_name),
            receiver:receiver_id(id, full_name)
          ''')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      // Group by conversation and get latest message
      final Map<String, Map<String, dynamic>> conversations = {};

      for (final message in response) {
        final otherUserId =
            message['sender_id'] == userId
                ? message['receiver_id']
                : message['sender_id'];

        if (!conversations.containsKey(otherUserId)) {
          conversations[otherUserId] = message;
        }
      }

      final conversationsList = conversations.values.toList();

      // Update the conversations stream
      _conversationsController.add(conversationsList);

      return conversationsList;
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  /// Get real-time conversations stream
  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    // Initial load
    getConversations();

    // Return the stream
    return _conversationsController.stream;
  }

  /// Update conversations list (called when new messages arrive)
  Future<void> _updateConversationsList() async {
    await getConversations();
  }

  /// Get unread messages count
  Future<int> getUnreadMessagesCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _client
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Search messages
  Future<List<Map<String, dynamic>>> searchMessages(
    String query, {
    String? otherUserId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      var queryBuilder = _client
          .from('messages')
          .select()
          .textSearch('content', query);

      if (otherUserId != null) {
        queryBuilder = queryBuilder.or(
          'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)',
        );
      } else {
        queryBuilder = queryBuilder.or(
          'sender_id.eq.$userId,receiver_id.eq.$userId',
        );
      }

      return await queryBuilder.order('created_at', ascending: false);
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  /// Mark all messages from a user as read (alias for compatibility)
  Future<void> markMessagesAsRead(String otherUserId) async {
    await markAllMessagesAsRead(otherUserId);
  }

  /// Dispose resources
  void dispose() {
    _messagesChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _messagesController.close();
    _typingController.close();
    _onlineUsersController.close();
    _conversationsController.close();
    _messagesCache.clear();
  }
}
