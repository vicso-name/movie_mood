import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../models/mood.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites';
  static const String _movieMoodKey = 'movie_moods';

  Future<List<Movie>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

      return favoritesJson
          .map((movieJson) => Movie.fromJson(json.decode(movieJson)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addToFavorites(Movie movie, Mood mood) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();

      // Проверяем, нет ли уже фильма в избранном (по imdbID)
      if (favorites.any((fav) => fav.imdbID == movie.imdbID)) {
        return false;
      }

      // Добавляем фильм
      favorites.add(movie);
      final favoritesJson = favorites
          .map((movie) => json.encode(movie.toJson()))
          .toList();

      // Сохраняем связь фильм-настроение
      await _saveMovieMood(movie.imdbID, mood);

      return await prefs.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromFavorites(String imdbID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();

      favorites.removeWhere((movie) => movie.imdbID == imdbID);

      final favoritesJson = favorites
          .map((movie) => json.encode(movie.toJson()))
          .toList();

      // Удаляем связь фильм-настроение
      await _removeMovieMood(imdbID);

      return await prefs.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      return false;
    }
  }

  Future<bool> isFavorite(String imdbID) async {
    final favorites = await getFavorites();
    return favorites.any((movie) => movie.imdbID == imdbID);
  }

  Future<Map<String, List<Movie>>> getFavoritesByMood() async {
    try {
      final favorites = await getFavorites();
      final movieMoods = await _getMovieMoods();

      Map<String, List<Movie>> groupedFavorites = {};

      for (final movie in favorites) {
        final mood = movieMoods[movie.imdbID];
        final moodName = mood?.name ?? 'Other';

        groupedFavorites.putIfAbsent(moodName, () => []);
        groupedFavorites[moodName]!.add(movie);
      }

      return groupedFavorites;
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveMovieMood(String imdbID, Mood mood) async {
    final prefs = await SharedPreferences.getInstance();
    final movieMoods = await _getMovieMoods();
    movieMoods[imdbID] = mood;

    final movieMoodsJson = movieMoods.map(
      (key, value) => MapEntry(key, json.encode(value.toJson())),
    );

    await prefs.setString(_movieMoodKey, json.encode(movieMoodsJson));
  }

  Future<void> _removeMovieMood(String imdbID) async {
    final prefs = await SharedPreferences.getInstance();
    final movieMoods = await _getMovieMoods();
    movieMoods.remove(imdbID);

    final movieMoodsJson = movieMoods.map(
      (key, value) => MapEntry(key, json.encode(value.toJson())),
    );

    await prefs.setString(_movieMoodKey, json.encode(movieMoodsJson));
  }

  Future<Map<String, Mood>> _getMovieMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final movieMoodsJsonString = prefs.getString(_movieMoodKey);

      if (movieMoodsJsonString == null) return {};

      final Map<String, dynamic> movieMoodsJson = json.decode(
        movieMoodsJsonString,
      );

      return movieMoodsJson.map(
        (key, value) => MapEntry(key, Mood.fromJson(json.decode(value))),
      );
    } catch (e) {
      return {};
    }
  }
}
