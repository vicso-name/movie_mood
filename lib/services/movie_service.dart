import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/app_error.dart';
import '../constants/api_config.dart';
import '../data/actors_database.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class MovieService {
  static const String _baseUrl = ApiConfig.omdbBaseUrl;
  final String _apiKey = ApiConfig.omdbApiKey;
  final CacheService _cacheService = CacheService();

  // Настройки таймаутов
  static const Duration _requestTimeout = Duration(seconds: 10);

  // Расширенные поисковые запросы для настроений с весами приоритета
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

  // Ключевые слова для фильтрации по жанрам и описаниям
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

  // Жанры, которые НЕ подходят для определенных настроений
  static const Map<String, List<String>> _excludedGenres = {
    'happy': ['horror', 'war', 'thriller'],
    'romantic': ['horror', 'war', 'action'],
    'cozy': ['horror', 'thriller', 'war'],
    'inspiring': ['horror', 'comedy'],
  };

  // Поиск фильмов по актеру с обработкой ошибок
  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    if (!ActorsDatabase.isKnownActor(actorName)) {
      throw AppError.notFound();
    }

    try {
      // Сначала проверяем кеш
      final cachedMovies = await _cacheService.getCachedActorMovies(actorName);
      if (cachedMovies != null && cachedMovies.isNotEmpty) {
        return cachedMovies;
      }

      // Проверяем интернет соединение
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      // Если в кеше нет, загружаем из API
      final movieTitles = ActorsDatabase.getActorMovies(actorName);
      final List<Movie> foundMovies = [];

      for (final title in movieTitles.take(15)) {
        try {
          final movie = await _getMovieWithCache(title);
          if (movie != null) {
            // Проверяем, что актер действительно указан в составе
            if (movie.actors != null &&
                movie.actors!.toLowerCase().contains(actorName.toLowerCase())) {
              foundMovies.add(movie);
            }
          }

          // Небольшая задержка чтобы не перегружать API
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          // Продолжаем поиск других фильмов при ошибке одного
          continue;
        }
      }

      // Удаляем дубликаты
      final uniqueMovies = <String, Movie>{};
      for (final movie in foundMovies) {
        uniqueMovies[movie.imdbID] = movie;
      }

      final result = uniqueMovies.values.toList();
      result.sort((a, b) => b.rating.compareTo(a.rating));

      // Кешируем результат
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

  // Получение фильма с проверкой кеша и обработкой ошибок
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

  // Поиск точного названия фильма с таймаутом
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

  // Получение деталей фильма с обработкой ошибок
  Future<Movie?> getMovieDetails(String imdbID) async {
    try {
      // Сначала проверяем кеш
      final cachedMovie = await _cacheService.getCachedMovie(imdbID);
      if (cachedMovie != null) {
        return cachedMovie;
      }

      // Проверяем интернет соединение
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

  // УЛУЧШЕННЫЙ метод для настроений с оценкой релевантности
  Future<List<Movie>> getMoviesByMood(String mood) async {
    try {
      // Проверяем интернет соединение
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      final moodLower = mood.toLowerCase();
      final searchTerms = _moodSearchTerms[moodLower]?.entries.toList() ?? [];

      if (searchTerms.isEmpty) {
        // Fallback для неизвестных настроений
        return await getRandomMovies();
      }

      // Сортируем термины по приоритету (весу)
      searchTerms.sort((a, b) => b.value.compareTo(a.value));

      final List<MovieWithScore> allMoviesWithScores = [];

      // Ищем фильмы по каждому термину с учетом приоритета
      for (int i = 0; i < min(5, searchTerms.length); i++) {
        final entry = searchTerms[i];
        final term = entry.key;
        final termWeight = entry.value;

        try {
          final movies = await _searchMovies(term);

          for (final movie in movies) {
            final relevanceScore = _calculateMoodRelevance(
              movie,
              moodLower,
              termWeight,
            );
            allMoviesWithScores.add(MovieWithScore(movie, relevanceScore));
          }
        } catch (e) {
          // Продолжаем с другими терминами при ошибке
          continue;
        }

        // Задержка между запросами
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Убираем дубликаты, оставляя фильмы с лучшим скором
      final Map<String, MovieWithScore> uniqueMovies = {};
      for (final movieWithScore in allMoviesWithScores) {
        final existing = uniqueMovies[movieWithScore.movie.imdbID];
        if (existing == null || movieWithScore.score > existing.score) {
          uniqueMovies[movieWithScore.movie.imdbID] = movieWithScore;
        }
      }

      // Сортируем по релевантности и рейтингу
      final sortedMovies = uniqueMovies.values.toList();
      sortedMovies.sort((a, b) {
        final scoreDiff = b.score.compareTo(a.score);
        if (scoreDiff != 0) return scoreDiff;
        return b.movie.rating.compareTo(a.movie.rating);
      });

      // Возвращаем только фильмы (без скоров) с небольшим элементом случайности для разнообразия
      final result = sortedMovies.map((mws) => mws.movie).toList();

      // Берем топ результаты, но с небольшим перемешиванием в группах
      return _shuffleByGroups(result.take(20).toList());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Вычисление релевантности фильма для настроения
  double _calculateMoodRelevance(Movie movie, String mood, double termWeight) {
    double score = termWeight; // Базовый вес поискового термина

    final keywords = _moodKeywords[mood] ?? [];
    final excludedGenres = _excludedGenres[mood] ?? [];

    // Анализируем жанры
    if (movie.genre != null) {
      final genres = movie.genre!.toLowerCase().split(',');

      // Штраф за нежелательные жанры
      for (final excludedGenre in excludedGenres) {
        if (genres.any((g) => g.trim().contains(excludedGenre))) {
          score -= 0.3;
        }
      }

      // Бонус за подходящие ключевые слова в жанрах
      for (final keyword in keywords) {
        if (genres.any((g) => g.trim().contains(keyword))) {
          score += 0.2;
        }
      }
    }

    // Анализируем описание/сюжет
    if (movie.plot != null) {
      final plotLower = movie.plot!.toLowerCase();
      int keywordMatches = 0;

      for (final keyword in keywords) {
        if (plotLower.contains(keyword)) {
          keywordMatches++;
        }
      }

      // Бонус за ключевые слова в описании
      score += keywordMatches * 0.1;
    }

    // Учитываем рейтинг фильма (выше рейтинг = больше бонус)
    if (movie.rating > 7.0) {
      score += 0.2;
    } else if (movie.rating > 6.0) {
      score += 0.1;
    }

    // Учитываем возраст фильма (более новые получают небольшой бонус)
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

    return max(0.0, score); // Минимальный скор 0
  }

  // Перемешивание результатов группами для разнообразия
  List<Movie> _shuffleByGroups(List<Movie> movies) {
    if (movies.length <= 6) {
      return movies; // Если фильмов мало, не перемешиваем
    }

    final result = <Movie>[];

    // Топ 6 фильмов - берем как есть (лучшие по релевантности)
    result.addAll(movies.take(6));

    // Остальные разбиваем на группы по 4 и перемешиваем внутри групп
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
      // Проверяем интернет соединение
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      final randomTerms = ['movie', 'film', 'cinema', 'story', 'adventure'];
      final randomTerm = randomTerms[Random().nextInt(randomTerms.length)];

      return await _searchMovies(randomTerm);
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

    for (int i = 0; i < min(10, searchResults.length); i++) {
      try {
        final movieDetails = await getMovieDetails(searchResults[i]['imdbID']);
        if (movieDetails != null) {
          movies.add(movieDetails);
        }
      } catch (e) {
        // Продолжаем с другими фильмами при ошибке
        continue;
      }
    }

    return movies;
  }

  // Обработка различных типов ошибок
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

  // Методы для работы с кешем
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  Future<String> getCacheSize() async {
    return await _cacheService.getCacheSize();
  }

  Future<int> getCachedItemsCount() async {
    return await _cacheService.getCachedItemsCount();
  }
}

// Вспомогательный класс для хранения фильма с оценкой релевантности
class MovieWithScore {
  final Movie movie;
  final double score;

  MovieWithScore(this.movie, this.score);
}
