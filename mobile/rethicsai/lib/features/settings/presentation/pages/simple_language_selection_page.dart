import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';

class SimpleLanguageSelectionPage extends StatefulWidget {
  const SimpleLanguageSelectionPage({super.key});

  @override
  State<SimpleLanguageSelectionPage> createState() => _SimpleLanguageSelectionPageState();
}

class _SimpleLanguageSelectionPageState extends State<SimpleLanguageSelectionPage> {
  late Locale _selectedLocale;
  late Locale _currentLocale;

  final List<LanguageOption> _languages = [
    LanguageOption(
      locale: const Locale('en'),
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      region: 'Global',
    ),
    LanguageOption(
      locale: const Locale('sw'),
      name: 'Swahili',
      nativeName: 'Kiswahili',
      flag: '🇰🇪',
      region: 'East Africa',
    ),
    LanguageOption(
      locale: const Locale('fr'),
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      region: 'West & Central Africa',
    ),
    LanguageOption(
      locale: const Locale('ar'),
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      region: 'North Africa',
    ),
    LanguageOption(
      locale: const Locale('ha'),
      name: 'Hausa',
      nativeName: 'Harshen Hausa',
      flag: '🇳🇬',
      region: 'West Africa',
    ),
    LanguageOption(
      locale: const Locale('yo'),
      name: 'Yoruba',
      nativeName: 'Èdè Yorùbá',
      flag: '🇳🇬',
      region: 'West Africa',
    ),
    LanguageOption(
      locale: const Locale('ig'),
      name: 'Igbo',
      nativeName: 'Asụsụ Igbo',
      flag: '🇳🇬',
      region: 'West Africa',
    ),
    LanguageOption(
      locale: const Locale('zu'),
      name: 'Zulu',
      nativeName: 'isiZulu',
      flag: '🇿🇦',
      region: 'Southern Africa',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentLocale = const Locale('en');
    _selectedLocale = const Locale('en');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _currentLocale = context.locale;
      _selectedLocale = context.locale;
      setState(() {});
    } catch (e) {
      debugPrint('Error getting locale: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'nav.language'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      body: Stack(
        children: [
          const AfricanPatternBackground(opacity: 0.03),
          Column(
            children: [
              // Current Language Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCurrentLanguageName(),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
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
                    final isSelected = _selectedLocale.languageCode == language.locale.languageCode;
                    final isCurrent = _currentLocale.languageCode == language.locale.languageCode;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : isCurrent
                                  ? AppTheme.secondaryColor
                                  : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
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
                                      language.flag,
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
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
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
                                              child: const Text(
                                                'CURRENT',
                                                style: TextStyle(
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
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        language.region,
                                        style: TextStyle(
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
              if (_selectedLocale.languageCode != _currentLocale.languageCode)
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrentLanguageName() {
    final current = _languages.firstWhere(
      (lang) => lang.locale.languageCode == _currentLocale.languageCode,
      orElse: () => _languages.first,
    );
    return '${current.name} (${current.nativeName})';
  }

  String _getCurrentLanguageFlag() {
    final current = _languages.firstWhere(
      (lang) => lang.locale.languageCode == _currentLocale.languageCode,
      orElse: () => _languages.first,
    );
    return current.flag;
  }

  void _selectLanguage(LanguageOption language) {
    setState(() {
      _selectedLocale = language.locale;
    });
  }

  void _applyLanguageChange() {
    context.setLocale(_selectedLocale);

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
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
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