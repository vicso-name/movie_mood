import 'package:flutter/material.dart';
import '../constants/moods.dart';

class Mood {
  final MoodType type;
  final String name;
  final IconData icon; // Заменено emoji на icon
  final int color;
  final String searchKey;

  Mood({
    required this.type,
    required this.name,
    required this.icon, // Заменено emoji на icon
    required this.color,
    required this.searchKey,
  });

  factory Mood.fromMoodData(MoodData moodData) {
    return Mood(
      type: moodData.type,
      name: moodData.name,
      icon: moodData.icon,
      color: moodData.color.toARGB32(),
      searchKey: moodData.searchKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'icon_code_point': icon.codePoint, // Сохраняем codePoint иконки
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
      icon: IconData(
        json['icon_code_point'] ?? 0, // Создаём IconData из codePoint
        fontFamily: 'MaterialIcons',
      ),
      color: json['color'] ?? 0,
      searchKey: json['search_key'] ?? 'happy',
    );
  }
}
