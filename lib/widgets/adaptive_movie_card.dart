import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../constants/colors.dart';
import '../providers/movie_provider.dart';
import 'animated_widgets.dart';

class AdaptiveMovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onTap;
  final int index;

  const AdaptiveMovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<AdaptiveMovieCard> createState() => _AdaptiveMovieCardState();
}

class _AdaptiveMovieCardState extends State<AdaptiveMovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hideController;
  late Animation<double> _hideAnimation;
  bool _isHiding = false;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _hideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hideController.dispose();
    super.dispose();
  }

  // 🔥 НОВЫЙ МЕТОД: Скрытие карточки с анимацией
  void _hideCardWithAnimation() {
    if (_isHiding) return;

    setState(() {
      _isHiding = true;
    });

    _hideController.forward().then((_) {
      // После анимации удаляем фильм из списка
      if (mounted) {
        context.read<MovieProvider>().removeMovieFromList(widget.movie.imdbID);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hideAnimation,
      builder: (context, child) {
        // Если карточка скрывается - применяем анимацию
        if (_isHiding) {
          return Transform.scale(
            scale: _hideAnimation.value,
            child: Opacity(opacity: _hideAnimation.value, child: child),
          );
        }
        return child!;
      },
      child: AnimatedMovieCard(
        index: widget.index,
        child: PulseAnimationButton(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔥 УЛУЧШЕННЫЙ ПОСТЕР: С реактивным скрытием при ошибке
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: _buildPosterImage(),
                  ),
                ),

                // Информация о фильме
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Название фильма
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Рейтинг и год
                      Row(
                        children: [
                          if (widget.movie.year.isNotEmpty) ...[
                            Text(
                              widget.movie.year,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (widget.movie.year.isNotEmpty &&
                              widget.movie.rating > 0)
                            const SizedBox(width: 12),
                          if (widget.movie.rating > 0) ...[
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.movie.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Жанры
                      if (widget.movie.genreList.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.movie.genreList.take(2).join(', '),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 НОВЫЙ МЕТОД: Улучшенное построение изображения постера
  Widget _buildPosterImage() {
    // Если у фильма нет валидного постера - показываем placeholder сразу
    if (!widget.movie.hasValidPoster) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: widget.movie.poster!,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // Обновляем валидацию постера в модели
        widget.movie.setPosterValidation(false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isHiding) {
            _hideCardWithAnimation();
          }
        });
        return _buildPlaceholder();
      },
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0 (compatible; MovieApp/1.0)',
      },
    );
  }

  // 🔥 НОВЫЙ МЕТОД: Стандартный placeholder
  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie, color: Colors.white54, size: 32),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.movie.title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
