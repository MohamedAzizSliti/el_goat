import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/message_service.dart';
import '../screens/chat_page.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({Key? key}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final MessageService _messageService = MessageService();
  List<Map<String, dynamic>> _conversations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final data = await _messageService.getConversations();
    setState(() {
      _conversations = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredConversations = _conversations.where((convo) {
      final name = convo['name']?.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversations"),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredConversations.isEmpty
                    ? const Center(child: Text("No results found"))
                    : ListView.builder(
                        itemCount: filteredConversations.length,
                        itemBuilder: (context, index) {
                          final convo = filteredConversations[index];
                          final timestamp = convo['createdAt'] != null
                              ? timeago.format(DateTime.parse(convo['createdAt']).toLocal())
                              : '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: convo['avatar'].toString().startsWith('http')
                                  ? NetworkImage(convo['avatar'])
                                  : AssetImage(convo['avatar']) as ImageProvider,
                            ),
                            title: Text(convo['name'] ?? 'Utilisateur'),
                            subtitle: Text(convo['lastMessage'] ?? ''),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(timestamp, style: const TextStyle(fontSize: 12)),
                                if (convo['unreadCount'] > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${convo['unreadCount']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: convo['userId'],
                                    otherUserName: convo['name'],
                                    otherUserImage: convo['avatar'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}    
