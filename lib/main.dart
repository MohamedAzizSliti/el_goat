import 'package:el_goat/screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/main_navigation.dart';
import 'screens/home_page.dart';
import 'screens/news_home_page.dart';
import 'screens/stories_page.dart';
import 'screens/news_reels_page.dart';
import 'screens/registration_page.dart';
import 'screens/login.dart';
import 'screens/accueil_page.dart';
import 'screens/scout_profile_page.dart';
import 'screens/club_profil_page.dart';
import 'screens/chat_page.dart';
import 'screens/games_page.dart';
import 'screens/clubsigup_page.dart';
import 'screens/scoutsignup_page.dart';
import 'screens/footballersignup_page.dart';
import 'screens/favorites_page.dart';
import 'screens/notifications_page.dart';
import 'screens/ratings_page.dart';
import 'screens/login_required_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nwmfqbvxdhcgawxfvhsg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53bWZxYnZ4ZGhjZ2F3eGZ2aHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2NjAyMDcsImV4cCI6MjA2MTIzNjIwN30.U0hCS3Q9oWaAGKBhmFHvAGU_ZeLMR6Wh0nvTFBBtoMQ',
  );

  AppLifecycleReactor().start();

  runApp(const MyApp());
}

class AppLifecycleReactor with WidgetsBindingObserver {
  void start() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateLastSeen();
    }
  }

  Future<void> _updateLastSeen() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    for (final table in [
      'footballer_profiles',
      'scout_profiles',
      'club_profiles',
    ]) {
      await Supabase.instance.client
          .from(table)
          .update({'last_seen': DateTime.now().toIso8601String()})
          .eq('user_id', userId);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Goat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigation(),
        '/home': (context) => const HomePage(),
        '/news_home': (ctx) => NewsHomePage(toggleTheme: () {}),
        '/stories': (ctx) => const StoriesPage(),
        '/news_reels': (ctx) => const NewsReelsPage(),
        '/registration': (ctx) => const RegistrationPage(),
        '/login': (ctx) => const LoginPage(),
        '/accueil': (ctx) => const AcceuilPage(),
        '/footballer_profile': (ctx) => FootballerProfilePage(),
        '/scout_profile': (ctx) => const ScoutProfilePage(),
        '/club_profile':
            (ctx) => ClubProfilePage(
              clubUserId: Supabase.instance.client.auth.currentUser!.id,
            ),
        '/chat':
            (ctx) => const ChatScreen(
              otherUserId: '',
              otherUserName: '',
              otherUserImage: '',
            ),
        '/games': (ctx) => const GamificationDashboard(),
        '/clubsignup':
            (ctx) => ClubSignUpPage(
              userId: Supabase.instance.client.auth.currentUser!.id,
            ),
        '/scoutsignup':
            (ctx) => ScoutSignUpPage(
              userId: Supabase.instance.client.auth.currentUser!.id,
            ),
        '/footballersignup':
            (ctx) => FootballerSignUpPage(
              userId: Supabase.instance.client.auth.currentUser!.id,
            ),
        '/favorites': (ctx) => const FavoritesPage(),
        '/notifications': (ctx) => const NotificationsPage(),
        '/ratings': (ctx) => const RatingsPage(),
        '/login_required': (ctx) => const LoginRequiredPage(),
      },
    );
  }
}
