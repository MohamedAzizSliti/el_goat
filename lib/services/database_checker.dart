import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseChecker {
  static final _client = Supabase.instance.client;

  /// Check if messaging tables exist and are properly configured
  static Future<Map<String, dynamic>> checkMessagingSetup() async {
    final results = <String, dynamic>{
      'messages_table_exists': false,
      'typing_status_table_exists': false,
      'user_authenticated': false,
      'realtime_enabled': false,
      'errors': <String>[],
      'recommendations': <String>[],
    };

    try {
      // Check authentication
      final user = _client.auth.currentUser;
      results['user_authenticated'] = user != null;
      
      if (user == null) {
        results['errors'].add('User not authenticated');
        results['recommendations'].add('Please log in first');
        return results;
      }

      // Check messages table
      try {
        await _client.from('messages').select('id').limit(1);
        results['messages_table_exists'] = true;
      } catch (e) {
        results['errors'].add('Messages table not found: $e');
        results['recommendations'].add('Run the database setup script');
      }

      // Check typing_status table
      try {
        await _client.from('typing_status').select('user_id').limit(1);
        results['typing_status_table_exists'] = true;
      } catch (e) {
        results['errors'].add('Typing status table not found: $e');
        results['recommendations'].add('Run the database setup script');
      }

      // Test message insertion (if tables exist)
      if (results['messages_table_exists']) {
        try {
          // Try to insert a test message (will be rolled back)
          await _client.from('messages').insert({
            'sender_id': user.id,
            'receiver_id': user.id, // Send to self for testing
            'content': 'Test message - please ignore',
            'message_type': 'text',
            'is_read': false,
          });
          
          // If successful, delete the test message
          await _client
              .from('messages')
              .delete()
              .eq('sender_id', user.id)
              .eq('receiver_id', user.id)
              .eq('content', 'Test message - please ignore');
              
          results['can_send_messages'] = true;
        } catch (e) {
          results['errors'].add('Cannot send messages: $e');
          results['recommendations'].add('Check RLS policies and permissions');
        }
      }

    } catch (e) {
      results['errors'].add('General error: $e');
    }

    return results;
  }

  /// Print a detailed report of the messaging setup
  static Future<void> printSetupReport() async {
    print('🔍 Checking Messaging System Setup...\n');
    
    final results = await checkMessagingSetup();
    
    print('📊 Setup Status:');
    print('  ✅ User Authenticated: ${results['user_authenticated']}');
    print('  ✅ Messages Table: ${results['messages_table_exists']}');
    print('  ✅ Typing Status Table: ${results['typing_status_table_exists']}');
    print('  ✅ Can Send Messages: ${results['can_send_messages'] ?? false}');
    
    if (results['errors'].isNotEmpty) {
      print('\n❌ Errors Found:');
      for (final error in results['errors']) {
        print('  • $error');
      }
    }
    
    if (results['recommendations'].isNotEmpty) {
      print('\n💡 Recommendations:');
      for (final rec in results['recommendations']) {
        print('  • $rec');
      }
    }
    
    if (results['errors'].isEmpty) {
      print('\n🎉 Messaging system is properly configured!');
    } else {
      print('\n🔧 Please follow the setup instructions to fix these issues.');
    }
  }

  /// Quick test to verify messaging functionality
  static Future<bool> testMessaging(String otherUserId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      // Try to send a test message
      await _client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': otherUserId,
        'content': 'Test message',
        'message_type': 'text',
        'is_read': false,
      });

      return true;
    } catch (e) {
      print('Messaging test failed: $e');
      return false;
    }
  }
}
