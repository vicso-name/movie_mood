import 'package:flutter/material.dart';
import '../constants/moods.dart';

class Mood {
  final MoodType type;
  final String name;
  final IconData icon;
  final int color;
  final String searchKey;

  Mood({
    required this.type,
    required this.name,
    required this.icon,
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
      'icon_code_point': icon.codePoint,
      'color': color,
      'search_key': searchKey,
    };
  }

  factory Mood.fromJson(Map<String, dynamic> json) {
    final moodType = MoodType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MoodType.happy,
    );

    final moodData = Moods.all.firstWhere(
      (mood) => mood.type == moodType,
      orElse: () => Moods.all.first,
    );

    return Mood(
      type: moodType,
      name: json['name'] ?? moodData.name,
      icon: moodData.icon,
      color: json['color'] ?? moodData.color.toARGB32(),
      searchKey: json['search_key'] ?? moodData.searchKey,
    );
  }
}
