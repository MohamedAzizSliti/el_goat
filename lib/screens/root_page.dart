import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'accueil_page.dart';
import 'home_page.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const HomePage(); // Show home/login/landing page if not signed in
    } else {
      return const AcceuilPage(); // Show main app with bottom bar if signed in
    }
  }
}
