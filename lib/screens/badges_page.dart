import 'package:flutter/material.dart';
import '../widgets/badges/badges_widget.dart';

class BadgesPage extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const BadgesPage({
    Key? key,
    required this.badges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Your Badges'),
        backgroundColor: Colors.black,
      ),
      body: BadgesWidget(
        badges: badges,
        showAll: true,
      ),
    );
  }
} 