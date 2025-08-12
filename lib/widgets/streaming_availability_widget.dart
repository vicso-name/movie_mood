import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/streaming_provider.dart';
import '../models/streaming_availability.dart';
import '../constants/colors.dart';

class StreamingAvailabilityWidget extends StatefulWidget {
  final String imdbId;
  final String movieTitle;

  const StreamingAvailabilityWidget({
    super.key,
    required this.imdbId,
    required this.movieTitle,
  });

  @override
  State<StreamingAvailabilityWidget> createState() =>
      _StreamingAvailabilityWidgetState();
}

class _StreamingAvailabilityWidgetState
    extends State<StreamingAvailabilityWidget> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
        'StreamingWidget: initState - Loading for IMDB ID: ${widget.imdbId}',
      );
      context.read<StreamingProvider>().loadStreamingAvailability(
        widget.imdbId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<StreamingProvider, StreamingLoadingState>(
      selector: (context, provider) {
        print('StreamingWidget: Selector called, state: ${provider.state}');
        return provider.state;
      },
      builder: (context, state, child) {
        print('StreamingWidget: Selector builder called with state: $state');
        final provider = Provider.of<StreamingProvider>(context, listen: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(),
            const SizedBox(height: 12),
            _buildContent(provider),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle() {
    return const Text(
      'Where to watch',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContent(StreamingProvider provider) {
    print(
      '🔥🔥🔥 _buildContent DEFINITELY CALLED with state: ${provider.state} 🔥🔥🔥',
    );

    switch (provider.state) {
      case StreamingLoadingState.loading:
        print('StreamingWidget: Returning loading state');
        return _buildLoadingState();

      case StreamingLoadingState.error:
        print('StreamingWidget: Returning error state');
        return _buildErrorState(provider);

      case StreamingLoadingState.notFound:
        print('StreamingWidget: Returning not found state');
        return _buildNotFoundState();

      case StreamingLoadingState.locked:
        print('StreamingWidget: Returning locked state');
        return _buildLockedState(provider);

      case StreamingLoadingState.showingAd:
        print('StreamingWidget: Returning showing ad state');
        return _buildShowingAdState();

      case StreamingLoadingState.unlocked:
        print('StreamingWidget: Returning unlocked state');
        return _buildAvailabilityContent(provider.availability!);

      case StreamingLoadingState.idle:
      default:
        print('StreamingWidget: Returning idle/default state');
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 60,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState(StreamingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          if (provider.canRetry)
            TextButton(
              onPressed: () => provider.retry(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This movie is currently not available on major streaming platforms.',
              style: const TextStyle(color: Colors.orange, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState(StreamingProvider provider) {
    print('StreamingWidget: _buildLockedState called!');

    final stats = provider.getAvailabilityStats();
    final totalSources = stats['total'] ?? 0;

    print('StreamingWidget: Total sources: $totalSources');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.play_circle_outline, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Found $totalSources streaming options!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Watch a short ad to unlock all streaming platforms and prices',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                print('StreamingWidget: Ad button pressed!');
                provider.showAdToUnlock();
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text(
                'Watch Ad & Unlock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Free • Takes 15-30 seconds',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[300],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShowingAdState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading ad...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we prepare your streaming options',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityContent(StreamingAvailability availability) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availability.freeSources.isNotEmpty)
          _buildSection('Free', availability.freeSources, Colors.green),

        // Then subscription
        if (availability.subscriptionSources.isNotEmpty)
          _buildSection(
            'Streaming',
            availability.subscriptionSources,
            AppColors.primary,
          ),

        // Then rent/buy
        if (availability.rentSources.isNotEmpty)
          _buildSection('Rent', availability.rentSources, Colors.orange),

        if (availability.purchaseSources.isNotEmpty)
          _buildSection('Buy', availability.purchaseSources, Colors.purple),
      ],
    );
  }

  Widget _buildSection(
    String title,
    List<StreamingSource> sources,
    Color color,
  ) {
    // Группируем источники по названию платформы, оставляя лучший формат
    final groupedSources = _groupSourcesByProvider(sources);
    final cheapestPrice = _getCheapestPrice(sources);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getSectionLabel(title, groupedSources.length, cheapestPrice),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: groupedSources
              .take(6)
              .map(
                (source) => _StreamingSourceButton(
                  source: source,
                  movieTitle: widget.movieTitle,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Возвращает информативную подпись для секции
  String _getSectionLabel(
    String title,
    int platformCount,
    String? cheapestPrice,
  ) {
    if (title == 'Free') {
      return '$platformCount platform${platformCount == 1 ? '' : 's'}';
    }

    if (title == 'Streaming') {
      return '$platformCount service${platformCount == 1 ? '' : 's'}';
    }

    // Для Rent и Buy показываем количество платформ + самую низкую цену
    if (cheapestPrice != null && cheapestPrice.isNotEmpty) {
      return 'from $cheapestPrice • $platformCount option${platformCount == 1 ? '' : 's'}';
    }

    return '$platformCount option${platformCount == 1 ? '' : 's'}';
  }

  /// Находит самую низкую цену в списке источников
  String? _getCheapestPrice(List<StreamingSource> sources) {
    double? minPrice;

    for (final source in sources) {
      if (source.price != null) {
        if (minPrice == null || source.price! < minPrice) {
          minPrice = source.price;
        }
      }
    }

    return minPrice != null ? '\$${minPrice.toStringAsFixed(2)}' : null;
  }

  /// Группирует источники по названию провайдера, оставляя лучший формат
  List<StreamingSource> _groupSourcesByProvider(List<StreamingSource> sources) {
    final Map<String, StreamingSource> grouped = {};

    for (final source in sources) {
      final existing = grouped[source.name];

      if (existing == null) {
        // Первый источник от этого провайдера
        grouped[source.name] = source;
      } else {
        // Выбираем лучший формат (4K > HD > SD)
        final newSource = _selectBetterFormat(existing, source);
        grouped[source.name] = newSource;
      }
    }

    return grouped.values.toList();
  }

  /// Выбирает источник с лучшим форматом
  StreamingSource _selectBetterFormat(
    StreamingSource current,
    StreamingSource candidate,
  ) {
    final currentPriority = _getFormatPriority(current.format);
    final candidatePriority = _getFormatPriority(candidate.format);

    // Если форматы одинаковые, выбираем с меньшей ценой
    if (currentPriority == candidatePriority) {
      if (current.price != null && candidate.price != null) {
        return current.price! <= candidate.price! ? current : candidate;
      }
    }

    // Иначе выбираем лучший формат
    return candidatePriority > currentPriority ? candidate : current;
  }

  /// Возвращает приоритет формата (выше = лучше)
  int _getFormatPriority(String? format) {
    if (format == null) return 0;

    switch (format.toUpperCase()) {
      case '4K':
        return 3;
      case 'HD':
        return 2;
      case 'SD':
        return 1;
      default:
        return 0;
    }
  }
}

class _StreamingSourceButton extends StatelessWidget {
  final StreamingSource source;
  final String movieTitle;

  const _StreamingSourceButton({
    required this.source,
    required this.movieTitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchSource(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Platform icon/logo placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getPlatformColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getPlatformIcon(), color: Colors.white, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              source.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Показываем формат если есть
            if (source.format != null && source.format!.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                source.format!,
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (source.displayPrice.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                source.displayPrice,
                style: TextStyle(
                  color: Colors.green[300],
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPlatformColor() {
    final name = source.name.toLowerCase();

    if (name.contains('netflix')) return const Color(0xFFE50914);
    if (name.contains('amazon') || name.contains('prime')) {
      return const Color(0xFF00A8E1);
    }
    if (name.contains('disney')) return const Color(0xFF113CCF);
    if (name.contains('hbo')) return const Color(0xFF8A2BE2);
    if (name.contains('hulu')) return const Color(0xFF1CE783);
    if (name.contains('apple')) return const Color(0xFF000000);
    if (name.contains('paramount')) return const Color(0xFF0F4C99);
    if (name.contains('peacock')) return const Color(0xFF000080);

    return AppColors.primary;
  }

  IconData _getPlatformIcon() {
    final type = source.type.toLowerCase();

    if (type.contains('free')) return Icons.play_circle_outline;
    if (type.contains('rent')) return Icons.video_library;
    if (type.contains('buy') || type.contains('purchase')) {
      return Icons.shopping_cart;
    }

    return Icons.play_arrow;
  }

  Future<void> _launchSource(BuildContext context) async {
    try {
      final url = source.preferredUrl;

      if (url.isEmpty) {
        await _fallbackSearch(context);
        return;
      }

      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await _fallbackSearch(context);
      }
    } catch (e) {
      await _fallbackSearch(context);
    }
  }

  Future<void> _fallbackSearch(BuildContext context) async {
    try {
      final query = Uri.encodeComponent('$movieTitle ${source.name}');
      final searchUrl = 'https://www.google.com/search?q=$query';
      await launchUrl(Uri.parse(searchUrl));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open streaming service'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
