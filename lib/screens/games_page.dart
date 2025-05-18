import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/navbar/bottom_navbar.dart'; // Import the BottomNavbar widget

class GamificationDashboard extends StatefulWidget {
  const GamificationDashboard({Key? key}) : super(key: key);

  @override
  _GamificationDashboardState createState() => _GamificationDashboardState();
}

class _GamificationDashboardState extends State<GamificationDashboard>
    with SingleTickerProviderStateMixin {
  double xpProgress = 0.7;
  String notification = "Welcome back, player! Keep up the streak!";
  int _selectedIndex = 0; // Default selected index for the bottom navbar

  @override
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/'); // Navigate to Home
        break;
      case 1:
        Navigator.pushNamed(context, '/stories'); // Navigate to Stories
        break;
      case 2:
        Navigator.pushNamed(context, '/news_home'); // Navigate to News
        break;
      case 3:
        Navigator.pushNamed(context, '/profile'); // Navigate to Profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("El Goat: Player Dashboard"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationCard(),
            const SizedBox(height: 16),
            _buildXPCard(),
            const SizedBox(height: 16),
            _buildStreakAndRank(),
            const SizedBox(height: 16),
            Expanded(child: _buildTabs()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      elevation: 2,
      color: Colors.amber[100],
      child: ListTile(
        leading: const Icon(Icons.notifications_active),
        title: Text(notification),
      ),
    );
  }

  Widget _buildXPCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Level 7 - Rising Star",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: xpProgress),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[300],
                color: Colors.green,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            const Text("XP: 1,400 / 2,000")
          ],
        ),
      ),
    );
  }

  Widget _buildStreakAndRank() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: ListTile(
              leading:
                  const Icon(Icons.local_fire_department, color: Colors.red),
              title: const Text("Daily Streak"),
              subtitle: const Text("🔥 5 Days"),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.leaderboard, color: Colors.blue),
              title: const Text("Weekly Rank"),
              subtitle: const Text("#23 Global"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
              Tab(icon: Icon(Icons.flag), text: 'Missions'),
              Tab(icon: Icon(Icons.star), text: 'Skills'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList([
                  "🏅 First Goal Scored",
                  "📸 5 Training Sessions Logged",
                  "🗣️ Contacted by a Scout",
                ]),
                _buildList([
                  "📅 Upload 3 Videos This Week",
                  "💬 Interact with 2 Players",
                  "🏃 Log Sprint Drill",
                ]),
                _buildList([
                  "⚽ Dribbling: Silver Level",
                  "🎯 Shooting: Bronze Level",
                  "🛡️ Defense: Beginner",
                ]),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildList(List<String> items) {
    return ListView(
      children: items
          .map((e) => Card(
                child: ListTile(
                  title: Text(e),
                ),
              ))
          .toList(),
    );
  }
}
