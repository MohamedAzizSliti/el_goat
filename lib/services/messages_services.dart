import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final supabase = Supabase.instance.client;

  Future<void> sendMessage(String receiverId, String content) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await supabase.from('messages').insert({
      'sender_id': user.id,
      'receiver_id': receiverId,
      'content': content,
      'is_read': false,
    });
  }

Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
  final userId = Supabase.instance.client.auth.currentUser!.id;

  return Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id'])
      // This fetches ALL messages where sender is me OR them
      .eq('sender_id', userId) // Just a placeholder to activate the stream
      .order('created_at')
      .execute()
      .map((messages) {
        // Dart-side filtering to include only conversations between two people
        return messages.where((msg) =>
          (msg['sender_id'] == userId && msg['receiver_id'] == otherUserId) ||
          (msg['sender_id'] == otherUserId && msg['receiver_id'] == userId)
        ).toList();
      });
}

}
