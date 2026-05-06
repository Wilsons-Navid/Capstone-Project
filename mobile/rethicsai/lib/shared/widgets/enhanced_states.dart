import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';

import '../../core/themes/app_theme.dart';
import 'african_pattern_background.dart';

// Enhanced loading states with African-inspired animations
class EnhancedLoadingState extends StatefulWidget {
  final String? message;
  final LoadingType type;
  final Color? color;
  final double size;

  const EnhancedLoadingState({
    super.key,
    this.message,
    this.type = LoadingType.circular,
    this.color,
    this.size = 48.0,
  });

  @override
  State<EnhancedLoadingState> createState() => _EnhancedLoadingStateState();
}

class _EnhancedLoadingStateState extends State<EnhancedLoadingState>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _primaryController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _secondaryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _primaryController, curve: Curves.linear),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _secondaryController, curve: Curves.easeInOut),
    );
    
    _primaryController.repeat();
    _secondaryController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildLoadingWidget(),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.color ?? AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds, colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.5),
                Colors.transparent,
              ]),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget() {
    switch (widget.type) {
      case LoadingType.circular:
        return _buildCircularLoader();
      case LoadingType.african:
        return _buildAfricanLoader();
      case LoadingType.dots:
        return _buildDotsLoader();
      case LoadingType.shield:
        return _buildShieldLoader();
      case LoadingType.skeleton:
        return _buildSkeletonLoader();
    }
  }

  Widget _buildCircularLoader() {
    return CircularProgressIndicator(
      color: widget.color ?? AppTheme.primaryColor,
      strokeWidth: 3,
    );
  }

  Widget _buildAfricanLoader() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.africanSunsetGradient,
            ),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.security,
                      color: AppTheme.primaryColor,
                      size: widget.size * 0.4,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotsLoader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _primaryController,
            builder: (context, child) {
              final delay = index * 0.3;
              final animationValue = (_primaryController.value - delay).clamp(0.0, 1.0);
              
              return Transform.scale(
                scale: 0.5 + (0.5 * (1 + (animationValue * 2 - 1).abs())),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color ?? AppTheme.primaryColor,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildShieldLoader() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(widget.size * 0.2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.security,
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        _SkeletonBox(width: widget.size, height: 12),
        const SizedBox(height: 8),
        _SkeletonBox(width: widget.size * 0.7, height: 12),
        const SizedBox(height: 8),
        _SkeletonBox(width: widget.size * 0.9, height: 12),
      ],
    );
  }
}

// Enhanced error states with actionable UI
class EnhancedErrorState extends StatefulWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final ErrorType errorType;
  final bool showDetails;

  const EnhancedErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.errorType = ErrorType.general,
    this.showDetails = false,
  });

  @override
  State<EnhancedErrorState> createState() => _EnhancedErrorStateState();
}

