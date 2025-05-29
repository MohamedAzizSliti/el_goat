import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/navigation_service.dart';
import '../services/profile_navigation_service.dart';

class PageRelationshipManager {
  /// Handles navigation between all pages with proper conditions
  static void navigateWithConditions(BuildContext context, String destination, {Map<String, dynamic>? arguments}) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    switch (destination) {
      case 'profile':
        _handleProfileNavigation(context);
        break;
      case 'games':
        _handleGamesNavigation(context);
        break;
      case 'news':
        _handleNewsNavigation(context);
        break;
      case 'home':
        _handleHomeNavigation(context);
        break;
      case 'search':
        _handleSearchNavigation(context, arguments);
        break;
      case 'chat':
        _handleChatNavigation(context, arguments);
        break;
      case 'notifications':
        _handleNotificationsNavigation(context);
        break;
      case 'favorites':
        _handleFavoritesNavigation(context);
        break;
      default:
        Navigator.pushNamed(context, destination, arguments: arguments);
    }
  }

  static void _handleProfileNavigation(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showAuthRequiredDialog(context, 'profile');
      return;
    }
    ProfileNavigationService.navigateToUserProfile(context);
  }

  static void _handleGamesNavigation(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showAuthRequiredDialog(context, 'games');
      return;
    }
    Navigator.pushNamed(context, '/games');
  }

  static void _handleNewsNavigation(BuildContext context) {
    Navigator.pushNamed(context, '/news_home');
  }

  static void _handleHomeNavigation(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  static void _handleSearchNavigation(BuildContext context, Map<String, dynamic>? arguments) {
    Navigator.pushNamed(context, '/search', arguments: arguments);
  }

  static void _handleChatNavigation(BuildContext context, Map<String, dynamic>? arguments) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showAuthRequiredDialog(context, 'chat');
      return;
    }
    
    if (arguments != null && 
        arguments.containsKey('otherUserId') && 
        arguments.containsKey('otherUserName')) {
      Navigator.pushNamed(context, '/chat', arguments: arguments);
    } else {
      // Navigate to chat list or show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid chat parameters'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void _handleNotificationsNavigation(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showAuthRequiredDialog(context, 'notifications');
      return;
    }
    Navigator.pushNamed(context, '/notifications');
  }

  static void _handleFavoritesNavigation(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showAuthRequiredDialog(context, 'favorites');
      return;
    }
    Navigator.pushNamed(context, '/favorites');
  }

  static void _showAuthRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.yellow, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Login Required',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'You need to be logged in to access ${feature}. Please login or create an account to continue.',
          style: const TextStyle(color: Colors.white70),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class ConditionalWrapper extends StatelessWidget {
  final Widget child;
  final bool requiresAuth;
  final String? requiredRole;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onRoleRequired;

  const ConditionalWrapper({
    Key? key,
    required this.child,
    this.requiresAuth = false,
    this.requiredRole,
    this.onAuthRequired,
    this.onRoleRequired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (requiresAuth) {
      return FutureBuilder<bool>(
        future: _checkAuthentication(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            );
          }

          if (!snapshot.data!) {
            return _buildAuthRequiredWidget(context);
          }

          if (requiredRole != null) {
            return FutureBuilder<String?>(
              future: _checkUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                    ),
                  );
                }

                if (roleSnapshot.data != requiredRole) {
                  return _buildRoleRequiredWidget(context);
                }

                return child;
              },
            );
          }

          return child;
        },
      );
    }

    return child;
  }

  Future<bool> _checkAuthentication() async {
    return Supabase.instance.client.auth.currentUser != null;
  }

  Future<String?> _checkUserRole() async {
    return await ProfileNavigationService.getUserRole();
  }

  Widget _buildAuthRequiredWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Authentication Required',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to access this feature',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAuthRequired ?? () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleRequiredWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Access Restricted',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature requires ${requiredRole} role',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRoleRequired ?? () => Navigator.pushNamed(context, '/registration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Complete Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
