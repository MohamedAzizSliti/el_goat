import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Padding to make it float
      child: Material(
        elevation: 8, // Elevation for shadow effect
        borderRadius: BorderRadius.circular(30), // Rounded corners
        color: const Color(0xFF000000), // True black background
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            onItemTapped(index);
            if (index == 0) {
              Navigator.pushNamed(context, '/'); // Navigate to Home
            } else if (index == 1) {
              Navigator.pushNamed(context, '/stories'); // Navigate to Stories
            } else if (index == 2) {
              Navigator.pushNamed(
                  context, '/news_reels'); // Navigate to News Reels
            } else if (index == 3) {
              Navigator.pushNamed(context, '/profile'); // Navigate to Profile
            }
          },
          backgroundColor:
              Colors.transparent, // Transparent to show Material color
          selectedItemColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFFF0000) // Red for light theme
              : const Color(0xFFFFD700), // Gold for dark theme
          unselectedItemColor: Colors.white, // White for inactive icons
          showSelectedLabels: true, // Show labels for selected icons
          showUnselectedLabels: true, // Show labels for unselected icons
          type: BottomNavigationBarType.fixed, // Fixed navigation bar
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              label: 'Play',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