class _EnhancedErrorStateState extends State<EnhancedErrorState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _showDetails = widget.showDetails;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error illustration
          _buildErrorIllustration()
              .animate()
              .scale(delay: 100.ms, duration: 400.ms, curve: Curves.bounceOut),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _getErrorColor(),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 12),
          
          // Message
          Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons()
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          
          // Details section (expandable)
          if (widget.showDetails) ...[
            const SizedBox(height: 16),
            _buildDetailsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorIllustration() {
    IconData iconData;
    Color backgroundColor;
    
    switch (widget.errorType) {
      case ErrorType.network:
        iconData = Icons.wifi_off;
        backgroundColor = Colors.orange;
        break;
      case ErrorType.server:
        iconData = Icons.cloud_off;
        backgroundColor = Colors.red;
        break;
      case ErrorType.authentication:
        iconData = Icons.lock_outline;
        backgroundColor = Colors.purple;
        break;
      case ErrorType.validation:
        iconData = Icons.warning;
        backgroundColor = Colors.amber;
        break;
      case ErrorType.permission:
        iconData = Icons.block;
        backgroundColor = Colors.deepOrange;
        break;
      case ErrorType.general:
      default:
        iconData = Icons.error_outline;
        backgroundColor = Colors.grey;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: backgroundColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        iconData,
        size: 60,
        color: backgroundColor,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action
        if (widget.actionText != null && widget.onAction != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onAction,
              icon: Icon(_getActionIcon()),
              label: Text(widget.actionText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getErrorColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        
        // Secondary action
        if (widget.secondaryActionText != null && widget.onSecondaryAction != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSecondaryAction,
              icon: const Icon(Icons.info_outline),
              label: Text(widget.secondaryActionText!),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getErrorColor(),
                side: BorderSide(color: _getErrorColor()),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsSection() {
    return ExpansionTile(
      title: Text(
        'errors.show_details'.tr(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: _getErrorColor(),
        ),
      ),
      leading: Icon(
        Icons.info_outline,
        color: _getErrorColor(),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'errors.error_type'.tr(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(widget.errorType.name.toUpperCase()),
              const SizedBox(height: 8),
              Text(
                'errors.timestamp'.tr(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(DateFormat('MMM dd, yyyy HH:mm:ss').format(DateTime.now())),
              const SizedBox(height: 8),
              Text(
                'errors.suggestions'.tr(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ..._getErrorSuggestions().map((suggestion) => 
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(suggestion)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getErrorColor() {
    switch (widget.errorType) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.authentication:
        return Colors.purple;
      case ErrorType.validation:
        return Colors.amber[700]!;
      case ErrorType.permission:
        return Colors.deepOrange;
      case ErrorType.general:
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getActionIcon() {
    switch (widget.errorType) {
      case ErrorType.network:
        return Icons.refresh;
      case ErrorType.server:
        return Icons.cloud_sync;
      case ErrorType.authentication:
        return Icons.login;
      case ErrorType.validation:
        return Icons.edit;
      case ErrorType.permission:
        return Icons.settings;
      case ErrorType.general:
      default:
        return Icons.refresh;
    }
  }

  List<String> _getErrorSuggestions() {
    switch (widget.errorType) {
      case ErrorType.network:
        return [
          'errors.suggestions.check_connection'.tr(),
          'errors.suggestions.try_wifi'.tr(),
          'errors.suggestions.restart_app'.tr(),
        ];
      case ErrorType.server:
        return [
          'errors.suggestions.wait_moment'.tr(),
          'errors.suggestions.check_status'.tr(),
          'errors.suggestions.contact_support'.tr(),
        ];
      case ErrorType.authentication:
        return [
          'errors.suggestions.check_credentials'.tr(),
          'errors.suggestions.reset_password'.tr(),
          'errors.suggestions.clear_data'.tr(),
        ];
      case ErrorType.validation:
        return [
          'errors.suggestions.check_input'.tr(),
          'errors.suggestions.required_fields'.tr(),
        ];
      case ErrorType.permission:
        return [
          'errors.suggestions.enable_permissions'.tr(),
          'errors.suggestions.app_settings'.tr(),
        ];
      case ErrorType.general:
      default:
        return [
          'errors.suggestions.try_again'.tr(),
          'errors.suggestions.restart_app'.tr(),
        ];
    }
  }
}

// Enhanced empty state with call-to-action
class EnhancedEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? illustration;
  final EmptyStateType type;

  const EnhancedEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.illustration,
    this.type = EmptyStateType.general,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          (illustration ?? _buildDefaultIllustration())
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 16),
          
          // Message
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          
          // Action button
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(_getActionIcon()),
              label: Text(actionText!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ).animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultIllustration() {
    IconData iconData;
    Color color;
    
    switch (type) {
      case EmptyStateType.incidents:
        iconData = Icons.report_problem_outlined;
        color = AppTheme.primaryColor;
        break;
      case EmptyStateType.education:
        iconData = Icons.school_outlined;
        color = AppTheme.accentColor;
        break;
      case EmptyStateType.notifications:
        iconData = Icons.notifications_outlined;
        color = AppTheme.secondaryColor;
        break;
      case EmptyStateType.search:
        iconData = Icons.search_off_outlined;
        color = Colors.grey;
        break;
      case EmptyStateType.general:
      default:
        iconData = Icons.inbox_outlined;
        color = Colors.grey;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 60,
        color: color,
      ),
    );
  }

  IconData _getActionIcon() {
    switch (type) {
      case EmptyStateType.incidents:
        return Icons.add_circle_outline;
      case EmptyStateType.education:
        return Icons.explore;
      case EmptyStateType.notifications:
        return Icons.refresh;
      case EmptyStateType.search:
        return Icons.search;
      case EmptyStateType.general:
      default:
        return Icons.add;
    }
  }
}

// Skeleton loading components
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: Colors.grey[100],
    ).animate(_animationController);
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

// Enums for different types
enum LoadingType {
  circular,
  african,
  dots,
  shield,
  skeleton,
}

enum ErrorType {
  general,
  network,
  server,
  authentication,
  validation,
  permission,
}

enum EmptyStateType {
  general,
  incidents,
  education,
  notifications,
  search,
}