import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late Locale _selectedLocale;

  final List<LanguageOption> _languages = [
    LanguageOption(
      locale: const Locale('en'),
      name: 'English',
      nativeName: 'English',
      flag: 'ðŸ‡ºðŸ‡¸',
      region: 'Global',
    ),
    LanguageOption(
      locale: const Locale('sw'),
      name: 'Swahili',
      nativeName: 'Kiswahili',
      flag: 'ðŸ‡°ðŸ‡ª',
      region: 'East Africa',
    ),
    LanguageOption(
      locale: const Locale('fr'),
      name: 'French',
      nativeName: 'FranÃ§ais',
      flag: 'ðŸ‡«ðŸ‡·',
      region: 'West & Central Africa',
    ),
    LanguageOption(
      locale: const Locale('ar'),
      name: 'Arabic',
      nativeName: 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©',
      flag: 'ðŸ‡¸ðŸ‡¦',
      region: 'North Africa',
    ),
    LanguageOption(
      locale: const Locale('ha'),
      name: 'Hausa',
      nativeName: 'Harshen Hausa',
      flag: 'ðŸ‡³ðŸ‡¬',
      region: 'West Africa',
    ),
    LanguageOption(
      locale: const Locale('yo'),
      name: 'Yoruba',
      nativeName: 'ÃˆdÃ¨ YorÃ¹bÃ¡',
      flag: 'ðŸ‡³ðŸ‡¬',
      region: 'West Africa',
    ),
    LanguageOption(
      locale: const Locale('ig'),
      name: 'Igbo',
      nativeName: 'Asá»¥sá»¥ Igbo',
      flag: 'ðŸ‡³ðŸ‡¬',
      region: 'West Africa',
    ),
    LanguageOption(
      locale: const Locale('zu'),
      name: 'Zulu',
      nativeName: 'isiZulu',
      flag: 'ðŸ‡¿ðŸ‡¦',
      region: 'Southern Africa',
    ),
    LanguageOption(
      locale: const Locale('xh'),
      name: 'Xhosa',
      nativeName: 'isiXhosa',
      flag: 'ðŸ‡¿ðŸ‡¦',
      region: 'Southern Africa',
    ),
    LanguageOption(
      locale: const Locale('af'),
      name: 'Afrikaans',
      nativeName: 'Afrikaans',
      flag: 'ðŸ‡¿ðŸ‡¦',
      region: 'Southern Africa',
    ),
    LanguageOption(
      locale: const Locale('dua'),
      name: 'Sawa (Duala)',
      nativeName: 'Duala',
      flag: 'ðŸ‡¨ðŸ‡²',
      region: 'Central Africa',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with English as default - will be updated in didChangeDependencies
    _selectedLocale = const Locale('en');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to access context.locale
    _selectedLocale = context.locale;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AfricanPatternBackground(opacity: 0.03),
          SafeArea(
            child: Column(
              children: [
                // Header
                PremiumSectionHeader(
                  title: 'language.settings'.tr(),
                  subtitle: 'language.choose_preferred'.tr(),
                  icon: Icons.language,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  action: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),

                // Current Language Info
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.secondaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.translate,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'common.current_language'.tr(),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getCurrentLanguageName(),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _getCurrentLanguageFlag(),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),

                // Languages List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final language = _languages[index];
                      final isSelected = _selectedLocale == language.locale;
                      final isCurrent = _isCurrentLanguage(language.locale);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.15),
                                    AppTheme.secondaryColor.withOpacity(0.15),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                )
                              : isCurrent
                                  ? Border.all(
                                      color: AppTheme.secondaryColor,
                                      width: 1,
                                    )
                                  : Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectLanguage(language),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Flag
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _flagFor(language.locale),
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Language Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            language.name,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppTheme.primaryColor
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: AppTheme.secondaryGradient,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'common.current'.tr(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      language.nativeName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      language.region,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Selection Indicator
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Apply Button
                if (!_isCurrentLanguage(_selectedLocale))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _applyLanguageChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle),
                          const SizedBox(width: 12),
                          Text(
                            'common.apply_changes'.tr(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentLanguageName() {
    try {
      final currentLocale = context.locale;
      final current = _languages.firstWhere(
        (lang) => lang.locale == currentLocale,
        orElse: () => _languages.first,
      );
      return '${current.name} (${current.nativeName})';
    } catch (e) {
      return 'English (English)';
    }
  }

  String _getCurrentLanguageFlag() {
    try {
      final currentLocale = context.locale;
      final current = _languages.firstWhere(
        (lang) => lang.locale == currentLocale,
        orElse: () => _languages.first,
      );
      return _flagFor(currentLocale);
    } catch (e) {
      return '🇬🇧';
    }
  }


  String _flagFor(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧';
      case 'sw':
        return '🇰🇪';
      case 'fr':
        return '🇫🇷';
      case 'ar':
        return '🇪🇬';
      case 'ha':
      case 'yo':
      case 'ig':
        return '🇳🇬';
      case 'zu':
      case 'xh':
      case 'af':
        return '🇿🇦';
      case 'dua':
        return '🇨🇲';
      default:
        return '🏳️';
    }
  }

  bool _isCurrentLanguage(Locale locale) {
    try {
      return context.locale == locale;
    } catch (e) {
      return locale.languageCode == 'en';
    }
  }

  void _selectLanguage(LanguageOption language) {
    setState(() {
      _selectedLocale = language.locale;
    });
  }

  void _applyLanguageChange() {
    // Apply the language change
    context.setLocale(_selectedLocale);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'common.language_changed'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'common.close'.tr(),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Pop back to previous screen after a brief delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  String _getLanguageName(Locale locale) {
    final language = _languages.firstWhere(
      (lang) => lang.locale == locale,
      orElse: () => _languages.first,
    );
    return language.name;
  }
}

class LanguageOption {
  final Locale locale;
  final String name;
  final String nativeName;
  final String flag;
  final String region;

  const LanguageOption({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.region,
  });
}
