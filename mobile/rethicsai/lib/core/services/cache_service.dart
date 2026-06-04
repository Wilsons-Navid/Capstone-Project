import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';

import '../utils/either.dart';
import '../errors/failures.dart';
import 'logging_service.dart';

class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._internal();
  
  CacheService._internal();

  // Cache boxes
  late Box<Map<dynamic, dynamic>> _generalCache;
  late Box<Map<dynamic, dynamic>> _incidentsCache;
  late Box<Map<dynamic, dynamic>> _educationCache;
  late Box<Map<dynamic, dynamic>> _userCache;
  late Box<Map<dynamic, dynamic>> _aiChatCache;
  late Box<String> _imageCache;
  late Box<CacheMetadata> _cacheMetadata;

  // Cache configuration
  static const Duration _defaultTtl = Duration(hours: 24);
  static const Duration _shortTtl = Duration(minutes: 30);
  static const Duration _longTtl = Duration(days: 7);
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxImageCacheSize = 50 * 1024 * 1024; // 50MB

  bool _isInitialized = false;
  final Connectivity _connectivity = Connectivity();

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CacheMetadataAdapter());
      }

      // Open cache boxes
      _generalCache = await Hive.openBox<Map<dynamic, dynamic>>('general_cache');
      _incidentsCache = await Hive.openBox<Map<dynamic, dynamic>>('incidents_cache');
      _educationCache = await Hive.openBox<Map<dynamic, dynamic>>('education_cache');
      _userCache = await Hive.openBox<Map<dynamic, dynamic>>('user_cache');
      _aiChatCache = await Hive.openBox<Map<dynamic, dynamic>>('ai_chat_cache');
      _imageCache = await Hive.openBox<String>('image_cache');
      _cacheMetadata = await Hive.openBox<CacheMetadata>('cache_metadata');

      // Initialize cleanup tasks
      await _initializeCleanupTasks();
      
      _isInitialized = true;
      LoggingService.info('CacheService','CacheService initialized successfully');
    } catch (e) {
      LoggingService.error('CacheService','Failed to initialize CacheService: $e');
      throw CacheException('Cache initialization failed: $e');
    }
  }

  /// Initialize background cleanup tasks
  Future<void> _initializeCleanupTasks() async {
    // Clean expired items
    await _cleanExpiredItems();
    
    // Check cache size and cleanup if needed
    await _enforceCacheSizeLimit();
  }

  /// Store data in cache with TTL
  Future<Either<Failure, bool>> store<T>({
    required String key,
    required T data,
    CacheCategory category = CacheCategory.general,
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final box = _getCacheBox(category);
      final expiresAt = DateTime.now().add(ttl ?? _defaultTtl);
      
      final cacheItem = CacheItem<T>(
        data: data,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
        priority: priority,
        category: category,
      );

      await box.put(key, cacheItem.toJson());
      
      // Store metadata for cleanup
      await _cacheMetadata.put(key, CacheMetadata(
        key: key,
        category: category,
        expiresAt: expiresAt,
        priority: priority,
        size: _estimateObjectSize(data),
      ));

      LoggingService.debug('CacheService','Cache item stored: $key (${category.name})');
      return const Right(true);
    } catch (e) {
      LoggingService.error('CacheService','Failed to store cache item: $key - $e');
      return Left(CacheFailure(message: 'Failed to store cache item: $e'));
    }
  }

  /// Retrieve data from cache
  Future<Either<Failure, T?>> retrieve<T>({
    required String key,
    CacheCategory category = CacheCategory.general,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final box = _getCacheBox(category);
      final cachedData = box.get(key);
      
      if (cachedData == null) {
        LoggingService.debug('CacheService','Cache miss: $key');
        return const Right(null);
      }

      final cacheItem = CacheItem<T>.fromJson(cachedData, fromJson);
      
      // Check if item has expired
      if (cacheItem.isExpired) {
        LoggingService.debug('CacheService','Cache item expired: $key');
        await _removeItem(key, category);
        return const Right(null);
      }

      LoggingService.debug('CacheService','Cache hit: $key');
      return Right(cacheItem.data);
    } catch (e) {
      LoggingService.error('CacheService','Failed to retrieve cache item: $key - $e');
      return Left(CacheFailure(message: 'Failed to retrieve cache item: $e'));
    }
  }

  /// Store image in cache
  Future<Either<Failure, bool>> storeImage({
    required String url,
    required String imagePath,
    Duration? ttl,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final key = _generateImageCacheKey(url);
      final expiresAt = DateTime.now().add(ttl ?? _longTtl);
      
      await _imageCache.put(key, imagePath);
      await _cacheMetadata.put(key, CacheMetadata(
        key: key,
        category: CacheCategory.images,
        expiresAt: expiresAt,
        priority: CachePriority.normal,
        size: await _getFileSize(imagePath),
      ));

      LoggingService.debug('CacheService','Image cached: $url');
      return const Right(true);
    } catch (e) {
      LoggingService.error('CacheService','Failed to cache image: $url - $e');
      return Left(CacheFailure(message: 'Failed to cache image: $e'));
    }
  }

  /// Retrieve cached image path
  Future<Either<Failure, String?>> retrieveImage(String url) async {
    try {
      if (!_isInitialized) await initialize();

      final key = _generateImageCacheKey(url);
      final imagePath = _imageCache.get(key);
      
      if (imagePath == null) return const Right(null);

      // Check if image file still exists
      if (await File(imagePath).exists()) {
        // Check if cache item has expired
        final metadata = _cacheMetadata.get(key);
        if (metadata != null && metadata.isExpired) {
          await _removeImageFromCache(key, imagePath);
          return const Right(null);
        }
        return Right(imagePath);
      } else {
        // File doesn't exist, remove from cache
        await _removeImageFromCache(key, imagePath);
        return const Right(null);
      }
    } catch (e) {
      LoggingService.error('CacheService','Failed to retrieve cached image: $url - $e');
      return Left(CacheFailure(message: 'Failed to retrieve cached image: $e'));
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      LoggingService.warning('CacheService','Failed to check connectivity: $e');
      return false; // Assume offline if check fails
    }
  }

  /// Get cached data or fetch from network
  Future<Either<Failure, T>> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetchFunction,
    CacheCategory category = CacheCategory.general,
    Duration? ttl,
    T Function(Map<String, dynamic>)? fromJson,
    bool forceRefresh = false,
  }) async {
    try {
      // Try cache first unless force refresh is requested
      if (!forceRefresh) {
        final cachedResult = await retrieve<T>(
          key: key,
          category: category,
          fromJson: fromJson,
        );
        
        if (cachedResult.isRight) {
          final cachedData = cachedResult.value;
          if (cachedData != null) {
            LoggingService.debug('CacheService','Returning cached data for: $key');
            return Right(cachedData);
          }
        }
      }

      // Check if online before fetching
      if (!await isOnline()) {
        LoggingService.warning('CacheService','Offline: Cannot fetch fresh data for $key');
        return Left(NetworkFailure(message: 'Device is offline'));
      }

      // Fetch fresh data
      LoggingService.debug('CacheService','Fetching fresh data for: $key');
      final freshData = await fetchFunction();
      
      // Cache the fresh data
      await store<T>(
        key: key,
        data: freshData,
        category: category,
        ttl: ttl,
      );

      return Right(freshData);
    } catch (e) {
      LoggingService.error('CacheService','Failed to get or fetch data: $key - $e');
      return Left(ServerFailure(message: 'Failed to get or fetch data: $e'));
    }
  }

  /// Remove specific item from cache
  Future<Either<Failure, bool>> remove(String key, [CacheCategory? category]) async {
    try {
      if (!_isInitialized) await initialize();

      await _removeItem(key, category ?? CacheCategory.general);
      LoggingService.debug('CacheService','Cache item removed: $key');
      return const Right(true);
    } catch (e) {
      LoggingService.error('CacheService','Failed to remove cache item: $key - $e');
      return Left(CacheFailure(message: 'Failed to remove cache item: $e'));
    }
  }

  /// Clear all cache data
  Future<Either<Failure, bool>> clearAll() async {
    try {
      if (!_isInitialized) await initialize();

      await _generalCache.clear();
      await _incidentsCache.clear();
      await _educationCache.clear();
      await _userCache.clear();
      await _aiChatCache.clear();
      await _imageCache.clear();
      await _cacheMetadata.clear();
      
      // Clear image files
      await _clearImageFiles();

      LoggingService.info('CacheService','All cache data cleared');
      return const Right(true);
    } catch (e) {
      LoggingService.error('CacheService','Failed to clear cache: $e');
      return Left(CacheFailure(message: 'Failed to clear cache: $e'));
    }
  }

  /// Clear cache for specific category
  Future<Either<Failure, bool>> clearCategory(CacheCategory category) async {
    try {
      if (!_isInitialized) await initialize();

      final box = _getCacheBox(category);
      await box.clear();
      
      // Clear metadata for this category
      final keysToRemove = <String>[];
      for (final key in _cacheMetadata.keys) {
        final metadata = _cacheMetadata.get(key);
        if (metadata?.category == category) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        await _cacheMetadata.delete(key);
      }

      LoggingService.info('CacheService','Cache cleared for category: ${category.name}');
      return const Right(true);
    } catch (e) {
      LoggingService.error('CacheService','Failed to clear category cache: ${category.name} - $e');
      return Left(CacheFailure(message: 'Failed to clear category cache: $e'));
    }
  }

  /// Get cache statistics
  Future<CacheStatistics> getStatistics() async {
    if (!_isInitialized) await initialize();

    final generalSize = _generalCache.length;
    final incidentsSize = _incidentsCache.length;
    final educationSize = _educationCache.length;
    final userSize = _userCache.length;
    final aiChatSize = _aiChatCache.length;
    final imageSize = _imageCache.length;

    int totalSize = 0;
    int expiredItems = 0;
    
    for (final key in _cacheMetadata.keys) {
      final metadata = _cacheMetadata.get(key);
      if (metadata != null) {
        totalSize += metadata.size;
        if (metadata.isExpired) expiredItems++;
      }
    }

    return CacheStatistics(
      totalItems: generalSize + incidentsSize + educationSize + userSize + aiChatSize + imageSize,
      totalSizeBytes: totalSize,
      expiredItems: expiredItems,
      categorySizes: {
        CacheCategory.general: generalSize,
        CacheCategory.incidents: incidentsSize,
        CacheCategory.education: educationSize,
        CacheCategory.user: userSize,
        CacheCategory.aiChat: aiChatSize,
        CacheCategory.images: imageSize,
      },
      lastCleanup: _getLastCleanupTime(),
    );
  }

  // Private helper methods

  Box<Map<dynamic, dynamic>> _getCacheBox(CacheCategory category) {
    switch (category) {
      case CacheCategory.general:
        return _generalCache;
      case CacheCategory.incidents:
        return _incidentsCache;
      case CacheCategory.education:
        return _educationCache;
      case CacheCategory.user:
        return _userCache;
      case CacheCategory.aiChat:
        return _aiChatCache;
      case CacheCategory.images:
        return _generalCache; // Images use string cache, but metadata uses general
    }
  }

  Future<void> _removeItem(String key, CacheCategory category) async {
    final box = _getCacheBox(category);
    await box.delete(key);
    await _cacheMetadata.delete(key);
  }

  Future<void> _removeImageFromCache(String key, String imagePath) async {
    await _imageCache.delete(key);
    await _cacheMetadata.delete(key);
    try {
      await File(imagePath).delete();
    } catch (e) {
      LoggingService.warning('CacheService','Failed to delete image file: $imagePath - $e');
    }
  }

  Future<void> _cleanExpiredItems() async {
    final keysToRemove = <String>[];
    
    for (final key in _cacheMetadata.keys) {
      final metadata = _cacheMetadata.get(key);
      if (metadata != null && metadata.isExpired) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      final metadata = _cacheMetadata.get(key);
      if (metadata != null) {
        await _removeItem(key, metadata.category);
        if (metadata.category == CacheCategory.images) {
          final imagePath = _imageCache.get(key);
          if (imagePath != null) {
            await _removeImageFromCache(key, imagePath);
          }
        }
      }
    }

    if (keysToRemove.isNotEmpty) {
      LoggingService.info('CacheService','Cleaned ${keysToRemove.length} expired cache items');
    }
  }

  Future<void> _enforceCacheSizeLimit() async {
    int totalSize = 0;
    final items = <String, CacheMetadata>{};
    
    for (final key in _cacheMetadata.keys) {
      final metadata = _cacheMetadata.get(key);
      if (metadata != null) {
        totalSize += metadata.size;
        items[key] = metadata;
      }
    }

    if (totalSize <= _maxCacheSize) return;

    // Sort by priority and creation time (LRU-like)
    final sortedItems = items.entries.toList()
      ..sort((a, b) {
        final priorityCompare = a.value.priority.index.compareTo(b.value.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        return a.value.expiresAt.compareTo(b.value.expiresAt);
      });

    int removedSize = 0;
    final targetReduction = totalSize - (_maxCacheSize * 0.8).toInt(); // Reduce to 80% of limit

    for (final item in sortedItems) {
      if (removedSize >= targetReduction) break;
      
      await _removeItem(item.key, item.value.category);
      removedSize += item.value.size;
    }

    LoggingService.info('CacheService', 'Cache size reduction: removed ${removedSize} bytes');
  }

  String _generateImageCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return 'img_${digest.toString()}';
  }

  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  int _estimateObjectSize(dynamic object) {
    try {
      final jsonString = jsonEncode(object);
      return utf8.encode(jsonString).length;
    } catch (e) {
      return 1024; // Default estimate
    }
  }

  Future<void> _clearImageFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/image_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      LoggingService.warning('CacheService','Failed to clear image files: $e');
    }
  }

  DateTime? _getLastCleanupTime() {
    // This would be stored in preferences or a special cache key
    return null; // Implement based on your needs
  }

  /// Dispose cache service
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    await _generalCache.close();
    await _incidentsCache.close();
    await _educationCache.close();
    await _userCache.close();
    await _aiChatCache.close();
    await _imageCache.close();
    await _cacheMetadata.close();
    
    _isInitialized = false;
  }
}

