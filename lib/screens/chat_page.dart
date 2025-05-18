// lib/screens/chat_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/message_service.dart';
import '../widgets/navbar/bottom_navbar.dart';

class ChatScreen extends StatefulWidget {
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageService = MessageService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _otherTyping = false;
  String _lastSeen = 'Chargement...';
  int _navIndex = 0;
  Timer? _typingTimer;
  late RealtimeChannel _typingChan;

  @override
  void initState() {
    super.initState();
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) {
      // no session → bounce back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session expirée')));
      });
      return;
    }

    _messageService.markMessagesAsRead(widget.otherUserId);
    _loadLastSeen();
    _subscribeTyping();
  }

  void _subscribeTyping() {
    _typingChan = Supabase.instance.client
        .channel('public:typing_status')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'typing_status',
          callback: (payload) {
            final data = payload.newRecord as Map<String, dynamic>?;
            if (data != null && data['user_id'] == widget.otherUserId) {
              setState(() => _otherTyping = data['is_typing'] == true);
            }
          },
        );
    _typingChan.subscribe();
  }

  Future<void> _updateTyping(bool isTyping) async {
    final me = Supabase.instance.client.auth.currentUser!;
    await Supabase.instance.client.from('typing_status').upsert({
      'user_id': me.id,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _loadLastSeen() async {
    for (final table in [
      'scout_profiles',
      'footballer_profiles',
      'club_profiles',
    ]) {
      final res =
          await Supabase.instance.client
              .from(table)
              .select('last_seen')
              .eq('user_id', widget.otherUserId)
              .maybeSingle();
      if (res != null && res['last_seen'] != null) {
        final dt = DateTime.parse(res['last_seen']).toLocal();
        setState(() {
          _lastSeen =
              DateTime.now().difference(dt).inMinutes < 1
                  ? 'En ligne'
                  : 'Vu ${timeago.format(dt)}';
        });
        return;
      }
    }
    setState(() => _lastSeen = 'Dernière vue inconnue');
  }

  void _onNav(int idx) {
    setState(() => _navIndex = idx);
    const routes = ['/', '/stories', '/news_home', '/profile'];
    Navigator.pushNamed(context, routes[idx]);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _pickAndSendMedia({required bool video}) async {
    final picker = ImagePicker();
    final file =
        video
            ? await picker.pickVideo(source: ImageSource.gallery)
            : await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final f = File(file.path);
    final name = p.basename(file.path);
    final type = lookupMimeType(f.path);
    final path = 'chat/${DateTime.now().millisecondsSinceEpoch}_$name';

    await Supabase.instance.client.storage
        .from('chat_media')
        .uploadBinary(
          path,
          await f.readAsBytes(),
          fileOptions: FileOptions(contentType: type),
        );

    final publicUrl = Supabase.instance.client.storage
        .from('chat_media')
        .getPublicUrl(path);

    await _messageService.sendMessage(widget.otherUserId, publicUrl);
    _scrollToBottom();
  }

  Future<void> _sendText() async {
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() => _sending = true);
    await _messageService.sendMessage(widget.otherUserId, txt);
    _textCtrl.clear();
    await _updateTyping(false);
    _scrollToBottom();
    setState(() => _sending = false);
  }

  Future<void> _addReaction(String msgId, String emoji) async {
    final cur =
        await Supabase.instance.client
            .from('messages')
            .select('reactions')
            .eq('id', msgId)
            .maybeSingle();
    List rx = (cur?['reactions'] ?? []) as List;
    rx.add({
      'user_id': Supabase.instance.client.auth.currentUser!.id,
      'emoji': emoji,
    });
    await Supabase.instance.client
        .from('messages')
        .update({'reactions': rx})
        .eq('id', msgId);
  }

  void _showEmojis(String msgId) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            children:
                ['😂', '🔥', '😍', '👍', '👏'].map((e) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _addReaction(msgId, e);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _openVideo(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullscreenVideoPage(videoUrl: url)),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    Supabase.instance.client.removeChannel(_typingChan);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meId = Supabase.instance.client.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(widget.otherUserImage)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _otherTyping ? 'En train d’écrire...' : _lastSeen,
                  style: TextStyle(
                    color:
                        _otherTyping
                            ? Colors.orange
                            : (_lastSeen == 'En ligne'
                                ? Colors.green
                                : Colors.grey),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageService.getMessagesWithUser(widget.otherUserId),
              builder: (ctx, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final msgs = snap.data!;
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(10),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final isMe = m['sender_id'] == meId;
                    final c = m['content'].toString();
                    final img =
                        c.contains('chat_media') &&
                        (c.endsWith('.jpg') || c.endsWith('.png'));
                    final vid = c.contains('chat_media') && c.endsWith('.mp4');
                    return GestureDetector(
                      onLongPress: () => _showEmojis(m['id'].toString()),
                      child: Column(
                        crossAxisAlignment:
                            isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: InkWell(
                              onTap: () => vid ? _openVideo(c) : null,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      isMe
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:
                                    img
                                        ? Image.network(c, width: 200)
                                        : vid
                                        ? const Icon(
                                          Icons.play_circle_fill,
                                          size: 50,
                                        )
                                        : Text(c),
                              ),
                            ),
                          ),
                          if ((m['reactions'] as List).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                left: 8,
                                right: 8,
                              ),
                              child: Wrap(
                                spacing: 4,
                                children:
                                    (m['reactions'] as List).map<Widget>((r) {
                                      return Text(
                                        r['emoji'],
                                        style: const TextStyle(fontSize: 16),
                                      );
                                    }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () => _showEmojis(''),
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => _pickAndSendMedia(video: false),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () => _pickAndSendMedia(video: true),
                ),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message...',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) {
                      _updateTyping(true);
                      _typingTimer?.cancel();
                      _typingTimer = Timer(
                        const Duration(seconds: 2),
                        () => _updateTyping(false),
                      );
                    },
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                _sending
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendText,
                    ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _navIndex,
        onItemTapped: _onNav,
      ),
    );
  }
}

class FullscreenVideoPage extends StatefulWidget {
  final String videoUrl;
  const FullscreenVideoPage({Key? key, required this.videoUrl})
    : super(key: key);

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late VideoPlayerController _vCtrl;
  ChewieController? _cCtrl;

  @override
  void initState() {
    super.initState();
    _vCtrl = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _cCtrl = ChewieController(
            videoPlayerController: _vCtrl,
            autoPlay: true,
            looping: false,
          );
        });
      });
  }

  @override
  void dispose() {
    _cCtrl?.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child:
            _cCtrl != null
                ? Chewie(controller: _cCtrl!)
                : const CircularProgressIndicator(),
      ),
    );
  }
}
