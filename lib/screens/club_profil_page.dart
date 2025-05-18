import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/navbar/bottom_navbar.dart';
import 'chat_page.dart';

class ClubProfilePage extends StatefulWidget {
  final String clubUserId;
  const ClubProfilePage({Key? key, required this.clubUserId}) : super(key: key);

  @override
  State<ClubProfilePage> createState() => _ClubProfilePageState();
}

class _ClubProfilePageState extends State<ClubProfilePage> {
  int _selectedIndex = 3;
  Map<String, dynamic>? _club;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClubProfile();
  }

  Future<void> _loadClubProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final res = await Supabase.instance.client
        .from('club_profiles')
        .select()
        .eq('user_id', widget.clubUserId)
        .maybeSingle();
    setState(() {
      _club = (res is Map<String, dynamic>) ? res : null;
      _loading = false;
    });
  }

  Future<String> _getMyRole() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null) return 'normal';
    final scout = await Supabase.instance.client
        .from('scout_profiles')
        .select()
        .eq('user_id', me)
        .maybeSingle();
    if (scout != null) return 'scout';
    final footballer = await Supabase.instance.client
        .from('footballer_profiles')
        .select()
        .eq('user_id', me)
        .maybeSingle();
    if (footballer != null) return 'footballer';
    return 'normal';
  }

  void _onNav(int idx) {
    setState(() => _selectedIndex = idx);
    const routes = ['/', '/stories', '/news_home', '/profile'];
    Navigator.pushNamed(context, routes[idx]);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_club == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login_required');
      });
      return const SizedBox.shrink();
    }

    final club = _club!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(club['club_name'] ?? 'Club Profile', style: const TextStyle(color: Colors.white)),
        actions: [
          FutureBuilder<String>(
            future: _getMyRole(),
            builder: (ctx, snap) {
              if (snap.data == null || snap.data == 'normal') return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.message, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: widget.clubUserId,
                        otherUserName: club['club_name'] ?? 'Club',
                        otherUserImage: club['logo_url'] ?? '',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: club['logo_url'] != null
                        ? NetworkImage(club['logo_url'])
                        : const AssetImage('assets/images/club_logo.jpeg') as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(club['club_name'], style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${club['location']}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildSection(
                  title: 'Informations générales',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Localisation: ${club['location']}', style: const TextStyle(color: Colors.white)),
                      Text('Site web: ${club['website'] ?? "—"}', style: const TextStyle(color: Colors.white)),
                      Text('Membres staff: ${club['staff_count'] ?? "—"}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildSection(
                  title: 'Recrutement',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recherche: ${club['recruiting'] == true ? "Oui" : "Non"}', style: const TextStyle(color: Colors.white)),
                      Text('Postes: ${club['positions'] ?? "—"}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                )),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('S’ABONNER'),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Dernières nouvelles',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club['news'] ?? 'Aucune annonce pour le moment.', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(selectedIndex: _selectedIndex, onItemTapped: _onNav),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
