import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  String? _userRole;
  String? _error;
  late TabController _tabController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerScale;
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
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      final roleResponse =
          await Supabase.instance.client
              .from('user_roles')
              .select('role')
              .eq('user_id', userId)
              .maybeSingle();
      if (roleResponse == null) {
        setState(() {
          _isLoading = false;
          _error =
              'No role found for this user. Please contact support or complete registration.';
        });
        return;
      }
      setState(() {
        _userRole = roleResponse['role'];
      });
      final profileResponse =
          await Supabase.instance.client
              .from('${_userRole}_profiles')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
      if (profileResponse == null) {
        setState(() {
          _isLoading = false;
          _error = 'No profile found. Please complete your profile.';
        });
        return;
      }
      setState(() {
        _userProfile = profileResponse;
        _isLoading = false;
        _error = null;
        // Load posts if available
        _posts = List<Map<String, String>>.from(_userProfile?['posts'] ?? []);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error loading profile: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error!)));
    }
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

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUserProfile,
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final profile = _userProfile!;
    return Scaffold(
      backgroundColor: const Color(0xFF222831),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006847),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Column(
        children: [
          // Animated Header
          ScaleTransition(
            scale: _headerScale,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFF222831)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.yellow[700],
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile['full_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatCard(
                        label: 'Goals',
                        value: (profile['goals'] ?? '0').toString(),
                      ),
                      const SizedBox(width: 24),
                      _StatCard(
                        label: 'Age',
                        value: (profile['age'] ?? 'N/A').toString(),
                      ),
                      const SizedBox(width: 24),
                      _StatCard(
                        label: 'Pos',
                        value: profile['position'] ?? 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Teams Played For
                  if ((profile['teams'] ?? []).isNotEmpty) ...[
                    const Text(
                      'Teams Played For',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: (profile['teams'] as List).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder:
                            (_, i) => CircleAvatar(
                              backgroundImage: AssetImage(profile['teams'][i]),
                              radius: 18,
                              backgroundColor: Colors.white,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // TabBar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF393E46),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.yellow,
              labelColor: Colors.yellow,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.article), text: 'My Posts'),
                Tab(icon: Icon(Icons.info_outline), text: 'About Me'),
              ],
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Posts Tab
                _PostsTab(posts: _posts),
                // About Me Tab
                _AboutTab(about: profile['about'] ?? ''),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _tabController.index == 0
              ? FloatingActionButton(
                backgroundColor: Colors.yellow,
                child: const Icon(Icons.add, color: Colors.black),
                onPressed: _showAddPostDialog,
              )
              : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
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
  final String about;
  const _AboutTab({required this.about});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        about,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
