import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../models/footballer_profile_model.dart';
import '../services/ai_exercise_service.dart';
import '../services/exercise_database_service.dart';
import '../widgets/navbar/bottom_navbar.dart';
import 'exercise_detail_screen.dart';

class AITrainingScreen extends StatefulWidget {
  final FootballerProfileModel player;

  const AITrainingScreen({Key? key, required this.player}) : super(key: key);

  @override
  State<AITrainingScreen> createState() => _AITrainingScreenState();
}

class _AITrainingScreenState extends State<AITrainingScreen>
    with TickerProviderStateMixin {
  List<ExerciseModel> _exercises = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  int _selectedIndex = 1; // Training tab
  late TabController _tabController;
  late AnimationController _headerAnimController;
  late Animation<double> _headerScale;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _headerScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.elasticOut),
    );
    _headerAnimController.forward();
    _loadExercises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await ExerciseDatabaseService.getUserExercises(
        widget.player.userId,
      );
      setState(() => _exercises = exercises);
    } catch (e) {
      _showErrorSnackBar('Failed to load exercises: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateExercises() async {
    setState(() => _isGenerating = true);
    try {
      // Show focus areas dialog
      final focusAreas = await _showFocusAreasDialog();
      if (focusAreas == null || focusAreas.isEmpty) return;

      // Generate exercises using AI
      final newExercises = await AIExerciseService.generateExercises(
        player: widget.player,
        focusAreas: focusAreas,
        count: 3,
      );

      // Save to database
      final savedExercises = await ExerciseDatabaseService.saveExercises(
        newExercises,
      );

      setState(() {
        _exercises.insertAll(0, savedExercises);
      });

      _showSuccessSnackBar('${savedExercises.length} new exercises generated!');
    } catch (e) {
      _showErrorSnackBar('Failed to generate exercises: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<List<String>?> _showFocusAreasDialog() async {
    final availableAreas = [
      'Ball Control',
      'Passing',
      'Shooting',
      'Dribbling',
      'Defending',
      'Crossing',
      'Heading',
      'Speed',
      'Agility',
      'Stamina',
      'Positioning',
      'Decision Making',
      'Communication',
      'Mental Strength',
    ];

    final selectedAreas = <String>[];

    return showDialog<List<String>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF393E46),
                  title: const Text(
                    'Choose Focus Areas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select areas you want to improve (max 3):',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              availableAreas.map((area) {
                                final isSelected = selectedAreas.contains(area);
                                return FilterChip(
                                  label: Text(area),
                                  selected: isSelected,
                                  onSelected:
                                      selectedAreas.length < 3 || isSelected
                                          ? (selected) {
                                            setDialogState(() {
                                              if (selected) {
                                                selectedAreas.add(area);
                                              } else {
                                                selectedAreas.remove(area);
                                              }
                                            });
                                          }
                                          : null,
                                  selectedColor: Colors.yellow[700],
                                  backgroundColor: Colors.grey[800],
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.black
                                            : Colors.white,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedAreas.isNotEmpty
                              ? () => Navigator.pop(context, selectedAreas)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                      ),
                      child: const Text(
                        'Generate',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [Colors.yellow[400]!, Colors.orange[400]!],
              ).createShader(bounds),
          child: const Text(
            'AI Training',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.blue[400]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green[400]!.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon:
                  _isGenerating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Icon(Icons.auto_awesome, color: Colors.white),
              onPressed: _isGenerating ? null : _generateExercises,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f0f23),
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Beautiful Header Section
            Container(
              height: 200,
              child: Stack(
                children: [
                  // Background with gradient
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green[600]!.withValues(alpha: 0.8),
                          Colors.blue[600]!.withValues(alpha: 0.8),
                          Colors.purple[500]!.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // Header content
                  Positioned(
                    top: 90,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _headerScale,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.yellow[400]!,
                                  Colors.orange[400]!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow[400]!.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              size: 40,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [Colors.white, Colors.yellow[200]!],
                              ).createShader(bounds),
                          child: const Text(
                            'AI Personal Trainer',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.yellow[600]!, Colors.orange[500]!],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(child: Text('All', textAlign: TextAlign.center)),
                  Tab(child: Text('Pending', textAlign: TextAlign.center)),
                  Tab(child: Text('Doing', textAlign: TextAlign.center)),
                  Tab(child: Text('Done', textAlign: TextAlign.center)),
                ],
              ),
            ),

            // Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildExerciseList(_exercises),
                          _buildExerciseList(
                            _exercises.where((e) => e.isPending).toList(),
                          ),
                          _buildExerciseList(
                            _exercises.where((e) => e.isInProgress).toList(),
                          ),
                          _buildExerciseList(
                            _exercises.where((e) => e.isCompleted).toList(),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(List<ExerciseModel> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the AI button to generate personalized exercises',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(ExerciseModel exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            ).then((_) => _loadExercises());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTypeIcon(exercise.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(exercise.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(
                      Icons.schedule,
                      '${exercise.estimatedDuration} min',
                    ),
                    _buildInfoChip(
                      Icons.trending_up,
                      exercise.difficultyDisplayName,
                    ),
                    if (exercise.score != null)
                      _buildInfoChip(Icons.star, '${exercise.score}/100'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ExerciseType type) {
    IconData icon;
    List<Color> colors;

    switch (type) {
      case ExerciseType.technical:
        icon = Icons.sports_soccer;
        colors = [Colors.blue[400]!, Colors.cyan[400]!];
        break;
      case ExerciseType.physical:
        icon = Icons.fitness_center;
        colors = [Colors.red[400]!, Colors.orange[400]!];
        break;
      case ExerciseType.tactical:
        icon = Icons.psychology;
        colors = [Colors.purple[400]!, Colors.pink[400]!];
        break;
      case ExerciseType.mental:
        icon = Icons.self_improvement;
        colors = [Colors.green[400]!, Colors.teal[400]!];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildStatusChip(ExerciseStatus status) {
    Color color;
    String text;

    switch (status) {
      case ExerciseStatus.pending:
        color = Colors.orange[600]!;
        text = 'Pending';
        break;
      case ExerciseStatus.doing:
        color = Colors.blue[600]!;
        text = 'In Progress';
        break;
      case ExerciseStatus.done:
        color = Colors.green[600]!;
        text = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
