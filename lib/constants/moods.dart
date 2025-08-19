import 'package:flutter/material.dart';
import 'colors.dart';
import 'strings.dart';

enum MoodType { happy, romantic, sad, cozy, inspiring, thrilling }

class MoodData {
  final MoodType type;
  final String name;
  final IconData icon;
  final Color color;
  final String searchKey;

  const MoodData({
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
    required this.searchKey,
  });
}

class Moods {
  static const List<MoodData> all = [
    MoodData(
      type: MoodType.happy,
      name: AppStrings.moodHappy,
      icon: Icons.sentiment_very_satisfied,
      color: AppColors.happy,
      searchKey: 'happy',
    ),
    MoodData(
      type: MoodType.romantic,
      name: AppStrings.moodRomantic,
      icon: Icons.favorite,
      color: AppColors.romantic,
      searchKey: 'romantic',
    ),
    MoodData(
      type: MoodType.sad,
      name: AppStrings.moodSad,
      icon: Icons.sentiment_very_dissatisfied,
      color: AppColors.sad,
      searchKey: 'sad',
    ),
    MoodData(
      type: MoodType.cozy,
      name: AppStrings.moodCozy,
      icon: Icons.weekend,
      color: AppColors.cozy,
      searchKey: 'cozy',
    ),
    MoodData(
      type: MoodType.inspiring,
      name: AppStrings.moodInspiring,
      icon: Icons.emoji_objects,
      color: AppColors.inspiring,
      searchKey: 'inspiring',
    ),
    MoodData(
      type: MoodType.thrilling,
      name: AppStrings.moodThrilling,
      icon: Icons.local_fire_department,
      color: AppColors.thrilling,
      searchKey: 'thrilling',
    ),
  ];
}
