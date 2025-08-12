import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/mood.dart';
import '../models/app_error.dart';
import '../services/movie_service.dart';
import '../constants/moods.dart';

enum MovieLoadingState { idle, loading, loaded, error }

class MovieProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  List<Movie> _movies = [];
  MovieLoadingState _state = MovieLoadingState.idle;
  AppError? _error;
  Mood? _currentMood;

  List<Movie> get movies => _movies;
  MovieLoadingState get state => _state;
  AppError? get error => _error;
  String get errorMessage => _error?.userMessage ?? '';
  Mood? get currentMood => _currentMood;
  bool get canRetry => _error?.canRetry ?? true;

  Future<void> loadMoviesByMood(MoodData moodData) async {
    _setState(MovieLoadingState.loading);
    _currentMood = Mood.fromMoodData(moodData);
    _error = null;

    try {
      _movies = await _movieService.getMoviesByMood(moodData.searchKey);
      _setState(MovieLoadingState.loaded);
    } catch (e) {
      if (e is AppError) {
        _error = e;
      } else {
        _error = AppError.unknown(e.toString());
      }
      _movies = [];
      _setState(MovieLoadingState.error);
    }
  }

  Future<void> loadRandomMovies() async {
    _setState(MovieLoadingState.loading);
    _currentMood = null;
    _error = null;

    try {
      _movies = await _movieService.getRandomMovies();
      _setState(MovieLoadingState.loaded);
    } catch (e) {
      if (e is AppError) {
        _error = e;
      } else {
        _error = AppError.unknown(e.toString());
      }
      _movies = [];
      _setState(MovieLoadingState.error);
    }
  }

  Future<Movie?> getMovieDetails(String imdbID) async {
    try {
      return await _movieService.getMovieDetails(imdbID);
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
}
