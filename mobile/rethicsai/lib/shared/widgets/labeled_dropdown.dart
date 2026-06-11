import 'package:flutter/material.dart';

import '../../core/themes/app_theme.dart';

/// Dropdown with an always-visible caption above a filled field.
///
/// Replaces floating-label dropdowns in dense filter rows, where the
/// Material floating label clips against the outline border and becomes
/// unreadable once a value is selected.
class LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final String? Function(T?)? validator;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: value,
          hint: hint,
          validator: validator,
          style: const TextStyle(
            color: AppTheme.primaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          iconEnabledColor: AppTheme.primaryLight,
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.secondaryColor,
                width: 1.5,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
