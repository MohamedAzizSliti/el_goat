import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/beautiful_logout_button.dart';

class AcceuilPage extends StatefulWidget {
  const AcceuilPage({super.key});

  @override
  State<AcceuilPage> createState() => _AcceuilPageState();
}

class _AcceuilPageState extends State<AcceuilPage> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _successStories = [
    {
      'title': 'From Street to Stadium',
      'image': 'assets/images/1.jpg',
      'description': 'How a young talent made it to professional football',
      'author': 'John Doe',
    },
    {
      'title': 'The Scout\'s Discovery',
      'image': 'assets/images/2.jpg',
      'description': 'Finding diamonds in the rough',
      'author': 'Jane Smith',
    },
    {
      'title': 'Club Success Story',
      'image': 'assets/images/3.jpg',
      'description': 'Building a winning team from scratch',
      'author': 'Mike Johnson',
    },
  ];

  final List<Map<String, dynamic>> _featuredPlayers = [
    {
      'name': 'Alex Morgan',
      'position': 'Forward',
      'club': 'Manchester United',
      'image': 'assets/images/player1.jpg',
    },
    {
      'name': 'James Rodriguez',
      'position': 'Midfielder',
      'club': 'Real Madrid',
      'image': 'assets/images/player2.jpg',
    },
    {
      'name': 'Sarah Johnson',
      'position': 'Defender',
      'club': 'Barcelona',
      'image': 'assets/images/player3.jpg',
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation is handled by the main navigation controller
    // This method is kept for consistency with BottomNavbar interface
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Logo and Menu
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                      ).animate().fadeIn().scale(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              Navigator.pushNamed(context, '/search');
                            },
                          ).animate().fadeIn().scale(),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // Handle notifications
                            },
                          ).animate().fadeIn().scale(),
                          // Show logout button only if user is logged in
                          if (Supabase.instance.client.auth.currentUser != null)
                            const BeautifulLogoutButton(
                              isIconOnly: true,
                              showConfirmDialog: true,
                            ).animate().fadeIn().scale(),
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () {
                              // Handle menu
                            },
                          ).animate().fadeIn().scale(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Welcome Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to El-Goat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 8),
                      Text(
                        'Your gateway to football excellence',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ).animate().fadeIn().slideX(delay: 200.ms),
                    ],
                  ),
                ),

                // Success Stories Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success Stories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _successStories.length,
                          itemBuilder: (context, index) {
                            final story = _successStories[index];
                            return Container(
                              width: 300,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: AssetImage(story['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      story['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      story['description'],
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'By ${story['author']}',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn().slideX(
                              delay: (300 * index).ms,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Featured Players Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Players',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _featuredPlayers.length,
                          itemBuilder: (context, index) {
                            final player = _featuredPlayers[index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.asset(
                                      player['image'],
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          player['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          player['position'],
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          player['club'],
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideX(
                              delay: (300 * index).ms,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Actions Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().slideX(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.sports_soccer,
                            label: 'Find Players',
                            onTap: () {
                              Navigator.pushNamed(context, '/search');
                            },
                          ),
                          _buildQuickActionButton(
                            icon: Icons.search,
                            label: 'Scout',
                            onTap: () {
                              Navigator.pushNamed(context, '/search');
                            },
                          ),
                          _buildQuickActionButton(
                            icon: Icons.group,
                            label: 'Clubs',
                            onTap: () {
                              Navigator.pushNamed(context, '/search');
                            },
                          ),
                        ],
                      ).animate().fadeIn().slideY(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
