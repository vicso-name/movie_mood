import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/app_error.dart';
import '../constants/api_config.dart';
import '../data/actors_database.dart';
import '../data/top_movies_database.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';
import 'movie_rotation_service.dart';
import '../services/poster_validation_service.dart';

class MovieService {
  static const String _baseUrl = ApiConfig.omdbBaseUrl;
  final String _apiKey = ApiConfig.omdbApiKey;
  final CacheService _cacheService = CacheService();
  final MovieRotationService _rotationService = MovieRotationService();

  final PosterValidationService _posterValidator = PosterValidationService();
  static const Duration _requestTimeout = Duration(seconds: 10);

  static const Map<String, List<Map<String, double>>> _moodSearchGroups = {
    'happy': [
      {
        'comedy': 1.0,
        'funny': 0.9,
        'hilarious': 0.8,
        'laugh': 0.7,
        'humor': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 2: Ð¡ÐµÐ¼ÐµÐ¹Ð½Ñ‹Ðµ Ñ„Ð¸Ð»ÑŒÐ¼Ñ‹ (Ð²ÐµÑ‡ÐµÑ€)
      {
        'family': 1.0,
        'feel good': 0.9,
        'uplifting': 0.8,
        'cheerful': 0.7,
        'joyful': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 3: ÐÐ½Ð¸Ð¼Ð°Ñ†Ð¸Ñ Ð¸ Ð¼ÑŽÐ·Ð¸ÐºÐ»Ñ‹ (Ð²Ñ‹Ñ…Ð¾Ð´Ð½Ñ‹Ðµ)
      {
        'animation': 1.0,
        'musical': 0.9,
        'disney': 0.8,
        'cartoon': 0.7,
        'pixar': 0.6,
      },
    ],
    'romantic': [
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 1: ÐšÐ»Ð°ÑÑÐ¸Ñ‡ÐµÑÐºÐ°Ñ Ñ€Ð¾Ð¼Ð°Ð½Ñ‚Ð¸ÐºÐ° (Ð²ÐµÑ‡ÐµÑ€)
      {
        'romance': 1.0,
        'love': 0.9,
        'romantic': 0.8,
        'heart': 0.7,
        'passion': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 2: Ð Ð¾Ð¼Ð°Ð½Ñ‚Ð¸Ñ‡ÐµÑÐºÐ¸Ðµ ÐºÐ¾Ð¼ÐµÐ´Ð¸Ð¸ (Ð´ÐµÐ½ÑŒ)
      {
        'romantic comedy': 1.0,
        'date night': 0.9,
        'couple': 0.8,
        'wedding': 0.7,
        'relationship': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 3: Ð”Ñ€Ð°Ð¼Ð°Ñ‚Ð¸Ñ‡ÐµÑÐºÐ°Ñ Ñ€Ð¾Ð¼Ð°Ð½Ñ‚Ð¸ÐºÐ° (Ð¿Ð¾Ð·Ð´Ð½Ð¸Ð¹ Ð²ÐµÑ‡ÐµÑ€)
      {
        'love story': 1.0,
        'soulmate': 0.9,
        'valentine': 0.8,
        'eternal love': 0.7,
        'romantic drama': 0.6,
      },
    ],
    'sad': [
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 1: Ð­Ð¼Ð¾Ñ†Ð¸Ð¾Ð½Ð°Ð»ÑŒÐ½Ñ‹Ðµ Ð´Ñ€Ð°Ð¼Ñ‹
      {
        'drama': 1.0,
        'emotional': 0.9,
        'tearjerker': 0.8,
        'tragic': 0.7,
        'melancholy': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 2: Ðž Ð¿Ð¾Ñ‚ÐµÑ€ÑÑ… Ð¸ Ð³Ð¾Ñ€Ðµ
      {
        'loss': 1.0,
        'grief': 0.9,
        'heartbreak': 0.8,
        'tragedy': 0.7,
        'sorrow': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 3: Ð–Ð¸Ð·Ð½ÐµÐ½Ð½Ñ‹Ðµ Ð¸ÑÑ‚Ð¾Ñ€Ð¸Ð¸
      {
        'life story': 1.0,
        'difficult': 0.9,
        'struggle': 0.8,
        'painful': 0.7,
        'moving': 0.6,
      },
    ],
    'cozy': [
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 1: Ð¡ÐµÐ¼ÐµÐ¹Ð½Ñ‹Ðµ Ñ„Ð¸Ð»ÑŒÐ¼Ñ‹ (Ð·Ð¸Ð¼Ð°/Ð²ÐµÑ‡ÐµÑ€)
      {
        'family': 1.0,
        'warm': 0.9,
        'comfort': 0.8,
        'home': 0.7,
        'peaceful': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 2: ÐŸÑ€Ð°Ð·Ð´Ð½Ð¸Ñ‡Ð½Ñ‹Ðµ Ñ„Ð¸Ð»ÑŒÐ¼Ñ‹ (Ð·Ð¸Ð¼Ð°)
      {
        'holiday': 1.0,
        'christmas': 0.9,
        'winter': 0.8,
        'cozy': 0.7,
        'fireplace': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 3: ÐÐ¾ÑÑ‚Ð°Ð»ÑŒÐ³Ð¸Ñ‡ÐµÑÐºÐ¸Ðµ Ñ„Ð¸Ð»ÑŒÐ¼Ñ‹
      {
        'nostalgic': 1.0,
        'childhood': 0.9,
        'innocent': 0.8,
        'gentle': 0.7,
        'simple': 0.6,
      },
    ],
    'inspiring': [
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 1: Ð‘Ð¸Ð¾Ð³Ñ€Ð°Ñ„Ð¸Ð¸ Ð¸ Ñ€ÐµÐ°Ð»ÑŒÐ½Ñ‹Ðµ Ð¸ÑÑ‚Ð¾Ñ€Ð¸Ð¸
      {
        'biography': 1.0,
        'true story': 0.9,
        'real life': 0.8,
        'based on': 0.7,
        'documentary': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 2: ÐœÐ¾Ñ‚Ð¸Ð²Ð°Ñ†Ð¸Ð¾Ð½Ð½Ñ‹Ðµ Ð¸ÑÑ‚Ð¾Ñ€Ð¸Ð¸
      {
        'motivational': 1.0,
        'triumph': 0.9,
        'overcome': 0.8,
        'success': 0.7,
        'achievement': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 3: Ð“ÐµÑ€Ð¾Ð¸ Ð¸ Ð»Ð¸Ð´ÐµÑ€Ñ‹
      {
        'hero': 1.0,
        'leader': 0.9,
        'courage': 0.8,
        'determination': 0.7,
        'perseverance': 0.6,
      },
    ],
    'thrilling': [
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 1: Ð­ÐºÑˆÐ½ Ð¸ Ð¿Ñ€Ð¸ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ñ (Ð´ÐµÐ½ÑŒ)
      {
        'action': 1.0,
        'adventure': 0.9,
        'exciting': 0.8,
        'fast-paced': 0.7,
        'adrenaline': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 2: Ð¢Ñ€Ð¸Ð»Ð»ÐµÑ€Ñ‹ Ð¸ ÑÐ°ÑÐ¿ÐµÐ½Ñ (Ð²ÐµÑ‡ÐµÑ€)
      {
        'thriller': 1.0,
        'suspense': 0.9,
        'intense': 0.8,
        'edge of seat': 0.7,
        'tension': 0.6,
      },
      // Ð“Ñ€ÑƒÐ¿Ð¿Ð° 3: Ð¨Ð¿Ð¸Ð¾Ð½Ð°Ð¶ Ð¸ Ð¿Ð¾Ð³Ð¾Ð½Ð¸
      {
        'spy': 1.0,
        'chase': 0.9,
        'mission': 0.8,
        'danger': 0.7,
        'espionage': 0.6,
      },
    ],
  };

  // ðŸ†• ÐšÐžÐÐ¢Ð•ÐšÐ¡Ð¢ÐÐÐ¯ Ð›ÐžÐ“Ð˜ÐšÐ: Ð’Ñ‹Ð±Ð¾Ñ€ Ð³Ñ€ÑƒÐ¿Ð¿Ñ‹ Ð½Ð° Ð¾ÑÐ½Ð¾Ð²Ðµ Ð²Ñ€ÐµÐ¼ÐµÐ½Ð¸ Ð¸ ÐºÐ¾Ð½Ñ‚ÐµÐºÑÑ‚Ð°
  Map<String, double> _getContextualSearchTerms(String mood) {
    final groups = _moodSearchGroups[mood.toLowerCase()] ?? [];
    if (groups.isEmpty) {
      // Fallback Ðº ÑÑ‚Ð°Ñ€Ð¾Ð¹ ÑÐ¸ÑÑ‚ÐµÐ¼Ðµ ÐµÑÐ»Ð¸ Ð³Ñ€ÑƒÐ¿Ð¿Ñ‹ Ð½Ðµ Ð½Ð°Ð¹Ð´ÐµÐ½Ñ‹
      return _moodSearchTerms[mood.toLowerCase()] ?? {};
    }

    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend = now.weekday >= 6;
    final month = now.month;
    final isWinter = month == 12 || month <= 2;

    int groupIndex = 0;

    // ðŸ• Ð›Ð¾Ð³Ð¸ÐºÐ° Ð²Ñ‹Ð±Ð¾Ñ€Ð° Ð³Ñ€ÑƒÐ¿Ð¿Ñ‹ Ð½Ð° Ð¾ÑÐ½Ð¾Ð²Ðµ Ð²Ñ€ÐµÐ¼ÐµÐ½Ð¸ Ð´Ð½Ñ
    switch (mood.toLowerCase()) {
      case 'happy':
        if (hour >= 6 && hour < 12) {
          groupIndex = 0; // Ð£Ñ‚Ñ€Ð¾Ð¼ - ÑÐ½ÐµÑ€Ð³Ð¸Ñ‡Ð½Ñ‹Ðµ ÐºÐ¾Ð¼ÐµÐ´Ð¸Ð¸
        } else if (hour >= 18 || isWeekend) {
          groupIndex =
              1; // Ð’ÐµÑ‡ÐµÑ€Ð¾Ð¼/Ð²Ñ‹Ñ…Ð¾Ð´Ð½Ñ‹Ðµ - ÑÐµÐ¼ÐµÐ¹Ð½Ñ‹Ðµ Ñ„Ð¸Ð»ÑŒÐ¼Ñ‹
        } else {
          groupIndex = 2; // Ð”ÐµÐ½ÑŒ - Ð°Ð½Ð¸Ð¼Ð°Ñ†Ð¸Ñ Ð¸ Ð¼ÑŽÐ·Ð¸ÐºÐ»Ñ‹
        }
        break;

      case 'romantic':
        if (hour >= 19 || (isWeekend && hour >= 16)) {
          groupIndex =
              0; // Ð’ÐµÑ‡ÐµÑ€ - ÐºÐ»Ð°ÑÑÐ¸Ñ‡ÐµÑÐºÐ°Ñ Ñ€Ð¾Ð¼Ð°Ð½Ñ‚Ð¸ÐºÐ°
        } else if (hour >= 12 && hour < 19) {
          groupIndex =
              1; // Ð”ÐµÐ½ÑŒ - Ñ€Ð¾Ð¼Ð°Ð½Ñ‚Ð¸Ñ‡ÐµÑÐºÐ¸Ðµ ÐºÐ¾Ð¼ÐµÐ´Ð¸Ð¸
        } else {
          groupIndex =
              2; // ÐŸÐ¾Ð·Ð´Ð½Ð¸Ð¹ Ð²ÐµÑ‡ÐµÑ€ - Ð´Ñ€Ð°Ð¼Ð°Ñ‚Ð¸Ñ‡ÐµÑÐºÐ°Ñ Ñ€Ð¾Ð¼Ð°Ð½Ñ‚Ð¸ÐºÐ°
        }
        break;

      case 'cozy':
        if (isWinter || hour >= 17) {
          groupIndex = isWinter
              ? 1
              : 0; // Ð—Ð¸Ð¼Ð° - Ð¿Ñ€Ð°Ð·Ð´Ð½Ð¸Ñ‡Ð½Ñ‹Ðµ, Ð²ÐµÑ‡ÐµÑ€ - ÑÐµÐ¼ÐµÐ¹Ð½Ñ‹Ðµ
        } else {
          groupIndex = 2; // ÐÐ¾ÑÑ‚Ð°Ð»ÑŒÐ³Ð¸Ñ‡ÐµÑÐºÐ¸Ðµ
        }
        break;

      case 'inspiring':
        if (hour >= 6 && hour < 12) {
          groupIndex = 1; // Ð£Ñ‚Ñ€Ð¾Ð¼ - Ð¼Ð¾Ñ‚Ð¸Ð²Ð°Ñ†Ð¸Ð¾Ð½Ð½Ñ‹Ðµ
        } else if (isWeekend) {
          groupIndex = 0; // Ð’Ñ‹Ñ…Ð¾Ð´Ð½Ñ‹Ðµ - Ð±Ð¸Ð¾Ð³Ñ€Ð°Ñ„Ð¸Ð¸
        } else {
          groupIndex = 2; // Ð“ÐµÑ€Ð¾Ð¸ Ð¸ Ð»Ð¸Ð´ÐµÑ€Ñ‹
        }
        break;

      case 'thrilling':
        if (hour >= 6 && hour < 18) {
          groupIndex = 0; // Ð”ÐµÐ½ÑŒ - ÑÐºÑˆÐ½ Ð¸ Ð¿Ñ€Ð¸ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ñ
        } else if (hour >= 18 && hour < 22) {
          groupIndex = 1; // Ð’ÐµÑ‡ÐµÑ€ - Ñ‚Ñ€Ð¸Ð»Ð»ÐµÑ€Ñ‹
        } else {
          groupIndex = 2; // ÐŸÐ¾Ð·Ð´Ð½Ð¾ - ÑˆÐ¿Ð¸Ð¾Ð½Ð°Ð¶
        }
        break;

      case 'sad':
        if (hour >= 20 || isWeekend) {
          groupIndex =
              0; // Ð’ÐµÑ‡ÐµÑ€/Ð²Ñ‹Ñ…Ð¾Ð´Ð½Ñ‹Ðµ - ÑÐ¼Ð¾Ñ†Ð¸Ð¾Ð½Ð°Ð»ÑŒÐ½Ñ‹Ðµ Ð´Ñ€Ð°Ð¼Ñ‹
        } else if (hour >= 14 && hour < 18) {
          groupIndex = 1; // ÐŸÐ¾ÑÐ»Ðµ Ð¾Ð±ÐµÐ´Ð° - Ð¾ Ð¿Ð¾Ñ‚ÐµÑ€ÑÑ…
        } else {
          groupIndex = 2; // Ð–Ð¸Ð·Ð½ÐµÐ½Ð½Ñ‹Ðµ Ð¸ÑÑ‚Ð¾Ñ€Ð¸Ð¸
        }
        break;
    }

    // ðŸŽ² Ð”Ð¾Ð±Ð°Ð²Ð»ÑÐµÐ¼ ÑÐ»ÐµÐ¼ÐµÐ½Ñ‚ ÑÐ»ÑƒÑ‡Ð°Ð¹Ð½Ð¾ÑÑ‚Ð¸ (30% ÑˆÐ°Ð½Ñ Ð²Ñ‹Ð±Ñ€Ð°Ñ‚ÑŒ Ð´Ñ€ÑƒÐ³ÑƒÑŽ Ð³Ñ€ÑƒÐ¿Ð¿Ñƒ)
    if (Random().nextDouble() < 0.3 && groups.length > 1) {
      final availableGroups = List.generate(groups.length, (i) => i);
      availableGroups.remove(groupIndex);
      groupIndex = availableGroups[Random().nextInt(availableGroups.length)];
    }

    // ðŸ“Š Ð’Ð¾Ð·Ð²Ñ€Ð°Ñ‰Ð°ÐµÐ¼ Ð²Ñ‹Ð±Ñ€Ð°Ð½Ð½ÑƒÑŽ Ð³Ñ€ÑƒÐ¿Ð¿Ñƒ Ñ‚ÐµÑ€Ð¼Ð¸Ð½Ð¾Ð²
    final selectedGroup = groups[groupIndex.clamp(0, groups.length - 1)];

    print(
      'ðŸŽ¯ Mood: $mood, Hour: $hour, Group: $groupIndex, Terms: ${selectedGroup.keys.take(3).join(", ")}',
    );

    return selectedGroup;
  }

  static const Map<String, Map<String, double>> _moodSearchTerms = {
    'happy': {
      'comedy': 1.0,
      'family': 0.9,
      'animation': 0.8,
      'musical': 0.7,
      'adventure': 0.6,
      'feel good': 0.9,
      'uplifting': 0.8,
      'lighthearted': 0.7,
    },
    'romantic': {
      'romance': 1.0,
      'love': 0.9,
      'romantic comedy': 0.8,
      'wedding': 0.7,
      'valentine': 0.6,
      'relationship': 0.8,
      'couple': 0.7,
      'date night': 0.6,
    },
    'sad': {
      'drama': 1.0,
      'tragedy': 0.9,
      'emotional': 0.8,
      'tearjerker': 0.7,
      'melancholy': 0.6,
      'heartbreak': 0.8,
      'loss': 0.7,
      'grief': 0.6,
    },
    'cozy': {
      'family': 1.0,
      'holiday': 0.9,
      'christmas': 0.8,
      'home': 0.7,
      'comfort': 0.6,
      'warm': 0.8,
      'peaceful': 0.7,
      'nostalgic': 0.6,
    },
    'inspiring': {
      'biography': 1.0,
      'true story': 0.9,
      'motivational': 0.8,
      'success': 0.7,
      'hero': 0.6,
      'overcome': 0.8,
      'triumph': 0.7,
      'achievement': 0.6,
    },
    'thrilling': {
      'action': 1.0,
      'thriller': 0.9,
      'adventure': 0.8,
      'spy': 0.7,
      'chase': 0.6,
      'suspense': 0.9,
      'intense': 0.8,
      'edge of seat': 0.7,
    },
  };

  static const Map<String, List<String>> _moodKeywords = {
    'happy': [
      'comedy',
      'funny',
      'hilarious',
      'laugh',
      'humor',
      'cheerful',
      'upbeat',
      'joyful',
    ],
    'romantic': [
      'romance',
      'love',
      'romantic',
      'heart',
      'passion',
      'relationship',
      'couple',
      'wedding',
    ],
    'sad': [
      'drama',
      'tragic',
      'emotional',
      'tear',
      'loss',
      'death',
      'grief',
      'heartbreak',
    ],
    'cozy': [
      'family',
      'warm',
      'comfort',
      'home',
      'holiday',
      'christmas',
      'peaceful',
      'gentle',
    ],
    'inspiring': [
      'biography',
      'true',
      'inspire',
      'triumph',
      'overcome',
      'success',
      'hero',
      'motivate',
    ],
    'thrilling': [
      'action',
      'thriller',
      'adventure',
      'suspense',
      'intense',
      'exciting',
      'fast-paced',
    ],
  };

  static const Map<String, List<String>> _excludedGenres = {
    'happy': ['horror', 'war', 'thriller'],
    'romantic': ['horror', 'war', 'action'],
    'cozy': ['horror', 'thriller', 'war'],
    'inspiring': ['horror', 'comedy'],
  };

  Future<List<Movie>> getTopMoviesByIds(List<String> imdbIds) async {
    if (!await ConnectivityService.hasInternetConnection()) {
      throw AppError.network();
    }

    try {
      final List<Movie> movies = [];
      final Set<String> processedIds = {};

      for (int i = 0; i < imdbIds.length; i++) {
        final imdbId = imdbIds[i].trim();

        if (processedIds.contains(imdbId)) {
          continue;
        }
        processedIds.add(imdbId);

        try {
          Movie? movie = await _cacheService.getCachedMovie(imdbId);

          movie ??= await getMovieDetails(imdbId);

          if (movie != null && movie.hasValidPoster) {
            movies.add(movie);
            print('✅ Loaded: ${movie.title}');
          } else {
            print('❌ Skipped: $imdbId (no valid poster)');
          }

          // Небольшая задержка чтобы не перегружать API
          if (i < imdbIds.length - 1) {
            await Future.delayed(const Duration(milliseconds: 200));
          }

          // Прогресс каждые 5 фильмов
          if ((i + 1) % 5 == 0) {
            print(
              'Progress: ${i + 1}/${imdbIds.length} processed, ${movies.length} valid movies',
            );
          }
        } catch (e) {
          continue; // Продолжаем со следующим фильмом
        }
      }

      final validatedMovies = await _posterValidator.validateMoviePosters(
        movies,
        onProgress: (current, total) {
          print('Poster validation: $current/$total');
        },
      );
      validatedMovies.sort((a, b) => b.rating.compareTo(a.rating));
      return validatedMovies;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Movie>> getRandomTopMovies({int count = 20}) async {
    try {
      final categories = TopMoviesDatabase.getAllCategories();
      final randomCategory = categories[Random().nextInt(categories.length)];

      final categoryMovies = TopMoviesDatabase.getMoviesForCategory(
        randomCategory,
      );
      categoryMovies.shuffle();

      final selectedIds = categoryMovies.take(count).toList();
      return await getTopMoviesByIds(selectedIds);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Movie>> getMixedTopMovies({int moviesPerCategory = 5}) async {
    try {
      final categories = TopMoviesDatabase.getPopularCategories();
      final List<String> selectedIds = [];

      for (final category in categories) {
        final categoryMovies = TopMoviesDatabase.getMoviesForCategory(category);
        categoryMovies.shuffle();
        selectedIds.addAll(categoryMovies.take(moviesPerCategory));
      }

      selectedIds.shuffle();
      return await getTopMoviesByIds(selectedIds);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 📊 Получить статистику топ-фильмов
  Map<String, dynamic> getTopMoviesStats() {
    return TopMoviesDatabase.getDatabaseStats();
  }

  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    if (!ActorsDatabase.isKnownActor(actorName)) {
      throw AppError.notFound();
    }

    try {
      // Ð¡Ð½Ð°Ñ‡Ð°Ð»Ð° Ð¿Ñ€Ð¾Ð²ÐµÑ€ÑÐµÐ¼ ÐºÐµÑˆ
      final cachedMovies = await _cacheService.getCachedActorMovies(actorName);
      if (cachedMovies != null && cachedMovies.isNotEmpty) {
        return cachedMovies;
      }

      // ÐŸÑ€Ð¾Ð²ÐµÑ€ÑÐµÐ¼ Ð¸Ð½Ñ‚ÐµÑ€Ð½ÐµÑ‚ ÑÐ¾ÐµÐ´Ð¸Ð½ÐµÐ½Ð¸Ðµ
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      // Ð•ÑÐ»Ð¸ Ð² ÐºÐµÑˆÐµ Ð½ÐµÑ‚, Ð·Ð°Ð³Ñ€ÑƒÐ¶Ð°ÐµÐ¼ Ð¸Ð· API
      final movieTitles = ActorsDatabase.getActorMovies(actorName);
      final List<Movie> foundMovies = [];

      for (final title in movieTitles.take(15)) {
        try {
          final movie = await _getMovieWithCache(title);
          if (movie != null) {
            // ÐŸÑ€Ð¾Ð²ÐµÑ€ÑÐµÐ¼, Ñ‡Ñ‚Ð¾ Ð°ÐºÑ‚ÐµÑ€ Ð´ÐµÐ¹ÑÑ‚Ð²Ð¸Ñ‚ÐµÐ»ÑŒÐ½Ð¾ ÑƒÐºÐ°Ð·Ð°Ð½ Ð² ÑÐ¾ÑÑ‚Ð°Ð²Ðµ
            if (movie.actors != null &&
                movie.actors!.toLowerCase().contains(actorName.toLowerCase())) {
              foundMovies.add(movie);
            }
          }

          // ÐÐµÐ±Ð¾Ð»ÑŒÑˆÐ°Ñ Ð·Ð°Ð´ÐµÑ€Ð¶ÐºÐ° Ñ‡Ñ‚Ð¾Ð±Ñ‹ Ð½Ðµ Ð¿ÐµÑ€ÐµÐ³Ñ€ÑƒÐ¶Ð°Ñ‚ÑŒ API
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          // ÐŸÑ€Ð¾Ð´Ð¾Ð»Ð¶Ð°ÐµÐ¼ Ð¿Ð¾Ð¸ÑÐº Ð´Ñ€ÑƒÐ³Ð¸Ñ… Ñ„Ð¸Ð»ÑŒÐ¼Ð¾Ð² Ð¿Ñ€Ð¸ Ð¾ÑˆÐ¸Ð±ÐºÐµ Ð¾Ð´Ð½Ð¾Ð³Ð¾
          continue;
        }
      }

      // Ð£Ð´Ð°Ð»ÑÐµÐ¼ Ð´ÑƒÐ±Ð»Ð¸ÐºÐ°Ñ‚Ñ‹
      final uniqueMovies = <String, Movie>{};
      for (final movie in foundMovies) {
        uniqueMovies[movie.imdbID] = movie;
      }

      final result = uniqueMovies.values.toList();
      result.sort((a, b) => b.rating.compareTo(a.rating));

      // ÐšÐµÑˆÐ¸Ñ€ÑƒÐµÐ¼ Ñ€ÐµÐ·ÑƒÐ»ÑŒÑ‚Ð°Ñ‚
      if (result.isNotEmpty) {
        await _cacheService.cacheActorMovies(actorName, result);
      }

      return result;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      throw _handleError(e);
    }
  }

  // ÐŸÐ¾Ð»ÑƒÑ‡ÐµÐ½Ð¸Ðµ Ñ„Ð¸Ð»ÑŒÐ¼Ð° Ñ Ð¿Ñ€Ð¾Ð²ÐµÑ€ÐºÐ¾Ð¹ ÐºÐµÑˆÐ° Ð¸ Ð¾Ð±Ñ€Ð°Ð±Ð¾Ñ‚ÐºÐ¾Ð¹ Ð¾ÑˆÐ¸Ð±Ð¾Ðº
  Future<Movie?> _getMovieWithCache(String title) async {
    try {
      final movie = await _searchExactTitle(title);
      if (movie != null) {
        await _cacheService.cacheMovie(movie);
        return movie;
      }
      return null;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      return null;
    }
  }

  // ÐŸÐ¾Ð¸ÑÐº Ñ‚Ð¾Ñ‡Ð½Ð¾Ð³Ð¾ Ð½Ð°Ð·Ð²Ð°Ð½Ð¸Ñ Ñ„Ð¸Ð»ÑŒÐ¼Ð° Ñ Ñ‚Ð°Ð¹Ð¼Ð°ÑƒÑ‚Ð¾Ð¼
  Future<Movie?> _searchExactTitle(String title) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/?apikey=$_apiKey&t=${Uri.encodeComponent(title)}&type=movie',
      );

      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          return Movie.fromJson(data);
        } else if (data['Error'] != null) {
          _handleApiError(data['Error']);
        }
      } else {
        throw _handleHttpError(response.statusCode);
      }

      return null;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Movie?> getMovieDetails(String imdbID) async {
    try {
      final cachedMovie = await _cacheService.getCachedMovie(imdbID);
      if (cachedMovie != null) {
        return cachedMovie;
      }

      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      final url = Uri.parse('$_baseUrl/?apikey=$_apiKey&i=$imdbID&plot=full');

      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          final movie = Movie.fromJson(data);
          await _cacheService.cacheMovie(movie);
          return movie;
        } else if (data['Error'] != null) {
          _handleApiError(data['Error']);
        }
      } else {
        throw _handleHttpError(response.statusCode);
      }

      return null;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Movie>> getMoviesByMood(String mood) async {
    try {
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      print('🎬 Starting smart mood search for: $mood');

      final searchTermsMap = _getContextualSearchTerms(mood);
      final searchTerms = searchTermsMap.entries.toList();

      if (searchTerms.isEmpty) {
        return await getRandomMovies();
      }

      searchTerms.sort((a, b) => b.value.compareTo(a.value));

      final List<MovieWithScore> allMoviesWithScores = [];

      for (int i = 0; i < min(5, searchTerms.length); i++) {
        final entry = searchTerms[i];
        final term = entry.key;
        final termWeight = entry.value;

        try {
          final movies = await _searchMovies(term);
          print('🎥 Found ${movies.length} movies for term: "$term"');

          for (final movie in movies) {
            final relevanceScore = _calculateMoodRelevance(
              movie,
              mood.toLowerCase(),
              termWeight,
            );
            allMoviesWithScores.add(MovieWithScore(movie, relevanceScore));
          }
        } catch (e) {
          continue;
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      print('Total movies collected: ${allMoviesWithScores.length}');

      final Map<String, MovieWithScore> uniqueMovies = {};
      for (final movieWithScore in allMoviesWithScores) {
        final existing = uniqueMovies[movieWithScore.movie.imdbID];
        if (existing == null || movieWithScore.score > existing.score) {
          uniqueMovies[movieWithScore.movie.imdbID] = movieWithScore;
        }
      }

      final sortedMovies = uniqueMovies.values.toList();
      sortedMovies.sort((a, b) {
        final scoreDiff = b.score.compareTo(a.score);
        if (scoreDiff != 0) return scoreDiff;
        return b.movie.rating.compareTo(a.movie.rating);
      });

      List<Movie> result = sortedMovies.map((mws) => mws.movie).toList();

      // 🔥 ЭТАП 1: Быстрая фильтрация по базовым критериям
      print('Before basic filtering: ${result.length} movies');
      result = result.where((movie) => movie.hasBasicPosterUrl).toList();
      print('After basic filtering: ${result.length} movies');

      // 🔥 ЭТАП 2: Проверка кешированных результатов валидации
      result = _posterValidator.validateMoviePostersSync(result);
      print('After sync validation: ${result.length} movies');

      // 🔥 ЭТАП 3: Если фильмов мало - асинхронная валидация постеров
      if (result.length < 8) {
        print(
          '⚠️ Too few movies after filtering, performing full poster validation...',
        );

        // Берем больше фильмов для валидации
        final extendedList = sortedMovies
            .map((mws) => mws.movie)
            .where((movie) => movie.hasBasicPosterUrl)
            .take(20)
            .toList();

        // Валидируем постеры
        result = await _posterValidator.validateMoviePosters(
          extendedList,
          onProgress: (current, total) {
            print('Validating posters: $current/$total');
          },
        );
      }

      // Если после всей валидации осталось мало фильмов, загружаем дополнительные
      if (result.length < 5) {
        print('⚠️ Still too few movies, loading additional...');
        await _loadAdditionalMoviesWithPosters(mood, result);
      }

      // Применяем ротацию
      try {
        result = await _rotationService.filterRecentlyShown(
          mood.toLowerCase(),
          result,
        );

        if (result.length < sortedMovies.length * 0.5) {
          print(
            'Rotation filtered many movies (${sortedMovies.length} → ${result.length})',
          );
        }
      } catch (e) {
        print('Error in rotation service: $e, proceeding without rotation');
      }

      if (result.length > 10) {
        try {
          result = _rotationService.addRandomness(result, 0.2);
        } catch (e) {
          print('Error adding randomness: $e');
        }
      }

      print('Found ${result.length} movies for mood: $mood');

      final finalResult = _shuffleByGroups(result.take(20).toList());

      if (finalResult.isNotEmpty) {
        try {
          await _rotationService.markMoviesAsShown(
            mood.toLowerCase(),
            finalResult.take(8).toList(),
          );
          print(
            'Marked ${min(8, finalResult.length)} movies as shown for future rotation',
          );
        } catch (e) {
          print('Error marking movies as shown: $e');
        }
      }

      if (finalResult.isEmpty) {
        print('No movies found after all processing');
        throw AppError.notFound();
      }

      print(
        'Top movies: ${finalResult.take(3).map((m) => m.title).join(", ")}',
      );

      return finalResult;
    } catch (e) {
      print('Error in getMoviesByMood: $e');
      throw _handleError(e);
    }
  }

  // 🔥 ОБНОВЛЕННЫЙ МЕТОД: Загрузка дополнительных фильмов с проверкой постеров
  Future<void> _loadAdditionalMoviesWithPosters(
    String mood,
    List<Movie> currentResults,
  ) async {
    try {
      final additionalTerms = _getBackupSearchTerms(mood);

      for (final term in additionalTerms) {
        if (currentResults.length >= 10) break;

        try {
          final movies = await _searchMovies(term);

          // Быстрая фильтрация
          final moviesWithBasicUrls = movies
              .where((movie) => movie.hasBasicPosterUrl)
              .toList();

          // Полная валидация постеров
          final validatedMovies = await _posterValidator.validateMoviePosters(
            moviesWithBasicUrls.take(10).toList(),
          );

          // Добавляем только фильмы, которых еще нет в результатах
          final existingIds = currentResults.map((m) => m.imdbID).toSet();
          final newMovies = validatedMovies
              .where((m) => !existingIds.contains(m.imdbID))
              .toList();

          currentResults.addAll(newMovies.take(5));
          print(
            '🎯 Added ${newMovies.take(5).length} additional validated movies',
          );

          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      print('Error loading additional movies: $e');
    }
  }

  List<String> _getBackupSearchTerms(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return ['comedy 2020', 'feel good movies', 'family comedy'];
      case 'romantic':
        return ['romance 2019', 'love story', 'romantic drama'];
      case 'sad':
        return ['drama 2018', 'emotional movie', 'tearjerker'];
      case 'cozy':
        return ['family movie', 'heartwarming', 'christmas'];
      case 'inspiring':
        return ['biography', 'true story', 'motivational'];
      case 'thrilling':
        return ['action 2020', 'thriller', 'suspense'];
      default:
        return ['popular movie', 'best movie', 'top rated'];
    }
  }

  Future<RotationStats> getMoodRotationStats(String mood) async {
    return await _rotationService.getRotationStats(mood);
  }

  Future<void> resetMoodRotation(String mood) async {
    await _rotationService.resetMoodHistory(mood);
  }

  Future<void> resetAllRotation() async {
    await _rotationService.resetAllHistory();
  }

  Future<String> getRotationDataSize() async {
    return await _rotationService.getRotationDataSize();
  }

  double _calculateMoodRelevance(Movie movie, String mood, double termWeight) {
    double score = termWeight;

    final keywords = _moodKeywords[mood] ?? [];
    final excludedGenres = _excludedGenres[mood] ?? [];

    if (movie.genre != null) {
      final genres = movie.genre!.toLowerCase().split(',');

      for (final excludedGenre in excludedGenres) {
        if (genres.any((g) => g.trim().contains(excludedGenre))) {
          score -= 0.3;
        }
      }

      for (final keyword in keywords) {
        if (genres.any((g) => g.trim().contains(keyword))) {
          score += 0.2;
        }
      }
    }

    if (movie.plot != null) {
      final plotLower = movie.plot!.toLowerCase();
      int keywordMatches = 0;

      for (final keyword in keywords) {
        if (plotLower.contains(keyword)) {
          keywordMatches++;
        }
      }

      score += keywordMatches * 0.1;
    }

    if (movie.rating > 7.0) {
      score += 0.2;
    } else if (movie.rating > 6.0) {
      score += 0.1;
    }

    final currentYear = DateTime.now().year;
    final movieYear = int.tryParse(movie.year);
    if (movieYear != null) {
      final movieAge = currentYear - movieYear;
      if (movieAge <= 5) {
        score += 0.1;
      } else if (movieAge <= 15) {
        score += 0.05;
      }
    }

    return max(0.0, score);
  }

  List<Movie> _shuffleByGroups(List<Movie> movies) {
    if (movies.length <= 6) {
      return movies;
    }

    final result = <Movie>[];
    result.addAll(movies.take(6));

    final remaining = movies.skip(6).toList();

    for (int i = 0; i < remaining.length; i += 4) {
      final group = remaining.skip(i).take(4).toList();
      group.shuffle();
      result.addAll(group);
    }

    return result;
  }

  Future<List<Movie>> getRandomMovies() async {
    try {
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      final randomTerms = ['movie', 'film', 'cinema', 'story', 'adventure'];
      final randomTerm = randomTerms[Random().nextInt(randomTerms.length)];

      final allMovies = await _searchMovies(randomTerm);

      // Быстрая фильтрация
      final moviesWithBasicUrls = allMovies
          .where((movie) => movie.hasBasicPosterUrl)
          .toList();

      // Полная валидация для случайных фильмов
      final validatedMovies = await _posterValidator.validateMoviePosters(
        moviesWithBasicUrls.take(15).toList(),
      );

      print(
        'Random movies: ${allMovies.length} total, ${validatedMovies.length} with valid posters',
      );

      return validatedMovies;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Movie>> _searchMovies(String searchTerm) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/?apikey=$_apiKey&s=$searchTerm&type=movie',
      );

      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          final List<dynamic> searchResults = data['Search'] ?? [];
          return await _getMovieDetailsForResults(searchResults);
        } else if (data['Error'] != null) {
          _handleApiError(data['Error']);
          return [];
        } else {
          return [];
        }
      } else {
        throw _handleHttpError(response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Movie>> _getMovieDetailsForResults(
    List<dynamic> searchResults,
  ) async {
    final List<Movie> movies = [];

    for (int i = 0; i < min(15, searchResults.length); i++) {
      try {
        final movieDetails = await getMovieDetails(searchResults[i]['imdbID']);
        if (movieDetails != null && movieDetails.hasBasicPosterUrl) {
          movies.add(movieDetails);
        }
      } catch (e) {
        continue;
      }
    }

    // Валидируем постеры для всех найденных фильмов
    return await _posterValidator.validateMoviePosters(movies);
  }

  Map<String, dynamic> getPosterValidationStats() {
    return _posterValidator.getCacheStats();
  }

  void clearPosterValidationCache() {
    _posterValidator.clearCache();
  }

  AppError _handleError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    if (error is SocketException) {
      return AppError.network();
    }

    if (error is TimeoutException) {
      return AppError.timeout();
    }

    if (error is HttpException) {
      return AppError.server();
    }

    if (error is FormatException) {
      return AppError.server();
    }

    return AppError.unknown(error.toString());
  }

  AppError _handleHttpError(int statusCode) {
    switch (statusCode) {
      case 401:
        return AppError.invalidApiKey();
      case 402:
        return AppError.apiLimit();
      case 404:
        return AppError.notFound();
      case 429:
        return AppError.apiLimit();
      case 500:
      case 502:
      case 503:
      case 504:
        return AppError.server();
      default:
        return AppError.unknown('HTTP $statusCode');
    }
  }

  void _handleApiError(String apiError) {
    final error = apiError.toLowerCase();

    if (error.contains('invalid api key')) {
      throw AppError.invalidApiKey();
    }

    if (error.contains('request limit')) {
      throw AppError.apiLimit();
    }

    if (error.contains('not found')) {
      throw AppError.notFound();
    }

    throw AppError.unknown(apiError);
  }

  Future<void> clearCache({bool clearRotation = false}) async {
    await _cacheService.clearCache();

    if (clearRotation) {
      await _rotationService.resetAllHistory();
      print('Cleared cache and rotation history');
    } else {
      print('Cleared cache (rotation history preserved)');
    }
  }

  Future<String> getCacheSize() async {
    return await _cacheService.getCacheSize();
  }

  Future<int> getCachedItemsCount() async {
    return await _cacheService.getCachedItemsCount();
  }
}

class MovieWithScore {
  final Movie movie;
  final double score;

  MovieWithScore(this.movie, this.score);
}
