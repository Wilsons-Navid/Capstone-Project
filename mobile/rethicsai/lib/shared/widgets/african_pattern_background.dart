import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/themes/app_theme.dart';

class AfricanPatternBackground extends StatefulWidget {
  final double opacity;
  final List<Color> colors;

  const AfricanPatternBackground({
    super.key,
    this.opacity = 0.1,
    this.colors = const [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.saharaGold,
      AppTheme.secondaryColor,
      AppTheme.baobabBrown,
    ],
  });

  @override
  State<AfricanPatternBackground> createState() => _AfricanPatternBackgroundState();
}

class _AfricanPatternBackgroundState extends State<AfricanPatternBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_controller);
    _controller.repeat();
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
        return CustomPaint(
          painter: AfricanPatternPainter(
            animation: _animation.value,
            opacity: widget.opacity,
            colors: widget.colors,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class AfricanPatternPainter extends CustomPainter {
  final double animation;
  final double opacity;
  final List<Color> colors;

  AfricanPatternPainter({
    required this.animation,
    required this.opacity,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Create a beautiful gradient background
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF8F9FA),
        const Color(0xFFE8F5E8).withOpacity(0.5),
      ],
    );

    final backgroundRect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = backgroundGradient.createShader(backgroundRect);
    canvas.drawRect(backgroundRect, paint);

    // Draw African-inspired geometric patterns
    _drawKentePattern(canvas, size, paint);
    _drawAdinkraSymbols(canvas, size, paint);
    _drawTribalDiamonds(canvas, size, paint);
    _drawBaobabSilhouettes(canvas, size, paint);
  }

  void _drawKentePattern(Canvas canvas, Size size, Paint paint) {
    const patternSize = 80.0;
    final rows = (size.height / patternSize).ceil() + 1;
    final cols = (size.width / patternSize).ceil() + 1;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final x = j * patternSize + (animation * 20) % patternSize;
        final y = i * patternSize;

        // Alternating pattern
        if ((i + j) % 2 == 0) {
          paint.color = colors[0].withOpacity(opacity * 0.3);
          final rect = Rect.fromLTWH(x, y, patternSize / 2, patternSize / 4);
          canvas.drawRect(rect, paint);

          paint.color = colors[1].withOpacity(opacity * 0.2);
          final rect2 = Rect.fromLTWH(x + patternSize / 4, y + patternSize / 8, 
                                     patternSize / 4, patternSize / 8);
          canvas.drawRect(rect2, paint);
        }
      }
    }
  }

  void _drawAdinkraSymbols(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;

    final symbolSize = 40.0;
    final spacing = 120.0;
    final rows = (size.height / spacing).ceil();
    final cols = (size.width / spacing).ceil();

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final centerX = j * spacing + spacing / 2 + (animation * 10) % spacing;
        final centerY = i * spacing + spacing / 2;

        paint.color = colors[2].withOpacity(opacity * 0.4);

        // Draw Gye Nyame symbol (simplified)
        final path = Path();
        path.addOval(Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: symbolSize,
          height: symbolSize,
        ));

        // Add cross in center
        path.moveTo(centerX - symbolSize / 4, centerY);
        path.lineTo(centerX + symbolSize / 4, centerY);
        path.moveTo(centerX, centerY - symbolSize / 4);
        path.lineTo(centerX, centerY + symbolSize / 4);

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawTribalDiamonds(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;

    final diamondSize = 30.0;
    final spacing = 100.0;
    final rows = (size.height / spacing).ceil();
    final cols = (size.width / spacing).ceil();

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final centerX = j * spacing + (i.isEven ? 0 : spacing / 2) + 
                       (animation * 5) % spacing;
        final centerY = i * spacing * 0.8;

        paint.color = colors[3].withOpacity(opacity * 0.15);

        final path = Path();
        path.moveTo(centerX, centerY - diamondSize / 2);
        path.lineTo(centerX + diamondSize / 2, centerY);
        path.lineTo(centerX, centerY + diamondSize / 2);
        path.lineTo(centerX - diamondSize / 2, centerY);
        path.close();

        canvas.drawPath(path, paint);

        // Inner diamond
        paint.color = colors[4].withOpacity(opacity * 0.1);
        final innerPath = Path();
        final innerSize = diamondSize * 0.5;
        innerPath.moveTo(centerX, centerY - innerSize / 2);
        innerPath.lineTo(centerX + innerSize / 2, centerY);
        innerPath.lineTo(centerX, centerY + innerSize / 2);
        innerPath.lineTo(centerX - innerSize / 2, centerY);
        innerPath.close();

        canvas.drawPath(innerPath, paint);
      }
    }
  }

  void _drawBaobabSilhouettes(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;
    paint.color = colors[0].withOpacity(opacity * 0.05);

    // Draw stylized baobab trees at the bottom
    final treeHeight = size.height * 0.3;
    final numTrees = 3;
    final treeSpacing = size.width / (numTrees + 1);

    for (int i = 0; i < numTrees; i++) {
      final treeX = (i + 1) * treeSpacing + (animation * 2) % 20;
      final treeY = size.height - treeHeight;

      final path = Path();
      
      // Tree trunk
      final trunkWidth = 20.0;
      path.moveTo(treeX - trunkWidth / 2, size.height);
      path.lineTo(treeX - trunkWidth / 2, treeY + treeHeight * 0.7);
      
      // Crown (simplified baobab shape)
      path.quadraticBezierTo(
        treeX - treeHeight * 0.3, treeY + treeHeight * 0.5,
        treeX - treeHeight * 0.2, treeY + treeHeight * 0.3,
      );
      
      path.quadraticBezierTo(
        treeX, treeY,
        treeX + treeHeight * 0.2, treeY + treeHeight * 0.3,
      );
      
      path.quadraticBezierTo(
        treeX + treeHeight * 0.3, treeY + treeHeight * 0.5,
        treeX + trunkWidth / 2, treeY + treeHeight * 0.7,
      );
      
      path.lineTo(treeX + trunkWidth / 2, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}