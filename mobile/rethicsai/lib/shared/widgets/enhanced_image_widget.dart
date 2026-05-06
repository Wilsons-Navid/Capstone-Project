import 'package:flutter/material.dart';
import '../../core/constants/app_images.dart';

/// Enhanced image widget with fallback support and loading states
class EnhancedImageWidget extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool showPlaceholder;

  const EnhancedImageWidget({
    super.key,
    this.imagePath,
    required this.fallbackIcon,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.borderRadius,
    this.showPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || !showPlaceholder) {
      return _buildFallbackIcon();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          // Show loading placeholder
          return _buildLoadingPlaceholder();
        },
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: width != null ? width! * 0.6 : 24,
        color: color,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Colors.grey[400]!,
          ),
        ),
      ),
    );
  }
}

/// Cybersecurity themed image widget
class CybersecurityImageWidget extends StatelessWidget {
  final CybersecurityImageType imageType;
  final double? size;
  final Color? color;
  final bool useGradientOverlay;

  const CybersecurityImageWidget({
    super.key,
    required this.imageType,
    this.size = 64.0,
    this.color,
    this.useGradientOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageData = _getImageData(imageType);
    
    Widget imageWidget = EnhancedImageWidget(
      imagePath: imageData.imagePath,
      fallbackIcon: imageData.fallbackIcon,
      width: size,
      height: size,
      color: color,
      borderRadius: BorderRadius.circular(8),
    );

    if (useGradientOverlay) {
      imageWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              imageData.gradientColor.withOpacity(0.1),
              imageData.gradientColor.withOpacity(0.3),
            ],
          ),
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  _CybersecurityImageData _getImageData(CybersecurityImageType type) {
    switch (type) {
      case CybersecurityImageType.shieldLock:
        return _CybersecurityImageData(
          imagePath: AppImages.shieldLock,
          fallbackIcon: Icons.security,
          gradientColor: Colors.blue,
        );
      case CybersecurityImageType.mobileSecurity:
        return _CybersecurityImageData(
          imagePath: AppImages.mobileSecurity,
          fallbackIcon: Icons.smartphone,
          gradientColor: Colors.green,
        );
      case CybersecurityImageType.wifiSecurity:
        return _CybersecurityImageData(
          imagePath: AppImages.wifiSecurity,
          fallbackIcon: Icons.wifi_protected_setup,
          gradientColor: Colors.orange,
        );
      case CybersecurityImageType.passwordSecurity:
        return _CybersecurityImageData(
          imagePath: AppImages.passwordSecurity,
          fallbackIcon: Icons.lock,
          gradientColor: Colors.purple,
        );
      case CybersecurityImageType.phishingProtection:
        return _CybersecurityImageData(
          imagePath: AppImages.phishingProtection,
          fallbackIcon: Icons.email,
          gradientColor: Colors.red,
        );
      case CybersecurityImageType.dataProtection:
        return _CybersecurityImageData(
          imagePath: AppImages.dataProtection,
          fallbackIcon: Icons.storage,
          gradientColor: Colors.indigo,
        );
      case CybersecurityImageType.aiAssistant:
        return _CybersecurityImageData(
          imagePath: AppImages.aiAssistant,
          fallbackIcon: Icons.psychology,
          gradientColor: Colors.cyan,
        );
      case CybersecurityImageType.threatScanner:
        return _CybersecurityImageData(
          imagePath: AppImages.threatScanner,
          fallbackIcon: Icons.scanner,
          gradientColor: Colors.pink,
        );
      case CybersecurityImageType.incidentReport:
        return _CybersecurityImageData(
          imagePath: AppImages.incidentReport,
          fallbackIcon: Icons.report_problem,
          gradientColor: Colors.amber,
        );
      case CybersecurityImageType.emergencyHelp:
        return _CybersecurityImageData(
          imagePath: AppImages.emergencyHelp,
          fallbackIcon: Icons.emergency,
          gradientColor: Colors.red,
        );
    }
  }
}

class _CybersecurityImageData {
  final String imagePath;
  final IconData fallbackIcon;
  final Color gradientColor;

  _CybersecurityImageData({
    required this.imagePath,
    required this.fallbackIcon,
    required this.gradientColor,
  });
}

enum CybersecurityImageType {
  shieldLock,
  mobileSecurity,
  wifiSecurity,
  passwordSecurity,
  phishingProtection,
  dataProtection,
  aiAssistant,
  threatScanner,
  incidentReport,
  emergencyHelp,
}

/// African-themed image widget for cultural context
class AfricanContextImageWidget extends StatelessWidget {
  final AfricanImageType imageType;
  final double? size;
  final Color? overlayColor;

  const AfricanContextImageWidget({
    super.key,
    required this.imageType,
    this.size = 100.0,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageData = _getAfricanImageData(imageType);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        EnhancedImageWidget(
          imagePath: imageData.imagePath,
          fallbackIcon: imageData.fallbackIcon,
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(12),
        ),
        if (overlayColor != null)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: overlayColor!.withOpacity(0.2),
            ),
          ),
      ],
    );
  }

  _AfricanImageData _getAfricanImageData(AfricanImageType type) {
    switch (type) {
      case AfricanImageType.mobileMoney:
        return _AfricanImageData(
          imagePath: AppImages.mobileMoney,
          fallbackIcon: Icons.account_balance_wallet,
        );
      case AfricanImageType.communityProtection:
        return _AfricanImageData(
          imagePath: AppImages.communityProtection,
          fallbackIcon: Icons.groups,
        );
      case AfricanImageType.digitalInclusion:
        return _AfricanImageData(
          imagePath: AppImages.digitalInclusion,
          fallbackIcon: Icons.language,
        );
      case AfricanImageType.africanCybersecurity:
        return _AfricanImageData(
          imagePath: AppImages.africanCybersecurity,
          fallbackIcon: Icons.public,
        );
    }
  }
}

class _AfricanImageData {
  final String imagePath;
  final IconData fallbackIcon;

  _AfricanImageData({
    required this.imagePath,
    required this.fallbackIcon,
  });
}

enum AfricanImageType {
  mobileMoney,
  communityProtection,
  digitalInclusion,
  africanCybersecurity,
}