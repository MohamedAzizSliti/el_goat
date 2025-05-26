import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';
import '../models/footballer_profile_model.dart';
import '../config/api_config.dart';

class AIExerciseService {
  /// Generate a simple UUID-like string for fallback exercises
  static String _generateSimpleUuid() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return '$timestamp-$randomPart-fallback';
  }

  /// Generate personalized exercises based on player profile
  static Future<List<ExerciseModel>> generateExercises({
    required FootballerProfileModel player,
    required List<String> focusAreas,
    int count = 3,
  }) async {
    print('🎯 Starting exercise generation for ${player.fullName}');
    print('🎯 Focus areas: ${focusAreas.join(', ')}');
    print('🎯 Count: $count');

    try {
      print('✅ API key is configured, proceeding with AI generation');
      final prompt = _buildPrompt(player, focusAreas, count);
      print('📝 Generated prompt, calling Gemini API...');

      final response = await _callGeminiAPI(prompt);
      print('✅ Got response from Gemini, parsing exercises...');

      final exercises = _parseExerciseResponse(response, player.userId);
      print('✅ Successfully generated ${exercises.length} exercises');

      return exercises;
    } catch (e) {
      print('❌ Error in generateExercises: $e');
      print('🔄 Falling back to static exercises');
      // Use fallback exercises if API fails
      return _getFallbackExercises(player);
    }
  }

  /// Generate exercises for specific skill improvement
  static Future<List<ExerciseModel>> generateSkillExercises({
    required FootballerProfileModel player,
    required String targetSkill,
    int count = 2,
  }) async {
    try {
      final prompt = _buildSkillPrompt(player, targetSkill, count);
      final response = await _callGeminiAPI(prompt);
      return _parseExerciseResponse(response, player.userId);
    } catch (e) {
      print('Error generating skill exercises: $e');
      return _getFallbackSkillExercises(player, targetSkill);
    }
  }

  /// Generate position-specific exercises
  static Future<List<ExerciseModel>> generatePositionExercises({
    required FootballerProfileModel player,
    int count = 3,
  }) async {
    try {
      final prompt = _buildPositionPrompt(player, count);
      final response = await _callGeminiAPI(prompt);
      return _parseExerciseResponse(response, player.userId);
    } catch (e) {
      print('Error generating position exercises: $e');
      return _getFallbackPositionExercises(player);
    }
  }

  static String _buildPrompt(
    FootballerProfileModel player,
    List<String> focusAreas,
    int count,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSeed = Random().nextInt(10000);
    final sessionId = '$timestamp-$randomSeed';

    return '''
You are an expert football coach AI. Generate $count UNIQUE and PERSONALIZED training exercises for this specific session.

SESSION ID: $sessionId
TIMESTAMP: ${DateTime.now().toIso8601String()}

Player Profile:
- Name: ${player.fullName}
- Position: ${player.position}
- Experience Level: ${player.experience}
- Skills: ${player.skills.join(', ')}
- Preferred Foot: ${player.preferredFoot}
- Focus Areas: ${focusAreas.join(', ')}
- Age: ${DateTime.now().year - player.dateOfBirth.year} years old
- Height: ${player.height}cm
- Weight: ${player.weight}kg

IMPORTANT: Create COMPLETELY NEW exercises each time. Do NOT repeat previous exercises.

Requirements:
1. Create exercises that specifically target: ${focusAreas.join(', ')}
2. Match the ${player.experience} experience level
3. Consider their ${player.position} position requirements
4. Include both technical and physical aspects
5. Provide clear, step-by-step instructions
6. Make each exercise UNIQUE and CREATIVE

For each exercise, provide:
- Title (concise, motivating)
- Description (what the exercise achieves)
- Step-by-step instructions
- Exercise type (technical/physical/tactical/mental)
- Difficulty level (beginner/intermediate/advanced/professional)
- Estimated duration in minutes
- Target skills being improved

Format your response as a JSON array with this structure:
[
  {
    "title": "Exercise Title",
    "description": "What this exercise improves",
    "instructions": "Step-by-step instructions",
    "type": "technical|physical|tactical|mental",
    "difficulty": "beginner|intermediate|advanced|professional",
    "estimatedDuration": 30,
    "targetSkills": ["skill1", "skill2"]
  }
]

Make the exercises engaging, progressive, and specifically tailored to improve the player's weaknesses while building on their strengths.
''';
  }

  static String _buildSkillPrompt(
    FootballerProfileModel player,
    String targetSkill,
    int count,
  ) {
    return '''
You are an expert football coach AI. Generate $count specific training exercises to improve "$targetSkill" for this player:

Player Profile:
- Position: ${player.position}
- Experience Level: ${player.experience}
- Current Skills: ${player.skills.join(', ')}
- Target Skill: $targetSkill

Create exercises that:
1. Specifically target and improve "$targetSkill"
2. Are appropriate for a ${player.position} player
3. Match the ${player.experience} experience level
4. Build progressively in difficulty
5. Include practical, actionable steps

Format as JSON array with the same structure as before.
''';
  }

  static String _buildPositionPrompt(FootballerProfileModel player, int count) {
    return '''
You are an expert football coach AI. Generate $count position-specific training exercises for a ${player.position} player:

Player Profile:
- Position: ${player.position}
- Experience Level: ${player.experience}
- Skills: ${player.skills.join(', ')}

Create exercises that:
1. Are essential for ${player.position} players
2. Improve position-specific skills and responsibilities
3. Match the ${player.experience} level
4. Cover different aspects (technical, tactical, physical)

Format as JSON array with the same structure as before.
''';
  }

  static Future<String> _callGeminiAPI(String prompt) async {
    print('🚀 Starting Gemini API call...');
    print('🔑 API Key configured: ${ApiConfig.isGeminiApiKeyConfigured}');
    print(
      '🔑 API Key (first 10 chars): ${ApiConfig.geminiApiKey.substring(0, 10)}...',
    );

    // Add randomization to prevent caching
    final randomizedPrompt = '''
$prompt

RANDOMIZATION SEED: ${Random().nextInt(999999)}
GENERATION TIME: ${DateTime.now().toIso8601String()}

Please ensure each response is completely unique and different from any previous responses.
''';

    print('📝 Prompt length: ${randomizedPrompt.length} characters');

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': randomizedPrompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.9, // Increased for more creativity
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
        'candidateCount': 1,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    });

    print('📦 Request body length: ${requestBody.length} characters');
    print('🌐 Making API call to: ${ApiConfig.geminiApiUrl}');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.geminiApiUrl}?key=${ApiConfig.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
        body: requestBody,
      );

      print('📊 Response Status Code: ${response.statusCode}');
      print('📋 Response Headers: ${response.headers}');
      print('📄 Response Body Length: ${response.body.length} characters');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Successfully parsed JSON response');

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          print('✅ Extracted text length: ${text.length} characters');
          print(
            '✅ Extracted text preview: ${text.substring(0, text.length > 200 ? 200 : text.length)}...',
          );
          return text;
        } else {
          print('❌ No candidates found in response');
          throw Exception('No candidates in Gemini response');
        }
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception(
          'Failed to generate exercises: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('💥 Exception during API call: $e');
      rethrow;
    }
  }

  static List<ExerciseModel> _parseExerciseResponse(
    String response,
    String userId,
  ) {
    try {
      // Extract JSON from response (Gemini might include extra text)
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No valid JSON found in response');
      }

      final jsonString = response.substring(jsonStart, jsonEnd);
      final List<dynamic> exerciseData = jsonDecode(jsonString);

      return exerciseData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomId = Random().nextInt(999999);

        return ExerciseModel(
          id: 'ai_${timestamp}_${index}_${randomId}',
          userId: userId,
          title: data['title'] ?? 'Training Exercise',
          description: data['description'] ?? 'Improve your football skills',
          instructions: data['instructions'] ?? 'Follow the coach instructions',
          type: _parseExerciseType(data['type']),
          difficulty: _parseExerciseDifficulty(data['difficulty']),
          targetPosition: '', // Will be set based on player position
          targetSkills: List<String>.from(data['targetSkills'] ?? []),
          estimatedDuration: data['estimatedDuration'] ?? 30,
          status: ExerciseStatus.pending,
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error parsing exercise response: $e');
      throw Exception('Failed to parse AI response');
    }
  }

  static ExerciseType _parseExerciseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'technical':
        return ExerciseType.technical;
      case 'physical':
        return ExerciseType.physical;
      case 'tactical':
        return ExerciseType.tactical;
      case 'mental':
        return ExerciseType.mental;
      default:
        return ExerciseType.technical;
    }
  }

  static ExerciseDifficulty _parseExerciseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return ExerciseDifficulty.beginner;
      case 'intermediate':
        return ExerciseDifficulty.intermediate;
      case 'advanced':
        return ExerciseDifficulty.advanced;
      case 'professional':
        return ExerciseDifficulty.professional;
      default:
        return ExerciseDifficulty.beginner;
    }
  }

  // Fallback exercises when AI fails
  static List<ExerciseModel> _getFallbackExercises(
    FootballerProfileModel player,
  ) {
    return [
      ExerciseModel(
        id: _generateSimpleUuid(),
        userId: player.userId,
        title: 'Ball Control Drills',
        description: 'Improve your first touch and ball control',
        instructions:
            '1. Set up 5 cones in a line\n2. Dribble through using both feet\n3. Focus on close control\n4. Repeat 10 times',
        type: ExerciseType.technical,
        difficulty: ExerciseDifficulty.beginner,
        targetPosition: player.position,
        targetSkills: ['Ball Control', 'Dribbling'],
        estimatedDuration: 20,
        status: ExerciseStatus.pending,
        createdAt: DateTime.now(),
      ),
    ];
  }

  static List<ExerciseModel> _getFallbackSkillExercises(
    FootballerProfileModel player,
    String skill,
  ) {
    return [
      ExerciseModel(
        id: _generateSimpleUuid(),
        userId: player.userId,
        title: '$skill Training',
        description: 'Focused training to improve your $skill',
        instructions: 'Practice $skill with dedicated drills and repetition',
        type: ExerciseType.technical,
        difficulty: ExerciseDifficulty.intermediate,
        targetPosition: player.position,
        targetSkills: [skill],
        estimatedDuration: 25,
        status: ExerciseStatus.pending,
        createdAt: DateTime.now(),
      ),
    ];
  }

  static List<ExerciseModel> _getFallbackPositionExercises(
    FootballerProfileModel player,
  ) {
    return [
      ExerciseModel(
        id: _generateSimpleUuid(),
        userId: player.userId,
        title: '${player.position} Specific Training',
        description: 'Position-specific skills for ${player.position} players',
        instructions: 'Focus on key skills required for your position',
        type: ExerciseType.tactical,
        difficulty: ExerciseDifficulty.intermediate,
        targetPosition: player.position,
        targetSkills: ['Positioning', 'Decision Making'],
        estimatedDuration: 30,
        status: ExerciseStatus.pending,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
