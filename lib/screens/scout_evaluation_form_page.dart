import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scout_evaluation.dart';
import '../models/footballer_profile.dart';
import '../services/scout_evaluation_service.dart';
import '../widgets/rating_slider.dart';

class ScoutEvaluationFormPage extends StatefulWidget {
  final FootballerProfile player;
  final ScoutEvaluation? existingEvaluation;

  const ScoutEvaluationFormPage({
    Key? key,
    required this.player,
    this.existingEvaluation,
  }) : super(key: key);

  @override
  State<ScoutEvaluationFormPage> createState() =>
      _ScoutEvaluationFormPageState();
}

class _ScoutEvaluationFormPageState extends State<ScoutEvaluationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _evaluationService = ScoutEvaluationService();
  final _supabase = Supabase.instance.client;

  // Form controllers
  final _matchContextController = TextEditingController();
  final _strengthsController = TextEditingController();
  final _areasForImprovementController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  // Form values
  DateTime _evaluationDate = DateTime.now();
  String _playerPosition = '';
  RecommendationType _recommendation = RecommendationType.consider;

  // Technical Skills (1-10)
  int _ballControl = 5;
  int _passingAccuracy = 5;
  int _shootingAbility = 5;
  int _dribblingSkills = 5;
  int _crossingAbility = 5;
  int _headingAbility = 5;

  // Physical Attributes (1-10)
  int _speed = 5;
  int _stamina = 5;
  int _strength = 5;
  int _agility = 5;
  int _jumpingAbility = 5;

  // Mental Attributes (1-10)
  int _decisionMaking = 5;
  int _positioning = 5;
  int _communication = 5;
  int _leadership = 5;
  int _workRate = 5;
  int _attitude = 5;

  // Overall Assessment
  int _overallRating = 5;
  int _potentialRating = 5;

  bool _isLoading = false;

  final List<String> _positions = [
    'Goalkeeper',
    'Centre-Back',
    'Left-Back',
    'Right-Back',
    'Defensive Midfielder',
    'Central Midfielder',
    'Attacking Midfielder',
    'Left Winger',
    'Right Winger',
    'Striker',
    'Centre-Forward',
  ];

  @override
  void initState() {
    super.initState();
    _playerPosition = widget.player.position ?? _positions.first;
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingEvaluation != null) {
      final eval = widget.existingEvaluation!;
      _evaluationDate = eval.evaluationDate;
      _matchContextController.text = eval.matchContext ?? '';
      _playerPosition = eval.playerPosition;
      _recommendation = eval.recommendation;
      _strengthsController.text = eval.strengths ?? '';
      _areasForImprovementController.text = eval.areasForImprovement ?? '';
      _additionalNotesController.text = eval.additionalNotes ?? '';

      // Technical Skills
      _ballControl = eval.ballControl;
      _passingAccuracy = eval.passingAccuracy;
      _shootingAbility = eval.shootingAbility;
      _dribblingSkills = eval.dribblingSkills;
      _crossingAbility = eval.crossingAbility;
      _headingAbility = eval.headingAbility;

      // Physical Attributes
      _speed = eval.speed;
      _stamina = eval.stamina;
      _strength = eval.strength;
      _agility = eval.agility;
      _jumpingAbility = eval.jumpingAbility;

      // Mental Attributes
      _decisionMaking = eval.decisionMaking;
      _positioning = eval.positioning;
      _communication = eval.communication;
      _leadership = eval.leadership;
      _workRate = eval.workRate;
      _attitude = eval.attitude;

      // Overall Assessment
      _overallRating = eval.overallRating;
      _potentialRating = eval.potentialRating;
    }
  }

  @override
  void dispose() {
    _matchContextController.dispose();
    _strengthsController.dispose();
    _areasForImprovementController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if scout has already evaluated this player today
      if (widget.existingEvaluation == null) {
        final hasEvaluated = await _evaluationService.hasEvaluatedPlayerOnDate(
          currentUser.id,
          widget.player.userId,
          _evaluationDate,
        );

        if (hasEvaluated) {
          if (mounted) {
            _showErrorSnackBar(
              'You have already evaluated this player on this date',
            );
          }
          return;
        }
      }

      final evaluation = ScoutEvaluation(
        id: widget.existingEvaluation?.id ?? '',
        scoutId: currentUser.id,
        playerId: widget.player.userId,
        evaluationDate: _evaluationDate,
        matchContext:
            _matchContextController.text.trim().isEmpty
                ? null
                : _matchContextController.text.trim(),
        playerPosition: _playerPosition,
        ballControl: _ballControl,
        passingAccuracy: _passingAccuracy,
        shootingAbility: _shootingAbility,
        dribblingSkills: _dribblingSkills,
        crossingAbility: _crossingAbility,
        headingAbility: _headingAbility,
        speed: _speed,
        stamina: _stamina,
        strength: _strength,
        agility: _agility,
        jumpingAbility: _jumpingAbility,
        decisionMaking: _decisionMaking,
        positioning: _positioning,
        communication: _communication,
        leadership: _leadership,
        workRate: _workRate,
        attitude: _attitude,
        overallRating: _overallRating,
        potentialRating: _potentialRating,
        recommendation: _recommendation,
        strengths:
            _strengthsController.text.trim().isEmpty
                ? null
                : _strengthsController.text.trim(),
        areasForImprovement:
            _areasForImprovementController.text.trim().isEmpty
                ? null
                : _areasForImprovementController.text.trim(),
        additionalNotes:
            _additionalNotesController.text.trim().isEmpty
                ? null
                : _additionalNotesController.text.trim(),
        createdAt: widget.existingEvaluation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ScoutEvaluation? result;
      if (widget.existingEvaluation != null) {
        result = await _evaluationService.updateEvaluation(evaluation);
      } else {
        result = await _evaluationService.createEvaluation(evaluation);
      }

      if (result != null) {
        if (mounted) {
          _showSuccessSnackBar(
            widget.existingEvaluation != null
                ? 'Evaluation updated successfully!'
                : 'Evaluation saved successfully!',
          );
          Navigator.pop(context, result);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Failed to save evaluation');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.existingEvaluation != null
              ? 'Edit Evaluation'
              : 'Scout Evaluation',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveEvaluation,
              child: Text(
                widget.existingEvaluation != null ? 'UPDATE' : 'SAVE',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerHeader(),
              const SizedBox(height: 24),
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildTechnicalSkills(),
              const SizedBox(height: 24),
              _buildPhysicalAttributes(),
              const SizedBox(height: 24),
              _buildMentalAttributes(),
              const SizedBox(height: 24),
              _buildOverallAssessment(),
              const SizedBox(height: 24),
              _buildRecommendationSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.yellow,
            backgroundImage:
                widget.player.avatarUrl != null
                    ? NetworkImage(widget.player.avatarUrl!)
                    : null,
            child:
                widget.player.avatarUrl == null
                    ? Text(
                      widget.player.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.player.position ?? 'Position not specified',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                if (widget.player.currentClub != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.player.currentClub!,
                    style: TextStyle(color: Colors.yellow[700], fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          if (widget.player.isVerified)
            const Icon(Icons.verified, color: Colors.blue, size: 24),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSection('Basic Information', [
      _buildDatePicker(),
      const SizedBox(height: 16),
      _buildTextField(
        'Match Context (Optional)',
        _matchContextController,
        'e.g., League match vs Team X, Training session',
      ),
      const SizedBox(height: 16),
      _buildPositionDropdown(),
    ]);
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluation Date',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _evaluationDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.yellow,
                      onPrimary: Colors.black,
                      surface: Colors.grey,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _evaluationDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_evaluationDate.day}/${_evaluationDate.month}/${_evaluationDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Position',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _playerPosition,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          dropdownColor: Colors.grey[800],
          items:
              _positions.map((position) {
                return DropdownMenuItem<String>(
                  value: position,
                  child: Text(
                    position,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _playerPosition = value);
            }
          },
          validator:
              (value) => value == null ? 'Please select a position' : null,
        ),
      ],
    );
  }

  Widget _buildTechnicalSkills() {
    return _buildSection('Technical Skills', [
      RatingSlider(
        label: 'Ball Control',
        value: _ballControl,
        onChanged: (value) => setState(() => _ballControl = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Passing Accuracy',
        value: _passingAccuracy,
        onChanged: (value) => setState(() => _passingAccuracy = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Shooting Ability',
        value: _shootingAbility,
        onChanged: (value) => setState(() => _shootingAbility = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Dribbling Skills',
        value: _dribblingSkills,
        onChanged: (value) => setState(() => _dribblingSkills = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Crossing Ability',
        value: _crossingAbility,
        onChanged: (value) => setState(() => _crossingAbility = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Heading Ability',
        value: _headingAbility,
        onChanged: (value) => setState(() => _headingAbility = value),
      ),
    ]);
  }

  Widget _buildPhysicalAttributes() {
    return _buildSection('Physical Attributes', [
      RatingSlider(
        label: 'Speed',
        value: _speed,
        onChanged: (value) => setState(() => _speed = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Stamina',
        value: _stamina,
        onChanged: (value) => setState(() => _stamina = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Strength',
        value: _strength,
        onChanged: (value) => setState(() => _strength = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Agility',
        value: _agility,
        onChanged: (value) => setState(() => _agility = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Jumping Ability',
        value: _jumpingAbility,
        onChanged: (value) => setState(() => _jumpingAbility = value),
      ),
    ]);
  }

  Widget _buildMentalAttributes() {
    return _buildSection('Mental Attributes', [
      RatingSlider(
        label: 'Decision Making',
        value: _decisionMaking,
        onChanged: (value) => setState(() => _decisionMaking = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Positioning',
        value: _positioning,
        onChanged: (value) => setState(() => _positioning = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Communication',
        value: _communication,
        onChanged: (value) => setState(() => _communication = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Leadership',
        value: _leadership,
        onChanged: (value) => setState(() => _leadership = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Work Rate',
        value: _workRate,
        onChanged: (value) => setState(() => _workRate = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Attitude',
        value: _attitude,
        onChanged: (value) => setState(() => _attitude = value),
      ),
    ]);
  }

  Widget _buildOverallAssessment() {
    return _buildSection('Overall Assessment', [
      RatingSlider(
        label: 'Overall Rating',
        value: _overallRating,
        onChanged: (value) => setState(() => _overallRating = value),
      ),
      const SizedBox(height: 16),
      RatingSlider(
        label: 'Potential Rating',
        value: _potentialRating,
        onChanged: (value) => setState(() => _potentialRating = value),
      ),
    ]);
  }

  Widget _buildRecommendationSection() {
    return _buildSection('Recommendation & Notes', [
      _buildRecommendationDropdown(),
      const SizedBox(height: 16),
      _buildTextField(
        'Strengths',
        _strengthsController,
        'What are the player\'s main strengths?',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        'Areas for Improvement',
        _areasForImprovementController,
        'What areas need development?',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        'Additional Notes',
        _additionalNotesController,
        'Any additional observations or comments...',
      ),
    ]);
  }

  Widget _buildRecommendationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RecommendationType>(
          value: _recommendation,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          dropdownColor: Colors.grey[800],
          items:
              RecommendationType.values.map((recommendation) {
                return DropdownMenuItem<RecommendationType>(
                  value: recommendation,
                  child: Row(
                    children: [
                      Icon(
                        _getRecommendationIcon(recommendation),
                        color: _getRecommendationColor(recommendation),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        recommendation.displayName,
                        style: TextStyle(
                          color: _getRecommendationColor(recommendation),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _recommendation = value);
            }
          },
          validator:
              (value) =>
                  value == null ? 'Please select a recommendation' : null,
        ),
      ],
    );
  }

  IconData _getRecommendationIcon(RecommendationType recommendation) {
    switch (recommendation) {
      case RecommendationType.highlyRecommend:
        return Icons.star;
      case RecommendationType.recommend:
        return Icons.thumb_up;
      case RecommendationType.consider:
        return Icons.help_outline;
      case RecommendationType.notRecommend:
        return Icons.thumb_down;
    }
  }

  Color _getRecommendationColor(RecommendationType recommendation) {
    switch (recommendation) {
      case RecommendationType.highlyRecommend:
        return Colors.green;
      case RecommendationType.recommend:
        return Colors.lightGreen;
      case RecommendationType.consider:
        return Colors.orange;
      case RecommendationType.notRecommend:
        return Colors.red;
    }
  }
}
