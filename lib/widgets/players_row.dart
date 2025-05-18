import 'package:flutter/material.dart';

class PlayersRow extends StatelessWidget {
  const PlayersRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> players = [
      {'name': 'Player 1', 'image': 'assets/images/1.jpg', 'route': '/profile'},
      {'name': 'Player 2', 'image': 'assets/images/2.jpg', 'route': '/player2'},
      {'name': 'Player 3', 'image': 'assets/images/3.jpg', 'route': '/player3'},
      {
        'name': 'Player 4',
        'image': 'assets/images/5.jpeg',
        'route': '/player4'
      },
      {
        'name': 'Player 5',
        'image': 'assets/images/6.jpeg',
        'route': '/player5'
      },
      {
        'name': 'Player 6',
        'image': 'assets/images/7.jpeg',
        'route': '/player6'
      },
      {
        'name': 'Player 7',
        'image': 'assets/images/8.jpeg',
        'route': '/player7'
      },
      {
        'name': 'Player 8',
        'image': 'assets/images/9.jpeg',
        'route': '/player8'
      },
      {
        'name': 'Player 9',
        'image': 'assets/images/10.jpeg',
        'route': '/player9'
      },
      {
        'name': 'Player 10',
        'image': 'assets/images/11.jpeg',
        'route': '/player10'
      },
      {
        'name': 'Player 11',
        'image': 'assets/images/12.jpeg',
        'route': '/player11'
      },
      {
        'name': 'Player 12',
        'image': 'assets/images/13.jpeg',
        'route': '/player12'
      },
      {
        'name': 'Player 13',
        'image': 'assets/images/14.jpeg',
        'route': '/player13'
      },
      {
        'name': 'Player 14',
        'image': 'assets/images/15.jpeg',
        'route': '/player14'
      },
    ];

    return SizedBox(
      height: 100, // Fixed height for the swipeable row
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, player['route']!);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(player['image']!),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    player['name']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
