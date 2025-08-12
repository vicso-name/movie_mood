import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  static RewardedAdService? _instance;
  static RewardedAdService get instance => _instance ??= RewardedAdService._();

  RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isAdReady = false;
  bool _isLoading = false;
  Completer<void>? _loadingCompleter;

  // Production ad unit IDs - замените на реальные ID
  static const String _androidAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  String get _adUnitId {
    if (Platform.isAndroid) {
      return _androidAdUnitId;
    } else if (Platform.isIOS) {
      return _iosAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Инициализация AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Загрузка rewarded рекламы
  Future<void> loadRewardedAd() async {
    // Если уже загружается, возвращаем существующий Future
    if (_isLoading) {
      return _loadingCompleter?.future ?? Future.value();
    }

    // Если реклама уже готова, ничего не делаем
    if (_isAdReady && _rewardedAd != null) {
      return;
    }

    _isLoading = true;
    _loadingCompleter = Completer<void>();

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isAdReady = true;
            _isLoading = false;
            _setAdCallbacks();
            _loadingCompleter?.complete();
            _loadingCompleter = null;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _cleanup();
            _loadingCompleter?.complete();
            _loadingCompleter = null;
          },
        ),
      );
    } catch (e) {
      _cleanup();
      _loadingCompleter?.complete();
      _loadingCompleter = null;
    }
  }

  /// Настройка callback'ов для рекламы
  void _setAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        // Можно добавить аналитику здесь
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        _disposeCurrentAd();
        // Предзагружаем следующую рекламу асинхронно
        unawaited(loadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _disposeCurrentAd();
      },
    );
  }

  /// Показ рекламы с наградой
  Future<bool> showRewardedAd() async {
    // Если реклама не готова, пытаемся загрузить
    if (!_isAdReady || _rewardedAd == null) {
      await loadRewardedAd();

      // Если после загрузки реклама все еще не готова
      if (!_isAdReady || _rewardedAd == null) {
        return false;
      }
    }

    final completer = Completer<bool>();
    bool rewardEarned = false;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          rewardEarned = true;
        },
      );

      // Небольшая задержка для обработки callback'а
      await Future.delayed(const Duration(milliseconds: 100));
      completer.complete(rewardEarned);
    } catch (e) {
      completer.complete(false);
    }

    return completer.future;
  }

  /// Очистка состояния после ошибки загрузки
  void _cleanup() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
    _isLoading = false;
  }

  /// Очистка текущей рекламы
  void _disposeCurrentAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
  }

  /// Проверка готовности рекламы
  bool get isAdReady => _isAdReady && _rewardedAd != null;

  /// Проверка процесса загрузки
  bool get isLoading => _isLoading;

  /// Освобождение ресурсов
  void dispose() {
    _loadingCompleter?.complete();
    _loadingCompleter = null;
    _cleanup();
  }
}

/// Утилита для неблокирующего выполнения Future
void unawaited(Future<void> future) {
  // Просто запускаем Future без ожидания
  // В production можно добавить обработку ошибок через future.catchError()
}
