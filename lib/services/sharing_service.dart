import 'package:share_plus/share_plus.dart';
import '../models/movie.dart';
import '../constants/strings.dart';

class SharingService {
  static Future<void> shareCollection({
    required Map<String, List<Movie>> favoritesByMood,
    required int totalMovies,
  }) async {
    if (totalMovies == 0) {
      // Если коллекция пуста, шерим приглашение
      await _shareInvitation();
      return;
    }

    final shareText = _buildCollectionShareText(favoritesByMood, totalMovies);

    await Share.share(
      shareText,
      subject: '${AppStrings.myCollection} ${AppStrings.appName}',
    );
  }

  static Future<void> _shareInvitation() async {
    final invitationText =
        '''🎬 ${AppStrings.discoverMoviesByMood}

${AppStrings.imUsing} ${AppStrings.appName} - ${AppStrings.usingAppDescription}

✨ ${AppStrings.searchByMoodFeature}
🎭 ${AppStrings.findByActorsFeature}  
💾 ${AppStrings.buildWatchlistFeature}
🎲 ${AppStrings.randomPicksFeature}

${AppStrings.download} ${AppStrings.appName} ${AppStrings.downloadAppTonight}''';

    await Share.share(invitationText);
  }

  static String _buildCollectionShareText(
    Map<String, List<Movie>> favoritesByMood,
    int totalMovies,
  ) {
    final buffer = StringBuffer();

    // Заголовок
    buffer.writeln('🎬 ${AppStrings.myCollection} ${AppStrings.appName}');
    buffer.writeln();
    buffer.writeln(
      '${AppStrings.curatedMoviesText} $totalMovies ${AppStrings.amazingMoviesOrganized}',
    );
    buffer.writeln();

    // Статистика по настроениям
    buffer.writeln('📊 ${AppStrings.myMovieMoods}');
    for (final entry in favoritesByMood.entries) {
      final mood = entry.key;
      final count = entry.value.length;
      final emoji = _getMoodEmoji(mood);
      buffer.writeln(
        '$emoji $mood: $count ${count == 1 ? AppStrings.movie : AppStrings.movies}',
      );
    }
    buffer.writeln();

    // Топ-3 фильма (самые высокорейтинговые)
    final topMovies = _getTopMovies(favoritesByMood, 3);
    if (topMovies.isNotEmpty) {
      buffer.writeln('⭐ ${AppStrings.someOfMyFavorites}');
      for (int i = 0; i < topMovies.length; i++) {
        final movie = topMovies[i];
        buffer.writeln(
          '${i + 1}. ${movie.title} (${movie.year}) ⭐ ${movie.rating.toStringAsFixed(1)}',
        );
      }
      buffer.writeln();
    }

    // Призыв к действию
    buffer.writeln('🎯 ${AppStrings.wantToBuildCollection}');
    buffer.writeln(
      '${AppStrings.download} ${AppStrings.appName} ${AppStrings.discoverYourMood}',
    );

    return buffer.toString();
  }

  static List<Movie> _getTopMovies(
    Map<String, List<Movie>> favoritesByMood,
    int count,
  ) {
    final allMovies = <Movie>[];
    for (final movies in favoritesByMood.values) {
      allMovies.addAll(movies);
    }

    // Сортируем по рейтингу и берем топ
    allMovies.sort((a, b) => b.rating.compareTo(a.rating));
    return allMovies.take(count).toList();
  }

  static String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😄';
      case 'romantic':
        return '💕';
      case 'sad':
        return '😢';
      case 'cozy':
        return '🏠';
      case 'inspiring':
        return '⭐';
      case 'thrilling':
        return '🔥';
      default:
        return '🎬';
    }
  }
}
