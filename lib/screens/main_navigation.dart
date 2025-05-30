// lib/screens/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/navbar/bottom_navbar.dart';
import '../widgets/dynamic_profile_widget.dart';
import '../services/user_registration_service.dart';
import 'accueil_page.dart';
import 'news_home_page.dart';
import 'conversations_screen.dart';
import 'games_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserRole();
    _ensureUserRegistration();
  }

  Future<void> _loadUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response =
          await Supabase.instance.client
              .from('user_roles')
              .select('role')
              .eq('user_id', userId)
              .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userRole = response['role'] as String?;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _ensureUserRegistration() async {
    try {
      await UserRegistrationService.ensureUserRegistration();
    } catch (e) {
      // Handle error silently
      print('Error ensuring user registration: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) async {
    // Check authentication for protected tabs
    final isFootballer = _userRole == 'footballer';
    final protectedTabs =
        isFootballer
            ? [2, 3, 4] // Games, Messages, Profile for footballers
            : [2, 3]; // Messages, Profile for non-footballers

    if (protectedTabs.contains(index)) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          Navigator.pushNamed(context, '/login');
        }
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Widget> _buildPages() {
    final isFootballer = _userRole == 'footballer';

    if (isFootballer) {
      // For footballers: Home, News, Games, Messages, Profile
      return [
        const AcceuilPage(), // Index 0: Home
        NewsHomePage(toggleTheme: () {}), // Index 1: News
        const GamificationDashboard(), // Index 2: Games
        const ConversationsScreen(), // Index 3: Messages
        const ProfileRouterWidget(), // Index 4: Profile
      ];
    } else {
      // For non-footballers: Home, News, Messages, Profile
      return [
        const AcceuilPage(), // Index 0: Home
        NewsHomePage(toggleTheme: () {}), // Index 1: News
        const ConversationsScreen(), // Index 2: Messages
        const ProfileRouterWidget(), // Index 3: Profile
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _buildPages(),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavTapped,
      ),
    );
  }
}
