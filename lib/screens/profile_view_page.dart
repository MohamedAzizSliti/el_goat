// lib/screens/profile_view_page.dart

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/footballer_profile.dart';
import '../models/scout_profile.dart';
import '../models/club_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class ProfileViewPage extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const ProfileViewPage({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  UserProfile? userProfile;
  dynamic roleProfile;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => isLoading = true);

      // Get user role first
      final role = await ProfileService.getUserRole(widget.userId);
      if (role == null) {
        setState(() => error = 'User role not found');
        return;
      }

      // Load role-specific profile
      switch (role.toLowerCase()) {
        case 'footballer':
          roleProfile = await ProfileService.getFootballerProfile(widget.userId);
          break;
        case 'scout':
          roleProfile = await ProfileService.getScoutProfile(widget.userId);
          break;
        case 'club':
          roleProfile = await ProfileService.getClubProfile(widget.userId);
          break;
        default:
          setState(() => error = 'Unknown user role: $role');
          return;
      }

      if (roleProfile == null) {
        setState(() => error = 'Profile not found');
        return;
      }

      setState(() {
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load profile: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOwnProfile ? 'My Profile' : 'Profile'),
        actions: widget.isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigate to edit profile
                  },
                ),
              ]
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (roleProfile is FootballerProfile) {
      return _buildFootballerProfile(roleProfile as FootballerProfile);
    } else if (roleProfile is ScoutProfile) {
      return _buildScoutProfile(roleProfile as ScoutProfile);
    } else if (roleProfile is ClubProfile) {
      return _buildClubProfile(roleProfile as ClubProfile);
    }
    return const Center(child: Text('Unknown profile type'));
  }

  Widget _buildFootballerProfile(FootballerProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileHeader(
            name: profile.fullName,
            subtitle: '${profile.positionDisplay} • ${profile.age} years old',
            avatarUrl: profile.avatarUrl,
            isVerified: profile.isVerified,
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Personal Information', [
            _buildInfoRow('Position', profile.positionDisplay),
            _buildInfoRow('Age', '${profile.age} years'),
            _buildInfoRow('Height', profile.heightCm != null ? '${profile.heightCm} cm' : 'Not specified'),
            _buildInfoRow('Weight', profile.weightKg != null ? '${profile.weightKg} kg' : 'Not specified'),
            _buildInfoRow('Preferred Foot', profile.preferredFoot ?? 'Not specified'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Career Information', [
            _buildInfoRow('Experience Level', profile.experienceDisplay),
            _buildInfoRow('Current Club', profile.displayClub),
            _buildInfoRow('XP Points', '${profile.xpPoints}'),
          ]),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('About', [
              Text(
                profile.bio!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildScoutProfile(ScoutProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileHeader(
            name: profile.fullName,
            subtitle: '${profile.levelDisplay} Scout • ${profile.experienceDisplay}',
            avatarUrl: profile.avatarUrl,
            isVerified: profile.isVerified,
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Professional Information', [
            _buildInfoRow('Scouting Level', profile.levelDisplay),
            _buildInfoRow('Experience', profile.experienceDisplay),
            _buildInfoRow('Location', profile.locationDisplay),
            if (profile.organization != null)
              _buildInfoRow('Organization', profile.organization!),
          ]),
          if (profile.specializations.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Specializations', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.specializations
                    .map((spec) => Chip(
                          label: Text(spec),
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        ))
                    .toList(),
              ),
            ]),
          ],
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('About', [
              Text(
                profile.bio!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildClubProfile(ClubProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileHeader(
            name: profile.clubName,
            subtitle: '${profile.leagueDisplay} • ${profile.foundedDisplay}',
            avatarUrl: profile.logoUrl,
            isVerified: profile.isVerified,
          ),
          const SizedBox(height: 24),
          _buildInfoCard('Club Information', [
            _buildInfoRow('League', profile.leagueDisplay),
            _buildInfoRow('Location', profile.location ?? 'Not specified'),
            _buildInfoRow('Founded', profile.foundedDisplay),
            _buildInfoRow('Stadium', profile.stadiumDisplay),
            if (profile.website != null)
              _buildInfoRow('Website', profile.website!),
          ]),
          if (profile.achievements.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Achievements', [
              ...profile.achievements.map((achievement) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: AppTheme.accentColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(achievement)),
                    ],
                  ),
                ),
              ),
            ]),
          ],
          if (profile.description != null && profile.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('About', [
              Text(
                profile.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String subtitle,
    String? avatarUrl,
    bool isVerified = false,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    )
                  : null,
            ),
            if (isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondaryDark,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
