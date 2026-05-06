import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  Box? _box;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }
    
    _initializationFuture = _initialize();
    await _initializationFuture;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      // Wait for Hive to be initialized if it's not already
      if (!Hive.isAdapterRegistered(0)) {
        await Hive.initFlutter();
      }
      
      _box = await Hive.openBox('settings');
      _loadThemeMode();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('ThemeProvider initialization error: $e');
      // Fallback to system theme if initialization fails
      _isInitialized = true;
    }
  }
  
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  void _loadThemeMode() {
    if (_box == null) return;
    
    final savedTheme = _box!.get(_themeKey, defaultValue: 'system');
    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode || _box == null) return;
    
    _themeMode = mode;
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    
    try {
      await _box!.put(_themeKey, themeString);
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await _ensureInitialized();
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}