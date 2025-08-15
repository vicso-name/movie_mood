import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../models/movie.dart';
import '../models/app_error.dart';
import '../widgets/staggered_movie_grid.dart';
import '../providers/search_provider.dart';
import '../data/top_movies_database.dart';
import '../widgets/adaptive_movie_card.dart';
import '../widgets/loading_widget.dart';
import 'movie_details_screen.dart';

class TopMoviesScreen extends StatefulWidget {
  const TopMoviesScreen({super.key});

  @override
  State<TopMoviesScreen> createState() => _TopMoviesScreenState();
}

class _TopMoviesScreenState extends State<TopMoviesScreen>
    with TickerProviderStateMixin {
  String? _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().clearSearch();
      _selectedCategory = null;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    context.read<SearchProvider>().clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _selectedCategory != null
                  ? TopMoviesDatabase.getCategoryInfo(
                          _selectedCategory!,
                        )?.name ??
                        'Top Movies'
                  : 'Top Movies',
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showCategoryInfo,
            ),
        ],
      ),
      body: _selectedCategory == null
          ? _buildCategorySelection()
          : _buildMovieResults(),
    );
  }

  Widget _buildCategorySelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Curated Movie Collections',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Discover the best films across different categories',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatsRow(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Popular categories
          const Text(
            'Popular Collections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...TopMoviesDatabase.getPopularCategories().map(
            (category) => _buildCategoryCard(category, isPopular: true),
          ),

          const SizedBox(height: 24),

          // All categories
          const Text(
            'All Collections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...TopMoviesDatabase.getAllCategories()
              .where(
                (cat) =>
                    !TopMoviesDatabase.getPopularCategories().contains(cat),
              )
              .map((category) => _buildCategoryCard(category)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = TopMoviesDatabase.getDatabaseStats();

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.category,
          label: 'Collections',
          value: '${stats['total_categories']}',
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          icon: Icons.movie,
          label: 'Movies',
          value: '${stats['unique_movies']}',
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          icon: Icons.star,
          label: 'Avg/Collection',
          value: '${stats['average_per_category']}',
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category, {bool isPopular = false}) {
    final info = TopMoviesDatabase.getCategoryInfo(category);
    if (info == null) return const SizedBox.shrink();

    final movieCount = TopMoviesDatabase.getMoviesForCategory(category).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectCategory(category),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isPopular
                  ? Border.all(
                      color: Color(info.color).withOpacity(0.5),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isPopular
                  ? [
                      BoxShadow(
                        color: Color(info.color).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Category emoji and color indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(info.color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(info.emoji, style: const TextStyle(fontSize: 24)),
                ),

                const SizedBox(width: 16),

                // Category info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              info.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.5),
                                ),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.movie, color: Color(info.color), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$movieCount movies',
                            style: TextStyle(
                              color: Color(info.color),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieResults() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        switch (searchProvider.state) {
          case SearchState.loading:
            return const LoadingWidget(type: LoadingType.searchingMovies);

          case SearchState.error:
            return AppErrorWidget(
              error: searchProvider.error ?? AppError.unknown('Unknown error'),
              onRetry: () => searchProvider.retry(),
            );

          case SearchState.loaded:
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMovieGrid(searchProvider.searchResults),
            );

          default:
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
        }
      },
    );
  }

  Widget _buildMovieGrid(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'No movies found in this collection',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
                context.read<SearchProvider>().clearSearch();
              },
              child: const Text('Back to Collections'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    context.read<SearchProvider>().clearSearch();
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TopMoviesDatabase.getCategoryInfo(
                              _selectedCategory!,
                            )?.name ??
                            'Movies',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${movies.length} movies found',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Movies grid
          StaggeredMovieGrid(
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            children: movies.asMap().entries.map((entry) {
              final index = entry.key;
              final movie = entry.value;
              return AdaptiveMovieCard(
                movie: movie,
                index: index,
                onTap: () => _onMovieTap(movie),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });

    // Получаем IMDb ID фильмов из выбранной категории
    final movieIds = TopMoviesDatabase.getMoviesForCategory(category);

    // Загружаем фильмы через SearchProvider
    context.read<SearchProvider>().searchTopMovies(movieIds);

    // Запускаем анимацию
    _animationController.forward();
  }

  void _onMovieTap(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movie: movie, mood: null),
      ),
    );
  }

  void _showCategoryInfo() {
    if (_selectedCategory == null) return;

    final info = TopMoviesDatabase.getCategoryInfo(_selectedCategory!);
    if (info == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Text(info.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(info.name, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          info.description,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
