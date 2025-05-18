// ScoutProfilePage with enhanced UI and latest profile data from Supabase

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScoutProfilePage extends StatefulWidget {
  const ScoutProfilePage({Key? key}) : super(key: key);

  @override
  State<ScoutProfilePage> createState() => _ScoutProfilePageState();
}

class _ScoutProfilePageState extends State<ScoutProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchLatestProfile();
  }

  Future<void> _fetchLatestProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final response = await _supabase
        .from('scout_profiles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    setState(() {
      _profile = response;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No profile found', style: TextStyle(color: Colors.white))),
      );
    }

    final profile = _profile!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scout Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/scout.jpeg'),
            ),
            const SizedBox(height: 12),
            Text(profile['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${profile['country'] ?? ''} • ${profile['city'] ?? ''}', style: const TextStyle(color: Colors.grey)),
            const Divider(color: Colors.white38, height: 30),

            _infoRow('Phone', profile['phone']),
            _infoRow('Scouting Level', profile['scouting_level']),
            _infoRow('Experience', '${profile['years_experience'] ?? '0'} years'),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Bio', style: TextStyle(color: Colors.yellow[700], fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(profile['bio'] ?? '', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value ?? '', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
} 
