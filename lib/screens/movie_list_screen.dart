import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../models/movie.dart';
import '../models/app_error.dart';
import '../widgets/staggered_movie_grid.dart';
import '../providers/movie_provider.dart';
import '../widgets/adaptive_movie_card.dart';
import '../widgets/loading_widget.dart';
import 'movie_details_screen.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

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
                  : 'Random Movies',
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
                child: StaggeredMovieGrid(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  children: movieProvider.movies.asMap().entries.map((entry) {
                    final index = entry.key;
                    final movie = entry.value;
                    return AdaptiveMovieCard(
                      movie: movie,
                      index: index,
                      onTap: () => _onMovieTap(context, movie),
                    );
                  }).toList(),
                ),
              );

            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
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
