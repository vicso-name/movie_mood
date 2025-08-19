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
import '../utils/logger.dart';

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
      {
        'family': 1.0,
        'feel good': 0.9,
        'uplifting': 0.8,
        'cheerful': 0.7,
        'joyful': 0.6,
      },
      {
        'animation': 1.0,
        'musical': 0.9,
        'disney': 0.8,
        'cartoon': 0.7,
        'pixar': 0.6,
      },
    ],
    'romantic': [
      {
        'romance': 1.0,
        'love': 0.9,
        'romantic': 0.8,
        'heart': 0.7,
        'passion': 0.6,
      },
      {
        'romantic comedy': 1.0,
        'date night': 0.9,
        'couple': 0.8,
        'wedding': 0.7,
        'relationship': 0.6,
      },
      {
        'love story': 1.0,
        'soulmate': 0.9,
        'valentine': 0.8,
        'eternal love': 0.7,
        'romantic drama': 0.6,
      },
    ],
    'sad': [
      {
        'drama': 1.0,
        'emotional': 0.9,
        'tearjerker': 0.8,
        'tragic': 0.7,
        'melancholy': 0.6,
      },
      {
        'loss': 1.0,
        'grief': 0.9,
        'heartbreak': 0.8,
        'tragedy': 0.7,
        'sorrow': 0.6,
      },
      {
        'life story': 1.0,
        'difficult': 0.9,
        'struggle': 0.8,
        'painful': 0.7,
        'moving': 0.6,
      },
    ],
    'cozy': [
      {
        'family': 1.0,
        'warm': 0.9,
        'comfort': 0.8,
        'home': 0.7,
        'peaceful': 0.6,
      },
      {
        'holiday': 1.0,
        'christmas': 0.9,
        'winter': 0.8,
        'cozy': 0.7,
        'fireplace': 0.6,
      },
      {
        'nostalgic': 1.0,
        'childhood': 0.9,
        'innocent': 0.8,
        'gentle': 0.7,
        'simple': 0.6,
      },
    ],
    'inspiring': [
      {
        'biography': 1.0,
        'true story': 0.9,
        'real life': 0.8,
        'based on': 0.7,
        'documentary': 0.6,
      },
      {
        'motivational': 1.0,
        'triumph': 0.9,
        'overcome': 0.8,
        'success': 0.7,
        'achievement': 0.6,
      },
      {
        'hero': 1.0,
        'leader': 0.9,
        'courage': 0.8,
        'determination': 0.7,
        'perseverance': 0.6,
      },
    ],
    'thrilling': [
      {
        'action': 1.0,
        'adventure': 0.9,
        'exciting': 0.8,
        'fast-paced': 0.7,
        'adrenaline': 0.6,
      },
      {
        'thriller': 1.0,
        'suspense': 0.9,
        'intense': 0.8,
        'edge of seat': 0.7,
        'tension': 0.6,
      },
      {
        'spy': 1.0,
        'chase': 0.9,
        'mission': 0.8,
        'danger': 0.7,
        'espionage': 0.6,
      },
    ],
  };

  Map<String, double> _getContextualSearchTerms(String mood) {
    final groups = _moodSearchGroups[mood.toLowerCase()] ?? [];
    if (groups.isEmpty) {
      return _moodSearchTerms[mood.toLowerCase()] ?? {};
    }

    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend = now.weekday >= 6;
    final month = now.month;
    final isWinter = month == 12 || month <= 2;

    int groupIndex = 0;

    switch (mood.toLowerCase()) {
      case 'happy':
        if (hour >= 6 && hour < 12) {
          groupIndex = 0;
        } else if (hour >= 18 || isWeekend) {
          groupIndex = 1;
        } else {
          groupIndex = 2;
        }
        break;

      case 'romantic':
        if (hour >= 19 || (isWeekend && hour >= 16)) {
          groupIndex = 0;
        } else if (hour >= 12 && hour < 19) {
          groupIndex = 1;
        } else {
          groupIndex = 2;
        }
        break;

      case 'cozy':
        if (isWinter || hour >= 17) {
          groupIndex = isWinter ? 1 : 0;
        } else {
          groupIndex = 2;
        }
        break;

      case 'inspiring':
        if (hour >= 6 && hour < 12) {
          groupIndex = 1;
        } else if (isWeekend) {
          groupIndex = 0;
        } else {
          groupIndex = 2;
        }
        break;

      case 'thrilling':
        if (hour >= 6 && hour < 18) {
          groupIndex = 0;
        } else if (hour >= 18 && hour < 22) {
          groupIndex = 1;
        } else {
          groupIndex = 2;
        }
        break;

      case 'sad':
        if (hour >= 20 || isWeekend) {
          groupIndex = 0;
        } else if (hour >= 14 && hour < 18) {
          groupIndex = 1;
        } else {
          groupIndex = 2;
        }
        break;
    }

    if (Random().nextDouble() < 0.3 && groups.length > 1) {
      final availableGroups = List.generate(groups.length, (i) => i);
      availableGroups.remove(groupIndex);
      groupIndex = availableGroups[Random().nextInt(availableGroups.length)];
    }

    final selectedGroup = groups[groupIndex.clamp(0, groups.length - 1)];

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
      // 1. Создаем список Future для каждого запроса деталей фильма.
      final List<Future<Movie?>> movieFutures = imdbIds
          .map((imdbId) => getMovieDetails(imdbId.trim()))
          .toList();

      // 2. Параллельно выполняем все запросы с помощью Future.wait.
      // Это значительно ускоряет загрузку.
      final List<Movie?> results = await Future.wait(movieFutures);

      // 3. Фильтруем результаты, оставляя только фильмы с валидными постерами.
      final List<Movie> movies = results
          .where((movie) => movie != null && movie.hasValidPoster)
          .cast<Movie>()
          .toList();

      // 4. Валидируем постеры
      final validatedMovies = await _posterValidator.validateMoviePosters(
        movies,
      );

      // 5. Сортируем фильмы по рейтингу и возвращаем результат.
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

  Map<String, dynamic> getTopMoviesStats() {
    return TopMoviesDatabase.getDatabaseStats();
  }

  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    final movieTitles = ActorsDatabase.getActorMovies(actorName);

    // 1. Сразу проверяем, есть ли фильмы в базе. Если нет, выбрасываем ошибку.
    if (movieTitles.isEmpty) {
      throw AppError.notFound();
    }

    try {
      // 2. Сначала проверяем кэш для этого актера.
      final cachedMovies = await _cacheService.getCachedActorMovies(actorName);
      if (cachedMovies != null && cachedMovies.isNotEmpty) {
        return cachedMovies;
      }

      // 3. Проверяем интернет-соединение перед началом запросов.
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      // 4. Создаем список Future для параллельных запросов.
      // Используем take(15) чтобы не перегружать API
      final List<Future<Movie?>> futures = movieTitles
          .take(15)
          .map((title) => _getMovieWithCache(title))
          .toList();

      // 5. Запускаем все запросы параллельно.
      final List<Movie?> results = await Future.wait(futures);

      // 6. Фильтруем результаты: удаляем null и проверяем наличие актера.
      final List<Movie> foundMovies = results
          .where((movie) => movie != null)
          .cast<Movie>()
          .where(
            (movie) =>
                movie.actors != null &&
                movie.actors!.toLowerCase().contains(actorName.toLowerCase()),
          )
          .toList();

      // 7. Удаляем дубликаты и сортируем.
      final uniqueMovies = foundMovies.toSet().toList();
      uniqueMovies.sort((a, b) => b.rating.compareTo(a.rating));

      // 8. Кэшируем результат.
      if (uniqueMovies.isNotEmpty) {
        await _cacheService.cacheActorMovies(actorName, uniqueMovies);
      }

      return uniqueMovies;
    } catch (e) {
      // 9. Используем общий обработчик ошибок
      throw _handleError(e);
    }
  }

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
      result = result.where((movie) => movie.hasBasicPosterUrl).toList();

      // 🔥 ЭТАП 2: Проверка кешированных результатов валидации
      result = _posterValidator.validateMoviePostersSync(result);

      // 🔥 ЭТАП 3: Если фильмов мало - асинхронная валидация постеров
      if (result.length < 8) {
        final extendedList = sortedMovies
            .map((mws) => mws.movie)
            .where((movie) => movie.hasBasicPosterUrl)
            .take(20)
            .toList();

        // Валидируем постеры
        result = await _posterValidator.validateMoviePosters(extendedList);
      }

      // Если после всей валидации осталось мало фильмов, загружаем дополнительные
      if (result.length < 5) {
        await _loadAdditionalMoviesWithPosters(mood, result);
      }

      // Применяем ротацию
      try {
        result = await _rotationService.filterRecentlyShown(
          mood.toLowerCase(),
          result,
        );
      } catch (e, stackTrace) {
        logger.e(
          'Error in rotation service, proceeding without rotation',
          error: e,
          stackTrace: stackTrace,
        );
      }

      if (result.length > 10) {
        try {
          result = _rotationService.addRandomness(result, 0.2);
        } catch (e, stackTrace) {
          logger.e('Error adding randomness', error: e, stackTrace: stackTrace);
        }
      }

      final finalResult = _shuffleByGroups(result.take(20).toList());

      if (finalResult.isNotEmpty) {
        try {
          await _rotationService.markMoviesAsShown(
            mood.toLowerCase(),
            finalResult.take(8).toList(),
          );
        } catch (e, stackTrace) {
          logger.e(
            'Error marking movies as shown',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      if (finalResult.isEmpty) {
        throw AppError.notFound();
      }

      return finalResult;
    } catch (e) {
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

          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      logger.e('Error loading additional movies', error: e);
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
    final List<Future<Movie?>> futures = [];

    for (int i = 0; i < min(15, searchResults.length); i++) {
      final imdbId = searchResults[i]['imdbID'];
      futures.add(getMovieDetails(imdbId));
    }

    // Запускаем все запросы одновременно
    final List<Movie?> results = await Future.wait(futures);

    final List<Movie> movies = [];
    for (final movie in results) {
      if (movie != null && movie.hasBasicPosterUrl) {
        movies.add(movie);
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
