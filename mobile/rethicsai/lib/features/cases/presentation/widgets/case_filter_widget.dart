import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/themes/app_theme.dart';

class CaseFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const CaseFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All Cases', 'icon': Icons.list_alt},
      {'key': 'submitted', 'label': 'Submitted', 'icon': Icons.upload},
      {'key': 'in_progress', 'label': 'In Progress', 'icon': Icons.hourglass_empty},
      {'key': 'resolved', 'label': 'Resolved', 'icon': Icons.check_circle},
    ];

    return Container(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.asMap().entries.map((entry) {
            final index = entry.key;
            final filter = entry.value;
            final isSelected = selectedFilter == filter['key'];
            
            return Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 12,
                right: index == filters.length - 1 ? 0 : 0,
              ),
              child: GestureDetector(
                onTap: () => onFilterChanged(filter['key'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: Duration(milliseconds: index * 100),
                  )
                  .slideY(begin: 0.3, end: 0),
            );
          }).toList(),
        ),
      ),
    );
  }
}