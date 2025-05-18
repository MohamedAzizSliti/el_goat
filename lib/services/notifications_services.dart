import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final data = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase.from('notifications').update({
      'is_read': true,
    }).eq('id', notificationId);
  }

  Future<void> sendNotification(String userId, String title, String body) async {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
    });
  }
}

