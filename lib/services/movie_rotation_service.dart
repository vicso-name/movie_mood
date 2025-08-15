import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class MovieRotationService {
  static const String _rotationKeyPrefix = 'movie_rotation_';
  static const String _lastRotationKeyPrefix = 'last_rotation_';
  static const String _rotationCountKeyPrefix = 'rotation_count_';

  // Максимальное количество фильмов в истории для каждого настроения
  static const int _maxHistorySize = 30;

  // Время жизни ротации (24 часа)
  static const Duration _rotationResetTime = Duration(hours: 24);

  // Минимальное время между повторами одного и того же фильма (6 часов)
  static const Duration _minimumRepeatInterval = Duration(hours: 6);

  /// Помечает фильмы как показанные для определенного настроения
  Future<void> markMoviesAsShown(String mood, List<Movie> movies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedMood = mood.toLowerCase().trim();

      // Получаем текущую историю
      final currentHistory = await _getShownMovieHistory(normalizedMood);

      // Добавляем новые фильмы с временными метками
      final now = DateTime.now();
      for (final movie in movies) {
        currentHistory[movie.imdbID] = now.millisecondsSinceEpoch;
      }

      // Ограничиваем размер истории
      final limitedHistory = _limitHistorySize(currentHistory);

      // Сохраняем обновленную историю
      await prefs.setString(
        '$_rotationKeyPrefix$normalizedMood',
        json.encode(limitedHistory),
      );

      // Обновляем время последней ротации
      await prefs.setString(
        '$_lastRotationKeyPrefix$normalizedMood',
        now.toIso8601String(),
      );

      // Увеличиваем счетчик ротаций
      final currentCount =
          prefs.getInt('$_rotationCountKeyPrefix$normalizedMood') ?? 0;
      await prefs.setInt(
        '$_rotationCountKeyPrefix$normalizedMood',
        currentCount + 1,
      );
    } catch (e) {
      // Игнорируем ошибки ротации - это не критично для функциональности
    }
  }

  /// Фильтрует список фильмов, исключая недавно показанные
  Future<List<Movie>> filterRecentlyShown(
    String mood,
    List<Movie> movies,
  ) async {
    try {
      final normalizedMood = mood.toLowerCase().trim();

      // Проверяем нужно ли сбросить историю
      await _resetHistoryIfNeeded(normalizedMood);

      // Получаем историю показанных фильмов
      final shownHistory = await _getShownMovieHistory(normalizedMood);

      if (shownHistory.isEmpty) {
        return movies;
      }

      // Определяем минимальное время для повтора
      final now = DateTime.now();
      final minimumTime = now
          .subtract(_minimumRepeatInterval)
          .millisecondsSinceEpoch;

      // Фильтруем фильмы
      final filteredMovies = movies.where((movie) {
        final lastShownTime = shownHistory[movie.imdbID];

        // Если фильм не показывался - включаем
        if (lastShownTime == null) return true;

        // Если прошло достаточно времени - включаем
        return lastShownTime < minimumTime;
      }).toList();

      // Если отфильтровали слишком много, возвращаем часть старых
      if (filteredMovies.length < movies.length * 0.3) {
        return _mixOldAndNew(movies, filteredMovies, shownHistory, minimumTime);
      }

      return filteredMovies;
    } catch (e) {
      // При ошибке возвращаем исходный список
      return movies;
    }
  }

  /// Добавляет случайность в результаты для разнообразия
  List<Movie> addRandomness(List<Movie> movies, double randomnessFactor) {
    if (movies.length <= 1 || randomnessFactor <= 0) {
      return movies;
    }

    final random = Random();
    final result = List<Movie>.from(movies);

    // Применяем случайное перемешивание к части списка
    final shuffleCount = (movies.length * randomnessFactor * 0.3).round();

    for (int i = 0; i < shuffleCount && i < result.length - 1; i++) {
      final swapIndex = i + random.nextInt(result.length - i);
      if (swapIndex != i) {
        final temp = result[i];
        result[i] = result[swapIndex];
        result[swapIndex] = temp;
      }
    }

    return result;
  }

  /// Получает статистику ротации для настроения
  Future<RotationStats> getRotationStats(String mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedMood = mood.toLowerCase().trim();

      final history = await _getShownMovieHistory(normalizedMood);
      final rotationCount =
          prefs.getInt('$_rotationCountKeyPrefix$normalizedMood') ?? 0;
      final lastRotationString = prefs.getString(
        '$_lastRotationKeyPrefix$normalizedMood',
      );

      DateTime? lastRotation;
      if (lastRotationString != null) {
        lastRotation = DateTime.tryParse(lastRotationString);
      }

      return RotationStats(
        mood: mood,
        totalShownMovies: history.length,
        rotationCount: rotationCount,
        lastRotation: lastRotation,
      );
    } catch (e) {
      return RotationStats(
        mood: mood,
        totalShownMovies: 0,
        rotationCount: 0,
        lastRotation: null,
      );
    }
  }

  /// Сбрасывает историю для определенного настроения
  Future<void> resetMoodHistory(String mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedMood = mood.toLowerCase().trim();

      await prefs.remove('$_rotationKeyPrefix$normalizedMood');
      await prefs.remove('$_lastRotationKeyPrefix$normalizedMood');
      await prefs.remove('$_rotationCountKeyPrefix$normalizedMood');
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Сбрасывает всю историю ротации
  Future<void> resetAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final rotationKeys = keys
          .where(
            (key) =>
                key.startsWith(_rotationKeyPrefix) ||
                key.startsWith(_lastRotationKeyPrefix) ||
                key.startsWith(_rotationCountKeyPrefix),
          )
          .toList();

      for (final key in rotationKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Получает общий размер данных ротации
  Future<String> getRotationDataSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int totalSize = 0;
      for (final key in keys) {
        if (key.startsWith(_rotationKeyPrefix) ||
            key.startsWith(_lastRotationKeyPrefix) ||
            key.startsWith(_rotationCountKeyPrefix)) {
          final value = prefs.getString(key) ?? '';
          totalSize += value.length;
        }
      }

      return _formatSize(totalSize);
    } catch (e) {
      return '0B';
    }
  }

  // PRIVATE METHODS

  /// Получает историю показанных фильмов для настроения
  Future<Map<String, int>> _getShownMovieHistory(String mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('$_rotationKeyPrefix$mood');

      if (historyString == null) return {};

      final Map<String, dynamic> historyJson = json.decode(historyString);
      return historyJson.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  /// Ограничивает размер истории, удаляя самые старые записи
  Map<String, int> _limitHistorySize(Map<String, int> history) {
    if (history.length <= _maxHistorySize) {
      return history;
    }

    // Сортируем по времени и оставляем только последние записи
    final sortedEntries = history.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final limitedEntries = sortedEntries.take(_maxHistorySize);
    return Map.fromEntries(limitedEntries);
  }

  /// Сбрасывает историю если прошло много времени
  Future<void> _resetHistoryIfNeeded(String mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRotationString = prefs.getString(
        '$_lastRotationKeyPrefix$mood',
      );

      if (lastRotationString == null) return;

      final lastRotation = DateTime.tryParse(lastRotationString);
      if (lastRotation == null) return;

      final now = DateTime.now();
      if (now.difference(lastRotation) > _rotationResetTime) {
        await resetMoodHistory(mood);
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Смешивает старые и новые фильмы когда отфильтровано слишком много
  List<Movie> _mixOldAndNew(
    List<Movie> allMovies,
    List<Movie> newMovies,
    Map<String, int> shownHistory,
    int minimumTime,
  ) {
    // Получаем старые фильмы, которые можно показать снова
    final oldMovies = allMovies.where((movie) {
      final lastShownTime = shownHistory[movie.imdbID];
      return lastShownTime != null && lastShownTime < minimumTime;
    }).toList();

    // Сортируем старые фильмы по времени последнего показа (старые первыми)
    oldMovies.sort((a, b) {
      final timeA = shownHistory[a.imdbID] ?? 0;
      final timeB = shownHistory[b.imdbID] ?? 0;
      return timeA.compareTo(timeB);
    });

    // Смешиваем: 70% новых, 30% старых
    final result = <Movie>[];
    result.addAll(newMovies);

    final oldToAdd = (allMovies.length * 0.3).round();
    result.addAll(oldMovies.take(oldToAdd));

    return result;
  }

  /// Форматирует размер в читаемый вид
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

/// Статистика ротации для настроения
class RotationStats {
  final String mood;
  final int totalShownMovies;
  final int rotationCount;
  final DateTime? lastRotation;

  const RotationStats({
    required this.mood,
    required this.totalShownMovies,
    required this.rotationCount,
    this.lastRotation,
  });

  @override
  String toString() {
    return 'RotationStats(mood: $mood, shown: $totalShownMovies, rotations: $rotationCount, last: $lastRotation)';
  }
}
