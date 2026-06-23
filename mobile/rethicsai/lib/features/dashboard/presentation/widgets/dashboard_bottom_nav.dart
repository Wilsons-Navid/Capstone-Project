import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/utils/app_router.dart';

/// Bottom navigation bar with a notch for the centre-docked AI FAB.
class DashboardBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const DashboardBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_rounded, 'nav.dashboard'.tr(), 0),
              _buildNavItem(Icons.report_rounded, 'nav.report'.tr(), 1),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(Icons.track_changes_rounded, 'nav.cases'.tr(), 3),
              _buildNavItem(Icons.person_rounded, 'nav.profile'.tr(), 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
          ), // Column
        ), // Container
      ), // InkWell
    ); // Semantics
  }
}

/// Centre-docked FAB opening the AI assistant.
class AiAssistantFab extends StatelessWidget {
  const AiAssistantFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondaryColor,
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, AppRouter.aiChat);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.psychology_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
