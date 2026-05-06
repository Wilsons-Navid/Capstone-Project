import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../network/dio_client.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/incidents/data/repositories/incident_repository_impl.dart';
import '../../features/incidents/domain/repositories/incident_repository.dart';
import '../../features/cases/data/repositories/case_repository_impl.dart';
import '../../features/cases/domain/repositories/case_repository.dart';

final GetIt getIt = GetIt.instance;

class DIService {
  static Future<void> init() async {
    // Register SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    // Register secure storage
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    getIt.registerSingleton<FlutterSecureStorage>(secureStorage);

    // Register connectivity
    getIt.registerSingleton<Connectivity>(Connectivity());

    // Register Dio
    final dio = Dio();
    dio.interceptors.addAll([
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    ]);

    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    getIt.registerSingleton<Dio>(dio);
    getIt.registerSingleton<DioClient>(DioClient(dio));

    // Register repositories
    getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl());
    getIt.registerSingleton<IncidentRepository>(IncidentRepositoryImpl());
    getIt.registerSingleton<CaseRepository>(CaseRepositoryImpl());
  }

  static T get<T extends Object>() => getIt<T>();
  
  static void reset() => getIt.reset();
}