import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../providers/favorites_provider.dart';
import '../widgets/compact_movie_card.dart';
import '../widgets/loading_widget.dart';
import '../services/sharing_service.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.favorites),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              return IconButton(
                onPressed: () => _shareCollection(context, favoritesProvider),
                icon: const Icon(Icons.share),
                tooltip: AppStrings.shareCollection,
              );
            },
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const LoadingWidget(message: AppStrings.loading);
          }

          if (!favoritesProvider.hasFavorites) {
            return _buildEmptyState(context);
          }

          final favoritesByMood = favoritesProvider.favoritesByMood;

          return Column(
            children: [
              // Collection stats header
              _buildCollectionHeader(context, favoritesProvider),

              // Movies list
              Expanded(
                child: ListView.builder(
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
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
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: movies.length,
                            itemBuilder: (context, movieIndex) {
                              final movie = movies[movieIndex];

                              return Container(
                                width: 130,
                                margin: EdgeInsets.only(
                                  right: movieIndex < movies.length - 1
                                      ? 12
                                      : 0,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_outline, size: 80, color: Colors.white54),
            const SizedBox(height: 20),
            const Text(
              AppStrings.noFavorites,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.addSomeMovies,
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Share button даже при пустой коллекции для приглашения друзей
            OutlinedButton.icon(
              onPressed: () => _shareCollection(context, null),
              icon: const Icon(Icons.share, color: AppColors.primary),
              label: const Text(
                AppStrings.inviteFriends,
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionHeader(
    BuildContext context,
    FavoritesProvider favoritesProvider,
  ) {
    final totalMovies = favoritesProvider.favoritesCount;
    final moodCount = favoritesProvider.favoritesByMood.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.myCollection,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalMovies ${totalMovies == 1 ? AppStrings.movie : AppStrings.movies}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$moodCount ${moodCount == 1 ? AppStrings.mood : AppStrings.moods}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _shareCollection(context, favoritesProvider),
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: AppStrings.shareCollection,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCollection(
    BuildContext context,
    FavoritesProvider? favoritesProvider,
  ) async {
    try {
      if (favoritesProvider == null || !favoritesProvider.hasFavorites) {
        // Пустая коллекция - шерим приглашение
        await SharingService.shareCollection(
          favoritesByMood: {},
          totalMovies: 0,
        );
      } else {
        // Шерим коллекцию
        await SharingService.shareCollection(
          favoritesByMood: favoritesProvider.favoritesByMood,
          totalMovies: favoritesProvider.favoritesCount,
        );
      }
    } catch (e) {
      // Обработка ошибок
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.failedToShare}: ${e.toString()}'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
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
