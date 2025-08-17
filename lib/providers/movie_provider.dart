import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/mood.dart';
import '../models/app_error.dart';
import '../services/movie_service.dart';
import '../services/poster_validation_service.dart';
import '../constants/moods.dart';

enum MovieLoadingState { idle, loading, loaded, error }

class MovieProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  List<Movie> _movies = [];
  MovieLoadingState _state = MovieLoadingState.idle;
  AppError? _error;
  Mood? _currentMood;

  String _loadingStatus = '';
  double _validationProgress = 0.0;

  List<Movie> get movies => _movies;
  MovieLoadingState get state => _state;
  AppError? get error => _error;
  String get errorMessage => _error?.userMessage ?? '';
  Mood? get currentMood => _currentMood;
  bool get canRetry => _error?.canRetry ?? true;
  String get loadingStatus => _loadingStatus;
  double get validationProgress => _validationProgress;

  Future<void> loadMoviesByMood(MoodData moodData) async {
    _setState(MovieLoadingState.loading);
    _currentMood = Mood.fromMoodData(moodData);
    _error = null;
    _loadingStatus = 'Searching for ${moodData.name.toLowerCase()} movies...';
    _validationProgress = 0.0;

    try {
      final allMovies = await _movieService.getMoviesByMood(moodData.searchKey);

      // 🔥 ОБНОВЛЕНИЕ: Финальная проверка на Provider уровне
      _movies = allMovies.where((movie) => movie.hasValidPoster).toList();

      if (_movies.isEmpty) {
        _error = AppError.notFound();
        _loadingStatus = 'No movies found with valid posters';
        _setState(MovieLoadingState.error);
        return;
      }

      _loadingStatus = 'Found ${_movies.length} movies with valid posters';
      _validationProgress = 1.0;
      _setState(MovieLoadingState.loaded);
    } catch (e) {
      if (e is AppError) {
        _error = e;
      } else {
        _error = AppError.unknown(e.toString());
      }
      _movies = [];
      _loadingStatus = 'Error loading movies';
      _setState(MovieLoadingState.error);
    }
  }

  Future<void> loadRandomMovies() async {
    _setState(MovieLoadingState.loading);
    _currentMood = null;
    _error = null;
    _loadingStatus = 'Loading random movies...';
    _validationProgress = 0.0;

    try {
      final allMovies = await _movieService.getRandomMovies();

      // 🔥 ОБНОВЛЕНИЕ: Финальная проверка на Provider уровне
      _movies = allMovies.where((movie) => movie.hasValidPoster).toList();

      if (_movies.isEmpty) {
        _error = AppError.notFound();
        _loadingStatus = 'No random movies found with valid posters';
        _setState(MovieLoadingState.error);
        return;
      }

      _loadingStatus = 'Found ${_movies.length} random movies';
      _validationProgress = 1.0;
      _setState(MovieLoadingState.loaded);
    } catch (e) {
      if (e is AppError) {
        _error = e;
      } else {
        _error = AppError.unknown(e.toString());
      }
      _movies = [];
      _loadingStatus = 'Error loading random movies';
      _setState(MovieLoadingState.error);
    }
  }

  Future<Movie?> getMovieDetails(String imdbID) async {
    try {
      final movie = await _movieService.getMovieDetails(imdbID);

      if (movie != null && !movie.hasValidPoster) {
        return null;
      }

      return movie;
    } catch (e) {
      if (e is AppError) {
        _error = e;
      } else {
        _error = AppError.unknown(e.toString());
      }
      notifyListeners();
      return null;
    }
  }

  void clearMovies() {
    _movies = [];
    _currentMood = null;
    _error = null;
    _loadingStatus = '';
    _validationProgress = 0.0;
    _setState(MovieLoadingState.idle);
  }

  void _setState(MovieLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void retry() {
    if (_currentMood != null) {
      final moodData = Moods.all.firstWhere(
        (mood) => mood.type == _currentMood!.type,
      );
      loadMoviesByMood(moodData);
    } else {
      loadRandomMovies();
    }
  }

  // 🔥 ОБНОВЛЕННЫЙ МЕТОД: Удаление проблемного фильма из списка
  void removeMovieFromList(String imdbID) {
    _movies.removeWhere((movie) => movie.imdbID == imdbID);

    if (_movies.isEmpty) {
      _loadingStatus = 'All movies removed due to poster issues';
      _error = AppError.notFound();
      _setState(MovieLoadingState.error);
    } else {
      notifyListeners();
    }
  }

  // 🔥 НОВЫЙ МЕТОД: Обновление прогресса валидации (вызывается из сервиса)
  void updateValidationProgress(int current, int total, String status) {
    _validationProgress = current / total;
    _loadingStatus = status;
    notifyListeners();
  }

  // 🔥 НОВЫЙ МЕТОД: Получение статистики валидации
  Map<String, dynamic> getPosterValidationStats() {
    return _movieService.getPosterValidationStats();
  }

  // 🔥 НОВЫЙ МЕТОД: Очистка кеша валидации постеров
  void clearPosterValidationCache() {
    _movieService.clearPosterValidationCache();
  }

  // 🔥 НОВЫЙ МЕТОД: Принудительная проверка постеров для текущих фильмов
  Future<void> recheckCurrentMoviePosters() async {
    if (_movies.isEmpty) return;

    _setState(MovieLoadingState.loading);
    _loadingStatus = 'Rechecking movie posters...';
    _validationProgress = 0.0;

    try {
      // Очищаем валидацию для текущих фильмов (сбрасываем кеш)
      for (final movie in _movies) {
        movie.resetPosterValidation(); // Сбрасываем кеш валидации
      }

      // Повторно валидируем все постеры
      final posterValidator = PosterValidationService();
      final validatedMovies = await posterValidator.validateMoviePosters(
        _movies,
        onProgress: (current, total) {
          _validationProgress = current / total;
          _loadingStatus = 'Checking poster $current of $total...';
          notifyListeners();
        },
      );

      _movies = validatedMovies;
      _loadingStatus =
          'Recheck complete: ${_movies.length} movies with valid posters';
      _validationProgress = 1.0;
      _setState(MovieLoadingState.loaded);

      if (_movies.isEmpty) {
        _error = AppError.notFound();
        _loadingStatus = 'No movies have valid posters';
        _setState(MovieLoadingState.error);
      }
    } catch (e) {
      _error = AppError.unknown('Failed to recheck posters: ${e.toString()}');
      _loadingStatus = 'Error during poster recheck';
      _setState(MovieLoadingState.error);
    }
  }
}
