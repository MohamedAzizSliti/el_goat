// lib/screens/chat_page.dart
// This file redirects to the modern chat screen
import 'package:flutter/material.dart';
import 'modern_chat_page.dart';

class ChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernChatScreen(
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserImage: otherUserImage,
    );
  }
}
