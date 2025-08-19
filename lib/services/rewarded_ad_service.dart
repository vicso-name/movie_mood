import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/logger.dart';

enum AdResult { success, failed, dismissed, notReady, timeout }

class RewardedAdService {
  static RewardedAdService? _instance;
  static RewardedAdService get instance => _instance ??= RewardedAdService._();

  RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isAdReady = false;
  bool _isLoading = false;
  bool _isShowing = false;
  Completer<void>? _loadingCompleter;

  // Для отслеживания результатов
  bool _rewardEarned = false;
  bool _adShown = false;
  bool _adDismissed = false;

  // Production ad unit IDs - замените на реальные ID
  static const String _androidAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  static const Duration _loadTimeout = Duration(seconds: 8);

  String get _adUnitId {
    if (Platform.isAndroid) {
      return _androidAdUnitId;
    } else if (Platform.isIOS) {
      return _iosAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      logger.i('AdMob initialized successfully');
    } catch (e) {
      logger.e('AdMob initialization failed', error: e);
    }
  }

  /// Настройка полноэкранного режима для рекламы
  Future<void> _setFullscreenMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      logger.e('Failed to set fullscreen mode', error: e);
    }
  }

  /// Восстановление нормального режима UI
  Future<void> _restoreNormalMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    } catch (e) {
      logger.e('Failed to restore normal mode', error: e);
    }
  }

  /// Загрузка rewarded рекламы с таймаутом
  Future<bool> loadRewardedAd() async {
    // Если уже загружается, ждем результат
    if (_isLoading) {
      try {
        await _loadingCompleter?.future.timeout(_loadTimeout);
        return _isAdReady;
      } catch (e) {
        return false;
      }
    }

    // Если реклама уже готова
    if (_isAdReady && _rewardedAd != null) {
      return true;
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
            if (!_loadingCompleter!.isCompleted) {
              _loadingCompleter!.complete();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _cleanup();
            if (!_loadingCompleter!.isCompleted) {
              _loadingCompleter!.complete();
            }
          },
        ),
      );

      // Ждем завершения загрузки с таймаутом
      await _loadingCompleter!.future.timeout(_loadTimeout);
      return _isAdReady;
    } catch (e) {
      _cleanup();
      return false;
    } finally {
      _loadingCompleter = null;
    }
  }

  /// Настройка callback'ов для рекламы
  void _setAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        _adShown = true;
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        _adDismissed = true;
        _disposeCurrentAd();
        _restoreNormalMode();
        _loadNextAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _disposeCurrentAd();
        _restoreNormalMode();
      },
    );
  }

  /// Показ рекламы с детальным логированием
  Future<AdResult> showRewardedAd() async {
    if (_isShowing) {
      return AdResult.failed;
    }

    // Проверяем готовность рекламы
    if (!_isAdReady || _rewardedAd == null) {
      final loaded = await loadRewardedAd();
      if (!loaded) {
        return AdResult.notReady;
      }
    }

    _isShowing = true;
    _rewardEarned = false;
    _adShown = false;
    _adDismissed = false;

    final completer = Completer<AdResult>();

    try {
      await _setFullscreenMode();
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          _rewardEarned = true;
        },
      );

      // Ждем результат с таймаутом
      await Future.delayed(const Duration(milliseconds: 1000));
      int attempts = 0;
      while (!_rewardEarned && _adShown && !_adDismissed && attempts < 5) {
        await Future.delayed(const Duration(milliseconds: 1000));
        attempts++;
      }

      // Определяем результат
      AdResult result;
      if (_rewardEarned) {
        result = AdResult.success;
      } else if (_adShown && _adDismissed) {
        result = AdResult.dismissed;
      } else if (_adShown && !_rewardEarned && attempts >= 5) {
        result = AdResult.success;
      } else {
        result = AdResult.failed;
      }

      completer.complete(result);
    } catch (e) {
      _restoreNormalMode();
      completer.complete(AdResult.failed);
    } finally {
      _isShowing = false;
    }

    return completer.future;
  }

  /// Асинхронная загрузка следующей рекламы
  void _loadNextAd() {
    Future.delayed(const Duration(seconds: 1), () {
      loadRewardedAd()
          .then((success) {
            logger.i('Next ad preload result: $success');
          })
          .catchError((e) {
            logger.e('Next ad preload error: $e');
          });
    });
  }

  /// Очистка состояния после ошибки загрузки
  void _cleanup() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
    _isLoading = false;
    _isShowing = false;
  }

  /// Очистка текущей рекламы
  void _disposeCurrentAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
  }

  /// Проверка готовности рекламы
  bool get isAdReady => _isAdReady && _rewardedAd != null && !_isShowing;

  /// Проверка процесса загрузки
  bool get isLoading => _isLoading;

  /// Проверка показа рекламы
  bool get isShowing => _isShowing;

  /// Освобождение ресурсов
  void dispose() {
    _loadingCompleter?.complete();
    _loadingCompleter = null;
    _cleanup();
    // Восстанавливаем нормальный режим при закрытии сервиса
    _restoreNormalMode();
  }
}
