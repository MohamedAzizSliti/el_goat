import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/navbar/bottom_navbar.dart';

class NewsReelsPage extends StatefulWidget {
  const NewsReelsPage({Key? key}) : super(key: key);

  @override
  State<NewsReelsPage> createState() => _NewsReelsPageState();
}

class _NewsReelsPageState extends State<NewsReelsPage> {
  final List<String> videoUrls = [
    'assets/videos/goal1.mp4',
    'assets/videos/goal2.mp4',
    'assets/videos/goal3.mp4',
    'assets/videos/football.mp4',
  ];

  final PageController _pageController = PageController();
  final List<VideoPlayerController> _controllers = [];

  int _currentIndex = 0;
  int _selectedIndex = 2;
  bool _isMuted = false;

  List<bool> isLiked = [];
  List<int> likeCounts = [];
  List<bool> showHeart = [];
  List<bool> isSaved = [];
  List<int> saveCounts = [];
  List<List<String>> comments = [];
  String? anonymousUserId;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    isLiked = List.filled(videoUrls.length, false);
    likeCounts = List.filled(videoUrls.length, 0);
    showHeart = List.filled(videoUrls.length, false);
    isSaved = List.filled(videoUrls.length, false);
    saveCounts = List.filled(videoUrls.length, 0);
    comments = List.generate(videoUrls.length, (_) => []);
    _initializeAnonymousId();
    _loadLikes();
    _loadComments();
    _loadSaves();
  }

  void _initializeAnonymousId() {
    anonymousUserId ??= 'anon_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializeControllers() async {
    for (final url in videoUrls) {
      final controller = VideoPlayerController.asset(url);
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(_isMuted ? 0.0 : 1.0);
      _controllers.add(controller);
    }

    _controllers[0].play();
    setState(() {});
  }

  Future<void> _loadLikes() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final userId = user?.id ?? anonymousUserId;

    for (int i = 0; i < videoUrls.length; i++) {
      final videoPath = videoUrls[i];

      final res = await supabase
          .from('likes')
          .select()
          .eq('video_path', videoPath);
      likeCounts[i] = res.length;

      final userLike = await supabase
          .from('likes')
          .select()
          .eq('video_path', videoPath)
          .eq('user_id', userId!);
      isLiked[i] = userLike.isNotEmpty;
    }

    setState(() {});
  }

  Future<void> _loadComments() async {
    final supabase = Supabase.instance.client;

    for (int i = 0; i < videoUrls.length; i++) {
      final video = videoUrls[i];

      final res = await supabase
          .from('comments')
          .select('''
            content,
            user_id,
            created_at,
            profiles:user_id (
              username,
              avatar_url
            )
          ''')
          .eq('video_path', video)
          .order('created_at', ascending: true);

      comments[i] = List<String>.from(res.map((e) => e['content']));
      setState(() {});
    }
  }

  Future<void> _loadSaves() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final userId = user?.id ?? anonymousUserId;

    for (int i = 0; i < videoUrls.length; i++) {
      final videoPath = videoUrls[i];

      final allSaves = await supabase
          .from('saves')
          .select()
          .eq('video_path', videoPath);

      final userSave = await supabase
          .from('saves')
          .select()
          .eq('video_path', videoPath)
          .eq('user_id', userId!);

      setState(() {
        saveCounts[i] = allSaves.length;
        isSaved[i] = userSave.isNotEmpty;
      });
    }
  }

  Future<void> _handleLike(int index) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final userId = user?.id ?? anonymousUserId;
    final videoPath = videoUrls[index];

    setState(() {
      isLiked[index] = !isLiked[index];
      likeCounts[index] += isLiked[index] ? 1 : -1;
    });

    if (isLiked[index]) {
      await supabase.from('likes').insert({
        'user_id': userId,
        'video_path': videoPath,
      });
    } else {
      await supabase
          .from('likes')
          .delete()
          .eq('user_id', userId!)
          .eq('video_path', videoPath);
    }
  }

  Future<void> _handleSave(int index) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final userId = user?.id ?? anonymousUserId;
    final videoPath = videoUrls[index];

    setState(() {
      isSaved[index] = !isSaved[index];
      saveCounts[index] += isSaved[index] ? 1 : -1;
    });

    if (isSaved[index]) {
      await supabase.from('saves').insert({
        'user_id': userId,
        'video_path': videoPath,
      });
    } else {
      await supabase
          .from('saves')
          .delete()
          .eq('user_id', userId!)
          .eq('video_path', videoPath);
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _controllers[_currentIndex].pause();
      _currentIndex = index;
      _controllers[_currentIndex].play();
    });
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      for (var controller in _controllers) {
        controller.setVolume(_isMuted ? 0.0 : 1.0);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/');
        break;
      case 1:
        Navigator.pushNamed(context, '/stories');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  void _openCommentsSheet(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 10,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getCommentsWithUserInfo(index),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No comments yet',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, i) {
                            final commentData = snapshot.data![i];
                            final isAnonymous = commentData['user_id']
                                .toString()
                                .startsWith('anon_');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        isAnonymous ? Colors.grey[800] : null,
                                    backgroundImage:
                                        !isAnonymous &&
                                                commentData['avatar_url'] !=
                                                    null
                                            ? NetworkImage(
                                              commentData['avatar_url'],
                                            )
                                            : null,
                                    child:
                                        isAnonymous
                                            ? const Icon(
                                              Icons.person_outline,
                                              color: Colors.white70,
                                            )
                                            : (commentData['avatar_url'] == null
                                                ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                )
                                                : null),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              commentData['username'],
                                              style: TextStyle(
                                                color:
                                                    isAnonymous
                                                        ? Colors.grey[400]
                                                        : Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTimestamp(
                                                commentData['created_at'],
                                              ),
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          commentData['content'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            final comment = _commentController.text.trim();
                            if (comment.isNotEmpty) {
                              final supabase = Supabase.instance.client;
                              final user = supabase.auth.currentUser;
                              final userId = user?.id ?? anonymousUserId;

                              try {
                                await supabase.from('comments').insert({
                                  'user_id': userId,
                                  'video_path': videoUrls[index],
                                  'content': comment,
                                });

                                _commentController.clear();

                                setSheetState(() {});

                                setState(() {
                                  comments[index].add(comment);
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error posting comment: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 10,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getCommentsWithUserInfo(int index) async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('comments')
        .select('''
          content,
          user_id,
          created_at,
          profiles:user_id (
            username,
            avatar_url
          )
        ''')
        .eq('video_path', videoUrls[index])
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(
      res.map((comment) {
        final isAnonymous = comment['user_id'].toString().startsWith('anon_');
        final visitorNumber =
            isAnonymous ? comment['user_id'].toString().split('_')[1] : '';

        return {
          'content': comment['content'],
          'username':
              isAnonymous
                  ? 'Visitor #${visitorNumber.substring(visitorNumber.length - 4)}'
                  : (comment['profiles']?['username'] ?? 'Anonymous'),
          'avatar_url': comment['profiles']?['avatar_url'],
          'user_id': comment['user_id'],
          'created_at': comment['created_at'],
        };
      }),
    );
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _controllers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _controllers.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final controller = _controllers[index];

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: _togglePlayPause,
                        onDoubleTap: () {
                          if (!isLiked[index]) {
                            _handleLike(index);
                            setState(() => showHeart[index] = true);
                            Future.delayed(
                              const Duration(milliseconds: 800),
                              () {
                                setState(() => showHeart[index] = false);
                              },
                            );
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child:
                                  controller.value.isInitialized
                                      ? VideoPlayer(controller)
                                      : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                            ),
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedOpacity(
                                      opacity:
                                          controller.value.isPlaying
                                              ? 0.0
                                              : 0.7,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                        child: Icon(
                                          controller.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (showHeart[index])
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 100,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        right: 15,
                        child: Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked[index]
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isLiked[index] ? Colors.red : Colors.white,
                                size: 32,
                              ),
                              onPressed: () => _handleLike(index),
                            ),
                            Text(
                              '${likeCounts[index]}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            IconButton(
                              icon: const Icon(
                                Icons.comment,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => _openCommentsSheet(index),
                            ),
                            Text(
                              '${comments[index].length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            IconButton(
                              icon: Icon(
                                isSaved[index]
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => _handleSave(index),
                            ),
                            Text(
                              '${saveCounts[index]}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
