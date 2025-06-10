import 'package:el_goat/screens/profile_page.dart';
import 'package:el_goat/screens/scout_profil_page.dart';
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
import 'screens/root_page.dart';
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
import 'screens/search_page.dart';
import 'screens/countries_list_page.dart';
import 'screens/conversations_screen.dart';
import 'services/message_service.dart';
import 'theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize messaging service
  await MessageService().initialize();

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
        '/search': (context) => const SearchPage(),
        '/countries': (context) => const CountriesListPage(),
        '/news_home': (ctx) => NewsHomePage(toggleTheme: () {}),
        '/stories': (ctx) => const StoriesPage(),
        '/news_reels': (ctx) => const NewsReelsPage(),
        '/registration': (ctx) => const RegistrationPage(),
        '/login': (ctx) => const LoginPage(),
        '/accueil': (ctx) => const AcceuilPage(),
        '/footballer_profile': (ctx) => FootballerProfilePage(),
        '/scout_profile':
            (ctx) => ScoutProfilePage(
              scoutUserId: Supabase.instance.client.auth.currentUser!.id,
            ),
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
              name: '', // No name available for direct route
              email: Supabase.instance.client.auth.currentUser?.email ?? '',
            ),
        '/scoutsignup':
            (ctx) => ScoutSignUpPage(
              userId: Supabase.instance.client.auth.currentUser!.id,
              name: '', // No name available for direct route
              email: Supabase.instance.client.auth.currentUser?.email ?? '',
            ),
        '/footballersignup':
            (ctx) => FootballerSignUpPage(
              userId: Supabase.instance.client.auth.currentUser!.id,
              name: '', // No name available for direct route
              email: Supabase.instance.client.auth.currentUser?.email ?? '',
            ),
        '/favorites': (ctx) => const FavoritesPage(),
        '/notifications': (ctx) => const NotificationsPage(),
        '/ratings': (ctx) => const RatingsPage(),
        '/login_required': (ctx) => const LoginRequiredPage(),
        '/conversations': (ctx) => const ConversationsScreen(),
      },
    );
  }
}
