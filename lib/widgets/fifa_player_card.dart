import 'package:flutter/material.dart';

class FifaPlayerCard extends StatelessWidget {
  final String playerName;
  final int overallRating;
  final String position;
  final String playerImagePath;
  final String clubLogoPath;
  final Map<String, int> stats;

  const FifaPlayerCard({
    Key? key,
    required this.playerName,
    required this.overallRating,
    required this.position,
    required this.playerImagePath,
    required this.clubLogoPath,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = constraints.maxWidth;

        return Container(
          width: cardWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/gold_foil_texture.png'), // Gold foil texture
              fit: BoxFit.cover,
              opacity: 0.9, // Slight transparency for elegant look
            ),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFD700), // Deep Gold
                Color(0xFFFFC107), // Light Gold
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: cardWidth * 0.15,
                backgroundImage: AssetImage(playerImagePath),
                backgroundColor: Colors.grey[800],
              ),
              const SizedBox(height: 10),
              Text(
                "$playerName – $overallRating OVR",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    position,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    clubLogoPath,
                    width: cardWidth * 0.1,
                    height: cardWidth * 0.1,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PAC: ${stats['PAC'] ?? 0}",
                        style: _statStyle(),
                      ),
                      Text(
                        "SHO: ${stats['SHO'] ?? 0}",
                        style: _statStyle(),
                      ),
                      Text(
                        "PAS: ${stats['PAS'] ?? 0}",
                        style: _statStyle(),
                      ),
                    ],
                  ),
                  // Right Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DRI: ${stats['DRI'] ?? 0}",
                        style: _statStyle(),
                      ),
                      Text(
                        "DEF: ${stats['DEF'] ?? 0}",
                        style: _statStyle(),
                      ),
                      Text(
                        "PHY: ${stats['PHY'] ?? 0}",
                        style: _statStyle(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static TextStyle _statStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
}
