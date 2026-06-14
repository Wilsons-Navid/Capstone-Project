import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';

class QuickSuggestions extends StatelessWidget {
  final Function(String, {String? customResponse}) onSuggestionTap;

  const QuickSuggestions({
    super.key,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ai.suggestions'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return _buildSuggestionCard(
                  suggestions[index],
                  index,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(QuickSuggestion suggestion, int index) {
    return Container(
      width: 200,
      constraints: const BoxConstraints(
        minWidth: 180,
        maxWidth: 220,
      ),
      margin: EdgeInsets.only(right: index < _getSuggestions().length - 1 ? 16 : 0),
      decoration: BoxDecoration(
        gradient: suggestion.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: suggestion.gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSuggestionTap(suggestion.text),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  suggestion.icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    suggestion.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  flex: 2,
                  child: Text(
                    suggestion.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.3, end: 0)
        .shimmer(delay: Duration(milliseconds: 1000 + (200 * index)), duration: 1500.ms);
  }

  List<QuickSuggestion> _getSuggestions() {
    return [
      QuickSuggestion(
        title: 'Password Security',
        subtitle: 'Learn about strong passwords',
        text: 'How can I create a strong password?',
        icon: Icons.lock,
        gradient: AppTheme.primaryGradient,
        category: 'password_security',
      ),
      QuickSuggestion(
        title: 'Phishing Protection',
        subtitle: 'Identify suspicious emails',
        text: 'How do I identify phishing emails?',
        icon: Icons.email,
        gradient: AppTheme.secondaryGradient,
        category: 'phishing_awareness',
      ),
      QuickSuggestion(
        title: 'WiFi Security',
        subtitle: 'Secure your connection',
        text: 'How can I secure my WiFi network?',
        icon: Icons.wifi,
        gradient: AppTheme.accentGradient,
        category: 'wifi_security',
      ),
      QuickSuggestion(
        title: 'Mobile Money',
        subtitle: 'M-Pesa & mobile banking safety',
        text: 'How can I secure my mobile money account?',
        icon: Icons.account_balance_wallet,
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        ),
        category: 'mobile_money_security',
      ),
      QuickSuggestion(
        title: 'Social Media',
        subtitle: 'Privacy settings guide',
        text: 'How do I protect my privacy on social media?',
        icon: Icons.groups,
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
        ),
        category: 'social_media_safety',
      ),
      QuickSuggestion(
        title: 'Online Shopping',
        subtitle: 'Safe payment practices',
        text: 'How can I shop safely online?',
        icon: Icons.shopping_cart,
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
        category: 'online_shopping_safety',
      ),
      QuickSuggestion(
        title: 'Emergency Help',
        subtitle: 'Been hacked or scammed?',
        text: 'I think I\'ve been hacked or scammed. What do I do?',
        icon: Icons.emergency,
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
        ),
        category: 'incident_response',
      ),
      QuickSuggestion(
        title: 'General Security',
        subtitle: 'Cybersecurity basics',
        text: 'What are the most important cybersecurity practices for Africa?',
        icon: Icons.security,
        gradient: const LinearGradient(
          colors: [Color(0xFF455A64), Color(0xFF607D8B)],
        ),
        category: 'general_security',
      ),
    ];
  }
}

class QuickSuggestion {
  final String title;
  final String subtitle;
  final String text;
  final IconData icon;
  final LinearGradient gradient;
  final String category;

  const QuickSuggestion({
    required this.title,
    required this.subtitle,
    required this.text,
    required this.icon,
    required this.gradient,
    required this.category,
  });
}