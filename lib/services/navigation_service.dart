import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_navigation_service.dart';

class NavigationService {
  static final _supabase = Supabase.instance.client;

  /// Main navigation handler for bottom navigation bar
  static void handleBottomNavigation(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        _navigateToHome(context);
        break;
      case 1: // News
        _navigateToNews(context);
        break;
      case 2: // Profile
        _navigateToProfile(context);
        break;
      case 3: // Games
        _navigateToGames(context);
        break;
    }
  }

  /// Navigate to Home page
  static void _navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  /// Navigate to News page
  static void _navigateToNews(BuildContext context) {
    Navigator.pushNamed(context, '/news_home');
  }

  /// Navigate to Profile page (dynamic based on user role)
  static Future<void> _navigateToProfile(BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    await ProfileNavigationService.navigateToUserProfile(context);
  }

  /// Navigate to Games page
  static void _navigateToGames(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    Navigator.pushNamed(context, '/games');
  }

  /// Check if user is authenticated
  static bool isUserAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Navigate to login if not authenticated
  static void requireAuthentication(BuildContext context, VoidCallback onAuthenticated) {
    if (isUserAuthenticated()) {
      onAuthenticated();
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  /// Navigate to specific profile type
  static void navigateToSpecificProfile(BuildContext context, String profileType, {String? userId}) {
    final targetUserId = userId ?? getCurrentUserId();
    if (targetUserId == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    switch (profileType.toLowerCase()) {
      case 'footballer':
        Navigator.pushNamed(context, '/footballer_profile');
        break;
      case 'scout':
        Navigator.pushNamed(context, '/scout_profile');
        break;
      case 'club':
        Navigator.pushNamed(context, '/club_profile');
        break;
      case 'fan':
        Navigator.pushNamed(context, '/fan_profile');
        break;
      default:
        Navigator.pushNamed(context, '/footballer_profile');
    }
  }

  /// Navigate to chat with specific user
  static void navigateToChat(BuildContext context, {
    required String otherUserId,
    required String otherUserName,
    String? otherUserImage,
  }) {
    if (!isUserAuthenticated()) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserImage': otherUserImage ?? 'assets/images/default_avatar.png',
      },
    );
  }

  /// Navigate to search page with optional filters
  static void navigateToSearch(BuildContext context, {
    String? searchQuery,
    String? profileType,
    String? country,
  }) {
    final arguments = <String, dynamic>{};
    if (searchQuery != null) arguments['searchQuery'] = searchQuery;
    if (profileType != null) arguments['profileType'] = profileType;
    if (country != null) arguments['country'] = country;

    Navigator.pushNamed(
      context,
      '/search',
      arguments: arguments.isNotEmpty ? arguments : null,
    );
  }

  /// Navigate to registration with specific role
  static void navigateToRegistration(BuildContext context, {String? role}) {
    Navigator.pushNamed(
      context,
      '/registration',
      arguments: role != null ? {'role': role} : null,
    );
  }

  /// Navigate to specific signup page based on role
  static void navigateToRoleSignup(BuildContext context, String role) {
    final userId = getCurrentUserId();
    if (userId == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    switch (role.toLowerCase()) {
      case 'footballer':
        Navigator.pushNamed(context, '/footballersignup');
        break;
      case 'scout':
        Navigator.pushNamed(context, '/scoutsignup');
        break;
      case 'club':
        Navigator.pushNamed(context, '/clubsignup');
        break;
      default:
        Navigator.pushNamed(context, '/registration');
    }
  }

  /// Navigate to notifications page
  static void navigateToNotifications(BuildContext context) {
    requireAuthentication(context, () {
      Navigator.pushNamed(context, '/notifications');
    });
  }

  /// Navigate to favorites page
  static void navigateToFavorites(BuildContext context) {
    requireAuthentication(context, () {
      Navigator.pushNamed(context, '/favorites');
    });
  }

  /// Navigate to ratings page
  static void navigateToRatings(BuildContext context) {
    requireAuthentication(context, () {
      Navigator.pushNamed(context, '/ratings');
    });
  }

  /// Navigate to stories page
  static void navigateToStories(BuildContext context) {
    Navigator.pushNamed(context, '/stories');
  }

  /// Navigate to news reels page
  static void navigateToNewsReels(BuildContext context) {
    Navigator.pushNamed(context, '/news_reels');
  }

  /// Navigate back or to home if no previous route
  static void navigateBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  /// Navigate to main navigation with specific tab
  static void navigateToMainWithTab(BuildContext context, int tabIndex) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
      arguments: {'initialTab': tabIndex},
    );
  }

  /// Show authentication required dialog
  static void showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Authentication Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You need to be logged in to access this feature.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
