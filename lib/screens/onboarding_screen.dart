import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/moods.dart';
import '../widgets/custom_page_route.dart';
import '../models/onboarding_page.dart';
import '../services/onboarding_service.dart';
import '../widgets/animated_widgets.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: AppStrings.onboardingWelcomeTitle,
      description: AppStrings.onboardingWelcomeDescription,
      emoji: '🎬',
      backgroundGradientStart: '0xFF6C63FF',
      backgroundGradientEnd: '0xFF1A1A2E',
      features: [
        'Choose your mood',
        'Get personalized recommendations',
        'Discover hidden gems',
      ],
    ),
    const OnboardingPage(
      title: AppStrings.onboardingActorTitle,
      description: AppStrings.onboardingActorDescription,
      emoji: '🎭',
      backgroundGradientStart: '0xFFE94560',
      backgroundGradientEnd: '0xFF16213E',
      features: [
        'Search by actor name',
        'Browse popular actors',
        'Discover new talents',
      ],
    ),
    const OnboardingPage(
      title: AppStrings.onboardingFavoritesTitle,
      description: AppStrings.onboardingFavoritesDescription,
      emoji: '💾',
      backgroundGradientStart: '0xFF98D8C8',
      backgroundGradientEnd: '0xFF1A1A2E',
      features: [
        'Save to favorites',
        'Organize by mood',
        'Find streaming platforms',
      ],
    ),
    const OnboardingPage(
      title: AppStrings.onboardingSurpriseTitle,
      description: AppStrings.onboardingSurpriseDescription,
      emoji: '🎲',
      backgroundGradientStart: '0xFFFFB347',
      backgroundGradientEnd: '0xFF16213E',
      features: [
        'Random movie selection',
        'Discover new genres',
        'Break out of your comfort zone',
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    await OnboardingService.setOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(
                    int.parse(_pages[_currentPage].backgroundGradientStart),
                  ),
                  Color(int.parse(_pages[_currentPage].backgroundGradientEnd)),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with skip button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (visible only after first page)
                      AnimatedOpacity(
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          onPressed: _currentPage > 0 ? _previousPage : null,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Skip button
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: Text(
                          AppStrings.skip,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Bottom section with indicators and button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => _buildIndicator(index),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Continue/Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? AppStrings.getStarted
                                : AppStrings.continueText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji/Icon
          SlideInAnimation(
            delay: Duration(milliseconds: 200 * index),
            begin: const Offset(0, -0.3),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(page.emoji, style: const TextStyle(fontSize: 80)),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          SlideInAnimation(
            delay: Duration(milliseconds: 300 + (200 * index)),
            begin: const Offset(0, 0.3),
            child: Text(
              page.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          SlideInAnimation(
            delay: Duration(milliseconds: 400 + (200 * index)),
            begin: const Offset(0, 0.3),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Features list
          SlideInAnimation(
            delay: Duration(milliseconds: 500 + (200 * index)),
            begin: const Offset(0, 0.3),
            child: Column(
              children: page.features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
