import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import 'dart:math' as math;

class PosterValidationService {
  static final PosterValidationService _instance =
      PosterValidationService._internal();
  factory PosterValidationService() => _instance;
  PosterValidationService._internal();

  // Кеш проверенных URL (в памяти для сессии)
  final Map<String, bool> _validationCache = {};

  // Лимиты для избежания перегрузки
  static const Duration _requestTimeout = Duration(seconds: 2);
  static const int _maxConcurrentRequests = 8;

  // Семафор для ограничения конкурентных запросов
  int _activeRequests = 0;

  /// ОСНОВНОЙ МЕТОД: Быстрая проверка доступности изображения
  Future<bool> isImageUrlValid(String url) async {
    if (_validationCache.containsKey(url)) {
      return _validationCache[url]!;
    }

    // Ограничиваем количество одновременных запросов
    if (_activeRequests >= _maxConcurrentRequests) {
      return true;
    }

    try {
      _activeRequests++;
      // Делаем HEAD запрос
      final response = await http
          .head(
            Uri.parse(url),
            headers: {'User-Agent': 'Mozilla/5.0 (compatible; MovieApp/1.0)'},
          )
          .timeout(_requestTimeout);

      final isValid =
          response.statusCode == 200 &&
          _isImageContentType(response.headers['content-type']);
      _validationCache[url] = isValid;
      return isValid;
    } catch (e) {
      _validationCache[url] = false;
      return false;
    } finally {
      _activeRequests--;
    }
  }

  ///Валидация списка фильмов с прогрессом
  Future<List<Movie>> validateMoviePosters(
    List<Movie> movies, {
    Function(int current, int total)? onProgress,
  }) async {
    final moviesToValidate = movies.where((movie) {
      if (!movie.hasBasicPosterUrl) return false;
      if (movie.isPosterValidationCached) return movie.hasValidPoster;
      return true;
    }).toList();

    if (moviesToValidate.isEmpty) {
      return movies.where((m) => m.hasValidPoster).toList();
    }

    // ПАРАЛЛЕЛЬНАЯ валидация пачками
    final validatedMovies = <Movie>[];
    const batchSize = 8;

    for (int i = 0; i < moviesToValidate.length; i += batchSize) {
      final batch = moviesToValidate.skip(i).take(batchSize).toList();

      // Валидируем пачку параллельно
      final futures = batch.map((movie) async {
        final isValid = await isImageUrlValid(movie.poster!);
        final validatedMovie = movie.copyWithPosterValidation(isValid);
        if (isValid) {
          return validatedMovie;
        } else {
          return null;
        }
      });

      final batchResults = await Future.wait(futures);
      validatedMovies.addAll(batchResults.whereType<Movie>());
      onProgress?.call(
        math.min(i + batchSize, moviesToValidate.length),
        moviesToValidate.length,
      );
    }
    return validatedMovies;
  }

  List<Movie> validateMoviePostersSync(List<Movie> movies) {
    return movies.where((movie) {
      if (!movie.hasBasicPosterUrl) return false;
      if (movie.isPosterValidationCached) {
        return movie.hasValidPoster;
      }
      if (_validationCache.containsKey(movie.poster)) {
        final isValid = _validationCache[movie.poster!]!;
        movie.setPosterValidation(isValid);
        return isValid;
      }
      return true;
    }).toList();
  }

  bool _isImageContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.startsWith('image/');
  }

  void clearCache() {
    _validationCache.clear();
  }

  Map<String, dynamic> getCacheStats() {
    final total = _validationCache.length;
    final valid = _validationCache.values.where((v) => v).length;
    return {
      'total_checked': total,
      'valid_posters': valid,
      'invalid_posters': total - valid,
      'cache_hit_rate': total > 0
          ? (valid / total * 100).toStringAsFixed(1)
          : '0.0',
    };
  }
}