// Cache models and enums

enum CacheCategory {
  general,
  incidents,
  education,
  user,
  aiChat,
  images,
}

enum CachePriority {
  low,
  normal,
  high,
  critical,
}

@HiveType(typeId: 0)
class CacheMetadata extends HiveObject {
  @HiveField(0)
  final String key;
  
  @HiveField(1)
  final CacheCategory category;
  
  @HiveField(2)
  final DateTime expiresAt;
  
  @HiveField(3)
  final CachePriority priority;
  
  @HiveField(4)
  final int size;

  CacheMetadata({
    required this.key,
    required this.category,
    required this.expiresAt,
    required this.priority,
    required this.size,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheMetadataAdapter extends TypeAdapter<CacheMetadata> {
  @override
  final int typeId = 0;

  @override
  CacheMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheMetadata(
      key: fields[0] as String,
      category: CacheCategory.values[fields[1] as int],
      expiresAt: fields[2] as DateTime,
      priority: CachePriority.values[fields[3] as int],
      size: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CacheMetadata obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.category.index)
      ..writeByte(2)
      ..write(obj.expiresAt)
      ..writeByte(3)
      ..write(obj.priority.index)
      ..writeByte(4)
      ..write(obj.size);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CacheItem<T> {
  final T data;
  final DateTime expiresAt;
  final DateTime createdAt;
  final CachePriority priority;
  final CacheCategory category;

  CacheItem({
    required this.data,
    required this.expiresAt,
    required this.createdAt,
    required this.priority,
    required this.category,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'data': data,
    'expiresAt': expiresAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'priority': priority.index,
    'category': category.index,
  };

  factory CacheItem.fromJson(
    Map<dynamic, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonConverter,
  ) {
    T data;
    if (fromJsonConverter != null && json['data'] is Map<String, dynamic>) {
      data = fromJsonConverter(json['data'] as Map<String, dynamic>);
    } else {
      data = json['data'] as T;
    }

    return CacheItem<T>(
      data: data,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      priority: CachePriority.values[json['priority'] as int],
      category: CacheCategory.values[json['category'] as int],
    );
  }
}

class CacheStatistics {
  final int totalItems;
  final int totalSizeBytes;
  final int expiredItems;
  final Map<CacheCategory, int> categorySizes;
  final DateTime? lastCleanup;

  CacheStatistics({
    required this.totalItems,
    required this.totalSizeBytes,
    required this.expiredItems,
    required this.categorySizes,
    this.lastCleanup,
  });

  String get formattedSize {
    if (totalSizeBytes < 1024) return '${totalSizeBytes} B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Exception classes
class CacheException implements Exception {
  final String message;
  CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}