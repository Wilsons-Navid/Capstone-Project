import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/themes/app_theme.dart';

// Enhanced text field with better UX
class EnhancedTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool required;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const EnhancedTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.required = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  bool _isFocused = false;
  bool _hasError = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _labelAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _borderColorAnimation = ColorTween(
      begin: AppTheme.outline,
      end: AppTheme.primaryColor,
    ).animate(_animationController);
    
    _focusNode.addListener(_handleFocusChange);
    
    // Check initial state
    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused || (widget.controller != null && widget.controller!.text.isNotEmpty)) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _validateInput(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() {
        _hasError = error != null;
        _isValid = !_hasError && value.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null || _hasError;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // Text field container
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: hasError
                      ? AppTheme.errorColor
                      : _borderColorAnimation.value ?? AppTheme.outline,
                  width: _isFocused ? 2 : 1,
                ),
                color: widget.enabled 
                    ? Theme.of(context).colorScheme.surface
                    : Colors.grey.withOpacity(0.1),
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                enabled: widget.enabled,
                textCapitalization: widget.textCapitalization,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                decoration: InputDecoration(
                  labelText: widget.label != null && widget.required 
                      ? '${widget.label} *' 
                      : widget.label,
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                  ),
                  labelStyle: TextStyle(
                    color: _isFocused 
                        ? AppTheme.secondaryColor 
                        : AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: _buildSuffixIcon(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  counterText: '', // Hide character counter
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: widget.enabled 
                      ? AppTheme.primaryColor
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) {
                  _validateInput(value);
                  widget.onChanged?.call(value);
                  
                  // Animate label based on content
                  if (value.isNotEmpty && !_animationController.isCompleted) {
                    _animationController.forward();
                  } else if (value.isEmpty && !_isFocused) {
                    _animationController.reverse();
                  }
                },
                onFieldSubmitted: widget.onSubmitted,
                validator: widget.validator,
              ),
            );
          },
        ),
        
        // Helper text, error text, or success indicator
        if (widget.helperText != null || widget.errorText != null || _isValid)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                // Status icon
                Icon(
                  hasError 
                      ? Icons.error_outline
                      : _isValid 
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                  size: 16,
                  color: hasError 
                      ? AppTheme.errorColor
                      : _isValid 
                          ? AppTheme.successColor
                          : Colors.grey,
                ),
                const SizedBox(width: 6),
                
                // Text
                Expanded(
                  child: Text(
                    widget.errorText ?? 
                    (_isValid ? 'forms.valid_input'.tr() : widget.helperText ?? ''),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasError 
                          ? AppTheme.errorColor
                          : _isValid 
                              ? AppTheme.successColor
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: -0.5, end: 0, duration: 200.ms),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return GestureDetector(
        onTap: widget.onSuffixIconPressed,
        child: widget.suffixIcon,
      );
    }
    
    // Show validation status
    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      if (_hasError) {
        return const Icon(
          Icons.error,
          color: AppTheme.errorColor,
        );
      } else if (_isValid) {
        return const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
        );
      }
    }
    
    return null;
  }
}

// Enhanced dropdown with search capability
class EnhancedDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownItem<T>> items;
  final Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool required;
  final bool searchable;
  final Widget? prefixIcon;

  const EnhancedDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.searchable = false,
    this.prefixIcon,
  });

  @override
  State<EnhancedDropdown<T>> createState() => _EnhancedDropdownState<T>();
}

class _EnhancedDropdownState<T> extends State<EnhancedDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownItem<T>> _filteredItems = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items.where((item) {
        return item.label.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  widget.label!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.required) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        
        // Dropdown button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.outline),
            color: widget.enabled 
                ? Theme.of(context).colorScheme.surface
                : Colors.grey.withOpacity(0.1),
          ),
          child: widget.searchable 
              ? _buildSearchableDropdown()
              : _buildStandardDropdown(),
        ),
      ],
    );
  }

  Widget _buildStandardDropdown() {
    return DropdownButtonFormField<T>(
      value: widget.value,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: widget.items.map((item) {
        return DropdownMenuItem<T>(
          value: item.value,
          child: Text(item.label),
        );
      }).toList(),
      onChanged: widget.enabled ? widget.onChanged : null,
      validator: widget.validator,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildSearchableDropdown() {
    return Column(
      children: [
        // Current selection or search field
        InkWell(
          onTap: widget.enabled ? () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          } : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.value != null 
                        ? widget.items.firstWhere((item) => item.value == widget.value).label
                        : widget.hint ?? 'forms.select_option'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: widget.value != null 
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        
        // Expandable search and options
        if (_isExpanded)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.outline)),
            ),
            child: Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'forms.search'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.outline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: _filterItems,
                  ),
                ),
                
                // Options list
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item.value == widget.value;
                      
                      return ListTile(
                        title: Text(item.label),
                        leading: item.icon,
                        trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                        selected: isSelected,
                        onTap: () {
                          widget.onChanged?.call(item.value);
                          setState(() {
                            _isExpanded = false;
                          });
                          _searchController.clear();
                          _filteredItems = widget.items;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.5, duration: 200.ms).fadeIn(),
      ],
    );
  }
}

// Enhanced button with loading state
class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isPrimary;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.style,
    this.icon,
    this.isPrimary = true,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
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
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: widget.isPrimary
                ? ElevatedButton.icon(
                    onPressed: _handlePress,
                    icon: _buildButtonContent(),
                    label: const SizedBox.shrink(),
                    style: widget.style ?? ElevatedButton.styleFrom(
                      backgroundColor: widget.enabled && !widget.isLoading
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: widget.enabled ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _handlePress,
                    icon: _buildButtonContent(),
                    label: const SizedBox.shrink(),
                    style: widget.style ?? OutlinedButton.styleFrom(
                      foregroundColor: widget.enabled && !widget.isLoading
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      side: BorderSide(
                        color: widget.enabled && !widget.isLoading
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isPrimary ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('forms.loading'.tr()),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _handlePress() {
    if (!widget.enabled || widget.isLoading) return;
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    widget.onPressed?.call();
  }
}

// Enhanced checkbox with better visuals
class EnhancedCheckbox extends StatefulWidget {
  final bool value;
  final Function(bool?)? onChanged;
  final String? title;
  final String? subtitle;
  final bool enabled;

  const EnhancedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.title,
    this.subtitle,
    this.enabled = true,
  });

  @override
  State<EnhancedCheckbox> createState() => _EnhancedCheckboxState();
}

class _EnhancedCheckboxState extends State<EnhancedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.value) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.enabled ? () {
        widget.onChanged?.call(!widget.value);
      } : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Custom checkbox
            AnimatedBuilder(
              animation: _checkAnimation,
              builder: (context, child) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.value 
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.value 
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: widget.value
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ).animate(target: _checkAnimation.value)
                            .scale(duration: 200.ms)
                      : null,
                );
              },
            ),
            
            // Text content
            if (widget.title != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: widget.enabled 
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.grey,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Data class for dropdown items
class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? icon;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}