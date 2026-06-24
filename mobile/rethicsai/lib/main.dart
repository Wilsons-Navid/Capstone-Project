import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/services/di_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/scam_model_service.dart';
import 'core/services/logging_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/emergency_contacts_service.dart';
import 'core/themes/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style immediately for faster visual feedback
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryDark, // brand deep-earth (was off-brand indigo)
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations immediately
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize EasyLocalization first (required for app to start)
  await EasyLocalization.ensureInitialized();
  
  // Initialize Firebase first (required for AuthBloc)
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    firebaseReady = false;
  }
  
  // Start app with EasyLocalization and Firebase ready
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        BlocProvider(create: (context) => AuthBloc()..add(AuthStarted())),
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('sw'), // Swahili
          Locale('fr'), // French
          Locale('ar'), // Arabic
          Locale('dua'), // Sawa (Duala)
          Locale('ha'), // Hausa
          Locale('yo'), // Yoruba
          Locale('ig'), // Igbo
          Locale('zu'), // Zulu
          Locale('xh'), // Xhosa
          Locale('af'), // Afrikaans
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const RethicsecApp(),
      ),
    ),
  );
  
  // Initialize other services in background after app starts
  _initializeServicesInBackground(firebaseReady);
}

Future<void> _initializeServicesInBackground(bool firebaseReady) async {
  try {
    // Initialize Hive for local storage first
    await Hive.initFlutter();

    // Wake the (sleeping) scam-model Space early so the user's first scan is
    // fast and shows a model verdict instead of falling back to heuristics.
    unawaited(ScamModelService().warmUp());

    // Initialize other services
    await LoggingService.initialize();
    await AnalyticsService.initialize();
    await DIService.init();
    
    // Initialize Notification Service if Firebase is ready
    if (firebaseReady) {
      try {
        await NotificationService.initialize();
        print('✅ Notification Service initialized successfully');
        
        // Seed emergency contacts data
        await EmergencyContactsService.seedDefaultData();
        print('✅ Emergency contacts seeded successfully');
      } catch (e) {
        print('❌ Notification Service initialization failed: $e');
      }
    }
  } catch (e) {
    print('❌ Background service initialization error: $e');
  }
}

class RethicsecApp extends StatelessWidget {
  const RethicsecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Handle auth state changes globally
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                // Use global navigator key for reliable navigation
                final NavigatorState? navigatorState = _navigatorKey.currentState;
                if (navigatorState == null) {
                  print('⚠️ Global navigator not available yet, skipping navigation');
                  return;
                }
                
                final currentRoute = ModalRoute.of(context)?.settings.name;
                
                if (state is AuthInitial) {
                  // User signed out, navigate to login
                  print('🔄 AuthInitial detected, navigating to login from: $currentRoute');
                  navigatorState.pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  );
                } else if (state is AuthSuccess) {
                  // User signed in, navigate to dashboard if not already there
                  if (currentRoute != AppRouter.dashboard && 
                      currentRoute != AppRouter.splash) {
                    print('🔄 AuthSuccess detected, navigating to dashboard from: $currentRoute');
                    navigatorState.pushReplacementNamed(AppRouter.dashboard);
                  }
                }
              } catch (e) {
                print('❌ Navigation error: $e');
                // Fallback using global navigator key
                final NavigatorState? navigatorState = _navigatorKey.currentState;
                if (navigatorState != null) {
                  navigatorState.pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  );
                }
              }
            });
          },
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: false,
            
            // Localization
            localizationsDelegates: [
              ...context.localizationDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            
            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Routing
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.generateRoute,
            
            // Navigation key for global navigation
            navigatorKey: _navigatorKey,
            
            // Builder for responsive design and error handling
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                  ),
                ),
                child: child!,
              );
            },
          ),
        );
      },
    );
  }
}

// Global navigator key for handling navigation from anywhere
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
