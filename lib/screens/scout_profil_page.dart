import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';
import '../widgets/beautiful_logout_button.dart';

class ScoutProfilePage extends StatefulWidget {
  final String scoutUserId;
  final bool isViewingOtherUser;

  const ScoutProfilePage({
    super.key,
    required this.scoutUserId,
    this.isViewingOtherUser = false,
  });

  @override
  State<ScoutProfilePage> createState() => _ScoutProfilePageState();
}

class _ScoutProfilePageState extends State<ScoutProfilePage>
    with TickerProviderStateMixin {
  int _selectedIndex = 2;
  Map<String, dynamic>? _scout;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadScoutProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScoutProfile() async {
    try {
      final res =
          await Supabase.instance.client
              .from('scout_profiles')
              .select()
              .eq('user_id', widget.scoutUserId)
              .maybeSingle();

      setState(() {
        _scout = (res is Map<String, dynamic>) ? res : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ),
      );
    }

    if (_scout == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Scout not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final scout = _scout!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header Section (like club profile)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.withValues(alpha: 0.8), Colors.black],
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
                              ? (scout['full_name'] ?? 'Scout Profile')
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ChatScreen(
                                        otherUserId: widget.scoutUserId,
                                        otherUserName:
                                            scout['full_name'] ?? 'Scout',
                                        otherUserImage: '',
                                      ),
                                ),
                              );
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
                        // Scout Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.yellow, width: 3),
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
                            child: const Icon(
                              Icons.search,
                              size: 60,
                              color: Colors.yellow,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Scout Name
                        Text(
                          scout['full_name'] ?? 'Scout Name',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${scout['city'] ?? 'City'}, ${scout['country'] ?? 'Country'}',
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
                            _buildStatItem(
                              'Level',
                              scout['scouting_level'] ?? 'Local',
                            ),
                            _buildStatItem(
                              'Experience',
                              '${scout['experience_years'] ?? 0} yrs',
                            ),
                            _buildStatItem('Evaluations', '45'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Action Buttons
                        if (widget.isViewingOtherUser)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                'Follow',
                                Icons.add,
                                Colors.yellow,
                                () {},
                              ),
                              _buildActionButton(
                                'Message',
                                Icons.message,
                                Colors.blue,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChatScreen(
                                            otherUserId: widget.scoutUserId,
                                            otherUserName:
                                                scout['full_name'] ?? 'Scout',
                                            otherUserImage: '',
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    'Edit Profile',
                                    Icons.edit,
                                    Colors.yellow,
                                    () {
                                      // TODO: Navigate to edit profile
                                    },
                                  ),
                                  _buildActionButton(
                                    'Settings',
                                    Icons.settings,
                                    Colors.grey[700]!,
                                    () {
                                      // TODO: Navigate to settings
                                    },
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
              tabs: const [Tab(text: 'Posts'), Tab(text: 'About Me')],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPostsTab(), _buildAboutMeTab(scout)],
            ),
          ),
        ],
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
    final posts = [
      {
        'title': 'Scouting Report: Promising Young Talent! ⭐',
        'content':
            'Just watched an incredible match! Found a young midfielder with exceptional vision and passing ability. His technical skills and game intelligence are remarkable for his age. Definitely one to watch! #ScoutingReport #YoungTalent',
        'time': '3 hours ago',
        'likes': 28,
        'comments': 8,
        'image': null,
      },
      {
        'title': 'Regional Championship Analysis 📊',
        'content':
            'Completed my evaluation of the regional championship. Several standout players caught my attention. The level of competition was impressive, and I\'ve identified 3 potential prospects for further evaluation.',
        'time': '1 day ago',
        'likes': 45,
        'comments': 15,
        'image': null,
      },
      {
        'title': 'Training Session Observations 🏃‍♂️',
        'content':
            'Attended a youth academy training session today. The coaching methods and player development programs are excellent. Great to see young players working hard to improve their skills.',
        'time': '2 days ago',
        'likes': 32,
        'comments': 6,
        'image': null,
      },
      {
        'title': 'International Tournament Update 🌍',
        'content':
            'Back from the international youth tournament. Amazing experience watching future stars compete at the highest level. Several players have been added to my watchlist for continued monitoring.',
        'time': '1 week ago',
        'likes': 67,
        'comments': 22,
        'image': null,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.yellow,
                    child: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scout?['full_name'] ?? 'Scout Name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          post['time'] as String,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Post Content
              Text(
                post['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post['content'] as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Post Actions
              Row(
                children: [
                  _buildPostAction(
                    Icons.favorite_border,
                    '${post['likes']}',
                    Colors.red,
                    () {},
                  ),
                  const SizedBox(width: 24),
                  _buildPostAction(
                    Icons.comment_outlined,
                    '${post['comments']}',
                    Colors.blue,
                    () {},
                  ),
                  const SizedBox(width: 24),
                  _buildPostAction(
                    Icons.share_outlined,
                    'Share',
                    Colors.green,
                    () {},
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeTab(Map<String, dynamic> scout) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scout Bio (only if available)
          if (scout['bio'] != null && scout['bio'].toString().isNotEmpty)
            _buildInfoCard('About Me', [
              Text(
                scout['bio'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ]),
          if (scout['bio'] != null && scout['bio'].toString().isNotEmpty)
            const SizedBox(height: 16),

          // Scout Information (only actual data from model)
          _buildInfoCard('Scout Information', [
            _buildInfoRow('Full Name', scout['full_name'] ?? 'Not specified'),
            _buildInfoRow('Email', scout['email'] ?? 'Not specified'),
            _buildInfoRow('Phone', scout['phone'] ?? 'Not specified'),
            _buildInfoRow('Country', scout['country'] ?? 'Not specified'),
            _buildInfoRow('City', scout['city'] ?? 'Not specified'),
            _buildInfoRow(
              'Scouting Level',
              scout['scouting_level'] ?? 'Not specified',
            ),
            _buildInfoRow(
              'Experience',
              '${scout['experience_years'] ?? 0} years',
            ),
            _buildInfoRow(
              'Created',
              scout['created_at'] != null
                  ? DateTime.parse(scout['created_at']).year.toString()
                  : 'Not specified',
            ),
            if (scout['last_seen'] != null)
              _buildInfoRow('Last Active', _formatDate(scout['last_seen'])),
          ]),

          // Only show additional sections if there's meaningful data
          if (scout['bio'] == null || scout['bio'].toString().isEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No additional information available',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The scout hasn\'t added a bio or additional details yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
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
