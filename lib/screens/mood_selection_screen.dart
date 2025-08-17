import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/moods.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../providers/movie_provider.dart';
import '../providers/favorites_provider.dart';
import 'movie_list_screen.dart';
import 'favorites_screen.dart';
import 'actor_search_screen.dart';
import 'top_movies_screen.dart'; // 🔥 НОВЫЙ ИМПОРТ
import '../widgets/custom_page_route.dart';
import '../widgets/animated_widgets.dart';

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoritesProvider>().loadFavorites();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildModernSliverAppBar(),
          _buildMoodGrid(),
          const _BottomSpacer(),
        ],
      ),
    );
  }

  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      snap: false,
      backgroundColor: AppColors.background,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      // 🔥 ОБНОВЛЕНО: Добавлены кнопки в верхнюю панель
      actions: [_buildActionButtons(), const SizedBox(width: 8)],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 16),
        expandedTitleScale: 1.0,
        title: LayoutBuilder(
          builder: (context, constraints) {
            const expandedHeight = 200.0;
            final minHeight =
                kToolbarHeight + MediaQuery.of(context).padding.top;
            final currentHeight = constraints.maxHeight;

            final progress =
                1.0 -
                ((currentHeight - minHeight) / (expandedHeight - minHeight))
                    .clamp(0.0, 1.0);

            return _buildAnimatedTitle(progress);
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.chooseYourMood,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.whatAreYouInTheMoodFor,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(double progress) {
    final titleOpacity = progress > 0.7
        ? ((progress - 0.7) / 0.3).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: titleOpacity,
      child: Text(
        AppStrings.appName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // 🔥 ОБНОВЛЕНО: Добавлена кнопка Top Movies
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Кнопка поиска по актерам
        _ActionButton(
          onPressed: _navigateToActorSearch,
          icon: Icons.person_search,
          color: AppColors.primary,
          tooltip: AppStrings.searchByActorTooltip,
        ),
        const SizedBox(width: 8),

        _ActionButton(
          onPressed: _navigateToTopMovies,
          icon: Icons.emoji_events,
          color: const Color(0xFFFFD700),
          tooltip: AppStrings.topMoviesTooltip,
        ),
        const SizedBox(width: 8),

        // Кнопка избранного
        Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            return _FavoritesButton(
              onPressed: _navigateToFavorites,
              count: favoritesProvider.favoritesCount,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoodGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(20.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          _buildGridItem,
          childCount: Moods.all.length,
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, int index) {
    const baseDelay = 300;
    const itemDelay = 80;
    final delay = Duration(milliseconds: baseDelay + (index * itemDelay));

    final mood = Moods.all[index];
    return SlideInAnimation(
      delay: delay,
      child: _MoodCard(mood: mood, onTap: () => _onMoodSelected(mood)),
    );
  }

  void _onMoodSelected(MoodData mood) {
    context.read<MovieProvider>().loadMoviesByMood(mood);
    Navigator.push(
      context,
      SlidePageRoute(
        child: const MovieListScreen(),
        direction: AxisDirection.left,
      ),
    );
  }

  void _navigateToActorSearch() {
    Navigator.push(
      context,
      SlidePageRoute(
        child: const ActorSearchScreen(),
        direction: AxisDirection.up,
      ),
    );
  }

  // 🔥 НОВЫЙ МЕТОД: Переход к топ фильмам
  void _navigateToTopMovies() {
    Navigator.push(
      context,
      SlidePageRoute(
        child: const TopMoviesScreen(),
        direction: AxisDirection.down, // Слайд сверху вниз для премиум-ощущения
      ),
    );
  }

  void _navigateToFavorites() {
    Navigator.push(context, FadePageRoute(child: const FavoritesScreen()));
  }
}

// 🔥 ОБНОВЛЕНО: Поддержка эмодзи в кнопках
class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final String? tooltip;
  final String? emoji; // 🔥 НОВОЕ: Поддержка эмодзи

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    this.tooltip,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = FloatingActionButtonAnimation(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          // 🔥 НОВОЕ: Дополнительное свечение для Top Movies
          boxShadow: emoji != null
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Icon(icon, color: color, size: 20),
            // 🔥 НОВОЕ: Эмодзи поверх иконки
            if (emoji != null)
              Positioned(
                right: -2,
                top: -2,
                child: Text(emoji!, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );

    // Добавляем Tooltip если указан
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

class _FavoritesButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int count;

  const _FavoritesButton({required this.onPressed, required this.count});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButtonAnimation(
      onPressed: onPressed,
      child: Stack(
        children: [
          _ActionButton(
            onPressed: onPressed,
            icon: Icons.favorite,
            color: AppColors.accent,
            tooltip: AppStrings.favoritesTooltip,
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatefulWidget {
  final MoodData mood;
  final VoidCallback onTap;

  const _MoodCard({required this.mood, required this.onTap});

  @override
  State<_MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<_MoodCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.mood.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.mood.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.mood.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    widget.mood.name,
                    style: TextStyle(
                      color: widget.mood.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomSpacer extends StatelessWidget {
  const _BottomSpacer();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox(height: 40));
  }
}
