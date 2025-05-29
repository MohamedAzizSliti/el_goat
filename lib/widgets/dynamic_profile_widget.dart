import 'package:el_goat/screens/profile_page.dart';
import 'package:el_goat/screens/scout_profil_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_navigation_service.dart';
import '../screens/club_profil_page.dart';
import '../screens/login_required_page.dart';

class DynamicProfileWidget extends StatefulWidget {
  const DynamicProfileWidget({Key? key}) : super(key: key);

  @override
  State<DynamicProfileWidget> createState() => _DynamicProfileWidgetState();
}

class _DynamicProfileWidgetState extends State<DynamicProfileWidget> {
  String? _userRole;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkUserAndRole();
  }

  Future<void> _checkUserAndRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoggedIn = true);

      final role = await ProfileNavigationService.getUserRole(userId);

      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const LoginRequiredPage();
    }

    // Show appropriate profile based on user role
    switch (_userRole) {
      case 'footballer':
        return const FootballerProfilePage();
      case 'scout':
        return ScoutProfilePage(
          scoutUserId: Supabase.instance.client.auth.currentUser!.id,
        );
      case 'club':
        return ClubProfilePage(
          clubUserId: Supabase.instance.client.auth.currentUser!.id,
        );
      case 'fan':
        // TODO: Create FanProfilePage when needed
        return _buildNoProfileWidget('Fan Profile Coming Soon');
      default:
        return _buildNoProfileWidget('Profile Not Found');
    }
  }

  Widget _buildNoProfileWidget(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete your profile setup',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/registration');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Complete Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative approach: Profile Router Widget that can be used in PageView
class ProfileRouterWidget extends StatelessWidget {
  const ProfileRouterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            ),
          );
        }

        final role = snapshot.data;

        switch (role) {
          case 'footballer':
            return const FootballerProfilePage();
          case 'scout':
            return ScoutProfilePage(
              scoutUserId: Supabase.instance.client.auth.currentUser!.id,
            );
          case 'club':
            return ClubProfilePage(
              clubUserId: Supabase.instance.client.auth.currentUser!.id,
            );
          case 'fan':
            return _buildComingSoonWidget('Fan Profile');
          default:
            return _buildSetupProfileWidget();
        }
      },
    );
  }

  Future<String?> _getUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    return await ProfileNavigationService.getUserRole(userId);
  }

  Widget _buildComingSoonWidget(String profileType) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              '$profileType Coming Soon',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is under development',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupProfileWidget() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Profile Setup Required',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete your profile to continue',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
