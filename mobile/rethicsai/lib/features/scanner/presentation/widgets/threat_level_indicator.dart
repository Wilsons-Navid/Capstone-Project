import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/wilson_ai_service.dart';

class ThreatLevelIndicator extends StatelessWidget {
  final ThreatLevel threatLevel;
  final double size;
  final bool showLabel;
  final bool animated;

  const ThreatLevelIndicator({
    super.key,
    required this.threatLevel,
    this.size = 120,
    this.showLabel = true,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getThreatColors(threatLevel);
    final icon = _getThreatIcon(threatLevel);
    final label = _getThreatLabel(threatLevel);
    final progress = _getThreatProgress(threatLevel);

    Widget indicator = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.primary.withOpacity(0.8),
            colors.secondary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress Ring
          SizedBox(
            width: size * 0.9,
            height: size * 0.9,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          
          // Icon
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: size * 0.3,
                color: Colors.white,
              ),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (animated) {
      indicator = indicator
          .animate()
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 600.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 400.ms);

      // Add pulsing animation for high threat levels
      if (threatLevel == ThreatLevel.high || threatLevel == ThreatLevel.critical) {
        indicator = indicator
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 1500.ms,
            );
      }
    }

    return Column(
      children: [
        indicator,
        if (showLabel) ...[
          const SizedBox(height: 12),
          _buildThreatDescription(),
        ],
      ],
    );
  }

  Widget _buildThreatDescription() {
    final description = _getThreatDescription(threatLevel);
    final colors = _getThreatColors(threatLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        description,
        style: TextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  ThreatColors _getThreatColors(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return ThreatColors(
          primary: Colors.green[600]!,
          secondary: Colors.green[400]!,
        );
      case ThreatLevel.medium:
        return ThreatColors(
          primary: Colors.orange[600]!,
          secondary: Colors.orange[400]!,
        );
      case ThreatLevel.high:
        return ThreatColors(
          primary: Colors.red[600]!,
          secondary: Colors.red[400]!,
        );
      case ThreatLevel.critical:
        return ThreatColors(
          primary: Colors.red[900]!,
          secondary: Colors.red[700]!,
        );
      default:
        return ThreatColors(
          primary: Colors.grey[600]!,
          secondary: Colors.grey[400]!,
        );
    }
  }

  IconData _getThreatIcon(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return Icons.verified_user;
      case ThreatLevel.medium:
        return Icons.warning;
      case ThreatLevel.high:
        return Icons.error;
      case ThreatLevel.critical:
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }

  String _getThreatLabel(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return 'LOW\nRISK';
      case ThreatLevel.medium:
        return 'MEDIUM\nRISK';
      case ThreatLevel.high:
        return 'HIGH\nRISK';
      case ThreatLevel.critical:
        return 'CRITICAL\nRISK';
      default:
        return 'UNKNOWN\nRISK';
    }
  }

  String _getThreatDescription(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return 'Content appears safe';
      case ThreatLevel.medium:
        return 'Some suspicious elements detected';
      case ThreatLevel.high:
        return 'Likely malicious content';
      case ThreatLevel.critical:
        return 'Highly dangerous - Avoid at all costs';
      default:
        return 'Unable to determine threat level';
    }
  }

  double _getThreatProgress(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return 0.25;
      case ThreatLevel.medium:
        return 0.5;
      case ThreatLevel.high:
        return 0.75;
      case ThreatLevel.critical:
        return 1.0;
      default:
        return 0.0;
    }
  }
}

class ThreatColors {
  final Color primary;
  final Color secondary;

  const ThreatColors({
    required this.primary,
    required this.secondary,
  });
}