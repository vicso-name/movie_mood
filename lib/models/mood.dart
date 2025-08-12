import '../constants/moods.dart';

class Mood {
  final MoodType type;
  final String name;
  final String emoji;
  final int color;
  final String searchKey;

  Mood({
    required this.type,
    required this.name,
    required this.emoji,
    required this.color,
    required this.searchKey,
  });

  factory Mood.fromMoodData(MoodData moodData) {
    return Mood(
      type: moodData.type,
      name: moodData.name,
      emoji: moodData.emoji,
      color: moodData.color.value,
      searchKey: moodData.searchKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'emoji': emoji,
      'color': color,
      'search_key': searchKey,
    };
  }

  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      type: MoodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MoodType.happy,
      ),
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '',
      color: json['color'] ?? 0,
      searchKey: json['search_key'] ?? 'happy',
    );
  }
}
