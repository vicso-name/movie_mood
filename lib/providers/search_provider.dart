import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/app_error.dart';
import '../services/movie_service.dart';
import '../data/actors_database.dart';

enum SearchState { idle, loading, loaded, error }

class SearchProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  List<Movie> _searchResults = [];
  SearchState _state = SearchState.idle;
  AppError? _error;
  String _currentActor = '';
  bool _isFromCache = false;

  List<Movie> get searchResults => _searchResults;
  SearchState get state => _state;
  AppError? get error => _error;
  String get errorMessage => _error?.userMessage ?? '';
  String get currentActor => _currentActor;
  bool get isFromCache => _isFromCache;
  bool get canRetry => _error?.canRetry ?? true;

  Future<void> searchMovies(String actorName) async {
    if (actorName.trim().isEmpty) {
      clearSearch();
      return;
    }

    _currentActor = actorName;
    _error = null;
    _setState(SearchState.loading);

    try {
      final startTime = DateTime.now();
      _searchResults = await _movieService.searchMoviesByActor(actorName);
      final loadTime = DateTime.now().difference(startTime);

      // Определяем, были ли данные загружены из кеша (быстро = из кеша)
      _isFromCache = loadTime.inMilliseconds < 1000;

      _setState(SearchState.loaded);
    } catch (e) {
      if (e is AppError) {
        _error = e;
      } else {
        _error = AppError.unknown(e.toString());
      }
      _isFromCache = false;
      _searchResults = [];
      _setState(SearchState.error);
    }
  }

  void clearSearch() {
    _searchResults = [];
    _currentActor = '';
    _isFromCache = false;
    _error = null;
    _setState(SearchState.idle);
  }

  void _setState(SearchState newState) {
    _state = newState;
    notifyListeners();
  }

  void retry() {
    if (_currentActor.isNotEmpty) {
      searchMovies(_currentActor);
    }
  }

  // Получение списка популярных актеров
  List<String> getPopularActors() {
    return ActorsDatabase.getPopularActors();
  }

  // Проверка, известен ли актер
  bool isKnownActor(String actorName) {
    return ActorsDatabase.isKnownActor(actorName);
  }

  // Методы для работы с кешем
  Future<void> clearCache() async {
    await _movieService.clearCache();
    notifyListeners();
  }

  Future<String> getCacheSize() async {
    return await _movieService.getCacheSize();
  }

  Future<int> getCachedItemsCount() async {
    return await _movieService.getCachedItemsCount();
  }
}
