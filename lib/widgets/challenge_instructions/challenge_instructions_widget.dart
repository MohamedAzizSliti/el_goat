import 'package:flutter/material.dart';
import '../../models/challenge_instructions.dart';
import '../../services/challenge_instructions_service.dart';
import 'package:video_player/video_player.dart';

class ChallengeInstructionsWidget extends StatefulWidget {
  final String challengeId;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const ChallengeInstructionsWidget({
    Key? key,
    required this.challengeId,
    required this.onStart,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ChallengeInstructionsWidget> createState() =>
      _ChallengeInstructionsWidgetState();
}

class _ChallengeInstructionsWidgetState
    extends State<ChallengeInstructionsWidget> {
  final _instructionsService = ChallengeInstructionsService();
  late Future<ChallengeInstructions?> _instructionsFuture;
  int _currentStep = 0;
  bool _prerequisitesMet = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _instructionsFuture = _loadInstructions();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<ChallengeInstructions?> _loadInstructions() async {
    final instructions =
        await _instructionsService.getInstructions(widget.challengeId);
    if (instructions != null) {
      _prerequisitesMet =
          await _instructionsService.checkPrerequisites(widget.challengeId);
      if (instructions.steps.isNotEmpty &&
          instructions.steps[0].videoUrl != null) {
        await _initializeVideo(instructions.steps[0].videoUrl!);
      }
    }
    return instructions;
  }

  Future<void> _initializeVideo(String videoUrl) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.asset(videoUrl);
    await _videoController!.initialize();
    setState(() {});
  }

  Widget _buildPrerequisites(ChallengeInstructions instructions) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prerequisites',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (instructions.prerequisites['minimum_level'] != null)
              ListTile(
                leading: Icon(
                  _prerequisitesMet ? Icons.check_circle : Icons.warning,
                  color: _prerequisitesMet ? Colors.green : Colors.orange,
                ),
                title: Text(
                    'Minimum Level: ${instructions.prerequisites['minimum_level']}'),
              ),
            if (instructions.prerequisites['required_accuracy'] != null)
              ListTile(
                leading: Icon(
                  _prerequisitesMet ? Icons.check_circle : Icons.warning,
                  color: _prerequisitesMet ? Colors.green : Colors.orange,
                ),
                title: Text(
                    'Required Accuracy: ${instructions.prerequisites['required_accuracy']}'),
              ),
            ...?instructions.prerequisites['completed_tutorials']?.map<Widget>(
              (tutorial) => ListTile(
                leading: Icon(
                  _prerequisitesMet ? Icons.check_circle : Icons.warning,
                  color: _prerequisitesMet ? Colors.green : Colors.orange,
                ),
                title: Text('Complete Tutorial: $tutorial'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(ChallengeStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step.videoUrl != null && _videoController != null)
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                  child: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          step.description,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        if (step.tips.isNotEmpty) ...[
          const Text(
            'Tips:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...step.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (step.equipment.isNotEmpty) ...[
          const Text(
            'Required Equipment:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...step.equipment.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer, size: 20),
                  const SizedBox(width: 8),
                  Text(item),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepProgress(ChallengeInstructions instructions) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
              instructions.steps.length,
              (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: index <= _currentStep
                      ? Colors.blue
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                      if (instructions.steps[_currentStep].videoUrl != null) {
                        _initializeVideo(
                            instructions.steps[_currentStep].videoUrl!);
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                )
              else
                const SizedBox.shrink(),
              if (_currentStep < instructions.steps.length - 1)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep++;
                      if (instructions.steps[_currentStep].videoUrl != null) {
                        _initializeVideo(
                            instructions.steps[_currentStep].videoUrl!);
                      }
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                )
              else
                ElevatedButton.icon(
                  onPressed: widget.onComplete,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Challenge'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChallengeInstructions?>(
      future: _instructionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Failed to load challenge instructions'),
          );
        }

        final instructions = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrerequisites(instructions),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Step ${_currentStep + 1}: ${instructions.steps[_currentStep].title}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_currentStep + 1}/${instructions.steps.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStepContent(instructions.steps[_currentStep]),
                    ],
                  ),
                ),
              ),
              _buildStepProgress(instructions),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
} 