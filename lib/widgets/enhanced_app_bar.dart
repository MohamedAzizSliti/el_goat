import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/navigation_service.dart';

class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final bool showNotifications;
  final bool showProfile;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const EnhancedAppBar({
    Key? key,
    required this.title,
    this.showSearch = true,
    this.showNotifications = true,
    this.showProfile = true,
    this.onSearchTap,
    this.onNotificationTap,
    this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearchTap ?? () => NavigationService.navigateToSearch(context),
          ),
        if (showNotifications)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: onNotificationTap ?? () => NavigationService.navigateToNotifications(context),
              ),
              // Notification badge
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        if (showProfile)
          FutureBuilder<String?>(
            future: _getUserRole(),
            builder: (context, snapshot) {
              return GestureDetector(
                onTap: onProfileTap ?? () => NavigationService.handleBottomNavigation(context, 2),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.yellow,
                    child: _buildProfileIcon(snapshot.data),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildProfileIcon(String? role) {
    IconData icon;
    switch (role) {
      case 'footballer':
        icon = Icons.sports_soccer;
        break;
      case 'scout':
        icon = Icons.search;
        break;
      case 'club':
        icon = Icons.business;
        break;
      case 'fan':
        icon = Icons.favorite;
        break;
      default:
        icon = Icons.person;
    }

    return Icon(
      icon,
      color: Colors.black,
      size: 20,
    );
  }

  Future<String?> _getUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    
    // Check each profile table to determine role
    final tables = [
      {'table': 'footballer_profiles', 'role': 'footballer'},
      {'table': 'scout_profiles', 'role': 'scout'},
      {'table': 'club_profiles', 'role': 'club'},
      {'table': 'fan_profiles', 'role': 'fan'},
    ];

    for (final tableInfo in tables) {
      try {
        final response = await Supabase.instance.client
            .from(tableInfo['table']!)
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          return tableInfo['role'];
        }
      } catch (e) {
        // Continue to next table
      }
    }

    return null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class FloatingSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String hintText;

  const FloatingSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText = 'Search players, scouts, clubs...',
  }) : super(key: key);

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final _searchController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.arrow_back : Icons.search,
              color: Colors.yellow,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (!_isExpanded) {
                  _searchController.clear();
                }
              });
            },
          ),
          if (_isExpanded)
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  widget.onSearch(value);
                  setState(() => _isExpanded = false);
                },
              ),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isExpanded = true),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.hintText,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          if (_isExpanded && _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color ?? Colors.yellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color ?? Colors.yellow.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.yellow,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.yellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
