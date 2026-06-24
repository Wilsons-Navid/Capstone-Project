import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/utils/app_router.dart';

/// First-run intro carousel. Shown once (gated by [OnboardingService]) between
/// the splash screen and login, it walks a new user through the app's core
/// sections with a Skip / Next / Get Started flow.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.shield_outlined,
      color: AppTheme.primaryColor,
      title: 'Stay a step ahead of scammers',
      body:
          'Rethicsec helps you spot fraud, phishing and mobile-money scams '
          'before they cost you. Let\'s show you around.',
    ),
    _OnboardingSlide(
      icon: Icons.search_rounded,
      color: AppTheme.secondaryDark,
      title: 'Scan anything suspicious',
      body:
          'Paste a message, link, email or phone number and our AI checks it '
          'instantly, telling you how risky it is and why.',
    ),
    _OnboardingSlide(
      icon: Icons.campaign_outlined,
      color: AppTheme.baobabBrown,
      title: 'Report and take action',
      body:
          'Found a scam? Report it to the right authorities in your country '
          'with one tap, and help protect your community.',
    ),
    _OnboardingSlide(
      icon: Icons.school_outlined,
      color: AppTheme.successColor,
      title: 'Learn and stay alert',
      body:
          'Build your scam-spotting skills with short lessons and get notified '
          'about new threats as they emerge.',
    ),
  ];

  bool get _isLastPage => _index == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingService.setIntroSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Dots — decorative, announced as a single progress label.
            Semantics(
              label: 'Page ${_index + 1} of ${_slides.length}',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: i == _index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? AppTheme.secondaryColor
                            : AppTheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isLastPage ? 'Get started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    // Group the icon + title + body so a screen reader reads each slide as one unit.
    return MergeSemantics(
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 64, color: slide.color,
                semanticLabel: ''),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
      ), // Padding
    ); // MergeSemantics
  }
}

class _OnboardingSlide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _OnboardingSlide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
