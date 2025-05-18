// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/navbar/bottom_navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _accent = Color(0xFFFFD600);
  int _selectedIndex = 0;

  void _onNavTapped(int idx) async {
    setState(() => _selectedIndex = idx);

    if (idx == 3) { // Profile tab
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        Navigator.pushNamed(context, '/login_required');
        return;
      }

      // Fetch the user's role
      final roleResponse = await Supabase.instance.client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      if (roleResponse == null || roleResponse['role'] == null) {
        Navigator.pushNamed(context, '/login_required');
        return;
      }

      final role = roleResponse['role'];

      // Navigate to the appropriate profile page
      switch (role) {
        case 'footballer':
          Navigator.pushNamed(context, '/footballer_profile');
          break;
        case 'scout':
          Navigator.pushNamed(context, '/scout_profile');
          break;
        case 'club':
          Navigator.pushNamed(context, '/club_profile');
          break;
        default:
          Navigator.pushNamed(context, '/login_required');
      }
    } else {
      const routes = ['/', '/stories', '/news_home', '/profile'];
      if (idx < routes.length) Navigator.pushNamed(context, routes[idx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black87),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/'),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.white),
              title: const Text('Stories', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/stories'),
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.white),
              title: const Text('News', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/news_home'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Logo + Login/Sign Up Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Your logo
                Image.asset('assets/images/logo.png', height: 40),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Login', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text('Sign Up', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Explore Stories ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Explore Stories',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (_, i) => Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 80,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: AssetImage('assets/images/${i+1}.jpg'),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Story ${i+1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // --- Join as ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Join as',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _RoleCard(
                          icon: Icons.sports_soccer,
                          label: 'Footballer',
                          onTap: () => Navigator.pushNamed(context, '/footballersignup'),
                        ),
                        const SizedBox(width: 12),
                        _RoleCard(
                          icon: Icons.search,
                          label: 'Scout',
                          onTap: () => Navigator.pushNamed(context, '/scoutsignup'),
                        ),
                        const SizedBox(width: 12),
                        _RoleCard(
                          icon: Icons.business,
                          label: 'Club',
                          onTap: () => Navigator.pushNamed(context, '/clubsigup'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // --- Featured Players ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Featured Players',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 8,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/profile', arguments: {'id': '$i'}),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/images/player${i+1}.jpeg'),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // --- Latest News ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Latest News',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(3, (i) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const Icon(Icons.article, color: Colors.white),
                      title:
                          Text('News Headline ${i+1}', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Brief description…',
                          style: TextStyle(color: Colors.grey[400])),
                      onTap: () =>
                          Navigator.pushNamed(context, '/news_detail', arguments: {'id': '$i'}),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavTapped,
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoleCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
