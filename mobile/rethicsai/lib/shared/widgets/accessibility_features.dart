import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/themes/app_theme.dart';

// Enhanced accessibility wrapper with comprehensive features
class AccessibilityWrapper extends StatefulWidget {
  final Widget child;
  final String? semanticsLabel;
  final String? semanticsHint;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final bool isButton;
  final bool isHeader;
  final bool isSelected;
  final bool isEnabled;

  const AccessibilityWrapper({
    super.key,
    required this.child,
    this.semanticsLabel,
    this.semanticsHint,
    this.excludeSemantics = false,
    this.onTap,
    this.isButton = false,
    this.isHeader = false,
    this.isSelected = false,
    this.isEnabled = true,
  });

  @override
  State<AccessibilityWrapper> createState() => _AccessibilityWrapperState();
}

class _AccessibilityWrapperState extends State<AccessibilityWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      button: widget.isButton,
      header: widget.isHeader,
      selected: widget.isSelected,
      enabled: widget.isEnabled,
      excludeSemantics: widget.excludeSemantics,
      onTap: widget.onTap,
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
          
          if (focused) {
            // Provide haptic feedback when focused
            HapticFeedback.selectionClick();
            
            // Announce focus for screen readers
            if (widget.semanticsLabel != null) {
              SemanticsService.announce(
                'accessibility.focused'.tr(args: [widget.semanticsLabel!]),
                ui.TextDirection.ltr,
              );
            }
          }
        },
        child: Container(
          decoration: _isFocused ? BoxDecoration(
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ) : null,
          child: widget.child,
        ),
      ),
    );
  }
}

// High contrast theme provider for better accessibility
class HighContrastTheme extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const HighContrastTheme({
    super.key,
    required this.child,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Theme(
      data: _buildHighContrastTheme(context),
      child: child,
    );
  }

  ThemeData _buildHighContrastTheme(BuildContext context) {
    final base = Theme.of(context);
    
    return base.copyWith(
      // High contrast colors
      colorScheme: base.colorScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
        error: Colors.red[900]!,
        onError: Colors.white,
      ),
      
      // High contrast text theme
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // High contrast button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      
      // High contrast input decoration
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 3),
        ),
      ),
    );
  }
}

// Screen reader optimized text widget
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? semanticsLabel;
  final bool isHeading;
  final int headingLevel;
  final TextAlign textAlign;
  final int? maxLines;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.semanticsLabel,
    this.isHeading = false,
    this.headingLevel = 1,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );

    if (isHeading) {
      textWidget = Semantics(
        header: true,
        child: textWidget,
      );
    }

    return Semantics(
      label: semanticsLabel ?? text,
      child: textWidget,
    );
  }
}

// Voice control helper
class VoiceControlHelper extends StatefulWidget {
  final Widget child;
  final List<VoiceCommand> commands;

  const VoiceControlHelper({
    super.key,
    required this.child,
    required this.commands,
  });

  @override
  State<VoiceControlHelper> createState() => _VoiceControlHelperState();
}

class _VoiceControlHelperState extends State<VoiceControlHelper> {
  final Map<String, GlobalKey> _commandKeys = {};

  @override
  void initState() {
    super.initState();
    
    // Create global keys for each command
    for (final command in widget.commands) {
      _commandKeys[command.keyword] = GlobalKey();
    }
    
    _setupVoiceCommands();
  }

  void _setupVoiceCommands() {
    // Register voice commands with the system
    // This is a placeholder - actual implementation would depend on
    // speech recognition package and platform capabilities
    
    for (final command in widget.commands) {
      _registerVoiceCommand(command);
    }
  }

  void _registerVoiceCommand(VoiceCommand command) {
    // Placeholder for voice command registration
    // In a real implementation, this would integrate with speech recognition
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _executeVoiceCommand(String keyword) {
    final command = widget.commands.firstWhere(
      (cmd) => cmd.keyword.toLowerCase() == keyword.toLowerCase(),
      orElse: () => VoiceCommand(keyword: '', action: () {}),
    );
    
    if (command.keyword.isNotEmpty) {
      // Provide feedback
      HapticFeedback.mediumImpact();
      SemanticsService.announce(
        'accessibility.voice_command_executed'.tr(args: [keyword]),
        ui.TextDirection.ltr,
      );
      
      // Execute command
      command.action();
    }
  }
}

// Enhanced button with full accessibility support
class AccessibleButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final ButtonStyle? style;
  final Widget? icon;
  final String? semanticsLabel;
  final String? semanticsHint;
  final bool autofocus;

  const AccessibleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
    this.style,
    this.icon,
    this.semanticsLabel,
    this.semanticsHint,
    this.autofocus = false,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? widget.text,
      hint: widget.semanticsHint,
      enabled: widget.enabled,
      onTap: widget.onPressed,
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
          
