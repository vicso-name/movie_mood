import 'package:flutter/widgets.dart';
import '../models/streaming_availability.dart';
import '../models/app_error.dart';
import '../services/streaming_service.dart';
import '../services/rewarded_ad_service.dart';

enum StreamingLoadingState {
  idle,
  loading,
  loaded,
  error,
  notFound,
  locked,
  showingAd,
  unlocked,
}

class StreamingProvider extends ChangeNotifier {
  final StreamingService _streamingService = StreamingService();

  StreamingAvailability? _availability;
  StreamingLoadingState _state = StreamingLoadingState.idle;
  AppError? _error;
  String? _currentImdbId;
  bool _isUnlockedForCurrentMovie = false;

  StreamingAvailability? get availability => _availability;
  StreamingLoadingState get state => _state;
  AppError? get error => _error;
  String get errorMessage => _error?.userMessage ?? '';
  bool get canRetry => _error?.canRetry ?? true;
  bool get hasAvailability => _availability?.hasAnyAvailability ?? false;
  bool get isUnlocked => _isUnlockedForCurrentMovie;

  /// Загрузка streaming availability для фильма
  Future<void> loadStreamingAvailability(String imdbId) async {
    // Если это новый фильм, сбрасываем статус разблокировки
    if (_currentImdbId != imdbId) {
      _isUnlockedForCurrentMovie = false;
      _currentImdbId = imdbId;
    }

    // Избегаем повторной загрузки для того же фильма
    if (_currentImdbId == imdbId &&
        (_state == StreamingLoadingState.loaded ||
            _state == StreamingLoadingState.locked ||
            _state == StreamingLoadingState.unlocked) &&
        _availability != null &&
        !_availability!.isExpired) {
      // Просто обновляем состояние на основе статуса разблокировки
      if (_availability!.hasAnyAvailability) {
        _setState(
          _isUnlockedForCurrentMovie
              ? StreamingLoadingState.unlocked
              : StreamingLoadingState.locked,
        );
      } else {
        _setState(StreamingLoadingState.notFound);
      }
      return;
    }

    _setState(StreamingLoadingState.loading);
    _error = null;

    try {
      _availability = await _streamingService.getStreamingAvailability(imdbId);

      if (_availability == null || !_availability!.hasAnyAvailability) {
        _setState(StreamingLoadingState.notFound);
      } else {
        // Данные загружены, но заблокированы рекламой
        _setState(
          _isUnlockedForCurrentMovie
              ? StreamingLoadingState.unlocked
              : StreamingLoadingState.locked,
        );
      }
    } catch (e) {
      if (e is AppError) {
        _error = e;
      } else {
        _error = AppError.unknown(e.toString());
      }
      _availability = null;
      _setState(StreamingLoadingState.error);
    }
  }

  /// Показ рекламы для разблокировки streaming данных
  Future<void> showAdToUnlock() async {
    if (_state != StreamingLoadingState.locked) {
      return;
    }
    _setState(StreamingLoadingState.showingAd);

    try {
      // Пытаемся показать рекламу
      final adResult = await RewardedAdService.instance.showRewardedAd();
      switch (adResult) {
        case AdResult.success:
          _isUnlockedForCurrentMovie = true;
          _setState(StreamingLoadingState.unlocked);
          _preloadNextAd();
          break;

        case AdResult.dismissed:
          _setState(StreamingLoadingState.locked);
          break;

        case AdResult.failed:
        case AdResult.notReady:
        case AdResult.timeout:
          await _handleAdFailure(adResult);
          break;
      }
    } catch (e) {
      await _handleAdFailure(AdResult.failed);
    }
  }

  /// Обработка сбоев рекламы с fallback стратегией
  Future<void> _handleAdFailure(AdResult failureReason) async {
    // Стратегия 1: Пробуем загрузить рекламу еще раз
    final reloadSuccess = await RewardedAdService.instance.loadRewardedAd();
    if (reloadSuccess) {
      _setState(StreamingLoadingState.locked);
      return;
    }
    // Стратегия 2: Если перезагрузка не помогла - разблокируем контент
    print('🆓 FALLBACK: Unable to load ads, unlocking content for user');
    _isUnlockedForCurrentMovie = true;
    _setState(StreamingLoadingState.unlocked);
    _preloadNextAd();
  }

