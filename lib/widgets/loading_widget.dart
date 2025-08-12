import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/app_error.dart';

// Типы загрузки для разных контекстов
enum LoadingType {
  general,
  searchingMovies,
  moodAnalysis,
  actorSearch,
  gettingDetails,
}

class LoadingWidget extends StatefulWidget {
  final String? message;
  final LoadingType type;
  final String? mood; // Для персонализации сообщений

  const LoadingWidget({
    super.key,
    this.message,
    this.type = LoadingType.general,
    this.mood,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentMessageIndex = 0;
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();

    _setupAnimations();
    _setupMessages();
    _startMessageRotation();
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _setupMessages() {
    if (widget.message != null) {
      _messages = [widget.message!];
      return;
    }

    switch (widget.type) {
      case LoadingType.general:
        _messages = ['⏳ Loading...', '🔄 Processing...', '⚡ Almost there...'];
        break;

      case LoadingType.searchingMovies:
        _messages = [
          '🎬 Searching for movies...',
          '🎭 Analyzing genres...',
          '⭐ Checking ratings...',
          '🍿 Finding the best matches...',
        ];
        break;

      case LoadingType.moodAnalysis:
        _messages = _getMoodSpecificMessages();
        break;

      case LoadingType.actorSearch:
        _messages = [
          '🎭 Searching filmography...',
          '🎬 Finding best performances...',
          '⭐ Sorting by ratings...',
          '🍿 Almost ready...',
        ];
        break;

      case LoadingType.gettingDetails:
        _messages = [
          '📋 Getting movie details...',
          '🎬 Loading information...',
          '⭐ Fetching ratings...',
        ];
        break;
    }
  }

  List<String> _getMoodSpecificMessages() {
    final mood = widget.mood?.toLowerCase() ?? 'general';

    switch (mood) {
      case 'happy':
        return [
          '😊 Looking for happy films...',
          '🎭 Finding comedies...',
          '🌟 Searching feel-good movies...',
          '🍿 Almost got the perfect picks!',
        ];

      case 'romantic':
        return [
          '💕 Finding romantic stories...',
          '❤️ Searching love tales...',
          '🌹 Looking for perfect date movies...',
          '✨ Almost ready for romance!',
        ];

      case 'sad':
        return [
          '🎭 Finding emotional dramas...',
          '💧 Searching touching stories...',
          '🖤 Looking for deep films...',
          '🎬 Preparing heartfelt cinema...',
        ];

      case 'cozy':
        return [
          '🏠 Finding cozy films...',
          '☕ Searching comfort movies...',
          '🔥 Looking for warm stories...',
          '🧸 Almost ready for coziness!',
        ];

      case 'inspiring':
        return [
          '⭐ Finding inspiring stories...',
          '🚀 Searching motivational films...',
          '💪 Looking for success tales...',
          '🏆 Almost got your inspiration!',
        ];

      case 'thrilling':
        return [
          '⚡ Finding thrilling adventures...',
          '🎯 Searching action-packed films...',
          '💥 Looking for adrenaline rush...',
          '🔥 Almost ready for excitement!',
        ];

      default:
        return [
          '🎬 Analyzing your mood...',
          '🎭 Finding perfect matches...',
          '⭐ Selecting best options...',
          '🍿 Almost ready!',
        ];
    }
  }

  void _startMessageRotation() {
    if (_messages.length <= 1) return;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _rotateMessage();
    });
  }

  void _rotateMessage() {
    _fadeController.reverse().then((_) {
      if (!mounted) return;

      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
      });

      _fadeController.forward().then((_) {
        if (!mounted) return;

        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) _rotateMessage();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Анимированный индикатор загрузки
          _buildLoadingIndicator(),

          const SizedBox(height: 24),

          // Анимированное сообщение
          if (_messages.isNotEmpty)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    _messages[_currentMessageIndex],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

          // Дополнительная информация для длительных операций
          if (widget.type == LoadingType.moodAnalysis ||
              widget.type == LoadingType.actorSearch) ...[
            const SizedBox(height: 12),
            Text(
              'This might take a few seconds...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    // Для разных типов загрузки - разные индикаторы
    switch (widget.type) {
      case LoadingType.moodAnalysis:
        return _buildPulsingIcon(Icons.psychology, AppColors.accent);

      case LoadingType.actorSearch:
        return _buildPulsingIcon(Icons.person_search, AppColors.primary);

      case LoadingType.searchingMovies:
        return _buildMovieReelAnimation();

      default:
        return _buildClassicSpinner();
    }
  }

  Widget _buildClassicSpinner() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * pi,
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        );
      },
    );
  }

  Widget _buildPulsingIcon(IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final pulseValue =
            (1.0 + 0.3 * sin(1.0 + _rotationController.value * 2 * pi)) / 1.3;
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
        );
      },
    );
  }

  Widget _buildMovieReelAnimation() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Внешнее кольцо
            Transform.rotate(
              angle: _rotationController.value * 2 * pi,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.movie, color: AppColors.primary, size: 24),
                ),
              ),
            ),
            // Точки по кругу (имитация кинопленки)
            ...List.generate(8, (index) {
              final angle = (index * 45.0) + (_rotationController.value * 360);
              return Transform.rotate(
                angle: angle * pi / 180,
                child: Transform.translate(
                  offset: const Offset(0, -35),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

class AppErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимированная иконка ошибки
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    _getErrorIcon(),
                    size: 64,
                    color: _getErrorColor(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Заголовок ошибки
            Text(
              _getErrorTitle(),
              style: TextStyle(
                color: _getErrorColor(),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Описание ошибки
            Text(
              error.userMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (error.canRetry && onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(AppStrings.retry),
                  ),
                ],

                if (error.type == ErrorType.network) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showNetworkTips(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Help'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.access_time;
      case ErrorType.apiLimit:
        return Icons.hourglass_empty;
      case ErrorType.invalidApiKey:
        return Icons.key_off;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.timeout:
        return Colors.blue;
      case ErrorType.apiLimit:
        return Colors.yellow[700]!;
      case ErrorType.invalidApiKey:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.grey;
      case ErrorType.server:
        return Colors.red[400]!;
      case ErrorType.unknown:
        return AppColors.accent;
    }
  }

  String _getErrorTitle() {
    switch (error.type) {
      case ErrorType.network:
        return 'No Internet Connection';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.apiLimit:
        return 'Too Many Requests';
      case ErrorType.invalidApiKey:
        return 'Service Unavailable';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.unknown:
        return 'Something Went Wrong';
    }
  }

  void _showNetworkTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Connection Tips',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '• Check your Wi-Fi or mobile data\n'
          '• Make sure you have internet access\n'
          '• Try switching between Wi-Fi and mobile data\n'
          '• Restart your internet connection',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
