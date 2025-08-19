import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/streaming_availability.dart';
import '../models/app_error.dart';
import '../constants/api_config.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class StreamingService {
  static const String _baseUrl = ApiConfig.watchmodeBaseUrl;
  final String _apiKey = ApiConfig.watchmodeApiKey;
  final CacheService _cacheService = CacheService();

  // Настройки таймаутов
  static const Duration _requestTimeout = Duration(seconds: 15);

  // Кэш для Watchmode ID mappings (IMDB -> Watchmode ID)
  static final Map<String, String> _idMappingCache = {};

  /// Получение streaming availability для фильма по IMDB ID
  Future<StreamingAvailability?> getStreamingAvailability(String imdbId) async {
    try {
      // Сначала проверяем кеш
      final cachedAvailability = await _cacheService
          .getCachedStreamingAvailability(imdbId);
      if (cachedAvailability != null && !cachedAvailability.isExpired) {
        return cachedAvailability;
      }

      // Проверяем интернет соединение
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      // Получаем Watchmode ID по IMDB ID
      final watchmodeId = await _getWatchmodeIdByImdb(imdbId);
      if (watchmodeId == null) {
        return null; // Фильм не найден в Watchmode
      }

      // Получаем источники streaming
      final sources = await _getTitleSources(watchmodeId);
      if (sources.isEmpty) {
        // Создаем пустой объект для кеширования "не найдено"
        final emptyAvailability = StreamingAvailability(
          imdbId: imdbId,
          subscriptionSources: [],
          purchaseSources: [],
          rentSources: [],
          freeSources: [],
          lastUpdated: DateTime.now(),
        );
        await _cacheService.cacheStreamingAvailability(emptyAvailability);
        return emptyAvailability;
      }

      // Создаем объект availability
      final availability = StreamingAvailability.fromWatchmodeJson(
        imdbId,
        sources,
      );

      // Кешируем результат
      await _cacheService.cacheStreamingAvailability(availability);

      return availability;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Поиск Watchmode ID по IMDB ID
  Future<String?> _getWatchmodeIdByImdb(String imdbId) async {
    try {
      // Проверяем локальный кеш
      if (_idMappingCache.containsKey(imdbId)) {
        return _idMappingCache[imdbId];
      }
      // НЕ убираем префикс 'tt' - попробуем с полным ID
      final searchImdbId = imdbId; // используем полный ID как есть
      final url = Uri.parse(
        '$_baseUrl/search/?apiKey=$_apiKey&search_field=imdb_id&search_value=$searchImdbId&types=movie',
      );
      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['title_results'] != null &&
            (data['title_results'] as List).isNotEmpty) {
          final firstResult = data['title_results'][0];
          final watchmodeId = firstResult['id']?.toString();

          if (watchmodeId != null) {
            _idMappingCache[imdbId] = watchmodeId;
            return watchmodeId;
          }
        }
      } else {
        throw _handleHttpError(response.statusCode);
      }

      return null;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Получение источников streaming для конкретного title
  Future<List<dynamic>> _getTitleSources(String watchmodeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/title/$watchmodeId/sources/?apiKey=$_apiKey&regions=US',
      );

      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as List<dynamic>? ?? [];
      } else {
        throw _handleHttpError(response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Поиск фильмов в Watchmode (для будущего использования)
  Future<List<Map<String, dynamic>>> searchTitles(String query) async {
    try {
      // Проверяем интернет соединение
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      final url = Uri.parse(
        '$_baseUrl/search/?apiKey=$_apiKey&search_field=name&search_value=${Uri.encodeComponent(query)}',
      );

      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['title_results'] ?? []);
      } else {
        throw _handleHttpError(response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Получение списка всех поддерживаемых источников
  Future<List<Map<String, dynamic>>> getSupportedSources() async {
    try {
      // Проверяем кеш для источников (они редко меняются)
      final cachedSources = await _cacheService.getCachedSources();
      if (cachedSources != null) {
        return cachedSources;
      }

      // Проверяем интернет соединение
      if (!await ConnectivityService.hasInternetConnection()) {
        throw AppError.network();
      }

      final url = Uri.parse('$_baseUrl/sources/?apiKey=$_apiKey');

      final response = await http.get(url).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sources = List<Map<String, dynamic>>.from(data);

        // Кешируем источники на долгое время (24 часа)
        await _cacheService.cacheSources(sources);

        return sources;
      } else {
        throw _handleHttpError(response.statusCode);
      }
    } catch (e) {
      throw _handleError(e);
    }
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
      case 429:
        return AppError.apiLimit();
      case 404:
        return AppError.notFound();
      case 500:
      case 502:
      case 503:
      case 504:
        return AppError.server();
      default:
        return AppError.unknown('HTTP $statusCode');
    }
  }

  /// Очистка кеша streaming данных
  Future<void> clearStreamingCache() async {
    await _cacheService.clearStreamingCache();
    _idMappingCache.clear();
  }

  /// Получение размера кеша
  Future<String> getStreamingCacheSize() async {
    return await _cacheService.getStreamingCacheSize();
  }

  /// Получение количества закешированных элементов
  Future<int> getCachedStreamingItemsCount() async {
    return await _cacheService.getCachedStreamingItemsCount();
  }
}
