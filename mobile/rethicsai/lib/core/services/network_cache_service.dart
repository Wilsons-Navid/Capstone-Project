import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import '../utils/either.dart';
import '../errors/failures.dart';
import 'cache_service.dart';
import 'logging_service.dart';

class NetworkCacheService {
  static NetworkCacheService? _instance;
  static NetworkCacheService get instance => _instance ??= NetworkCacheService._internal();
  
  NetworkCacheService._internal();

  final CacheService _cacheService = CacheService.instance;
  late Directory _imageDirectory;
  bool _isInitialized = false;

  /// Initialize network cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _cacheService.initialize();
      await _initializeImageDirectory();
      _isInitialized = true;
      LoggingService.info('NetworkCacheService initialized');
    } catch (e) {
      LoggingService.error('Failed to initialize NetworkCacheService: $e');
      throw Exception('NetworkCacheService initialization failed: $e');
    }
  }

  /// Initialize image cache directory
  Future<void> _initializeImageDirectory() async {
    final tempDir = await getTemporaryDirectory();
    _imageDirectory = Directory('${tempDir.path}/rethics_image_cache');
    
    if (!await _imageDirectory.exists()) {
      await _imageDirectory.create(recursive: true);
    }
  }

  /// Cached network request with intelligent caching
  Future<Either<Failure, Response>> cachedRequest({
    required String url,
    required RequestOptions options,
    Duration? cacheTtl,
    bool forceRefresh = false,
    CacheCategory category = CacheCategory.general,
    CachePriority priority = CachePriority.normal,
  }) async {
    if (!_isInitialized) await initialize();

    final cacheKey = _generateCacheKey(url, options);
    
    try {
      // Get cached response unless force refresh
      if (!forceRefresh) {
        final cachedResult = await _cacheService.retrieve<Map<String, dynamic>>(
          key: cacheKey,
          category: category,
        );

        if (cachedResult.isRight) {
          final cachedData = cachedResult.right;
          if (cachedData != null) {
            LoggingService.debug('Cache hit for URL: $url');
            return Right(_responseFromCachedData(cachedData));
          }
        }
      }

      // Check if online
      if (!await _cacheService.isOnline()) {
        LoggingService.warning('Offline: Cannot make request to $url');
        return Left(NetworkFailure('Device is offline'));
      }

      // Make network request
      final dio = Dio();
      final response = await dio.request(
        url,
        options: options,
      );

      // Cache successful response
      if (response.statusCode == 200) {
        await _cacheService.store<Map<String, dynamic>>(
          key: cacheKey,
          data: _responseToMap(response),
          category: category,
          ttl: cacheTtl,
          priority: priority,
        );
      }

      LoggingService.debug('Network request successful: $url');
      return Right(response);

    } on DioException catch (e) {
      LoggingService.error('Network request failed: $url - ${e.message}');
      return Left(NetworkFailure('Network request failed: ${e.message}'));
    } catch (e) {
      LoggingService.error('Unexpected error in cached request: $url - $e');
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  /// Cache image from URL with smart storage
  Future<Either<Failure, String>> cacheImage({
    required String imageUrl,
    Duration? ttl,
    int? maxWidth,
    int? maxHeight,
    bool forceRefresh = false,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Check cached image first
      if (!forceRefresh) {
        final cachedResult = await _cacheService.retrieveImage(imageUrl);
        if (cachedResult.isRight) {
          final cachedPath = cachedResult.right;
          if (cachedPath != null && await File(cachedPath).exists()) {
            LoggingService.debug('Image cache hit: $imageUrl');
            return Right(cachedPath);
          }
        }
      }

      // Check if online
      if (!await _cacheService.isOnline()) {
        return Left(NetworkFailure('Cannot download image: device is offline'));
      }

      // Download image
      final imageData = await _downloadImage(imageUrl);
      
      // Generate unique filename
      final filename = _generateImageFilename(imageUrl);
      final imagePath = '${_imageDirectory.path}/$filename';
      
      // Save image file
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageData);

      // Optimize image if size constraints provided
      if (maxWidth != null || maxHeight != null) {
        await _optimizeImage(imagePath, maxWidth, maxHeight);
      }

      // Store in cache
      await _cacheService.storeImage(
        url: imageUrl,
        imagePath: imagePath,
        ttl: ttl,
      );

      LoggingService.debug('Image cached successfully: $imageUrl');
      return Right(imagePath);

    } catch (e) {
      LoggingService.error('Failed to cache image: $imageUrl - $e');
      return Left(CacheFailure('Failed to cache image: $e'));
    }
  }

  /// Preload critical resources
  Future<void> preloadCriticalResources({
    required List<String> urls,
    CacheCategory category = CacheCategory.general,
    Duration? ttl,
  }) async {
    if (!await _cacheService.isOnline()) {
      LoggingService.warning('Cannot preload resources: device is offline');
      return;
    }

    LoggingService.info('Preloading ${urls.length} critical resources');
    
    final preloadTasks = urls.map((url) async {
      try {
        await cachedRequest(
          url: url,
          options: RequestOptions(path: url, method: 'GET'),
          category: category,
          ttl: ttl,
          priority: CachePriority.high,
        );
      } catch (e) {
        LoggingService.warning('Failed to preload resource: $url - $e');
      }
    });

    await Future.wait(preloadTasks);
    LoggingService.info('Critical resources preload completed');
  }

  /// Preload images for better UX
  Future<void> preloadImages({
    required List<String> imageUrls,
    Duration? ttl,
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (!await _cacheService.isOnline()) {
      LoggingService.warning('Cannot preload images: device is offline');
      return;
    }

    LoggingService.info('Preloading ${imageUrls.length} images');
    
    final imageTasks = imageUrls.map((url) async {
      try {
        await cacheImage(
          imageUrl: url,
          ttl: ttl,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
      } catch (e) {
        LoggingService.warning('Failed to preload image: $url - $e');
      }
    });

    await Future.wait(imageTasks);
    LoggingService.info('Image preload completed');
  }

  /// Smart cache warming for user-specific content
  Future<void> warmCache({
    required String userId,
    required List<String> frequentUrls,
    Duration? ttl,
  }) async {
    if (!await _cacheService.isOnline()) return;

    LoggingService.info('Warming cache for user: $userId');
    
    for (final url in frequentUrls) {
      try {
        // Check if already cached and fresh
        final cacheKey = _generateCacheKey(url, RequestOptions(path: url));
        final cachedResult = await _cacheService.retrieve<Map<String, dynamic>>(
          key: cacheKey,
          category: CacheCategory.user,
        );
        
        if (cachedResult.isRight && cachedResult.right != null) {
          continue; // Already cached
        }

        // Warm cache with fresh data
        await cachedRequest(
          url: url,
          options: RequestOptions(path: url, method: 'GET'),
          category: CacheCategory.user,
          ttl: ttl,
          priority: CachePriority.high,
        );

        // Add small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        LoggingService.warning('Failed to warm cache for URL: $url - $e');
      }
    }
    
    LoggingService.info('Cache warming completed for user: $userId');
  }

  /// Background sync for offline-first experience
  Future<void> backgroundSync({
    required List<PendingRequest> pendingRequests,
    Function(String)? onProgress,
  }) async {
    if (!await _cacheService.isOnline()) {
      LoggingService.info('Background sync skipped: device is offline');
      return;
    }

    LoggingService.info('Starting background sync for ${pendingRequests.length} requests');
    
    int completed = 0;
    for (final request in pendingRequests) {
      try {
        await cachedRequest(
          url: request.url,
          options: request.options,
          category: request.category,
          priority: CachePriority.normal,
        );
        
        completed++;
        onProgress?.call('Synced $completed/${pendingRequests.length}');
        
        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        LoggingService.warning('Background sync failed for: ${request.url} - $e');
      }
    }
    
    LoggingService.info('Background sync completed: $completed/${pendingRequests.length} successful');
  }

  /// Clear network cache
  Future<void> clearNetworkCache() async {
    await _cacheService.clearAll();
    
    // Clear image cache directory
    if (await _imageDirectory.exists()) {
      await for (final entity in _imageDirectory.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
    
    LoggingService.info('Network cache cleared');
  }

  // Private helper methods

  String _generateCacheKey(String url, RequestOptions options) {
    final keyData = {
      'url': url,
      'method': options.method,
      'headers': options.headers,
      'queryParameters': options.queryParameters,
    };
    
    final keyString = jsonEncode(keyData);
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return 'net_${digest.toString()}';
  }

  String _generateImageFilename(String imageUrl) {
    final bytes = utf8.encode(imageUrl);
    final digest = sha256.convert(bytes);
    final extension = _getImageExtension(imageUrl);
    return '${digest.toString()}$extension';
  }

  String _getImageExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();
    
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
    if (path.endsWith('.gif')) return '.gif';
    if (path.endsWith('.webp')) return '.webp';
    
    return '.jpg'; // Default extension
  }

  Future<Uint8List> _downloadImage(String url) async {
    final dio = Dio();
    final response = await dio.get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    
    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to download image from $url');
    }
    
    return response.data!;
  }

  Future<void> _optimizeImage(String imagePath, int? maxWidth, int? maxHeight) async {
    // Image optimization would go here
    // This would typically use a package like 'image' to resize images
    // For now, we'll skip this implementation detail
    LoggingService.debug('Image optimization placeholder for: $imagePath');
  }

  Map<String, dynamic> _responseToMap(Response response) {
    return {
      'data': response.data,
      'statusCode': response.statusCode,
      'statusMessage': response.statusMessage,
      'headers': response.headers.map,
      'requestPath': response.requestOptions.path,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Response _responseFromCachedData(Map<String, dynamic> cachedData) {
    return Response(
      data: cachedData['data'],
      statusCode: cachedData['statusCode'] as int?,
      statusMessage: cachedData['statusMessage'] as String?,
      headers: Headers.fromMap(
        Map<String, dynamic>.from(cachedData['headers'] as Map? ?? {}),
      ),
      requestOptions: RequestOptions(path: cachedData['requestPath'] as String),
    );
  }
}

/// Model for pending network requests
class PendingRequest {
  final String url;
  final RequestOptions options;
  final CacheCategory category;
  final DateTime createdAt;

  PendingRequest({
    required this.url,
    required this.options,
    this.category = CacheCategory.general,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'method': options.method,
    'headers': options.headers,
    'data': options.data,
    'queryParameters': options.queryParameters,
    'category': category.index,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      url: json['url'] as String,
      options: RequestOptions(
        path: json['url'] as String,
        method: json['method'] as String,
        headers: json['headers'] as Map<String, dynamic>?,
        data: json['data'],
        queryParameters: json['queryParameters'] as Map<String, dynamic>?,
      ),
      category: CacheCategory.values[json['category'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}