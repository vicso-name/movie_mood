import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../models/streaming_availability.dart';

class CacheService {
  static const String _movieCacheKey = 'movie_cache';
  static const String _actorCacheKey = 'actor_cache';
  static const String _streamingCacheKey = 'streaming_cache';
  static const String _sourcesCacheKey = 'sources_cache';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _streamingTimestampKey = 'streaming_timestamp';
  static const String _sourcesTimestampKey = 'sources_timestamp';

  // Время жизни кеша (24 часа)
  static const Duration _cacheExpiration = Duration(hours: 24);
  // Время жизни streaming кеша (1 час)
  static const Duration _streamingCacheExpiration = Duration(hours: 1);
  // Время жизни sources кеша (24 часа)
  static const Duration _sourcesCacheExpiration = Duration(hours: 24);

  // ========== EXISTING MOVIE CACHE METHODS ==========

  // Кеширование отдельного фильма
  Future<void> cacheMovie(Movie movie) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedMovies = await _getCachedMovies();

      cachedMovies[movie.imdbID] = movie;

      final movieJsonMap = cachedMovies.map(
        (key, value) => MapEntry(key, json.encode(value.toJson())),
      );

      await prefs.setString(_movieCacheKey, json.encode(movieJsonMap));
      await _updateCacheTimestamp();
    } catch (e) {
      // Игнорируем ошибки кеширования
    }
  }

  // Получение фильма из кеша
  Future<Movie?> getCachedMovie(String imdbID) async {
    try {
      if (!await _isCacheValid()) {
        return null;
      }

      final cachedMovies = await _getCachedMovies();
      return cachedMovies[imdbID];
    } catch (e) {
      return null;
    }
  }

  // Кеширование фильмов актера
  Future<void> cacheActorMovies(String actorName, List<Movie> movies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actorCache = await _getCachedActorMovies();

      final normalizedName = actorName.toLowerCase().trim();
      actorCache[normalizedName] = movies;

      // Также кешируем каждый фильм отдельно
      for (final movie in movies) {
        await cacheMovie(movie);
      }

      final actorJsonMap = actorCache.map(
        (key, value) => MapEntry(
          key,
          value.map((movie) => json.encode(movie.toJson())).toList(),
        ),
      );

      await prefs.setString(_actorCacheKey, json.encode(actorJsonMap));
      await _updateCacheTimestamp();
    } catch (e) {
      // Игнорируем ошибки кеширования
    }
  }

  // Получение кешированных фильмов актера
  Future<List<Movie>?> getCachedActorMovies(String actorName) async {
    try {
      if (!await _isCacheValid()) {
        return null;
      }

      final actorCache = await _getCachedActorMovies();
      final normalizedName = actorName.toLowerCase().trim();

      return actorCache[normalizedName];
    } catch (e) {
      return null;
    }
  }

  // ========== NEW STREAMING CACHE METHODS ==========

  // Кеширование streaming availability
  Future<void> cacheStreamingAvailability(
    StreamingAvailability availability,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStreaming = await _getCachedStreamingAvailabilities();

      cachedStreaming[availability.imdbId] = availability;

      final streamingJsonMap = cachedStreaming.map(
        (key, value) => MapEntry(key, json.encode(value.toJson())),
      );

      await prefs.setString(_streamingCacheKey, json.encode(streamingJsonMap));
      await _updateStreamingTimestamp();
    } catch (e) {
      // Игнорируем ошибки кеширования
    }
  }

  // Получение streaming availability из кеша
  Future<StreamingAvailability?> getCachedStreamingAvailability(
    String imdbId,
  ) async {
    try {
      if (!await _isStreamingCacheValid()) {
        return null;
      }

      final cachedStreaming = await _getCachedStreamingAvailabilities();
      return cachedStreaming[imdbId];
    } catch (e) {
      return null;
    }
  }

  // Кеширование источников (платформ)
  Future<void> cacheSources(List<Map<String, dynamic>> sources) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sourcesCacheKey, json.encode(sources));
      await _updateSourcesTimestamp();
    } catch (e) {
      // Игнорируем ошибки кеширования
    }
  }

  // Получение кешированных источников
  Future<List<Map<String, dynamic>>?> getCachedSources() async {
    try {
      if (!await _isSourcesCacheValid()) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final sourcesString = prefs.getString(_sourcesCacheKey);

      if (sourcesString == null) return null;

      final List<dynamic> sourcesList = json.decode(sourcesString);
      return sourcesList.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // ========== CACHE MANAGEMENT METHODS ==========

  // Очистка всего кеша
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_movieCacheKey);
      await prefs.remove(_actorCacheKey);
      await prefs.remove(_streamingCacheKey);
      await prefs.remove(_sourcesCacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_streamingTimestampKey);
      await prefs.remove(_sourcesTimestampKey);
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  // Очистка только streaming кеша
  Future<void> clearStreamingCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_streamingCacheKey);
      await prefs.remove(_sourcesCacheKey);
      await prefs.remove(_streamingTimestampKey);
      await prefs.remove(_sourcesTimestampKey);
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  // Получение размера кеша
  Future<String> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final movieCache = prefs.getString(_movieCacheKey) ?? '{}';
      final actorCache = prefs.getString(_actorCacheKey) ?? '{}';
      final streamingCache = prefs.getString(_streamingCacheKey) ?? '{}';
      final sourcesCache = prefs.getString(_sourcesCacheKey) ?? '[]';

      final totalSize =
          movieCache.length +
          actorCache.length +
          streamingCache.length +
          sourcesCache.length;

      return _formatSize(totalSize);
    } catch (e) {
      return '0B';
    }
  }

  // Получение размера streaming кеша
  Future<String> getStreamingCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streamingCache = prefs.getString(_streamingCacheKey) ?? '{}';
      final sourcesCache = prefs.getString(_sourcesCacheKey) ?? '[]';

      final totalSize = streamingCache.length + sourcesCache.length;
      return _formatSize(totalSize);
    } catch (e) {
      return '0B';
    }
  }

  // Получение количества кешированных элементов
  Future<int> getCachedItemsCount() async {
    try {
      final movieCache = await _getCachedMovies();
      final actorCache = await _getCachedActorMovies();
      final streamingCache = await _getCachedStreamingAvailabilities();

      return movieCache.length + actorCache.length + streamingCache.length;
    } catch (e) {
      return 0;
    }
  }

  // Получение количества кешированных streaming элементов
  Future<int> getCachedStreamingItemsCount() async {
    try {
      final streamingCache = await _getCachedStreamingAvailabilities();
      return streamingCache.length;
    } catch (e) {
      return 0;
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  Future<Map<String, Movie>> _getCachedMovies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final movieCacheString = prefs.getString(_movieCacheKey);

      if (movieCacheString == null) return {};

      final Map<String, dynamic> movieJsonMap = json.decode(movieCacheString);

      return movieJsonMap.map(
        (key, value) => MapEntry(key, Movie.fromJson(json.decode(value))),
      );
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, List<Movie>>> _getCachedActorMovies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actorCacheString = prefs.getString(_actorCacheKey);

      if (actorCacheString == null) return {};

      final Map<String, dynamic> actorJsonMap = json.decode(actorCacheString);

      return actorJsonMap.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((movieJson) => Movie.fromJson(json.decode(movieJson)))
              .toList(),
        ),
      );
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, StreamingAvailability>>
  _getCachedStreamingAvailabilities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streamingCacheString = prefs.getString(_streamingCacheKey);

      if (streamingCacheString == null) return {};

      final Map<String, dynamic> streamingJsonMap = json.decode(
        streamingCacheString,
      );

      return streamingJsonMap.map(
        (key, value) =>
            MapEntry(key, StreamingAvailability.fromJson(json.decode(value))),
      );
    } catch (e) {
      return {};
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_cacheTimestampKey);

      if (timestampString == null) return false;

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();

      return now.difference(timestamp) < _cacheExpiration;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isStreamingCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_streamingTimestampKey);

      if (timestampString == null) return false;

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();

      return now.difference(timestamp) < _streamingCacheExpiration;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isSourcesCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_sourcesTimestampKey);

      if (timestampString == null) return false;

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();

      return now.difference(timestamp) < _sourcesCacheExpiration;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  Future<void> _updateStreamingTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _streamingTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  Future<void> _updateSourcesTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sourcesTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
