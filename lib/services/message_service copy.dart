import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getMessagesWithUser(String otherUserId) {
    final userId = _client.auth.currentUser!.id;

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .execute()
        .map((messages) {
          return messages.where((msg) =>
              (msg['sender_id'] == userId && msg['receiver_id'] == otherUserId) ||
              (msg['sender_id'] == otherUserId && msg['receiver_id'] == userId)).toList();
        });
  }
  Future<void> sendMessage(String receiverId, String content) async {
    // Replace with your actual implementation to send a message
    // Example: Using Supabase to insert a message into a database
    await Supabase.instance.client.from('messages').insert({
      'sender_id': Supabase.instance.client.auth.currentUser!.id,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  Future<void> markMessagesAsRead(String senderId) async {
  final userId = Supabase.instance.client.auth.currentUser!.id;

  await Supabase.instance.client
      .from('messages')
      .update({'is_read': true})
      .eq('receiver_id', userId)
      .eq('sender_id', senderId);
}

Future<List<Map<String, dynamic>>> getConversations() async {
  final userId = Supabase.instance.client.auth.currentUser!.id;

  final response = await Supabase.instance.client
      .from('messages')
      .select()
      .or('sender_id.eq.$userId,receiver_id.eq.$userId')
      .order('created_at', ascending: false);

  final messages = response as List;

  final Map<String, Map<String, dynamic>> conversations = {};

  for (var msg in messages) {
    final otherId = msg['sender_id'] == userId ? msg['receiver_id'] : msg['sender_id'];

    if (!conversations.containsKey(otherId)) {
      conversations[otherId] = {
        'userId': otherId,
        'lastMessage': msg['content'],
        'createdAt': msg['created_at'],
        'unreadCount': 0,
      };
    }

    if (msg['receiver_id'] == userId && msg['is_read'] == false) {
      conversations[otherId]!['unreadCount'] += 1;
    }
  }

  // Fetch profile info from all 3 tables
  for (final convo in conversations.values) {
    final otherId = convo['userId'];

    Map? profile;

    profile = await Supabase.instance.client
        .from('scout_profiles')
        .select('full_name, avatar_url')
        .eq('user_id', otherId)
        .maybeSingle();

    profile ??= await Supabase.instance.client
        .from('footballer_profiles')
        .select('full_name, avatar_url')
        .eq('user_id', otherId)
        .maybeSingle();

    profile ??= await Supabase.instance.client
        .from('club_profiles')
        .select('full_name, avatar_url')
        .eq('user_id', otherId)
        .maybeSingle();

    convo['name'] = profile?['full_name'] ?? 'Utilisateur';
    convo['avatar'] = profile?['avatar_url'] ?? 'assets/images/player1.jpeg';
  }

  return conversations.values.toList();
}

}
