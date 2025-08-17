import '../models/mood.dart';
import '../constants/moods.dart';
import '../constants/strings.dart';

class MoodDetector {
  static const Map<String, String> _genreToMoodMap = {
    // Happy/Comedy
    'comedy': 'happy',
    'family': 'happy',
    'animation': 'happy',
    'musical': 'happy',

    // Romantic
    'romance': 'romantic',

    // Sad/Drama
    'drama': 'sad',
    'biography': 'sad',
    'history': 'sad',
    'war': 'sad',

    // Thrilling/Action
    'action': 'thrilling',
    'thriller': 'thrilling',
    'crime': 'thrilling',
    'mystery': 'thrilling',
    'horror': 'thrilling',
    'sci-fi': 'thrilling',
    'fantasy': 'thrilling',
    'adventure': 'thrilling',

    // Inspiring
    'sport': 'inspiring',

    // Cozy
    'documentary': 'cozy',
  };

  // Ключевые слова для дополнительного анализа
  static const Map<String, List<String>> _moodKeywords = {
    'happy': [
      'comedy',
      'family',
      'animation',
      'musical',
      'fun',
      'funny',
      'laugh',
      'joy',
    ],
    'romantic': [
      'romance',
      'love',
      'romantic',
      'wedding',
      'valentine',
      'heart',
      'kiss',
    ],
    'sad': [
      'drama',
      'tragedy',
      'emotional',
      'tearjerker',
      'melancholy',
      'death',
      'loss',
    ],
    'cozy': ['family', 'holiday', 'christmas', 'home', 'comfort', 'peaceful'],
    'inspiring': [
      'biography',
      'true story',
      'motivational',
      'success',
      'hero',
      'triumph',
    ],
    'thrilling': [
      'action',
      'thriller',
      'adventure',
      'spy',
      'chase',
      'fight',
      'battle',
    ],
  };

  static Mood detectMoodFromMovie({
    required List<String> genres,
    String? title,
    String? plot,
  }) {
    final Map<String, int> moodScores = {};

    for (final genre in genres) {
      final normalizedGenre = genre.toLowerCase().trim();
      final mood = _genreToMoodMap[normalizedGenre];
      if (mood != null) {
        moodScores[mood] = (moodScores[mood] ?? 0) + 3;
      }
    }

    final searchText = '${title ?? ''} ${plot ?? ''}'.toLowerCase();

    for (final entry in _moodKeywords.entries) {
      final mood = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (searchText.contains(keyword)) {
          moodScores[mood] = (moodScores[mood] ?? 0) + 1;
        }
      }
    }

    if (moodScores.isEmpty) {
      return _getDefaultMood();
    }

    final bestMoodEntry = moodScores.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return _getMoodByType(bestMoodEntry.key);
  }

  static Mood detectMoodFromGenres(List<String> genres) {
    return detectMoodFromMovie(genres: genres);
  }

  static Mood _getMoodByType(String searchKey) {
    final moodData = Moods.all.firstWhere(
      (mood) => mood.searchKey == searchKey,
      orElse: () => Moods.all.first,
    );

    return Mood.fromMoodData(moodData);
  }

  static Mood _getDefaultMood() {
    return _getMoodByType('thrilling');
  }

  static String getDetectionExplanation({
    required List<String> genres,
    String? title,
    required String detectedMood,
  }) {
    final genreMatches = genres
        .where((g) => _genreToMoodMap[g.toLowerCase()] == detectedMood)
        .toList();

    if (genreMatches.isNotEmpty) {
      return '${AppStrings.basedOnGenres} ${genreMatches.join(', ')}';
    }

    if (title != null && title.isNotEmpty) {
      final titleKeywords = _moodKeywords[detectedMood] ?? [];
      final foundKeywords = titleKeywords
          .where((keyword) => title.toLowerCase().contains(keyword))
          .toList();

      if (foundKeywords.isNotEmpty) {
        return '${AppStrings.basedOnTitleKeywords} ${foundKeywords.join(', ')}';
      }
    }
    return AppStrings.autoDetectedCategory;
  }
}
