import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // OMDB API configuration
  static const String omdbBaseUrl = 'https://www.omdbapi.com';

  static String get omdbApiKey {
    final key = dotenv.env['OMDB_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OMDB_API_KEY not found in .env file');
    }
    return key;
  }

  // Watchmode API configuration
  static const String watchmodeBaseUrl = 'https://api.watchmode.com/v1/';

  static String get watchmodeApiKey {
    final key = dotenv.env['WATCHMODE_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('WATCHMODE_API_KEY not found in .env file');
    }
    return key;
  }

  // Deprecated - for backward compatibility
  @Deprecated('Use omdbBaseUrl instead')
  static const String baseUrl = omdbBaseUrl;

  @Deprecated('Use omdbApiKey instead')
  static String get apiKey => omdbApiKey;
}
