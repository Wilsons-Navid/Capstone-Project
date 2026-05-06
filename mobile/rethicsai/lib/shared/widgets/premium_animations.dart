import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../core/themes/app_theme.dart';

/// Floating particles animation for African ambiance
class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final List<Color> colors;
  final double speed;

  const FloatingParticles({
    super.key,
    this.particleCount = 20,
    this.colors = const [
      AppTheme.saharaGold,
      AppTheme.primaryColor,
      AppTheme.accentColor,
    ],
    this.speed = 1.0,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        color: widget.colors[index % widget.colors.length],
        size: math.Random().nextDouble() * 4 + 2,
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        velocity: math.Random().nextDouble() * 0.1 + 0.05,
        direction: math.Random().nextDouble() * 2 * math.pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _controller.value * widget.speed),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  Color color;
  double size;
  double x;
  double y;
  double velocity;
  double direction;

  Particle({
    required this.color,
    required this.size,
    required this.x,
    required this.y,
    required this.velocity,
    required this.direction,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double time;

  ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final x = (particle.x + math.sin(time * particle.velocity + particle.direction) * 0.1) * size.width;
      final y = (particle.y + math.cos(time * particle.velocity) * 0.05) * size.height;

      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Ripple effect animation for premium interactions
class RippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;
  final Duration duration;

  const RippleEffect({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor = AppTheme.primaryColor,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward().then((_) {
      _controller.reset();
      setState(() {
        _tapPosition = null;
      });
    });
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: CustomPaint(
        painter: _tapPosition != null
            ? RipplePainter(_tapPosition!, _animation.value, widget.rippleColor)
            : null,
        child: widget.child,
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Offset center;
  final double progress;
  final Color color;

  RipplePainter(this.center, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0) {
      final radius = math.max(size.width, size.height) * progress;
      final paint = Paint()
        ..color = color.withOpacity(1 - progress)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Pulse animation for status indicators
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleFactor;
  final bool enabled;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.scaleFactor = 1.1,
    this.enabled = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enabled ? _animation.value : 1.0,
          child: widget.child,
        );
      },
    );
  }
}

/// Slide reveal animation for premium content
class SlideReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset direction;

  const SlideReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.direction = const Offset(0, 50),
  });

  @override
  State<SlideReveal> createState() => _SlideRevealState();
}

class _SlideRevealState extends State<SlideReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _slideAnimation = Tween<Offset>(
      begin: widget.direction,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8),
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// African-inspired loading spinner
class AfricanSpinner extends StatefulWidget {
  final Color color;
  final double size;
  final double strokeWidth;

  const AfricanSpinner({
    super.key,
    this.color = AppTheme.primaryColor,
    this.size = 48.0,
    this.strokeWidth = 3.0,
  });

  @override
  State<AfricanSpinner> createState() => _AfricanSpinnerState();
}

class _AfricanSpinnerState extends State<AfricanSpinner>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _animation1 = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(_controller1);
    _animation2 = Tween<double>(begin: 0, end: -2 * math.pi)
        .animate(_controller2);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_animation1, _animation2]),
        builder: (context, child) {
          return CustomPaint(
            painter: AfricanSpinnerPainter(
              progress1: _animation1.value,
              progress2: _animation2.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
            size: Size.square(widget.size),
          );
        },
      ),
    );
  }
}

class AfricanSpinnerPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final Color color;
  final double strokeWidth;

  AfricanSpinnerPainter({
    required this.progress1,
    required this.progress2,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    
    final paint1 = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final paint2 = Paint()
      ..color = AppTheme.saharaGold.withOpacity(0.6)
      ..strokeWidth = strokeWidth / 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Outer arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress1,
      math.pi,
      false,
      paint1,
    );
    
    // Inner arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.6),
      progress2,
      math.pi * 0.8,
      false,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}