import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class PosterValidationService {
  static final PosterValidationService _instance =
      PosterValidationService._internal();
  factory PosterValidationService() => _instance;
  PosterValidationService._internal();

  // Кеш проверенных URL (в памяти для сессии)
  final Map<String, bool> _validationCache = {};

  // Лимиты для избежания перегрузки
  static const Duration _requestTimeout = Duration(seconds: 5);
  static const int _maxConcurrentRequests = 3;

  // Семафор для ограничения конкурентных запросов
  int _activeRequests = 0;

  /// 🔥 ОСНОВНОЙ МЕТОД: Быстрая проверка доступности изображения
  Future<bool> isImageUrlValid(String url) async {
    // Проверяем кеш
    if (_validationCache.containsKey(url)) {
      return _validationCache[url]!;
    }

    // Ограничиваем количество одновременных запросов
    if (_activeRequests >= _maxConcurrentRequests) {
      // Если слишком много запросов - возвращаем true и проверим позже
      return true;
    }

    try {
      _activeRequests++;

      // Делаем HEAD запрос (быстрее чем GET)
      final response = await http
          .head(
            Uri.parse(url),
            headers: {'User-Agent': 'Mozilla/5.0 (compatible; MovieApp/1.0)'},
          )
          .timeout(_requestTimeout);

      final isValid =
          response.statusCode == 200 &&
          _isImageContentType(response.headers['content-type']);

      // Кешируем результат
      _validationCache[url] = isValid;

      return isValid;
    } catch (e) {
      // При ошибке считаем изображение недоступным
      _validationCache[url] = false;
      return false;
    } finally {
      _activeRequests--;
    }
  }

  /// 🔥 НОВЫЙ МЕТОД: Валидация списка фильмов с прогрессом
  Future<List<Movie>> validateMoviePosters(
    List<Movie> movies, {
    Function(int current, int total)? onProgress,
  }) async {
    final validatedMovies = <Movie>[];

    for (int i = 0; i < movies.length; i++) {
      final movie = movies[i];

      // Обновляем прогресс
      onProgress?.call(i + 1, movies.length);

      // Если у фильма нет базового URL - пропускаем
      if (!movie.hasBasicPosterUrl) {
        print('❌ Skipping ${movie.title}: No basic poster URL');
        continue;
      }

      // Если уже проверяли этот постер - используем кешированный результат
      if (movie.isPosterValidationCached) {
        if (movie.hasValidPoster) {
          validatedMovies.add(movie);
        } else {
          print('❌ Skipping ${movie.title}: Cached validation failed');
        }
        continue;
      }

      // Проверяем доступность изображения
      final isValid = await isImageUrlValid(movie.poster!);
      final validatedMovie = movie.copyWithPosterValidation(isValid);

      if (isValid) {
        validatedMovies.add(validatedMovie);
        print('✅ Validated ${movie.title}: Poster OK');
      } else {
        print('❌ Skipping ${movie.title}: Poster validation failed');
        print('   URL: ${movie.poster}');
      }

      // Небольшая задержка между запросами
      if (i < movies.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    print(
      '🎯 Poster validation complete: ${validatedMovies.length}/${movies.length} movies valid',
    );
    return validatedMovies;
  }

  /// 🔥 НОВЫЙ МЕТОД: Быстрая валидация (только уже известные результаты)
  List<Movie> validateMoviePostersSync(List<Movie> movies) {
    return movies.where((movie) {
      // Если нет базового URL - исключаем
      if (!movie.hasBasicPosterUrl) return false;

      // Если есть кешированный результат - используем его
      if (movie.isPosterValidationCached) {
        return movie.hasValidPoster;
      }

      // Если URL в нашем кеше валидации - проверяем
      if (_validationCache.containsKey(movie.poster)) {
        final isValid = _validationCache[movie.poster!]!;
        movie.setPosterValidation(isValid);
        return isValid;
      }

      // Иначе считаем валидным (будет проверено позже)
      return true;
    }).toList();
  }

  /// Проверка типа контента
  bool _isImageContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.startsWith('image/');
  }

  /// Очистка кеша
  void clearCache() {
    _validationCache.clear();
  }

  /// Получение статистики кеша
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
