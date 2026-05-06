import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;

import '../../core/themes/app_theme.dart';

// Enhanced statistics card with animated numbers
class EnhancedStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const EnhancedStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  State<EnhancedStatsCard> createState() => _EnhancedStatsCardState();
}

class _EnhancedStatsCardState extends State<EnhancedStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _numberAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _numberAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and trend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (widget.trend != null)
                          _buildTrendIndicator(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Value with animation
                    AnimatedBuilder(
                      animation: _numberAnimation,
                      builder: (context, child) {
                        // Try to parse numeric value for animation
                        final numericValue = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), ''));
                        final animatedValue = numericValue != null 
                            ? (numericValue * _numberAnimation.value).toInt().toString()
                            : widget.value;
                        
                        return Text(
                          numericValue != null ? animatedValue : widget.value,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Subtitle
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isPositiveTrend ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            widget.trend!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced chart widget with African-inspired colors
class EnhancedChart extends StatefulWidget {
  final List<ChartData> data;
  final ChartType type;
  final String? title;
  final double height;
  final bool animated;

  const EnhancedChart({
    super.key,
    required this.data,
    this.type = ChartType.line,
    this.title,
    this.height = 200,
    this.animated = true,
  });

  @override
  State<EnhancedChart> createState() => _EnhancedChartState();
}

class _EnhancedChartState extends State<EnhancedChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.animated) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: widget.height,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: ChartPainter(
                      data: widget.data,
                      type: widget.type,
                      animationProgress: _animation.value,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final color = _getChartColor(index);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.saharaGold,
      AppTheme.victoriaBlue,
      AppTheme.clayRed,
    ];
    return colors[index % colors.length];
  }
}

// Enhanced activity timeline
class EnhancedActivityTimeline extends StatefulWidget {
  final List<ActivityItem> activities;
  final int maxItems;

  const EnhancedActivityTimeline({
    super.key,
    required this.activities,
    this.maxItems = 10,
  });

  @override
  State<EnhancedActivityTimeline> createState() => _EnhancedActivityTimelineState();
}

class _EnhancedActivityTimelineState extends State<EnhancedActivityTimeline> {
  @override
  Widget build(BuildContext context) {
    final displayActivities = widget.activities.take(widget.maxItems).toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'dashboard.recent_activity'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (displayActivities.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayActivities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final activity = displayActivities[index];
                  return _buildActivityItem(activity, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity, int index) {
    return Row(
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getActivityColor(activity.type),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getActivityColor(activity.type).withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (index < widget.activities.length - 1)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Activity content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getActivityIcon(activity.type),
                    size: 16,
                    color: _getActivityColor(activity.type),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                activity.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(activity.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate(delay: Duration(milliseconds: index * 100))
        .slideX(begin: -0.3, duration: 400.ms)
        .fadeIn();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'dashboard.no_activity'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'dashboard.activity_will_appear'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.incidentReported:
        return AppTheme.errorColor;
      case ActivityType.caseUpdated:
        return AppTheme.secondaryColor;
      case ActivityType.educationCompleted:
        return AppTheme.accentColor;
      case ActivityType.aiInteraction:
        return AppTheme.primaryColor;
      case ActivityType.login:
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.incidentReported:
        return Icons.report_problem;
      case ActivityType.caseUpdated:
        return Icons.update;
      case ActivityType.educationCompleted:
        return Icons.school;
      case ActivityType.aiInteraction:
        return Icons.psychology;
      case ActivityType.login:
        return Icons.login;
      default:
        return Icons.circle;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'dashboard.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return 'dashboard.minutes_ago'.tr(args: [difference.inMinutes.toString()]);
    } else if (difference.inHours < 24) {
      return 'dashboard.hours_ago'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inDays < 7) {
      return 'dashboard.days_ago'.tr(args: [difference.inDays.toString()]);
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}

// Enhanced progress indicator with African styling
class EnhancedProgressIndicator extends StatefulWidget {
  final double progress;
  final String label;
  final String? sublabel;
  final Color? color;
  final double height;
  final bool animated;

  const EnhancedProgressIndicator({
    super.key,
    required this.progress,
    required this.label,
    this.sublabel,
    this.color,
    this.height = 8,
    this.animated = true,
  });

  @override
  State<EnhancedProgressIndicator> createState() => _EnhancedProgressIndicatorState();
}

class _EnhancedProgressIndicatorState extends State<EnhancedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    if (widget.animated) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                );
              },
            ),
          ],
        ),
        
        if (widget.sublabel != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.sublabel!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Progress bar
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Custom chart painter
class ChartPainter extends CustomPainter {
  final List<ChartData> data;
  final ChartType type;
  final double animationProgress;

  ChartPainter({
    required this.data,
    required this.type,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    switch (type) {
      case ChartType.line:
        _paintLineChart(canvas, size);
        break;
      case ChartType.bar:
        _paintBarChart(canvas, size);
        break;
      case ChartType.pie:
        _paintPieChart(canvas, size);
        break;
    }
  }

  void _paintLineChart(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final maxValue = data.map((e) => e.value).reduce(math.max);
    final minValue = data.map((e) => e.value).reduce(math.min);
    final valueRange = maxValue - minValue;

    final path = Path();
    
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].value - minValue) / valueRange) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Create animated path
    final pathMetric = path.computeMetrics().first;
    final animatedPath = pathMetric.extractPath(0, pathMetric.length * animationProgress);
    
    paint.color = AppTheme.primaryColor;
    canvas.drawPath(animatedPath, paint);

    // Draw points
    for (int i = 0; i < (data.length * animationProgress).floor(); i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].value - minValue) / valueRange) * size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = AppTheme.primaryColor,
      );
    }
  }

  void _paintBarChart(Canvas canvas, Size size) {
    final maxValue = data.map((e) => e.value).reduce(math.max);
    final barWidth = size.width / data.length * 0.8;
    final barSpacing = size.width / data.length * 0.2;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i].value / maxValue) * size.height * animationProgress;
      final x = i * (barWidth + barSpacing) + barSpacing / 2;
      final y = size.height - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final paint = Paint()..color = _getChartColor(i);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  void _paintPieChart(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    final total = data.map((e) => e.value).reduce((a, b) => a + b);

    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi * animationProgress;
      
      final paint = Paint()
        ..color = _getChartColor(i)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  Color _getChartColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.saharaGold,
      AppTheme.victoriaBlue,
      AppTheme.clayRed,
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data models
class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}

class ActivityItem {
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  ActivityItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });
}

// Enums
enum ChartType { line, bar, pie }

enum ActivityType {
  incidentReported,
  caseUpdated,
  educationCompleted,
  aiInteraction,
  login,
  other,
}