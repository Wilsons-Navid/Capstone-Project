import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import 'enhanced_image_widget.dart';

class DashboardFeatureCard extends StatefulWidget {
  final DashboardFeature feature;
  final Duration delay;

  const DashboardFeatureCard({
    super.key,
    required this.feature,
    this.delay = Duration.zero,
  });

  @override
  State<DashboardFeatureCard> createState() => _DashboardFeatureCardState();
}

class _DashboardFeatureCardState extends State<DashboardFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _hoverController.forward(),
            onTapUp: (_) => _hoverController.reverse(),
            onTapCancel: () => _hoverController.reverse(),
            onTap: () {
              try {
                Navigator.pushNamed(context, widget.feature.route);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigation error: ${widget.feature.title}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.feature.gradient.colors.first.withOpacity(0.3),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.feature.useImage && widget.feature.imagePath != null
                          ? Image.asset(
                              widget.feature.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to gradient if image fails
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: widget.feature.gradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: widget.feature.gradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                    ),
                  ),
                  
                  // Gradient Overlay for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.feature.gradient.colors.first.withOpacity(0.7),
                            widget.feature.gradient.colors.last.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  
                  // Background pattern
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: FeatureCardPatternPainter(),
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enhanced Icon or Image
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: widget.feature.useImage && widget.feature.imagePath != null
                                ? EnhancedImageWidget(
                                    imagePath: widget.feature.imagePath,
                                    fallbackIcon: widget.feature.icon,
                                    width: 16,
                                    height: 16,
                                    color: Colors.white,
                                    fit: BoxFit.contain,
                                  )
                                : Icon(
                                    widget.feature.icon,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Title
                        Text(
                          widget.feature.title.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 2),
                        
                        // Subtitle
                        Flexible(
                          child: Text(
                            widget.feature.subtitle.tr(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 9,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(height: 2),
                        
                        // Arrow icon
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.7),
                            size: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate(delay: widget.delay)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0)
        .shimmer(delay: 1000.ms, duration: 1500.ms);
  }
}

class FeatureCardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw subtle geometric patterns
    final path = Path();
    
    // Top right corner pattern
    path.moveTo(size.width * 0.7, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.15,
      size.width * 0.7,
      0,
    );
    
    canvas.drawPath(path, paint);
    
    // Bottom left corner pattern
    paint.color = Colors.white.withOpacity(0.03);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.lineTo(0, size.height);
    path2.lineTo(size.width * 0.3, size.height);
    path2.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.85,
      0,
      size.height * 0.7,
    );
    
    canvas.drawPath(path2, paint);
    
    // Add some dots
    paint.color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      1.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
