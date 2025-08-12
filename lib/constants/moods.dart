import 'package:flutter/material.dart';
import 'colors.dart';
import 'strings.dart';

enum MoodType { happy, romantic, sad, cozy, inspiring, thrilling }

class MoodData {
  final MoodType type;
  final String name;
  final String emoji;
  final Color color;
  final String searchKey;

  const MoodData({
    required this.type,
    required this.name,
    required this.emoji,
    required this.color,
    required this.searchKey,
  });
}

class Moods {
  static const List<MoodData> all = [
    MoodData(
      type: MoodType.happy,
      name: AppStrings.moodHappy,
      emoji: '😄',
      color: AppColors.happy,
      searchKey: 'happy',
    ),
    MoodData(
      type: MoodType.romantic,
      name: AppStrings.moodRomantic,
      emoji: '💕',
      color: AppColors.romantic,
      searchKey: 'romantic',
    ),
    MoodData(
      type: MoodType.sad,
      name: AppStrings.moodSad,
      emoji: '😢',
      color: AppColors.sad,
      searchKey: 'sad',
    ),
    MoodData(
      type: MoodType.cozy,
      name: AppStrings.moodCozy,
      emoji: '🏠',
      color: AppColors.cozy,
      searchKey: 'cozy',
    ),
    MoodData(
      type: MoodType.inspiring,
      name: AppStrings.moodInspiring,
      emoji: '⭐',
      color: AppColors.inspiring,
      searchKey: 'inspiring',
    ),
    MoodData(
      type: MoodType.thrilling,
      name: AppStrings.moodThrilling,
      emoji: '🔥',
      color: AppColors.thrilling,
      searchKey: 'thrilling',
    ),
  ];
}
