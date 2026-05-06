import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/themes/app_theme.dart';
import 'african_pattern_background.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  
  const AnimatedSplashScreen({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _logoController;
  
  late List<Animation<double>> _letterAnimations;
  late List<Animation<Offset>> _letterSlideAnimations;
  late List<Animation<double>> _letterRotationAnimations;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;
  late Animation<Color?> _backgroundAnimation;
  
  final String _text = "RETHICSSEC";
  final List<Color> _letterColors = [
    AppTheme.primaryColor,     // Primary Blue
    AppTheme.secondaryColor,   // Secondary Blue
    AppTheme.saharaGold,       // Gold accent
    AppTheme.copperAccent,     // Copper accent
    AppTheme.primaryColor,     // Primary Blue
    AppTheme.secondaryColor,   // Secondary Blue
    AppTheme.saharaGold,       // Gold accent
    AppTheme.copperAccent,     // Copper accent
    AppTheme.primaryColor,     // Primary Blue
    AppTheme.secondaryColor,   // Secondary Blue
  ];
  
  final List<IconData> _particleIcons = [
    Icons.security,
    Icons.shield,
    Icons.lock,
    Icons.verified_user,
    Icons.fingerprint,
    Icons.vpn_key,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Main animation controller for the entire sequence (ultra fast)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Pulse animation for background effects (fast)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Particle animation controller (fast)
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Logo animation controller (fast)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Background color animation
    _backgroundAnimation = ColorTween(
      begin: AppTheme.primaryColor,
      end: AppTheme.secondaryColor,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOutCubic),
    ));
    
    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));
    
    // Particle animation
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
    
    // Logo animations
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
    ));
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutBack),
    ));
    
    // Letter animations with staggered timing
    _letterAnimations = [];
    _letterSlideAnimations = [];
    _letterRotationAnimations = [];
    
    for (int i = 0; i < _text.length; i++) {
      double start = 0.1 + (i * 0.04); // Faster stagger timing (reduced from 0.06 to 0.04)
      double end = start + 0.08; // Reduced duration per letter (from 0.12 to 0.08)
      
      // Scale animation for each letter
      _letterAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
      
      // Slide animation for each letter
      _letterSlideAnimations.add(
        Tween<Offset>(
          begin: Offset(0, -1.5 + (i % 2 == 0 ? -0.5 : 0.5)), // Smoother alternating motion
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
      
      // Rotation animation for each letter
      _letterRotationAnimations.add(
        Tween<double>(
          begin: (i % 2 == 0 ? -1 : 1) * math.pi, // Reduced rotation for smoothness
          end: 0,
        ).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }
  }

  void _startAnimationSequence() async {
    // Start all animations simultaneously for maximum speed
    _pulseController.repeat(reverse: true);
    _particleController.forward();
    
    // Start both main animations in parallel
    final mainAnimationFuture = _mainController.forward();
    final logoAnimationFuture = _logoController.forward();
    
    // Wait for animations to complete
    await Future.wait([mainAnimationFuture, logoAnimationFuture]);
    
    // Complete immediately
    widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _pulseController,
          _particleController,
          _logoController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.africanSunsetGradient,
            ),
            child: Stack(
              children: [
                // African Pattern Background with animation
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1 * _mainController.value,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: const AfricanPatternBackground(),
                    ),
                  ),
                ),
                
                // Animated particles
                ..._buildParticles(),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animation
                      Opacity(
                        opacity: _logoFadeAnimation.value,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(bottom: 40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3 * _logoFadeAnimation.value),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.2 * _logoFadeAnimation.value),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/Rethicsec.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Animated text
                      _buildAnimatedText(),
                      
                      // Subtitle with fade in
                      const SizedBox(height: 30),
                      Opacity(
                        opacity: (_mainController.value > 0.8) ? (_mainController.value - 0.8) * 5 : 0.0,
                        child: Text(
                          'Protecting Africa Digitally',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Loading indicator at bottom
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (_mainController.value > 0.7) ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing Security...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedText() {
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: _text.split('').asMap().entries.map((entry) {
            int index = entry.key;
            String letter = entry.value;
            
            return AnimatedBuilder(
              animation: _letterAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _letterAnimations[index].value,
                  child: Transform.rotate(
                    angle: _letterRotationAnimations[index].value,
                    child: SlideTransition(
                      position: _letterSlideAnimations[index],
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                _letterColors[index],
                                _letterColors[index].withOpacity(0.8),
                                Colors.white,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds);
                          },
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: _letterColors[index].withOpacity(0.6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    List<Widget> particles = [];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Define strategic positions for better visual composition
    final List<Map<String, dynamic>> particlePositions = [
      // Top corners and edges
      {'x': 0.05, 'y': 0.08, 'size': 1.2, 'delay': 0.0},
      {'x': 0.95, 'y': 0.12, 'size': 1.0, 'delay': 0.1},
      {'x': 0.15, 'y': 0.05, 'size': 0.8, 'delay': 0.2},
      {'x': 0.85, 'y': 0.07, 'size': 0.9, 'delay': 0.3},
      
      // Left and right sides (avoiding center content)
      {'x': 0.02, 'y': 0.35, 'size': 1.1, 'delay': 0.4},
      {'x': 0.98, 'y': 0.38, 'size': 1.3, 'delay': 0.5},
      {'x': 0.08, 'y': 0.55, 'size': 0.7, 'delay': 0.6},
      {'x': 0.92, 'y': 0.52, 'size': 1.0, 'delay': 0.7},
      
      // Mid-level scattered positions
      {'x': 0.25, 'y': 0.25, 'size': 0.9, 'delay': 0.8},
      {'x': 0.75, 'y': 0.28, 'size': 1.1, 'delay': 0.9},
      {'x': 0.18, 'y': 0.72, 'size': 1.0, 'delay': 1.0},
      {'x': 0.82, 'y': 0.68, 'size': 0.8, 'delay': 1.1},
      
      // Bottom area (avoiding UI elements)
      {'x': 0.12, 'y': 0.85, 'size': 1.2, 'delay': 1.2},
      {'x': 0.88, 'y': 0.82, 'size': 1.0, 'delay': 1.3},
      {'x': 0.35, 'y': 0.88, 'size': 0.9, 'delay': 1.4},
      {'x': 0.65, 'y': 0.90, 'size': 1.1, 'delay': 1.5},
      
      // Additional scattered particles for depth
      {'x': 0.05, 'y': 0.65, 'size': 0.6, 'delay': 1.6},
      {'x': 0.95, 'y': 0.62, 'size': 0.8, 'delay': 1.7},
      {'x': 0.30, 'y': 0.15, 'size': 0.7, 'delay': 1.8},
      {'x': 0.70, 'y': 0.18, 'size': 0.9, 'delay': 1.9},
    ];
    
    for (int i = 0; i < particlePositions.length; i++) {
      final pos = particlePositions[i];
      double animationOffset = (pos['delay'] * 0.15) % 1.0;
      double progress = (_particleAnimation.value + animationOffset) % 1.0;
      
      // Calculate position with slight random movement
      double baseX = pos['x'] * screenWidth;
      double baseY = pos['y'] * screenHeight;
      
      // Add subtle floating animation
      double floatX = baseX + (math.sin(progress * 2 * math.pi + i) * 15);
      double floatY = baseY + (math.cos(progress * 2 * math.pi + i * 0.7) * 10);
      
      // Dynamic sizing based on position and progress
      double baseSizeMultiplier = pos['size'];
      double dynamicSize = 18 + (baseSizeMultiplier * 12) + (progress * 8);
      
      // Opacity with breathing effect
      double breathingOpacity = 0.4 + (math.sin(progress * 4 * math.pi) * 0.3);
      double finalOpacity = ((1 - progress) * 0.9) * breathingOpacity.abs();
      
      particles.add(
        Positioned(
          left: floatX - (dynamicSize / 2),
          top: floatY - (dynamicSize / 2),
          child: Opacity(
            opacity: finalOpacity,
            child: Transform.scale(
              scale: 0.4 + (progress * 1.8) + (baseSizeMultiplier * 0.3),
              child: Transform.rotate(
                angle: progress * 3 * math.pi + (i * 0.5),
                child: Container(
                  width: dynamicSize,
                  height: dynamicSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(dynamicSize / 2),
                    gradient: RadialGradient(
                      colors: [
                        _letterColors[i % _letterColors.length].withOpacity(0.8),
                        _letterColors[i % _letterColors.length].withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _letterColors[i % _letterColors.length].withOpacity(0.7),
                        blurRadius: 20 * baseSizeMultiplier,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 15 * baseSizeMultiplier,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _particleIcons[i % _particleIcons.length],
                      color: Colors.white.withOpacity(0.95),
                      size: dynamicSize * 0.6,
                      shadows: [
                        Shadow(
                          color: _letterColors[i % _letterColors.length].withOpacity(0.8),
                          blurRadius: 12,
                          offset: const Offset(0, 0),
                        ),
                        Shadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return particles;
  }
}