import 'package:flutter_dotenv/flutter_dotenv.dart';
class AppConfig {
  /// Get a free key at https://aistudio.google.com/app/apikey
  /// Leave as is to use the built-in offline analyzer (no AI, keyword based).
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Models are tried from top to bottom. If one is busy (503), rate limited
  /// (429) or not found (404), the app automatically tries the next one.
  /// You can add or remove names. Check current names at
  /// https://ai.google.dev/gemini-api/docs/models
  static const List<String> geminiModels = [
    // 'gemini-3.5-flash',
    // 'gemini-3.1-flash-lite',
    // 'gemini-3.6-flash',
    'gemini-3-flash-preview',
    // 'gemini-flash-latest',
  ];

  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty && !geminiApiKey.startsWith('PASTE');
}