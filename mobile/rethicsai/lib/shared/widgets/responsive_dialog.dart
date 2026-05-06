import 'package:flutter/material.dart';

/// A responsive dialog widget that prevents overflow on small screens
class ResponsiveDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final double maxHeightFactor;
  final EdgeInsetsGeometry? contentPadding;
  final ShapeBorder? shape;

  const ResponsiveDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.maxWidth = 500,
    this.maxHeightFactor = 0.9,
    this.contentPadding,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600 || screenSize.height < 600;
    
    return Dialog(
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isSmallScreen 
            ? screenSize.width * 0.95 
            : screenSize.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: screenSize.height * maxHeightFactor,
          minHeight: 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title section (fixed)
            if (title != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: title!,
              ),
            
            // Content section (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding ?? const EdgeInsets.all(24),
                child: content,
              ),
            ),
            
            // Actions section (fixed)
            if (actions != null && actions!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildResponsiveActions(context, actions!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResponsiveActions(BuildContext context, List<Widget> actions) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // On very small screens, stack buttons vertically
    if (screenWidth < 400) {
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: action,
            );
          }).toList(),
        ),
      ];
    }
    
    // On larger screens, use horizontal layout with spacing
    final List<Widget> spacedActions = [];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) spacedActions.add(const SizedBox(width: 12));
      spacedActions.add(Flexible(child: actions[i]));
    }
    
    return spacedActions;
  }
}

/// A responsive alert dialog that prevents overflow
class ResponsiveAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;
  final double maxHeightFactor;

  const ResponsiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.maxWidth = 400,
    this.maxHeightFactor = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.zero,
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * maxHeightFactor,
          maxWidth: maxWidth,
        ),
        child: content != null 
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: content!,
              )
            : null,
      ),
      actions: actions,
      actionsPadding: const EdgeInsets.all(16),
    );
  }
}

/// Helper extension for showing responsive dialogs
extension ResponsiveDialogExtension on BuildContext {
  Future<T?> showResponsiveDialog<T>({
    required Widget content,
    Widget? title,
    List<Widget>? actions,
    double maxWidth = 500,
    double maxHeightFactor = 0.9,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (context) => ResponsiveDialog(
        title: title,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
        maxHeightFactor: maxHeightFactor,
      ),
    );
  }

  Future<T?> showResponsiveAlertDialog<T>({
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    double maxWidth = 400,
    double maxHeightFactor = 0.8,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (context) => ResponsiveAlertDialog(
        title: title,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
        maxHeightFactor: maxHeightFactor,
      ),
    );
  }
}

/// Responsive form field with optimized spacing for dialogs
class ResponsiveFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;

  const ResponsiveFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: isSmallScreen ? 6 : 8,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          isDense: true,
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
      ),
    );
  }
}

/// Responsive dropdown field
class ResponsiveDropdownField<T> extends StatelessWidget {
  final T? value;
  final String? labelText;
  final String? hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  const ResponsiveDropdownField({
    super.key,
    this.value,
    this.labelText,
    this.hintText,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: isSmallScreen ? 6 : 8,
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}