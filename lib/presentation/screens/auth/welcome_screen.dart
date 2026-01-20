import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme_config.dart';

/// Welcome Screen - Entry point for new users
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      title: 'Welcome to Coopvest Africa',
      subtitle: 'Save. Borrow. Invest. Together.',
      description: 'Join a community of salaried workers building wealth together through cooperative savings and investments.',
      icon: Icons.people,
      color: CoopvestColors.primary,
    ),
    OnboardingSlide(
      title: 'Save Together',
      subtitle: 'Monthly Contributions',
      description: 'Build your savings with peers. Make regular contributions and watch your wealth grow with the cooperative.',
      icon: Icons.savings,
      color: CoopvestColors.secondary,
    ),
    OnboardingSlide(
      title: 'Borrow Easily',
      subtitle: 'Peer-Backed Loans',
      description: 'Get loans backed by your peers. Three guarantors verify your commitment, making loans accessible and fair.',
      icon: Icons.handshake,
      color: CoopvestColors.tertiary,
    ),
    OnboardingSlide(
      title: 'Invest Together',
      subtitle: 'Profit Sharing',
      description: 'Participate in cooperative investment projects and share in the profits. Grow your wealth as a community.',
      icon: Icons.trending_up,
      color: CoopvestColors.primary,
    ),
    OnboardingSlide(
      title: 'Your Security Matters',
      subtitle: 'Encrypted & Secure',
      description: 'Your data is protected with enterprise-grade security. We prioritize your privacy and financial safety.',
      icon: Icons.security,
      color: CoopvestColors.secondary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return OnboardingSlideWidget(slide: slides[index]);
            },
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.05).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => Container(
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? CoopvestColors.primary
                              : CoopvestColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Skip Button
                      if (_currentPage < slides.length - 1)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/login');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: CoopvestColors.lightGray,
                              ),
                            ),
                            child: const Text('Skip'),
                          ),
                        ),
                      if (_currentPage < slides.length - 1)
                        const SizedBox(width: 12),

                      // Next/Get Started Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == slides.length - 1) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            _currentPage == slides.length - 1
                                ? 'Get Started'
                                : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Onboarding Slide Data
class OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Onboarding Slide Widget
class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideWidget({
    Key? key,
    required this.slide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: slide.color.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Icon(
                    slide.icon,
                    size: 60,
                    color: slide.color,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: const Duration(milliseconds: 600),
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                  )
                  .fadeIn(),

              const SizedBox(height: 40),

              // Title
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: CoopvestTypography.displaySmall.copyWith(
                  color: CoopvestColors.darkGray,
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: CoopvestTypography.headlineMedium.copyWith(
                  color: slide.color,
                  fontWeight: FontWeight.w600,
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 500))
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 20),

              // Description
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: CoopvestTypography.bodyMedium.copyWith(
                  color: CoopvestColors.mediumGray,
                  height: 1.6,
                ),
              )
                  .animate()
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
