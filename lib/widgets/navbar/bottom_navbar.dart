import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/message_service.dart';

class BottomNavbar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  final MessageService _messageService = MessageService();
  int _unreadCount = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _setupRealTimeUnreadCount();
    _loadUserRole();
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

  Future<void> _loadUnreadCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final count = await _messageService.getUnreadMessagesCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _setupRealTimeUnreadCount() {
    // Update unread count every few seconds
    Stream.periodic(const Duration(seconds: 3)).listen((_) {
      if (mounted) {
        _loadUnreadCount();
      }
    });
  }

  bool _shouldShowGamesTab() {
    // Only show games tab for footballers
    return _userRole == 'footballer';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.article_outlined,
            activeIcon: Icons.article,
            label: 'News',
            index: 1,
          ),
          // Games tab - only show for footballers
          if (_shouldShowGamesTab())
            _buildNavItem(
              context,
              icon: Icons.sports_soccer_outlined,
              activeIcon: Icons.sports_soccer,
              label: 'Games',
              index: 2,
            ),
          _buildNavItem(
            context,
            icon: Icons.message_outlined,
            activeIcon: Icons.message,
            label: 'Messages',
            index: _shouldShowGamesTab() ? 3 : 2,
            showBadge: true,
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            index: _shouldShowGamesTab() ? 4 : 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    bool showBadge = false,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Colors.yellow.withValues(alpha: 0.2)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border:
                isSelected
                    ? Border.all(
                      color: Colors.yellow.withValues(alpha: 0.5),
                      width: 1,
                    )
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey(
                        'navbar_icon_${index}_${isSelected}_${icon.codePoint}',
                      ),
                      size: 24,
                      color: isSelected ? Colors.yellow : Colors.grey[600],
                    ),
                  ),
                  if (showBadge &&
                      index == 2 &&
                      _unreadCount > 0) // Messages tab
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.yellow : Colors.grey[600],
                  fontSize: isSelected ? 12 : 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
