// Enhanced FootballerProfilePage fetching latest profile data

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/chat_page.dart';
import '../screens/ai_training_screen.dart';
import '../models/footballer_profile_model.dart';
import '../widgets/beautiful_logout_button.dart';

class FootballerProfilePage extends StatefulWidget {
  final String? userId;
  final bool isViewingOtherUser;

  const FootballerProfilePage({
    Key? key,
    this.userId,
    this.isViewingOtherUser = false,
  }) : super(key: key);

  @override
  State<FootballerProfilePage> createState() => _FootballerProfilePageState();
}

class _FootballerProfilePageState extends State<FootballerProfilePage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  FootballerProfileModel? _profile;
  String? _userRole;
  String? _error;
  late TabController _tabController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerScale;
  final List<String> _uploadedImages = [];
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 3;
  List<Map<String, String>> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _headerScale = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.elasticOut,
    );
    _fetchLatestProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchLatestProfile() async {
    try {
      // Use provided userId or current user's ID
      final targetUserId =
          widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
      if (targetUserId == null) {
        setState(() {
          _error =
              widget.isViewingOtherUser
                  ? 'User profile not found'
                  : 'Please log in to view your profile';
          _isLoading = false;
        });
        return;
      }

      // Get user role
      final roleResponse =
          await Supabase.instance.client
              .from('user_roles')
              .select('role')
              .eq('user_id', targetUserId)
              .maybeSingle();

      if (roleResponse == null || roleResponse['role'] == null) {
        setState(() {
          _error = 'User role not found. Please complete your registration.';
          _isLoading = false;
        });
        return;
      }

      final role = roleResponse['role'];
      setState(() => _userRole = role);

      // Get profile data
      final profileResponse =
          await Supabase.instance.client
              .from('${role}_profiles')
              .select()
              .eq('user_id', targetUserId)
              .maybeSingle();

      if (profileResponse == null) {
        setState(() {
          _error = 'Profile not found. Please complete your profile setup.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profile = FootballerProfileModel.fromJson(profileResponse);
        _isLoading = false;
        _error = null;
        _posts = List<Map<String, String>>.from(profileResponse['posts'] ?? []);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _formatPlayerName(String fullName) {
    // Replace underscores with spaces and capitalize each word
    return fullName
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word,
        )
        .join(' ');
  }

  String _formatExperienceLevel(String experience) {
    // Handle common experience level formats
    switch (experience.toLowerCase()) {
      case 'beginner':
      case 'amateur':
        return 'Beginner';
      case 'intermediate':
      case 'semi-pro':
        return 'Intermediate';
      case 'advanced':
      case 'professional':
      case 'pro':
        return 'Professional';
      case 'unknown':
      case '':
        return 'Beginner'; // Default fallback
      default:
        return experience.isNotEmpty
            ? experience[0].toUpperCase() +
                experience.substring(1).toLowerCase()
            : 'Beginner';
    }
  }

  Widget _buildExperienceBar(String level) {
    final levels = ['Amateur', 'Semi-Pro', 'Pro'];
    final idx = levels.indexOf(level);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(levels.length, (i) {
        final isActive = i <= idx;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Icon(
                Icons.sports_soccer,
                color: isActive ? Colors.yellow : Colors.white24,
                size: 28,
              ),
              Text(
                levels[i],
                style: TextStyle(
                  color: isActive ? Colors.yellow : Colors.white54,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _onItemTapped(int index) {
    // Navigation is handled by MainNavigation parent
    // This is just for maintaining the selected state
    setState(() => _selectedIndex = index);
  }

  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _uploadedImages.add(image.path));
  }

  void _showAddPostDialog() {
    String title = '';
    String content = '';
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF393E46),
            title: const Text(
              'Add Post',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (v) => title = v,
                ),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (v) => content = v,
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                ),
                child: const Text('Add', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  if (title.isNotEmpty && content.isNotEmpty) {
                    setState(() {
                      _posts.insert(0, {'title': title, 'content': content});
                    });
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.yellow[400]!, Colors.orange[400]!],
              ),
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f0f23)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Error Icon
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red[400]!.withValues(alpha: 0.3),
                                Colors.red[600]!.withValues(alpha: 0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red[400]!.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 60,
                            color: Colors.red[400],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Title with gradient
                  ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: [Colors.red[400]!, Colors.orange[400]!],
                        ).createShader(bounds),
                    child: const Text(
                      'Access Required',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.yellow[600]!,
                                Colors.orange[500]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow[600]!.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              _fetchLatestProfile();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final data = _profile!;
    final name = _formatPlayerName(data.fullName);
    final image = data.profileImage ?? 'assets/images/player_avatar.jpeg';
    final position = data.position;
    final age = _calculateAge(data.dateOfBirth);
    final experience = _formatExperienceLevel(data.experience);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section (like club and scout profiles)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.withValues(alpha: 0.8), Colors.black],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // App Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            widget.isViewingOtherUser
                                ? 'Profile'
                                : 'My Profile',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (widget.isViewingOtherUser)
                            IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // Check if user is authenticated
                                final currentUser =
                                    Supabase.instance.client.auth.currentUser;
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please log in to send messages',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChatScreen(
                                            otherUserId: data.userId,
                                            otherUserName: name,
                                            otherUserImage: image,
                                          ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error opening chat: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                // Navigate to edit profile
                                // TODO: Implement edit profile functionality
                              },
                            ),
                        ],
                      ),
                    ),
                    // Profile Header Content
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Player Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.yellow,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: AssetImage(image),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Player Name
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Position
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.sports_soccer,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                position,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('Age', age.toString()),
                              _buildStatItem('Level', experience),
                              _buildStatItem('XP', '1,250'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Action Buttons
                          if (!widget.isViewingOtherUser)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        'AI Training',
                                        Icons.auto_awesome,
                                        Colors.yellow,
                                        () {
                                          if (_profile != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        AITrainingScreen(
                                                          player: _profile!,
                                                        ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildActionButton(
                                        'Game',
                                        Icons.sports_soccer,
                                        Colors.green,
                                        () {
                                          // Navigate to games page
                                          Navigator.pushNamed(
                                            context,
                                            '/games',
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Beautiful Logout Button
                                const BeautifulLogoutButton(
                                  customText: 'Logout',
                                  customIcon: Icons.logout_rounded,
                                  showConfirmDialog: true,
                                ),
                              ],
                            )
                          else
                            _buildActionButton(
                              'Message',
                              Icons.message,
                              Colors.blue,
                              () {
                                // Check if user is authenticated
                                final currentUser =
                                    Supabase.instance.client.auth.currentUser;
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please log in to send messages',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChatScreen(
                                            otherUserId: data.userId,
                                            otherUserName: name,
                                            otherUserImage: image,
                                          ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error opening chat: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.black,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.yellow,
                labelColor: Colors.yellow,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [Tab(text: 'My Posts'), Tab(text: 'About Me')],
              ),
            ),
            // Tab Views
            Container(
              height: 600, // Fixed height for tab content
              child: TabBarView(
                controller: _tabController,
                children: [_buildPostsTab(), _buildAboutMeTab(data)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return const Center(
        child: Text('No posts yet.', style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:
          (_, i) => Card(
            color: const Color(0xFF393E46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(
                _posts[i]['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _posts[i]['content'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
    );
  }

  Widget _buildAboutMeTab(FootballerProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[600]!.withValues(alpha: 0.2),
                    Colors.purple[600]!.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.purple[400]!],
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'About Me',
                        style: TextStyle(
                          color: Colors.yellow[400],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.bio!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Player Details Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange[600]!.withValues(alpha: 0.2),
                  Colors.red[600]!.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.orange[400]!, Colors.red[400]!],
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Player Details',
                      style: TextStyle(
                        color: Colors.yellow[400],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Full Name', profile.fullName),
                _buildInfoRow('Position', profile.position),
                _buildInfoRow(
                  'Age',
                  _calculateAge(profile.dateOfBirth).toString(),
                ),
                _buildInfoRow('Experience', profile.experience),
                if (profile.height != null)
                  _buildInfoRow('Height', '${profile.height} cm'),
                if (profile.weight != null)
                  _buildInfoRow('Weight', '${profile.weight} kg'),
                if (profile.preferredFoot != null)
                  _buildInfoRow('Preferred Foot', profile.preferredFoot!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  final List<Map<String, String>> posts;
  const _PostsTab({required this.posts});
  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(
        child: Text('No posts yet.', style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:
          (_, i) => Card(
            color: const Color(0xFF393E46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(
                posts[i]['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                posts[i]['content'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final FootballerProfileModel profile;
  const _AboutTab({required this.profile});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[600]!.withValues(alpha: 0.2),
                    Colors.purple[600]!.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.purple[400]!],
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'About Me',
                        style: TextStyle(
                          color: Colors.yellow[400],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.bio!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Player Details Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange[600]!.withValues(alpha: 0.2),
                  Colors.red[600]!.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.orange[400]!, Colors.red[400]!],
                        ),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Player Details',
                      style: TextStyle(
                        color: Colors.yellow[400],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.flag, 'Nationality', profile.nationality),
                _buildDetailRow(
                  Icons.sports_soccer,
                  'Preferred Foot',
                  profile.preferredFoot,
                ),
                _buildDetailRow(Icons.height, 'Height', '${profile.height} cm'),
                _buildDetailRow(
                  Icons.fitness_center,
                  'Weight',
                  '${profile.weight} kg',
                ),
                _buildDetailRow(Icons.star, 'Experience', profile.experience),
              ],
            ),
          ),

          // Skills Section
          if (profile.skills.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green[600]!.withValues(alpha: 0.2),
                    Colors.teal[600]!.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.teal[400]!],
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Skills & Abilities',
                        style: TextStyle(
                          color: Colors.yellow[400],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        profile.skills
                            .map(
                              (skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.yellow[600]!,
                                      Colors.orange[500]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellow[600]!.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
