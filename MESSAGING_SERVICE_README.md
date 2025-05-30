# 💬 Real-Time Messaging Service for El Goat

## 🚀 Overview

A complete real-time messaging system built with Supabase for the El Goat football app. Features include instant messaging, typing indicators, message reactions, media sharing, and conversation management.

## ✨ Features

### 🔄 Real-Time Messaging
- **Instant Message Delivery**: Messages appear immediately using Supabase real-time subscriptions
- **Live Typing Indicators**: See when someone is typing
- **Message Status**: Read/unread status with timestamps
- **Auto-Sync**: Messages sync across all devices instantly

### 📱 Rich Message Types
- **Text Messages**: Standard text communication
- **Media Messages**: Images, videos, and files
- **Message Reactions**: React with emojis (😂, 🔥, 😍, 👍, 👏)
- **Message Search**: Find messages by content

### 👥 Conversation Management
- **Conversation List**: View all active conversations
- **Unread Count**: Badge showing unread message count
- **Last Message Preview**: See the latest message in each conversation
- **User Profiles**: Integration with footballer, scout, and club profiles

### 🔒 Security & Privacy
- **Row Level Security**: Users can only see their own messages
- **Authentication Required**: All features require user authentication
- **Secure Media Storage**: Files stored securely in Supabase storage

## 🛠️ Setup Instructions

### 1. Database Setup

Execute the SQL script in your Supabase dashboard:

```bash
# Run the SQL file in Supabase SQL Editor
database/messaging_schema.sql
```

This creates:
- `messages` table with RLS policies
- `typing_status` table for typing indicators
- `chat_media` storage bucket for media files
- Indexes for optimal performance
- Real-time subscriptions
- Helper functions

### 2. Initialize the Service

In your app's main function, initialize the messaging service:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // Initialize messaging service
  await MessageService().initialize();
  
  runApp(MyApp());
}
```

### 3. Add to Navigation

Add the conversations screen to your app navigation:

```dart
// In your bottom navigation or drawer
ListTile(
  leading: Icon(Icons.message),
  title: Text('Messages'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationsScreen(),
      ),
    );
  },
),
```

## 📋 Usage Examples

### Send a Text Message

```dart
final messageService = MessageService();

await messageService.sendMessage(
  'receiver_user_id',
  'Hello! How are you?',
);
```

### Send a Media Message

```dart
await messageService.sendMediaMessage(
  'receiver_user_id',
  'https://example.com/image.jpg',
  'image',
);
```

### Listen to Messages

```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: messageService.getMessagesWithUser('other_user_id'),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    
    final messages = snapshot.data!;
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(message: message);
      },
    );
  },
)
```

### Mark Messages as Read

```dart
// Mark a specific message as read
await messageService.markMessageAsRead('message_id');

// Mark all messages from a user as read
await messageService.markAllMessagesAsRead('other_user_id');
```

### Add Reaction to Message

```dart
await messageService.addReaction('message_id', '😂');
```

### Update Typing Status

```dart
// Start typing
await messageService.updateTypingStatus(true);

// Stop typing
await messageService.updateTypingStatus(false);
```

## 🎨 UI Components

### Chat Screen Features
- **Message Bubbles**: Different styles for sent/received messages
- **Typing Indicator**: Shows when other user is typing
- **Media Preview**: Images and videos display inline
- **Reaction Display**: Emoji reactions shown below messages
- **Time Stamps**: Relative time display (e.g., "2 minutes ago")

### Conversations Screen Features
- **Conversation List**: All active conversations
- **Unread Badges**: Visual indicators for unread messages
- **Last Message Preview**: Preview of the latest message
- **Pull to Refresh**: Refresh conversation list
- **Search Functionality**: Find specific conversations

## 🔧 Technical Details

### Database Schema

```sql
-- Messages table
messages (
  id UUID PRIMARY KEY,
  sender_id UUID REFERENCES auth.users(id),
  receiver_id UUID REFERENCES auth.users(id),
  content TEXT,
  message_type VARCHAR(20),
  is_read BOOLEAN,
  read_at TIMESTAMP,
  reactions JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

-- Typing status table
typing_status (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  is_typing BOOLEAN,
  updated_at TIMESTAMP
)
```

### Real-Time Subscriptions

The service automatically subscribes to:
- New message insertions
- Message updates (read status, reactions)
- Typing status changes

### Performance Optimizations

- **Message Caching**: Messages cached locally for faster access
- **Efficient Queries**: Optimized database queries with proper indexes
- **Lazy Loading**: Messages loaded on demand
- **Real-time Updates**: Only relevant changes trigger UI updates

## 🎯 Integration with El Goat Profiles

The messaging service integrates seamlessly with all user types:

- **Footballers**: Message other players, scouts, and clubs
- **Scouts**: Communicate with players and clubs
- **Clubs**: Contact players and scouts
- **Fans**: Message players and engage with community

Profile information is automatically fetched and displayed in conversations.

## 🚀 Future Enhancements

- **Group Messaging**: Support for group conversations
- **Voice Messages**: Audio message support
- **Message Encryption**: End-to-end encryption
- **Push Notifications**: Real-time notifications
- **Message Scheduling**: Schedule messages for later
- **Message Translation**: Multi-language support

## 🐛 Troubleshooting

### Common Issues

1. **Messages not appearing in real-time**
   - Check Supabase real-time is enabled
   - Verify RLS policies are correct
   - Ensure proper authentication

2. **Media upload failures**
   - Check storage bucket permissions
   - Verify file size limits
   - Ensure proper file types

3. **Typing indicators not working**
   - Check typing_status table exists
   - Verify real-time subscription is active
   - Check user permissions

### Debug Mode

Enable debug logging:

```dart
// In development, enable debug prints
const bool kDebugMode = true;
```

## 📞 Support

For issues or questions about the messaging service:
1. Check the troubleshooting section above
2. Review Supabase documentation
3. Check the database logs in Supabase dashboard
4. Verify all RLS policies are correctly configured

---

**Your El Goat app now has a complete, professional-grade messaging system! 🎉⚽💬**
