import 'package:el_goat/screens/club_profil_page.dart';
import 'package:el_goat/screens/scout_profil_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_navigation_service.dart';
import '../screens/profile_page.dart';

class RoleBasedProfileViewer extends StatefulWidget {
  final String userId;
  final bool isViewingOtherUser;

  const RoleBasedProfileViewer({
    super.key,
    required this.userId,
    this.isViewingOtherUser = false,
  });

  @override
  State<RoleBasedProfileViewer> createState() => _RoleBasedProfileViewerState();
}

class _RoleBasedProfileViewerState extends State<RoleBasedProfileViewer> {
  String? _userRole;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get user role
      final role = await ProfileNavigationService.getUserRole(widget.userId);
      if (role == null) {
        setState(() {
          _error = 'User role not found';
          _isLoading = false;
        });
        return;
      }

      // Get profile data
      final profileData = await ProfileNavigationService.getProfileData(
        widget.userId,
      );
      if (profileData == null) {
        setState(() {
          _error = 'Profile data not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userRole = role;
        _profileData = profileData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Profile Not Found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Show role-specific profile interface
    return _buildRoleSpecificProfile();
  }

  Widget _buildRoleSpecificProfile() {
    switch (_userRole?.toLowerCase()) {
      case 'footballer':
        return _buildFootballerProfileView();
      case 'scout':
        return _buildScoutProfileView();
      case 'club':
        return _buildClubProfileView();
      case 'fan':
        return _buildFanProfileView();
      default:
        return _buildUnknownProfileView();
    }
  }

  Widget _buildFootballerProfileView() {
    if (widget.isViewingOtherUser) {
      // Show footballer profile in view-only mode for other users
      return FootballerProfilePage(
        userId: widget.userId,
        isViewingOtherUser: true,
      );
    } else {
      // Show own footballer profile with edit capabilities
      return FootballerProfilePage();
    }
  }

  Widget _buildScoutProfileView() {
    return ScoutProfilePage(
      scoutUserId: widget.userId,
      isViewingOtherUser: widget.isViewingOtherUser,
    );
  }

  Widget _buildClubProfileView() {
    return ClubProfilePage(
      clubUserId: widget.userId,
      isViewingOtherUser: widget.isViewingOtherUser,
    );
  }

  Widget _buildFanProfileView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Fan Profile', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.yellow),
            SizedBox(height: 16),
            Text(
              'Fan Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fan profiles coming soon!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _profileData?['full_name'] ?? 'Fan User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Football Fan',
                    style: TextStyle(color: Colors.yellow, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknownProfileView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Unknown Profile Type',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This profile type is not supported yet.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