          if (focused) {
            HapticFeedback.selectionClick();
            SemanticsService.announce(
              'accessibility.button_focused'.tr(args: [widget.text]),
              ui.TextDirection.ltr,
            );
          }
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.identity()
                ..scale(_isPressed ? 0.95 : 1.0),
              child: Container(
                decoration: BoxDecoration(
                  border: _isFocused ? Border.all(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ) : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isHovered ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: widget.icon != null
                    ? ElevatedButton.icon(
                        onPressed: widget.enabled ? widget.onPressed : null,
                        icon: widget.icon!,
                        label: Text(widget.text),
                        style: widget.style,
                      )
                    : ElevatedButton(
                        onPressed: widget.enabled ? widget.onPressed : null,
                        style: widget.style,
                        child: Text(widget.text),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Screen reader announcement helper
class ScreenReaderAnnouncer extends StatelessWidget {
  final String message;
  final Widget child;
  final bool announceOnBuild;

  const ScreenReaderAnnouncer({
    super.key,
    required this.message,
    required this.child,
    this.announceOnBuild = false,
  });

  @override
  Widget build(BuildContext context) {
    if (announceOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SemanticsService.announce(message, ui.TextDirection.ltr);
      });
    }
    
    return child;
  }

  static void announce(String message) {
    SemanticsService.announce(message, ui.TextDirection.ltr);
  }
}

// Accessibility settings provider
class AccessibilitySettings extends StatefulWidget {
  final Widget child;

  const AccessibilitySettings({super.key, required this.child});

  @override
  State<AccessibilitySettings> createState() => _AccessibilitySettingsState();
}

class _AccessibilitySettingsState extends State<AccessibilitySettings> {
  bool _highContrastMode = false;
  bool _largeTextMode = false;
  bool _reducedMotion = false;
  bool _screenReaderMode = false;

  @override
  void initState() {
    super.initState();
    _loadAccessibilitySettings();
  }

  void _loadAccessibilitySettings() {
    // Load settings from shared preferences or device settings
    final mediaQuery = MediaQuery.of(context);
    
    setState(() {
      _highContrastMode = mediaQuery.highContrast;
      _largeTextMode = mediaQuery.textScaleFactor > 1.2;
      _reducedMotion = mediaQuery.disableAnimations;
      _screenReaderMode = mediaQuery.accessibleNavigation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityProvider(
      highContrastMode: _highContrastMode,
      largeTextMode: _largeTextMode,
      reducedMotion: _reducedMotion,
      screenReaderMode: _screenReaderMode,
      child: widget.child,
    );
  }
}

// Accessibility provider for global settings
class AccessibilityProvider extends InheritedWidget {
  final bool highContrastMode;
  final bool largeTextMode;
  final bool reducedMotion;
  final bool screenReaderMode;

  const AccessibilityProvider({
    super.key,
    required this.highContrastMode,
    required this.largeTextMode,
    required this.reducedMotion,
    required this.screenReaderMode,
    required super.child,
  });

  static AccessibilityProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AccessibilityProvider>();
  }

  @override
  bool updateShouldNotify(AccessibilityProvider oldWidget) {
    return highContrastMode != oldWidget.highContrastMode ||
           largeTextMode != oldWidget.largeTextMode ||
           reducedMotion != oldWidget.reducedMotion ||
           screenReaderMode != oldWidget.screenReaderMode;
  }
}

// Gesture-friendly touch targets
class AccessibleTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minTouchTargetSize;

  const AccessibleTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minTouchTargetSize = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minTouchTargetSize,
        minHeight: minTouchTargetSize,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(child: child),
      ),
    );
  }
}

// Skip navigation links for keyboard users
class SkipNavigationLinks extends StatelessWidget {
  final List<SkipLink> links;

  const SkipNavigationLinks({
    super.key,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          children: links.map((link) => 
            ElevatedButton(
              onPressed: () {
                // Scroll to target or trigger action
                link.action();
                
                // Announce navigation
                SemanticsService.announce(
                  'accessibility.navigated_to'.tr(args: [link.label]),
                  ui.TextDirection.ltr,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: Text('accessibility.skip_to'.tr(args: [link.label])),
            ),
          ).toList(),
        ),
      ),
    );
  }
}

// Data models
class VoiceCommand {
  final String keyword;
  final VoidCallback action;
  final String? description;

  VoiceCommand({
    required this.keyword,
    required this.action,
    this.description,
  });
}

class SkipLink {
  final String label;
  final VoidCallback action;

  SkipLink({
    required this.label,
    required this.action,
  });
}

// Extension for accessibility helpers
extension AccessibilityExtensions on Widget {
  Widget withAccessibility({
    String? label,
    String? hint,
    bool isButton = false,
    bool isHeader = false,
    VoidCallback? onTap,
  }) {
    return AccessibilityWrapper(
      semanticsLabel: label,
      semanticsHint: hint,
      isButton: isButton,
      isHeader: isHeader,
      onTap: onTap,
      child: this,
    );
  }

  Widget withScreenReader(String message, {bool announceOnBuild = false}) {
    return ScreenReaderAnnouncer(
      message: message,
      announceOnBuild: announceOnBuild,
      child: this,
    );
  }
}