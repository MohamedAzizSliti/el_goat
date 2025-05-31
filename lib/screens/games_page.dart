import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/navbar/bottom_navbar.dart';
import '../widgets/skill_tree/skill_tree_widget.dart';
import '../widgets/badges/badges_widget.dart';
import '../models/skill_progress.dart';
import '../services/skill_progress_service.dart';
import 'badges_page.dart';
import '../widgets/challenge_instructions/challenge_instructions_widget.dart';

enum GameStatusFilter { all, inProgress, completed }

class GamificationDashboard extends StatefulWidget {
  const GamificationDashboard({Key? key}) : super(key: key);

  @override
  State<GamificationDashboard> createState() => _GamificationDashboardState();
}

class _GamificationDashboardState extends State<GamificationDashboard>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final skillService = SkillProgressService();
  late TabController _tabController;
  int _selectedIndex = 0;

  Map<String, dynamic>? xpData;
  List<Map<String, dynamic>> challengesWithStatus = [];
  List<Map<String, dynamic>> gamesWithStatus = [];
  List<Map<String, dynamic>> badges = [];
  List<SkillCategory> skillCategories = [];
  GameStatusFilter _statusFilter = GameStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchGamificationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayerGames(String userId) async {
    try {
      // Check if player has any game entries
      final existingEntries = await supabase
          .from('player_games')
          .select('id')
          .eq('player_id', userId);

      if ((existingEntries as List).isEmpty) {
        print('Initializing player games...');

        // Get all games
        final games = await supabase.from('games').select('id');

        // Get all challenges
        final challenges = await supabase.from('challenges').select('id');

        // Create entries for games
        final gameEntries =
            (games as List)
                .map(
                  (game) => {
                    'player_id': userId,
                    'game_id': game['id'],
                    'status': 'not_started',
                    'current_progress': 0,
                  },
                )
                .toList();

        // Create entries for challenges
        final challengeEntries =
            (challenges as List)
                .map(
                  (challenge) => {
                    'player_id': userId,
                    'challenge_id': challenge['id'],
                    'status': 'not_started',
                    'current_progress': 0,
                  },
                )
                .toList();

        // Insert all entries
        if (gameEntries.isNotEmpty) {
          await supabase.from('player_games').insert(gameEntries);
        }
        if (challengeEntries.isNotEmpty) {
          await supabase.from('player_games').insert(challengeEntries);
        }

        print('Player games initialized successfully');
      }
    } catch (e) {
      print('Error initializing player games: $e');
    }
  }

  Future<void> _fetchGamificationData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Initialize player games if needed
      await _initializePlayerGames(userId);

      // Initialize skill service
      await skillService.initialize();

      // Fetch XP progress
      final xpRes =
          await supabase
              .from('player_xp_progress')
              .select()
              .eq('player_id', userId)
              .maybeSingle();

      // Fetch badges
      final badgeRes = await supabase
          .from('player_badges')
          .select()
          .eq('player_id', userId);

      // Fetch challenges with player_games status
      final challenges = await supabase
          .from('player_games')
          .select('''
            challenge:challenges(
              id,
              title,
              description,
              points_reward,
              target_progress,
              difficulty,
              skill_type
            ),
            status,
            current_progress
          ''')
          .eq('player_id', userId)
          .not('challenge', 'is', null);

      // Fetch games with player_games status
      final games = await supabase
          .from('player_games')
          .select('''
            game:games(
              id,
              title,
              description,
              xp_reward,
              game_type,
              skill_type,
              difficulty
            ),
            status,
            current_progress
          ''')
          .eq('player_id', userId)
          .not('game', 'is', null);

      print('Debug - Fetched challenges: ${challenges.length}');
      print('Debug - Fetched games: ${games.length}');

      // Format challenges
      final List<Map<String, dynamic>> challengesFormatted =
          List<Map<String, dynamic>>.from(
            (challenges as List<dynamic>).map((item) {
              return {
                ...Map<String, dynamic>.from(item['challenge'] as Map),
                'status': item['status'],
                'current_progress': item['current_progress'] ?? 0,
              };
            }).toList(),
          );

      // Format games
      final List<Map<String, dynamic>> gamesFormatted =
          List<Map<String, dynamic>>.from(
            (games as List<dynamic>).map((item) {
              return {
                ...Map<String, dynamic>.from(item['game'] as Map),
                'status': item['status'],
              };
            }).toList(),
          );

      setState(() {
        xpData = xpRes;
        badges = List<Map<String, dynamic>>.from(badgeRes);
        challengesWithStatus = challengesFormatted;
        gamesWithStatus = gamesFormatted;
        skillCategories = skillService.getAllCategories();
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> _ensurePlayerGames(String userId) async {
    try {
      // Check if player has any game entries
      final existingEntries = await supabase
          .from('player_games')
          .select('game_id')
          .eq('player_id', userId);

      if ((existingEntries as List).isEmpty) {
        // Get all games and challenges
        final games = await supabase.from('games').select('id');
        final challenges = await supabase.from('challenges').select('id');

        // Create player_games entries for each game and challenge
        final List<Map<String, dynamic>> entries = [];

        for (var game in games as List) {
          entries.add({
            'player_id': userId,
            'game_id': game['id'],
            'status': 'not_started',
          });
        }

        for (var challenge in challenges as List) {
          entries.add({
            'player_id': userId,
            'game_id': challenge['id'],
            'status': 'not_started',
          });
        }

        if (entries.isNotEmpty) {
          await supabase.from('player_games').upsert(entries);
          print('Debug - Created ${entries.length} player_games entries');
        }
      }
    } catch (e) {
      print("Error ensuring player games: $e");
    }
  }

  Future<void> updateProgress(
    Map<String, dynamic> item,
    bool isChallenge,
  ) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('player_games')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .match({
            'player_id': userId,
            isChallenge ? 'challenge_id' : 'game_id': item['id'],
          });

      _fetchGamificationData();
    } catch (e) {
      print("Error updating progress: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    const routes = ['/', '/stories', '/news_home', '/profile'];
    if (index < routes.length) Navigator.pushNamed(context, routes[index]);
  }

  void _onSkillTap(String skillId) {
    final skill = skillService.getSkill(skillId);
    if (skill == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSkillDetailsSheet(skill),
    );
  }

  Widget _buildSkillDetailsSheet(Skill skill) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  skill.icon ?? Icons.star,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level ${skill.currentLevel}',
                      style: TextStyle(color: Colors.blue[300], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            skill.description,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: skill.progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress: ${(skill.progress * 100).toInt()}%',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          if (skill.attributes.isNotEmpty) ...[
            const Text(
              'Attributes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  skill.attributes.entries.map((entry) {
                    return Chip(
                      backgroundColor: Colors.blue[900],
                      label: Text(
                        '${entry.key}: ${entry.value.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to skill training
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Start Training'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          GameStatusFilter.values.map((filter) {
            String label = switch (filter) {
              GameStatusFilter.all => "All",
              GameStatusFilter.inProgress => "In Progress",
              GameStatusFilter.completed => "Completed",
            };
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(label),
                selected: _statusFilter == filter,
                onSelected: (_) => setState(() => _statusFilter = filter),
              ),
            );
          }).toList(),
    );
  }

  List<Map<String, dynamic>> _filteredItems(bool isChallenges) {
    final items = isChallenges ? challengesWithStatus : gamesWithStatus;
    if (_statusFilter == GameStatusFilter.all) return items;

    final filterStatus =
        _statusFilter == GameStatusFilter.inProgress
            ? 'in_progress'
            : 'completed';
    return items.where((item) => item['status'] == filterStatus).toList();
  }

  void _showItemDetails(Map<String, dynamic> item, bool isChallenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: DefaultTabController(
                          length: isChallenge ? 2 : 1,
                          child: Column(
                            children: [
                              if (isChallenge)
                                TabBar(
                                  tabs: const [
                                    Tab(text: 'Overview'),
                                    Tab(text: 'Instructions'),
                                  ],
                                ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    // Overview Tab
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      item['status'] ==
                                                              'completed'
                                                          ? Colors.green[700]
                                                          : Colors.blue[700],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isChallenge
                                                      ? Icons.emoji_events
                                                      : Icons.games,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['title'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: _getDifficultyColor(
                                                              item['difficulty'],
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            item['difficulty']
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .blue[900],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            item['skill_type']
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            item['description'],
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (isChallenge) ...[
                                            const SizedBox(height: 20),
                                            const Text(
                                              'Progress',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(
                                                milliseconds: 1000,
                                              ),
                                              curve: Curves.easeInOut,
                                              tween: Tween<double>(
                                                begin: 0,
                                                end:
                                                    item['current_progress'] /
                                                    item['target_progress'],
                                              ),
                                              builder:
                                                  (context, value, _) => Column(
                                                    children: [
                                                      Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          CircularProgressIndicator(
                                                            value: value,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[800],
                                                            valueColor: AlwaysStoppedAnimation(
                                                              item['status'] ==
                                                                      'completed'
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .blue[400],
                                                            ),
                                                            strokeWidth: 8,
                                                          ),
                                                          Text(
                                                            '${(value * 100).toInt()}%',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Text(
                                                        '${item['current_progress']} / ${item['target_progress']}',
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            ),
                                          ],
                                          const SizedBox(height: 20),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.amber[900]
                                                  ?.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.amber[700]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isChallenge
                                                      ? Icons.stars
                                                      : Icons.workspace_premium,
                                                  color: Colors.amber,
                                                  size: 30,
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Reward',
                                                      style: TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      isChallenge
                                                          ? '${item['points_reward']} Points'
                                                          : '${item['xp_reward']} XP',
                                                      style: const TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 30),
                                          if (item['status'] != 'completed')
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  if (isChallenge) {
                                                    // Simulate progress update
                                                    final currentProgress =
                                                        item['current_progress'] ??
                                                        0;
                                                    final newProgress =
                                                        currentProgress +
                                                        (item['target_progress'] *
                                                                0.2)
                                                            .round();

                                                    await supabase
                                                        .from('player_games')
                                                        .update({
                                                          'current_progress':
                                                              newProgress,
                                                          'status':
                                                              newProgress >=
                                                                      item['target_progress']
                                                                  ? 'completed'
                                                                  : 'in_progress',
                                                        })
                                                        .match({
                                                          'player_id':
                                                              supabase
                                                                  .auth
                                                                  .currentUser!
                                                                  .id,
                                                          'challenge_id':
                                                              item['id'],
                                                        });
                                                  } else {
                                                    await updateProgress(
                                                      item,
                                                      isChallenge,
                                                    );
                                                  }

                                                  Navigator.pop(context);
                                                  _fetchGamificationData();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[700],
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  item['status'] ==
                                                          'in_progress'
                                                      ? 'Continue'
                                                      : 'Start',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Instructions Tab (only for challenges)
                                    if (isChallenge)
                                      ChallengeInstructionsWidget(
                                        challengeId: item['id'],
                                        onStart: () async {
                                          await supabase
                                              .from('player_games')
                                              .update({'status': 'in_progress'})
                                              .match({
                                                'player_id':
                                                    supabase
                                                        .auth
                                                        .currentUser!
                                                        .id,
                                                'challenge_id': item['id'],
                                              });
                                          _fetchGamificationData();
                                        },
                                        onComplete: () async {
                                          await supabase
                                              .from('player_games')
                                              .update({
                                                'status': 'completed',
                                                'completed_at':
                                                    DateTime.now()
                                                        .toIso8601String(),
                                              })
                                              .match({
                                                'player_id':
                                                    supabase
                                                        .auth
                                                        .currentUser!
                                                        .id,
                                                'challenge_id': item['id'],
                                              });
                                          Navigator.pop(context);
                                          _fetchGamificationData();
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildItemsList(bool isChallenges) {
    final items = isChallenges ? challengesWithStatus : gamesWithStatus;
    final filtered = _filteredItems(isChallenges);

    if (filtered.isEmpty) {
      return const Center(
        child: Text("No items found", style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final status = item['status'];
        final progress =
            isChallenges
                ? (item['current_progress'] / item['target_progress'])
                : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.grey[850],
          child: InkWell(
            onTap: () => _showItemDetails(item, isChallenges),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              status == 'completed'
                                  ? Colors.green
                                  : Colors.blue[700],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isChallenges ? Icons.emoji_events : Icons.games,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['description'],
                              style: const TextStyle(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation(
                        status == 'completed' ? Colors.green : Colors.blue[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Progress: ${item['current_progress']}/${item['target_progress']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = supabase.auth.currentUser != null;

    if (!isLoggedIn) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Please log in to view your dashboard",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("El Goat: Player Dashboard"),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sports_score), text: 'Challenges'),
            Tab(icon: Icon(Icons.games), text: 'Games'),
            Tab(icon: Icon(Icons.account_tree), text: 'Skills'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildXPCard(),
          const SizedBox(height: 16),
          _buildBadgesCard(),
          const SizedBox(height: 16),
          if (_tabController.index != 2) _buildFilterChips(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList(true), // Challenges
                _buildItemsList(false), // Games
                SkillTreeWidget(
                  categories: skillCategories,
                  onSkillTap: _onSkillTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPCard() {
    final level = xpData?['level'] ?? 1;
    final currentXp = xpData?['current_xp'] ?? 0;
    final nextXp = xpData?['next_level_xp'] ?? 100;
    final progress = currentXp / nextXp;
    final overallSkillProgress = skillService.getOverallProgress();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Level $level - ${_getLevelTitle(level)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Overall: ${(overallSkillProgress * 100).toInt()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 10),
            Text(
              "XP: $currentXp / $nextXp",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesCard() {
    return BadgesWidget(
      badges: badges,
      onViewAll: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BadgesPage(badges: badges)),
        );
      },
    );
  }

  String _getLevelTitle(int level) {
    if (level < 5) return "Beginner";
    if (level < 10) return "Rising Star";
    if (level < 20) return "Elite Prospect";
    return "GOAT Mode";
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.yellow;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