  /// Предзагрузка следующей рекламы
  void _preloadNextAd() {
    RewardedAdService.instance
        .loadRewardedAd()
        .then((success) {
          print('📱 Next ad preload result: $success');
        })
        .catchError((e) {
          print('🚨 Next ad preload failed: $e');
        });
  }

  /// Повторная попытка загрузки
  Future<void> retry() async {
    if (_currentImdbId != null) {
      await loadStreamingAvailability(_currentImdbId!);
    }
  }

  /// Очистка данных
  void clearStreaming() {
    _availability = null;
    _currentImdbId = null;
    _error = null;
    _isUnlockedForCurrentMovie = false;
    _setState(StreamingLoadingState.idle);
  }

  /// Получение источников по типу
  List<StreamingSource> getSourcesByType(String type) {
    if (_availability == null || !_isUnlockedForCurrentMovie) return [];

    switch (type.toLowerCase()) {
      case 'free':
        return _availability!.freeSources;
      case 'subscription':
      case 'sub':
        return _availability!.subscriptionSources;
      case 'rent':
        return _availability!.rentSources;
      case 'purchase':
      case 'buy':
        return _availability!.purchaseSources;
      default:
        return [];
    }
  }

  /// Получение всех источников, отсортированных по приоритету
  List<StreamingSource> getAllSourcesSorted() {
    if (_availability == null || !_isUnlockedForCurrentMovie) return [];
    return _availability!.allSources;
  }

  /// Получение лучших источников для отображения (топ 6)
  List<StreamingSource> getTopSources({int limit = 6}) {
    final allSources = getAllSourcesSorted();
    return allSources.take(limit).toList();
  }

  /// Проверка доступности на конкретной платформе
  bool isAvailableOn(String platformName) {
    if (_availability == null || !_isUnlockedForCurrentMovie) return false;

    final lowerPlatformName = platformName.toLowerCase();
    return _availability!.allSources.any(
      (source) => source.name.toLowerCase().contains(lowerPlatformName),
    );
  }

  /// Получение источника для конкретной платформы
  StreamingSource? getSourceForPlatform(String platformName) {
    if (_availability == null || !_isUnlockedForCurrentMovie) return null;

    final lowerPlatformName = platformName.toLowerCase();
    try {
      return _availability!.allSources.firstWhere(
        (source) => source.name.toLowerCase().contains(lowerPlatformName),
      );
    } catch (e) {
      return null;
    }
  }

  /// Получение самого дешевого варианта аренды/покупки
  StreamingSource? getCheapestPaidOption() {
    if (_availability == null || !_isUnlockedForCurrentMovie) return null;

    final paidSources = [
      ..._availability!.rentSources,
      ..._availability!.purchaseSources,
    ];

    if (paidSources.isEmpty) return null;

    // Фильтруем источники с ценами
    final sourcesWithPrices = paidSources
        .where((s) => s.price != null)
        .toList();

    if (sourcesWithPrices.isEmpty) {
      // Возвращаем первый доступный, если цены не указаны
      return paidSources.first;
    }

    // Сортируем по цене
    sourcesWithPrices.sort((a, b) => a.price!.compareTo(b.price!));
    return sourcesWithPrices.first;
  }

  /// Получение статистики доступности
  Map<String, int> getAvailabilityStats() {
    if (_availability == null) {
      return {
        'free': 0,
        'subscription': 0,
        'rent': 0,
        'purchase': 0,
        'total': 0,
      };
    }

    return {
      'free': _availability!.freeSources.length,
      'subscription': _availability!.subscriptionSources.length,
      'rent': _availability!.rentSources.length,
      'purchase': _availability!.purchaseSources.length,
      'total': _availability!.allSources.length,
    };
  }

  /// Проверка, истек ли кеш
  bool get isCacheExpired => _availability?.isExpired ?? true;

  /// Получение времени последнего обновления
  DateTime? get lastUpdated => _availability?.lastUpdated;

  void _setState(StreamingLoadingState newState) {
    _state = newState;

    // Принудительный rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    notifyListeners();
  }

  @override
  void dispose() {
    // Очищаем данные при dispose
    clearStreaming();
    super.dispose();
  }
}
