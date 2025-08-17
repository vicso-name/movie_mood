import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../constants/moods.dart';
import '../models/movie.dart';
import '../models/app_error.dart';
import '../widgets/staggered_movie_grid.dart';
import '../providers/movie_provider.dart';
import '../widgets/adaptive_movie_card.dart';
import '../widgets/loading_widget.dart';
import 'movie_details_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  int _suggestionCount =
      0; // Ð¡Ñ‡ÐµÑ‚Ñ‡Ð¸Ðº Ð¿Ñ€ÐµÐ´Ð»Ð¾Ð¶ÐµÐ½Ð¸Ð¹ Ð´Ð»Ñ Ð°Ð½Ð°Ð»Ð¸Ñ‚Ð¸ÐºÐ¸

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<MovieProvider>(
          builder: (context, movieProvider, child) {
            final mood = movieProvider.currentMood;
            return Text(
              mood != null
                  ? '${AppStrings.moviesFor} ${mood.name}'
                  : AppStrings.randomMovies,
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<MovieProvider>().clearMovies();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<MovieProvider>(
        builder: (context, movieProvider, child) {
          switch (movieProvider.state) {
            case MovieLoadingState.loading:
              return const LoadingWidget(type: LoadingType.searchingMovies);

            case MovieLoadingState.error:
              return AppErrorWidget(
                error: movieProvider.error ?? AppError.unknown('Unknown error'),
                onRetry: () => movieProvider.retry(),
              );

            case MovieLoadingState.loaded:
              if (movieProvider.movies.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.movie_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppStrings.noResults,
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ÐžÑÐ½Ð¾Ð²Ð½Ð°Ñ ÑÐµÑ‚ÐºÐ° Ñ„Ð¸Ð»ÑŒÐ¼Ð¾Ð²
                    StaggeredMovieGrid(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      children: movieProvider.movies.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final movie = entry.value;
                        return AdaptiveMovieCard(
                          movie: movie,
                          index: index,
                          onTap: () => _onMovieTap(context, movie),
                        );
                      }).toList(),
                    ),

                    // ÐšÐ½Ð¾Ð¿ÐºÐ° "Suggest Others"
                    const SizedBox(height: 32),
                    _buildSuggestOthersButton(context, movieProvider),
                    const SizedBox(height: 24),
                  ],
                ),
              );

            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildSuggestOthersButton(
    BuildContext context,
    MovieProvider movieProvider,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Ð Ð°Ð·Ð´ÐµÐ»Ð¸Ñ‚ÐµÐ»ÑŒ
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ÐžÑÐ½Ð¾Ð²Ð½Ð°Ñ ÐºÐ½Ð¾Ð¿ÐºÐ°
          ElevatedButton(
            onPressed: movieProvider.state == MovieLoadingState.loading
                ? null
                : () => _onSuggestOthers(context, movieProvider),
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.white.withValues(alpha: 0.1);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white.withValues(alpha: 0.05);
                    }
                    return Colors.transparent;
                  }),
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 12),
                Text(
                  _getSuggestButtonText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            _getSuggestSubtitle(movieProvider),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getSuggestButtonText() {
    if (_suggestionCount == 0) {
      return AppStrings.suggestOthers;
    } else if (_suggestionCount == 1) {
      return AppStrings.showMoreOptions;
    } else {
      return AppStrings.findDifferentMovies;
    }
  }

  String _getSuggestSubtitle(MovieProvider movieProvider) {
    final mood = movieProvider.currentMood;
    if (_suggestionCount == 0) {
      return '${AppStrings.getFreshSuggestions} ${mood?.name.toLowerCase() ?? AppStrings.movieLowercase} ${AppStrings.suggestions}';
    } else if (_suggestionCount == 1) {
      return '${AppStrings.discoverMore} ${mood?.name.toLowerCase() ?? ''} ${AppStrings.moviesLowercase}';
    } else {
      return AppStrings.keepExploring;
    }
  }

  void _onSuggestOthers(
    BuildContext context,
    MovieProvider movieProvider,
  ) async {
    setState(() {
      _suggestionCount++;
    });

    final mood = movieProvider.currentMood;

    if (mood != null) {
      final moodData = Moods.all.firstWhere(
        (data) => data.type == mood.type,
        orElse: () => Moods.all.first,
      );
      await movieProvider.loadMoviesByMood(moodData);
    } else {
      await movieProvider.loadRandomMovies();
    }
  }

  void _onMovieTap(BuildContext context, Movie movie) {
    final movieProvider = context.read<MovieProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MovieDetailsScreen(movie: movie, mood: movieProvider.currentMood),
      ),
    );
  }
}
