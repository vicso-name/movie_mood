import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../providers/favorites_provider.dart';
import '../widgets/compact_movie_card.dart';
import '../widgets/loading_widget.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.favorites)),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const LoadingWidget(message: AppStrings.loading);
          }

          if (!favoritesProvider.hasFavorites) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 80,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 20),
                    Text(
                      AppStrings.noFavorites,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      AppStrings.addSomeMovies,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final favoritesByMood = favoritesProvider.favoritesByMood;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favoritesByMood.length,
            itemBuilder: (context, index) {
              final moodName = favoritesByMood.keys.elementAt(index);
              final movies = favoritesByMood[moodName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mood section header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          moodName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${movies.length}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Horizontal movie list
                  SizedBox(
                    height:
                        250, // Увеличиваем высоту для более длинных названий
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: movies.length,
                      itemBuilder: (context, movieIndex) {
                        final movie = movies[movieIndex];

                        return Container(
                          width: 130,
                          margin: EdgeInsets.only(
                            right: movieIndex < movies.length - 1 ? 12 : 0,
                          ),
                          child: CompactMovieCard(
                            movie: movie,
                            onTap: () => _onMovieTap(context, movie),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _onMovieTap(BuildContext context, movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movie: movie,
          mood: null, // No mood context in favorites
        ),
      ),
    );
  }
}
