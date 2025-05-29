import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> badges;
  final bool showAll;
  final VoidCallback? onViewAll;

  const BadgesWidget({
    Key? key,
    required this.badges,
    this.showAll = false,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            const Text(
              'No badges earned yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete challenges and improve skills to earn badges!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (showAll) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Your Badges',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                return _buildBadgeCard(badges[index], context);
              },
            ),
          ),
        ] else ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: badges.length + 1,  // +1 for the "View All" card
              itemBuilder: (context, index) {
                if (index == badges.length) {
                  return _buildViewAllCard();
                }
                return _buildBadgeCard(badges[index], context);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, BuildContext context) {
    final bool isLocked = !(badge['is_unlocked'] ?? false);
    final double progress = badge['progress'] ?? 0.0;
    final Color backgroundColor = Color(badge['background_color'] ?? 0xFF1B4D3E);
    final Color iconColor = Color(badge['icon_color'] ?? 0xFFFFD700);

    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Progress indicator
            CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[850],
              valueColor: AlwaysStoppedAnimation(
                isLocked ? Colors.grey : iconColor,
              ),
              strokeWidth: 4,
            ),
            // Badge circle
            Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked ? Colors.grey[850] : backgroundColor,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Badge icon
                    _getBadgeIcon(badge['badge_type'], 
                      color: isLocked ? Colors.grey : iconColor,
                      size: 32,
                    ),
                    if (isLocked)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllCard() {
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue[900],
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'View All',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBadgeIcon(String badgeType, {Color? color, double? size}) {
    IconData iconData;
    switch (badgeType.toLowerCase()) {
      case 'topscorer':
        iconData = Icons.sports_soccer;
        break;
      case 'scoutapproved':
        iconData = Icons.verified;
        break;
      case 'fanfavorite':
        iconData = Icons.favorite;
        break;
      case 'skillmaster':
        iconData = Icons.psychology;
        break;
      case 'challengechampion':
        iconData = Icons.emoji_events;
        break;
      case 'risingtalent':
        iconData = Icons.trending_up;
        break;
      case 'teamplayer':
        iconData = Icons.group;
        break;
      case 'perfectattendance':
        iconData = Icons.calendar_today;
        break;
      case 'trainingexcellence':
        iconData = Icons.fitness_center;
        break;
      case 'matchmvp':
        iconData = Icons.star;
        break;
      default:
        iconData = Icons.emoji_events;
    }
    return Icon(iconData, color: color, size: size);
  }

  void _showBadgeDetails(BuildContext context, Map<String, dynamic> badge) {
    final bool isLocked = !(badge['is_unlocked'] ?? false);
    final double progress = badge['progress'] ?? 0.0;
    final Color backgroundColor = Color(badge['background_color'] ?? 0xFF1B4D3E);
    final Color iconColor = Color(badge['icon_color'] ?? 0xFFFFD700);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[850],
                    valueColor: AlwaysStoppedAnimation(
                      isLocked ? Colors.grey : iconColor,
                    ),
                    strokeWidth: 8,
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked ? Colors.grey[850] : backgroundColor,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _getBadgeIcon(
                        badge['badge_type'],
                        color: isLocked ? Colors.grey : iconColor,
                        size: 48,
                      ),
                      if (isLocked)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white54,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              badge['title'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge['description'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (isLocked && badge['requirements'] != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Requirements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...List.from(badge['requirements']).map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: req['completed'] ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        req['description'],
                        style: TextStyle(
                          color: req['completed'] ? Colors.white : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (!isLocked) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked on ${badge['unlocked_at'] ?? 'Unknown Date'}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 