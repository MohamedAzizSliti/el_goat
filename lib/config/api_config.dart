// lib/config/api_config.dart

class ApiConfig {
  // TODO: Replace with your actual Gemini API key
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyBI6NhDU_Ht6881F7cRm1W2nbQHITRDYiA';

  // Gemini API Configuration
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // API Settings
  static const double defaultTemperature = 0.9;
  static const int defaultTopK = 40;
  static const double defaultTopP = 0.95;
  static const int defaultMaxOutputTokens = 2048;

  // Validation
  static bool get isGeminiApiKeyConfigured =>
      geminiApiKey != 'AIzaSyBI6NhDU_Ht6881F7cRm1W2nbQHITRDYiA' &&
      geminiApiKey.isNotEmpty;
}
