// lib/screens/modern_chat_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import '../services/message_service.dart';

class ModernChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;

  const ModernChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
  }) : super(key: key);

  @override
  State<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen>
    with TickerProviderStateMixin {
  final _messageService = MessageService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _otherTyping = false;
  String _lastSeen = 'Loading...';
  Timer? _typingTimer;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session expired')));
      });
      return;
    }

    _messageService.markMessagesAsRead(widget.otherUserId);
    _loadLastSeen();
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
                  ? 'Online'
                  : 'Last seen ${timeago.format(dt)}';
        });
        return;
      }
    }
    setState(() => _lastSeen = 'Last seen unknown');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty) return;

    setState(() => _sending = true);

    try {
      await _messageService
          .sendMessage(widget.otherUserId, txt)
          .timeout(const Duration(seconds: 10));
      _textCtrl.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendText(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
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

    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(left: 16, right: 80, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (i * 100)),
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[400]!.withOpacity(
                      0.4 +
                          (0.6 *
                              (((_typingAnimation.value + (i * 0.3)) % 1.0))),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[700],
                backgroundImage: AssetImage(widget.otherUserImage),
                child: Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_lastSeen == 'Online')
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[900]!, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _otherTyping ? 'Typing...' : _lastSeen,
                  style: TextStyle(
                    color:
                        _otherTyping
                            ? Colors.yellow
                            : (_lastSeen == 'Online'
                                ? Colors.green
                                : Colors.grey[400]),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call feature coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call feature coming soon!')),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: Colors.grey[800],
          onSelected: (value) {
            // Handle menu actions
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'View Profile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Clear Chat', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading messages',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.grey[600], size: 64),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meId = Supabase.instance.client.auth.currentUser!.id;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageService.getMessagesWithUser(widget.otherUserId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                    ),
                  );
                }

                if (snap.hasError) {
                  return _buildErrorState(snap.error.toString());
                }

                final msgs = snap.data ?? [];
                _scrollToBottom();

                if (msgs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length + (_otherTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == msgs.length && _otherTyping) {
                      return _buildTypingIndicator();
                    }

                    final m = msgs[i];
                    final isMe = m['sender_id'] == meId;
                    return _buildMessageBubble(m, isMe);
                  },
                );
              },
            ),
          ),
          _buildModernInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final content = message['content'].toString();
    final timestamp = DateTime.parse(message['created_at']);
    final isImage =
        content.contains('chat_media') &&
        (content.endsWith('.jpg') || content.endsWith('.png'));
    final isVideo = content.contains('chat_media') && content.endsWith('.mp4');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[700],
              backgroundImage: AssetImage(widget.otherUserImage),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.yellow : Colors.grey[800],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        content,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 100,
                            color: Colors.grey[600],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    )
                  else if (isVideo)
                    GestureDetector(
                      onTap: () {
                        // TODO: Open video player
                      },
                      child: Container(
                        width: 200,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Text(
                      content,
                      style: TextStyle(
                        color: isMe ? Colors.black : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.yellow,
              child: const Icon(Icons.person, color: Colors.black, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                _showMediaOptions();
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _textCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendText(),
                  onChanged: (text) {
                    // Handle typing indicator
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            _sending
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                )
                : IconButton(
                  icon: const Icon(Icons.send, color: Colors.yellow),
                  onPressed: _sendText,
                ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    icon: Icons.photo,
                    label: 'Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendMedia(video: false);
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendMedia(video: true);
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Open camera
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.yellow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
