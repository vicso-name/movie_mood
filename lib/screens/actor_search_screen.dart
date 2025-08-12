import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../models/movie.dart';
import '../models/app_error.dart';
import '../widgets/staggered_movie_grid.dart';
import '../providers/search_provider.dart';
import '../data/actors_database.dart';
import '../widgets/adaptive_movie_card.dart';
import '../widgets/loading_widget.dart';
import 'movie_details_screen.dart';

class ActorSearchScreen extends StatefulWidget {
  const ActorSearchScreen({super.key});

  @override
  State<ActorSearchScreen> createState() => _ActorSearchScreenState();
}

class _ActorSearchScreenState extends State<ActorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _currentActor;
  List<String> _suggestions = []; // Добавили список подсказок
  bool _showSuggestions = false; // Флаг показа подсказок

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().clearSearch();
      _searchController.clear();
      _currentActor = null;
      _suggestions = []; // Очищаем подсказки
      _showSuggestions = false;
      setState(() {});
    });
  }

  @override
  void dispose() {
    context.read<SearchProvider>().clearSearch();
    _searchController.clear();
    _currentActor = null;
    _suggestions = []; // Очищаем подсказки
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Новый метод обработки изменений в поле поиска
  void _onSearchChanged(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _suggestions = [];
        _showSuggestions = false;
      } else {
        _suggestions = ActorsDatabase.searchActors(value);
        _showSuggestions = _suggestions.isNotEmpty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.searchByActor),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          // Search bar с автодополнением
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              // Изменили на Column для подсказок
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: AppStrings.actorSearchHint,
                    prefixIcon: const Icon(
                      Icons.person_search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _currentActor = null;
                              _suggestions = []; // Очищаем подсказки
                              _showSuggestions = false;
                              context.read<SearchProvider>().clearSearch();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      _searchActor(query);
                    }
                  },
                  onChanged: _onSearchChanged,
                ),

                // Dropdown с подсказками
                if (_showSuggestions && _suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _suggestions.map((suggestion) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          title: Text(
                            suggestion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.search,
                            color: Colors.white54,
                            size: 16,
                          ),
                          onTap: () {
                            _searchController.text = suggestion;
                            _showSuggestions = false;
                            _searchActor(suggestion);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                switch (searchProvider.state) {
                  case SearchState.idle:
                    return _buildActorSuggestions();

                  case SearchState.loading:
                    return LoadingWidget(type: LoadingType.actorSearch);

                  case SearchState.error:
                    return AppErrorWidget(
                      error:
                          searchProvider.error ??
                          AppError.unknown('Unknown error'),
                      onRetry: () => searchProvider.retry(),
                    );

                  case SearchState.loaded:
                    return _buildActorResults(searchProvider);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActorSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Actor Search',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Search for movies by your favorite actors. Start typing to see suggestions!', // Обновили текст
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Popular actors
          const Text(
            AppStrings.popularActors,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ActorsDatabase.getPopularActors().map((actor) {
              return _buildActorChip(actor);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActorResults(SearchProvider searchProvider) {
    if (searchProvider.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                _currentActor != null
                    ? '${AppStrings.noActorResults}\n$_currentActor'
                    : AppStrings.actorNotFound,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.addMoreActors,
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _currentActor = null;
                  _suggestions = []; // Очищаем подсказки
                  _showSuggestions = false;
                  context.read<SearchProvider>().clearSearch();
                  setState(() {});
                },
                child: const Text('Try Another Actor'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.actorMovies} $_currentActor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${searchProvider.searchResults.length} movies found',
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Movies grid
          StaggeredMovieGrid(
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            children: searchProvider.searchResults.asMap().entries.map((entry) {
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

  Widget _buildActorChip(String actorName) {
    return GestureDetector(
      onTap: () => _searchActor(actorName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 6),
            Text(
              actorName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchActor(String actorName) {
    // Получаем точное имя актера для исправления опечаток
    final exactName = ActorsDatabase.getExactActorName(actorName) ?? actorName;

    _searchController.text = exactName;
    _currentActor = exactName;
    _showSuggestions = false; // Скрываем подсказки

    context.read<SearchProvider>().searchMovies(exactName);
    _searchFocusNode.unfocus();
    setState(() {});
  }

  void _onMovieTap(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movie: movie, mood: null),
      ),
    );
  }
}
