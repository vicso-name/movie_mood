import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/mood.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();

  List<Movie> _favorites = [];
  Map<String, List<Movie>> _favoritesByMood = {};
  bool _isLoading = false;

  List<Movie> get favorites => _favorites;
  Map<String, List<Movie>> get favoritesByMood => _favoritesByMood;
  bool get isLoading => _isLoading;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _favoritesService.getFavorites();
      _favoritesByMood = await _favoritesService.getFavoritesByMood();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToFavorites(Movie movie, Mood mood) async {
    final success = await _favoritesService.addToFavorites(movie, mood);

    if (success) {
      _favorites.add(movie);

      final moodName = mood.name;
      _favoritesByMood.putIfAbsent(moodName, () => []);
      _favoritesByMood[moodName]!.add(movie);

      notifyListeners();
    }

    return success;
  }

  Future<bool> removeFromFavorites(String imdbID) async {
    final success = await _favoritesService.removeFromFavorites(imdbID);

    if (success) {
      _favorites.removeWhere((movie) => movie.imdbID == imdbID);

      // Remove from mood groups
      for (final key in _favoritesByMood.keys) {
        _favoritesByMood[key]!.removeWhere((movie) => movie.imdbID == imdbID);
        if (_favoritesByMood[key]!.isEmpty) {
          _favoritesByMood.remove(key);
        }
      }

      notifyListeners();
    }

    return success;
  }

  Future<bool> isFavorite(String imdbID) async {
    return await _favoritesService.isFavorite(imdbID);
  }

  bool isFavoriteSync(String imdbID) {
    return _favorites.any((movie) => movie.imdbID == imdbID);
  }

  int get favoritesCount => _favorites.length;

  bool get hasFavorites => _favorites.isNotEmpty;
}
