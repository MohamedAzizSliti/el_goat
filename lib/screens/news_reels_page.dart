import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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

  late PageController _pageController;
  late VideoPlayerController _videoController;
  int _currentIndex = 0; // Tracks the current video index
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _showPlayPauseButton =
      false; // Tracks visibility of the play/pause button
  int _selectedIndex = 2; // Default selected index for BottomNavbar

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeVideoPlayer(0);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer(int index) {
    _videoController = VideoPlayerController.asset(videoUrls[index])
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
      });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _videoController.dispose();
    _initializeVideoPlayer(index);
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
        _isPlaying = false;
      } else {
        _videoController.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    setState(() {
      if (_isMuted) {
        _videoController.setVolume(1.0);
        _isMuted = false;
      } else {
        _videoController.setVolume(0.0);
        _isMuted = true;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/'); // Navigate to Home
        break;
      case 1:
        Navigator.pushNamed(context, '/stories'); // Navigate to Stories
        break;
      case 2:
        // Stay on NewsReelsPage
        break;
      case 3:
        Navigator.pushNamed(context, '/profile'); // Navigate to Profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('El Goat'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Open drawer
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: videoUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _showPlayPauseButton = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                setState(() {
                  _showPlayPauseButton = false;
                });
              });
            },
            child: Stack(
              children: [
                // Video Player
                SizedBox.expand(
                  child: _videoController.value.isInitialized
                      ? VideoPlayer(_videoController)
                      : const Center(child: CircularProgressIndicator()),
                ),
                // Play/Pause Button
                if (_showPlayPauseButton)
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                // Mute/Unmute Button
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
                // Interactive UI Elements
                Positioned(
                  bottom: 20,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and Caption
                      const Text(
                        '@Footballer123',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Amazing goal from last night\'s match! ⚽🔥',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      // Floating Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite,
                                    color: Colors.red),
                                onPressed: () {
                                  // Handle like action
                                },
                              ),
                              const Text(
                                '1.2k',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.comment,
                                    color: Colors.white),
                                onPressed: () {
                                  // Handle comment action
                                },
                              ),
                              const Text(
                                '300',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.white),
                                onPressed: () {
                                  // Handle share action
                                },
                              ),
                              const Text(
                                'Share',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.bookmark,
                                    color: Colors.white),
                                onPressed: () {
                                  // Handle save action
                                },
                              ),
                              const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
