import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/navigation_service.dart';
import 'chat_page.dart';
import '../widgets/beautiful_logout_button.dart';

class ClubProfilePage extends StatefulWidget {
  final String clubUserId;
  final bool isViewingOtherUser;

  const ClubProfilePage({
    Key? key,
    required this.clubUserId,
    this.isViewingOtherUser = false,
  }) : super(key: key);

  @override
  State<ClubProfilePage> createState() => _ClubProfilePageState();
}

class _ClubProfilePageState extends State<ClubProfilePage>
    with TickerProviderStateMixin {
  int _selectedIndex = 2;
  Map<String, dynamic>? _club;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClubProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClubProfile() async {
    try {
      final res =
          await Supabase.instance.client
              .from('club_profiles')
              .select()
              .eq('user_id', widget.clubUserId)
              .maybeSingle();

      setState(() {
        _club = (res is Map<String, dynamic>) ? res : null;
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

    if (_club == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Club not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final club = _club!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header Section (like footballer profile)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple.withValues(alpha: 0.8), Colors.black],
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
                              ? (club['club_name'] ?? 'Club Profile')
                              : 'My Club',
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
                                        otherUserId: widget.clubUserId,
                                        otherUserName:
                                            club['club_name'] ?? 'Club',
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
                              // Navigate to edit club profile
                              // TODO: Implement edit club profile functionality
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
                        // Club Logo
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
                              Icons.business,
                              size: 60,
                              color: Colors.yellow,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Club Name
                        Text(
                          club['club_name'] ?? 'Club Name',
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
                              club['location'] ?? 'Location',
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
                            _buildStatItem('Players', '25'),
                            _buildStatItem('Trophies', '12'),
                            _buildStatItem('Founded', '1995'),
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
                                            otherUserId: widget.clubUserId,
                                            otherUserName:
                                                club['club_name'] ?? 'Club',
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
                                    'Edit Club',
                                    Icons.edit,
                                    Colors.yellow,
                                    () {
                                      // TODO: Navigate to edit club profile
                                    },
                                  ),
                                  _buildActionButton(
                                    'Manage',
                                    Icons.settings,
                                    Colors.grey[700]!,
                                    () {
                                      // TODO: Navigate to club management
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
              children: [_buildPostsTab(), _buildAboutMeTab(club)],
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
        'title': 'New Season Training Begins! 🏃‍♂️',
        'content':
            'Our team is ready for the new season! Training sessions have started and the players are showing great dedication. We\'re excited for what\'s to come! #NewSeason #Training',
        'time': '2 hours ago',
        'likes': 45,
        'comments': 12,
        'image': null,
      },
      {
        'title': 'Youth Academy Update 🌟',
        'content':
            'Great progress from our young talents! Our youth academy continues to develop the next generation of football stars. Proud of their commitment and skill development.',
        'time': '1 day ago',
        'likes': 78,
        'comments': 23,
        'image': null,
      },
      {
        'title': 'Victory in Championship! 🏆',
        'content':
            'What an incredible match! Our team showed amazing teamwork and determination. Thank you to all our fans for the incredible support. On to the next challenge!',
        'time': '3 days ago',
        'likes': 156,
        'comments': 45,
        'image': null,
      },
      {
        'title': 'Welcome New Players! 👋',
        'content':
            'We\'re excited to welcome our new signings to the club family. These talented players will strengthen our squad and help us achieve our goals this season.',
        'time': '1 week ago',
        'likes': 89,
        'comments': 34,
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
                      Icons.business,
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
                          _club?['club_name'] ?? 'Club Name',
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

  Widget _buildAboutMeTab(Map<String, dynamic> club) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Club Description (only if available)
          if (club['description'] != null &&
              club['description'].toString().isNotEmpty)
            _buildInfoCard('About Our Club', [
              Text(
                club['description'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ]),
          if (club['description'] != null &&
              club['description'].toString().isNotEmpty)
            const SizedBox(height: 16),

          // Club Information (only actual data from model)
          _buildInfoCard('Club Information', [
            _buildInfoRow('Club Name', club['club_name'] ?? 'Not specified'),
            _buildInfoRow('Location', club['location'] ?? 'Not specified'),
            if (club['website'] != null &&
                club['website'].toString().isNotEmpty)
              _buildInfoRow('Website', club['website']),
            _buildInfoRow(
              'Created',
              club['created_at'] != null
                  ? DateTime.parse(club['created_at']).year.toString()
                  : 'Not specified',
            ),
            if (club['last_seen'] != null)
              _buildInfoRow('Last Active', _formatDate(club['last_seen'])),
          ]),

          // Only show additional sections if there's meaningful data
          if (club['description'] == null ||
              club['description'].toString().isEmpty)
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
                        'The club hasn\'t added a description or additional details yet.',
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
