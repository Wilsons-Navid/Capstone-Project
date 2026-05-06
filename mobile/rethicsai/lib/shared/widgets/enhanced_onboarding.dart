import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';

import '../../core/themes/app_theme.dart';
import '../../core/utils/app_router.dart';
import 'african_pattern_background.dart';

class EnhancedOnboardingPage extends StatefulWidget {
  const EnhancedOnboardingPage({super.key});

  @override
  State<EnhancedOnboardingPage> createState() => _EnhancedOnboardingPageState();
}

class _EnhancedOnboardingPageState extends State<EnhancedOnboardingPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _updateProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    _progressController.animateTo((_currentPage + 1) / _totalPages);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.register);
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

  void _skipToEnd() {
    Navigator.pushReplacementNamed(context, AppRouter.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // African pattern background
          const Positioned.fill(
            child: AfricanPatternBackground(opacity: 0.03),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with progress and skip
                _buildTopBar(),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                      _updateProgress();
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildProtectionPage(),
                      _buildAIAssistantPage(),
                      _buildCommunityPage(),
                    ],
                  ),
                ),
                
                // Bottom navigation
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Progress indicator
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressController.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Skip button
          TextButton(
            onPressed: _skipToEnd,
            child: Text(
              'onboarding.skip'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return OnboardingPage(
      title: 'onboarding.welcome_title'.tr(),
      subtitle: 'onboarding.welcome_subtitle'.tr(),
      description: 'onboarding.welcome_description'.tr(),
      illustration: _buildWelcomeIllustration(),
      gradient: AppTheme.africanSunsetGradient,
    );
  }

  Widget _buildProtectionPage() {
    return OnboardingPage(
      title: 'onboarding.protection_title'.tr(),
      subtitle: 'onboarding.protection_subtitle'.tr(),
      description: 'onboarding.protection_description'.tr(),
      illustration: _buildProtectionIllustration(),
      gradient: AppTheme.primaryGradient,
      features: [
        OnboardingFeature(
          icon: Icons.report_problem,
          title: 'onboarding.report_incidents'.tr(),
          description: 'onboarding.report_incidents_desc'.tr(),
        ),
        OnboardingFeature(
          icon: Icons.track_changes,
          title: 'onboarding.track_cases'.tr(),
          description: 'onboarding.track_cases_desc'.tr(),
        ),
        OnboardingFeature(
          icon: Icons.security,
          title: 'onboarding.threat_scanning'.tr(),
          description: 'onboarding.threat_scanning_desc'.tr(),
        ),
      ],
    );
  }

  Widget _buildAIAssistantPage() {
    return OnboardingPage(
      title: 'onboarding.ai_title'.tr(),
      subtitle: 'onboarding.ai_subtitle'.tr(),
      description: 'onboarding.ai_description'.tr(),
      illustration: _buildAIIllustration(),
      gradient: AppTheme.secondaryGradient,
      features: [
        OnboardingFeature(
          icon: Icons.psychology,
          title: 'onboarding.smart_assistance'.tr(),
          description: 'onboarding.smart_assistance_desc'.tr(),
        ),
        OnboardingFeature(
          icon: Icons.translate,
          title: 'onboarding.multilingual'.tr(),
          description: 'onboarding.multilingual_desc'.tr(),
        ),
        OnboardingFeature(
          icon: Icons.lightbulb,
          title: 'onboarding.personalized_tips'.tr(),
          description: 'onboarding.personalized_tips_desc'.tr(),
        ),
      ],
    );
  }

  Widget _buildCommunityPage() {
    return OnboardingPage(
      title: 'onboarding.community_title'.tr(),
      subtitle: 'onboarding.community_subtitle'.tr(),
      description: 'onboarding.community_description'.tr(),
      illustration: _buildCommunityIllustration(),
      gradient: AppTheme.accentGradient,
      features: [
        OnboardingFeature(
          icon: Icons.school,
          title: 'onboarding.learn_together'.tr(),
          description: 'onboarding.learn_together_desc'.tr(),
        ),
        OnboardingFeature(
          icon: Icons.group,
          title: 'onboarding.community_support'.tr(),
          description: 'onboarding.community_support_desc'.tr(),
        ),
        OnboardingFeature(
          icon: Icons.trending_up,
          title: 'onboarding.stay_updated'.tr(),
          description: 'onboarding.stay_updated_desc'.tr(),
        ),
      ],
    );
  }

  Widget _buildWelcomeIllustration() {
    return Container(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main shield icon with animation
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.security,
              size: 80,
              color: Colors.white,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 3.seconds, colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.5),
                Colors.transparent,
              ]),
          
          // Floating elements
          Positioned(
            top: 40,
            left: 40,
            child: _FloatingIcon(
              icon: Icons.report_problem,
              delay: 0.5,
            ),
          ),
          Positioned(
            top: 60,
            right: 50,
            child: _FloatingIcon(
              icon: Icons.psychology,
              delay: 1.0,
            ),
          ),
          Positioned(
            bottom: 80,
            left: 60,
            child: _FloatingIcon(
              icon: Icons.school,
              delay: 1.5,
            ),
          ),
          Positioned(
            bottom: 100,
            right: 40,
            child: _FloatingIcon(
              icon: Icons.group,
              delay: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionIllustration() {
    return Container(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProtectionCard(Icons.phone_android, 'Mobile', 0.0),
          const SizedBox(width: 20),
          _buildProtectionCard(Icons.laptop, 'Computer', 0.3),
          const SizedBox(width: 20),
          _buildProtectionCard(Icons.cloud, 'Cloud', 0.6),
        ],
      ),
    );
  }

  Widget _buildProtectionCard(IconData icon, String label, double delay) {
    return Container(
      width: 80,
      height: 100,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 1,
      delay: Duration(milliseconds: (delay * 1000).toInt()),
      duration: 600.ms,
    ).fadeIn();
  }

  Widget _buildAIIllustration() {
    return Container(
      height: 220,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // AI brain icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            // Animated thought bubbles
            ..._buildThoughtBubbles(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildThoughtBubbles() {
    final positions = [
      const Offset(-80, -60),
      const Offset(80, -40),
      const Offset(-60, 60),
      const Offset(70, 80),
    ];
    
    return positions.asMap().entries.map((entry) {
      final index = entry.key;
      final position = entry.value;
      
      return Positioned(
        left: 120 + position.dx,
        top: 60 + position.dy,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            [Icons.lightbulb, Icons.security, Icons.help, Icons.tips_and_updates][index],
            size: 16,
            color: Colors.white,
          ),
        ).animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: (2 + index * 0.5).seconds,
            )
            .then()
            .scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(0.8, 0.8),
              duration: (2 + index * 0.5).seconds,
            ),
      );
    }).toList();
  }

  Widget _buildCommunityIllustration() {
    return Container(
      height: 220,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Central community icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group,
                size: 50,
                color: Colors.white,
              ),
            ),
            
            // Surrounding user avatars
            ..._buildUserAvatars(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUserAvatars() {
    final angles = [0, 60, 120, 180, 240, 300];
    const radius = 80.0;
    
    return angles.asMap().entries.map((entry) {
      final index = entry.key;
      final angle = entry.value * (3.14159 / 180); // Convert to radians
      
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      
      return Positioned(
        left: 110 + x - 15,
        top: 110 + y - 15,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 18,
            color: Colors.white,
          ),
        ).animate(delay: Duration(milliseconds: index * 200))
            .slideY(begin: 0.5, duration: 500.ms)
            .fadeIn(),
      );
    }).toList();
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Previous button
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.chevron_left),
              label: Text('onboarding.previous'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          
          const Spacer(),
          
          // Page indicators
          Row(
            children: List.generate(_totalPages, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? AppTheme.primaryColor 
                      : AppTheme.primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate(target: _currentPage == index ? 1 : 0)
                  .scale(duration: 200.ms);
            }),
          ),
          
          const Spacer(),
          
          // Next/Get Started button
          ElevatedButton.icon(
            onPressed: _nextPage,
            icon: Icon(_currentPage == _totalPages - 1 
                ? Icons.rocket_launch 
                : Icons.chevron_right),
            label: Text(_currentPage == _totalPages - 1 
                ? 'onboarding.get_started'.tr()
                : 'onboarding.next'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final Widget illustration;
  final LinearGradient gradient;
  final List<OnboardingFeature>? features;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
    required this.gradient,
    this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Illustration
            Expanded(
              flex: 2,
              child: Center(child: illustration),
            ),
            
            // Content
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ).animate().slideY(begin: 0.3, duration: 600.ms).fadeIn(),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate(delay: 200.ms).slideY(begin: 0.3, duration: 600.ms).fadeIn(),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ).animate(delay: 400.ms).slideY(begin: 0.3, duration: 600.ms).fadeIn(),
                  
                  // Features (if provided)
                  if (features != null) ...[
                    const SizedBox(height: 24),
                    ...features!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final feature = entry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeatureRow(feature: feature),
                      ).animate(delay: Duration(milliseconds: 600 + (index * 150)))
                          .slideX(begin: -0.3, duration: 500.ms)
                          .fadeIn();
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingFeature {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureRow extends StatelessWidget {
  final OnboardingFeature feature;

  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            feature.icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                feature.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double delay;

  const _FloatingIcon({
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .moveY(
          begin: 0,
          end: -10,
          duration: (2 + delay).seconds,
        )
        .then()
        .moveY(
          begin: -10,
          end: 0,
          duration: (2 + delay).seconds,
        );
  }
}

// Add math import for cos/sin functions
import 'dart:math' show cos, sin;