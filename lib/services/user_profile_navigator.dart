import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/role_based_profile_viewer.dart';
import '../services/profile_navigation_service.dart';

class UserProfileNavigator {
  static final _supabase = Supabase.instance.client;

  /// Navigate to any user's profile with role-based interface
  static Future<void> navigateToUserProfile(
    BuildContext context,
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check if it's the current user
      final currentUserId = _supabase.auth.currentUser?.id;
      final isViewingOtherUser = currentUserId != userId;

      // Show loading dialog for better UX
      if (forceRefresh) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );

        // Small delay to show loading
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context); // Close loading dialog
      }

      // Navigate to role-based profile viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoleBasedProfileViewer(
            userId: userId,
            isViewingOtherUser: isViewingOtherUser,
          ),
        ),
      );
    } catch (e) {
      // Handle navigation error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navigate to user profile with role detection and interface adaptation
  static Future<void> navigateToUserProfileWithRoleDetection(
    BuildContext context,
    String userId,
  ) async {
    try {
      // Get user role first
      final role = await ProfileNavigationService.getUserRole(userId);
      
      if (role == null) {
        _showProfileNotFoundDialog(context);
        return;
      }

      // Navigate with role information
      await navigateToUserProfile(context, userId);
    } catch (e) {
      _showErrorDialog(context, 'Error detecting user role: $e');
    }
  }

  /// Navigate to profile from search results or user lists
  static Future<void> navigateFromSearchResult(
    BuildContext context,
    Map<String, dynamic> userResult,
  ) async {
    try {
      final userId = userResult['user_id'] ?? userResult['id'];
      final role = userResult['role'] ?? userResult['profile_type'];

      if (userId == null) {
        _showErrorDialog(context, 'Invalid user data');
        return;
      }

      // Show role-specific loading message
      final roleDisplayName = _getRoleDisplayName(role);
      _showLoadingDialog(context, 'Loading $roleDisplayName profile...');

      // Small delay for better UX
      await Future.delayed(Duration(milliseconds: 800));
      Navigator.pop(context); // Close loading dialog

      // Navigate to profile
      await navigateToUserProfile(context, userId);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorDialog(context, 'Error loading profile: $e');
    }
  }

  /// Navigate to profile with custom transition animation
  static Future<void> navigateWithCustomTransition(
    BuildContext context,
    String userId, {
    String? expectedRole,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final isViewingOtherUser = currentUserId != userId;

      // Custom page transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RoleBasedProfileViewer(
            userId: userId,
            isViewingOtherUser: isViewingOtherUser,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Error navigating to profile: $e');
    }
  }

  /// Check if user can view another user's profile
  static Future<bool> canViewProfile(String targetUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      
      // Always allow viewing own profile
      if (currentUserId == targetUserId) return true;

      // Check if target user exists and has a profile
      final role = await ProfileNavigationService.getUserRole(targetUserId);
      return role != null;
    } catch (e) {
      return false;
    }
  }

  /// Get user's role and profile preview for quick display
  static Future<Map<String, dynamic>?> getUserProfilePreview(String userId) async {
    try {
      final role = await ProfileNavigationService.getUserRole(userId);
      if (role == null) return null;

      final profileData = await ProfileNavigationService.getProfileData(userId);
      if (profileData == null) return null;

      return {
        'user_id': userId,
        'role': role,
        'role_display': _getRoleDisplayName(role),
        'name': _extractName(profileData, role),
        'subtitle': _extractSubtitle(profileData, role),
        'avatar_url': profileData['avatar_url'],
        'is_verified': profileData['is_verified'] ?? false,
      };
    } catch (e) {
      return null;
    }
  }

  // Helper methods
  static String _getRoleDisplayName(String? role) {
    switch (role?.toLowerCase()) {
      case 'footballer':
        return 'Footballer';
      case 'scout':
        return 'Scout';
      case 'club':
        return 'Club';
      case 'fan':
        return 'Fan';
      default:
        return 'User';
    }
  }

  static String _extractName(Map<String, dynamic> profileData, String role) {
    switch (role.toLowerCase()) {
      case 'footballer':
      case 'scout':
      case 'fan':
        return profileData['full_name'] ?? 'Unknown User';
      case 'club':
        return profileData['club_name'] ?? 'Unknown Club';
      default:
        return 'Unknown User';
    }
  }

  static String _extractSubtitle(Map<String, dynamic> profileData, String role) {
    switch (role.toLowerCase()) {
      case 'footballer':
        final position = profileData['position'] ?? 'Player';
        final age = profileData['age'];
        return age != null ? '$position • $age years old' : position;
      case 'scout':
        final level = profileData['level'] ?? 'Scout';
        final experience = profileData['experience'] ?? '';
        return experience.isNotEmpty ? '$level • $experience' : level;
      case 'club':
        final league = profileData['league'] ?? '';
        final location = profileData['location'] ?? '';
        return [league, location].where((s) => s.isNotEmpty).join(' • ');
      case 'fan':
        return 'Football Fan';
      default:
        return '';
    }
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showProfileNotFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Profile Not Found', style: TextStyle(color: Colors.white)),
        content: Text(
          'This user profile could not be found or is not available.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }
}
