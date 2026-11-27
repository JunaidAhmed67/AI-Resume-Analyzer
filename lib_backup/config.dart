class AppConfig {
  /// Get a free key at https://aistudio.google.com/app/apikey
  /// Leave as is to use the built-in offline analyzer (no AI, keyword based).
  static const String geminiApiKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';

  /// If you get a "model not found" error, open Google AI Studio, check the
  /// current model name (for example a newer "...-flash") and put it here.
  static const String geminiModel = 'gemini-3.6-flash';

  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty && !geminiApiKey.startsWith('PASTE');
}
