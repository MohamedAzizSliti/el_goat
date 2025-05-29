import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scout_evaluation.dart';
import '../models/footballer_profile.dart';
import '../services/scout_evaluation_service.dart';
import '../widgets/rating_slider.dart';
import 'scout_evaluation_form_page.dart';

class ScoutEvaluationListPage extends StatefulWidget {
  const ScoutEvaluationListPage({Key? key}) : super(key: key);

  @override
  State<ScoutEvaluationListPage> createState() => _ScoutEvaluationListPageState();
}

class _ScoutEvaluationListPageState extends State<ScoutEvaluationListPage> {
  final _evaluationService = ScoutEvaluationService();
  final _supabase = Supabase.instance.client;
  
  List<ScoutEvaluation> _evaluations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final evaluations = await _evaluationService.getEvaluationsByScout(currentUser.id);
        setState(() => _evaluations = evaluations);
      }
    } catch (e) {
      print('Error loading evaluations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'My Evaluations',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            )
          : _evaluations.isEmpty
              ? _buildEmptyState()
              : _buildEvaluationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPlayerSelectionDialog,
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Evaluations Yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start evaluating players to see them here',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showPlayerSelectionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Evaluation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationsList() {
    return RefreshIndicator(
      onRefresh: _loadEvaluations,
      color: Colors.yellow,
      backgroundColor: Colors.grey[800],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _evaluations.length,
        itemBuilder: (context, index) {
          final evaluation = _evaluations[index];
          return _buildEvaluationCard(evaluation);
        },
      ),
    );
  }

  Widget _buildEvaluationCard(ScoutEvaluation evaluation) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[700]!),
      ),
      child: InkWell(
        onTap: () => _viewEvaluationDetails(evaluation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Player ID: ${evaluation.playerId.substring(0, 8)}...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          evaluation.playerPosition,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRecommendationColor(evaluation.recommendation),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      evaluation.recommendation.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildRatingDisplay(
                      'Overall',
                      evaluation.overallRating.toDouble(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRatingDisplay(
                      'Potential',
                      evaluation.potentialRating.toDouble(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Evaluated on ${_formatDate(evaluation.evaluationDate)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingDisplay(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RatingStars(
                rating: value,
                size: 16,
              ),
            ),
          ],
        ),
      ],
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewEvaluationDetails(ScoutEvaluation evaluation) {
    // TODO: Navigate to detailed evaluation view
    // For now, just show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Evaluation Details',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Rating: ${evaluation.overallRating}/10',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Potential: ${evaluation.potentialRating}/10',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Recommendation: ${evaluation.recommendation.displayName}',
              style: const TextStyle(color: Colors.white),
            ),
            if (evaluation.strengths != null) ...[
              const SizedBox(height: 8),
              Text(
                'Strengths: ${evaluation.strengths}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }

  void _showPlayerSelectionDialog() {
    // TODO: Implement player selection dialog
    // For now, show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Player selection dialog would be implemented here'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
