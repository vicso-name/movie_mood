import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../models/mood.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../providers/favorites_provider.dart';
import '../utils/mood_detector.dart';
import '../widgets/streaming_availability_widget.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;
  final Mood? mood;

  const MovieDetailsScreen({super.key, required this.movie, this.mood});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;

  // Константы для градиентов
  static const double _appBarHeight = 300.0;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final isFavorite = await context.read<FavoritesProvider>().isFavorite(
      widget.movie.imdbID,
    );
    if (mounted) {
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [_buildSliverAppBar(), _buildMovieContent()],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _appBarHeight,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: _AppBarButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        _FavoriteButton(
          isFavorite: _isFavorite,
          isLoading: _isLoading,
          onPressed: _toggleFavorite,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _PosterWithGradients(posterUrl: widget.movie.fullPosterUrl),
      ),
    );
  }

  Widget _buildMovieContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MovieHeader(movie: widget.movie),
            const SizedBox(height: 16),
            _GenreChips(genres: widget.movie.genreList),
            const SizedBox(height: 20),
            _MoviePlot(plot: widget.movie.plot),
            const SizedBox(height: 20),
            _CrewInfo(movie: widget.movie),
            const SizedBox(height: 20),
            StreamingAvailabilityWidget(
              imdbId: widget.movie.imdbID,
              movieTitle: widget.movie.title,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);

    final favoritesProvider = context.read<FavoritesProvider>();
    bool success;

    if (_isFavorite) {
      // Удаление из избранного
      success = await favoritesProvider.removeFromFavorites(
        widget.movie.imdbID,
      );
    } else {
      // Добавление в избранное
      Mood moodToUse;

      if (widget.mood != null) {
        // Если есть настроение из контекста - используем его
        moodToUse = widget.mood!;
      } else {
        // Автоматически определяем настроение
        moodToUse = MoodDetector.detectMoodFromMovie(
          genres: widget.movie.genreList,
          title: widget.movie.title,
          plot: widget.movie.plot,
        );

        // Показываем пользователю что категория была определена автоматически
        _showAutoDetectionSnackBar(moodToUse);
      }

      success = await favoritesProvider.addToFavorites(widget.movie, moodToUse);
    }

    if (success && mounted) {
      setState(() => _isFavorite = !_isFavorite);
      if (_isFavorite) {
        // Показываем сообщение только при добавлении, снэкбар уже показан выше
      } else {
        _showFavoriteSnackBar();
      }
    }

    setState(() => _isLoading = false);
  }

  void _showAutoDetectionSnackBar(Mood detectedMood) {
    final explanation = MoodDetector.getDetectionExplanation(
      genres: widget.movie.genreList,
      title: widget.movie.title,
      detectedMood: detectedMood.type.name,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(detectedMood.emoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.addedToCategory} "${detectedMood.name}" ${AppStrings.categoryText}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showFavoriteSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.removedFromFavorites),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Компоненты UI
class _PosterWithGradients extends StatelessWidget {
  final String posterUrl;

  const _PosterWithGradients({required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _PosterImage(posterUrl: posterUrl),
        _TopGradient(),
        _BottomGradient(),
      ],
    );
  }
}

class _PosterImage extends StatelessWidget {
  final String posterUrl;

  const _PosterImage({required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: posterUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.background,
        child: const Icon(Icons.movie, color: Colors.white54, size: 80),
      ),
    );
  }
}

class _TopGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120, // Высота верхнего градиента
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0.8), // Темный сверху
              AppColors.background.withValues(alpha: 0.6),
              AppColors.background.withValues(alpha: 0.3),
              Colors.transparent, // Прозрачный снизу
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 100, // Высота нижнего градиента
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.background.withValues(alpha: 0.4),
              AppColors.background.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AppBarButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final bool isLoading;
  final VoidCallback onPressed;

  const _FavoriteButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.accent : Colors.white,
              ),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}

class _MovieHeader extends StatelessWidget {
  final Movie movie;

  const _MovieHeader({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _MovieMetadata(movie: movie),
      ],
    );
  }
}

class _MovieMetadata extends StatelessWidget {
  final Movie movie;

  const _MovieMetadata({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        if (movie.rating > 0) _RatingChip(rating: movie.rating),
        if (movie.year.isNotEmpty) _MetadataText(text: movie.year),
        if (movie.runtime != null) _MetadataText(text: movie.runtime!),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;

  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetadataText extends StatelessWidget {
  final String text;

  const _MetadataText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 16),
    );
  }
}

class _GenreChips extends StatelessWidget {
  final List<String> genres;

  const _GenreChips({required this.genres});

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) => _GenreChip(genre: genre)).toList(),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String genre;

  const _GenreChip({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        genre,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MoviePlot extends StatelessWidget {
  final String? plot;

  const _MoviePlot({required this.plot});

  @override
  Widget build(BuildContext context) {
    if (plot == null || plot!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: AppStrings.overview),
        const SizedBox(height: 8),
        Text(
          plot!,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CrewInfo extends StatelessWidget {
  final Movie movie;

  const _CrewInfo({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movie.director != null) ...[
          _InfoRow(label: AppStrings.director, value: movie.director!),
          const SizedBox(height: 12),
        ],
        if (movie.actors != null) ...[
          _InfoRow(label: AppStrings.cast, value: movie.actors!),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
