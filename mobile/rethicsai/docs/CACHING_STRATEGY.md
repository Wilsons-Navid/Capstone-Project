# 🗂️ RethicsAI Caching Strategy

## 📋 Overview

RethicsAI implements a sophisticated multi-layer caching strategy designed to provide optimal offline functionality, performance, and user experience. The caching system is built with African mobile network conditions in mind, prioritizing reliability and efficiency.

## 🏗️ Architecture Overview

### Cache Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│                  Network Cache Service                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │ HTTP Cache  │ │ Image Cache │ │   Request Queue        │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     Core Cache Service                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │  Incidents  │ │  Education  │ │      User Data         │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   AI Chat   │ │   General   │ │      Metadata          │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                      Hive Storage                           │
│           (Local SQLite-based Key-Value Store)              │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Cache Categories

### 1. General Cache (`CacheCategory.general`)
- **Purpose**: Miscellaneous app data, settings, and configurations
- **TTL**: 24 hours (default)
- **Priority**: Normal
- **Examples**: App settings, feature flags, system announcements

### 2. Incidents Cache (`CacheCategory.incidents`)
- **Purpose**: User incident reports and case data
- **TTL**: 6 hours
- **Priority**: High (user-critical data)
- **Examples**: User's incident reports, case status updates, evidence files

### 3. Education Cache (`CacheCategory.education`)
- **Purpose**: Security education content and user progress
- **TTL**: 7 days
- **Priority**: Normal (content changes infrequently)
- **Examples**: Course materials, progress tracking, certificates

### 4. User Cache (`CacheCategory.user`)
- **Purpose**: User profile and personalized data
- **TTL**: 12 hours
- **Priority**: High
- **Examples**: User preferences, profile data, personalized recommendations

### 5. AI Chat Cache (`CacheCategory.aiChat`)
- **Purpose**: Wilson AI conversation history
- **TTL**: 3 days
- **Priority**: High (for context continuity)
- **Examples**: Chat sessions, AI responses, conversation context

### 6. Image Cache (`CacheCategory.images`)
- **Purpose**: Cached images and media files
- **TTL**: 7 days
- **Priority**: Normal
- **Examples**: Profile pictures, education images, evidence photos

## ⏰ TTL (Time To Live) Strategy

### Dynamic TTL Based on Content Type

```dart
Duration getTTLForContent(String contentType, CacheCategory category) {
  switch (category) {
    case CacheCategory.incidents:
      return contentType == 'active_case' 
          ? Duration(minutes: 30)  // Active cases update frequently
          : Duration(hours: 6);    // Closed cases change less
          
    case CacheCategory.education:
      return contentType == 'progress' 
          ? Duration(hours: 2)     // Progress updates frequently
          : Duration(days: 7);     // Content is static
          
    case CacheCategory.user:
      return contentType == 'preferences' 
          ? Duration(days: 1)      // Settings change rarely
          : Duration(hours: 12);   // Profile data moderately dynamic
          
    case CacheCategory.aiChat:
      return Duration(days: 3);    // Keep for context
      
    case CacheCategory.images:
      return Duration(days: 7);    // Images rarely change
      
    default:
      return Duration(hours: 24);  // Default TTL
  }
}
```

## 🎨 Cache Priority System

### Priority Levels

1. **Critical** (`CachePriority.critical`)
   - Never evicted unless expired
   - Used for: Emergency contacts, active incident data, user authentication

2. **High** (`CachePriority.high`)
   - Evicted only when cache is nearly full
   - Used for: User incidents, chat history, personal preferences

3. **Normal** (`CachePriority.normal`)
   - Standard eviction policy (LRU)
   - Used for: Education content, general app data

4. **Low** (`CachePriority.low`)
   - First to be evicted when space is needed
   - Used for: Temporary data, experimental features

### Eviction Strategy

```dart
Future<void> _enforceCacheSizeLimit() async {
  if (totalSize <= maxCacheSize) return;

  final sortedItems = items.entries.toList()
    ..sort((a, b) {
      // Sort by priority first (low priority evicted first)
      final priorityCompare = a.value.priority.index.compareTo(b.value.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      
      // Then by expiration time (soonest to expire evicted first)
      return a.value.expiresAt.compareTo(b.value.expiresAt);
    });

  // Remove items until we're back under the limit
  for (final item in sortedItems) {
    if (removedSize >= targetReduction) break;
    await _removeItem(item.key, item.value.category);
  }
}
```

## 🌐 Network-Aware Caching

### Intelligent Cache-First Strategy

The system adapts its behavior based on network conditions:

```dart
Future<Either<Failure, T>> getOrFetch<T>({
  required String key,
  required Future<T> Function() fetchFunction,
  bool forceRefresh = false,
}) async {
  // 1. Check cache first (unless force refresh)
  if (!forceRefresh) {
    final cachedData = await retrieve<T>(key: key);
    if (cachedData.isRight && cachedData.right != null) {
      return cachedData; // Return cached data
    }
  }

  // 2. Check network connectivity
  if (!await isOnline()) {
    // Offline: try to return stale cache data if available
    final staleData = await retrieve<T>(key: key, ignoreExpiry: true);
    if (staleData.isRight && staleData.right != null) {
      return staleData; // Return stale data with offline indicator
    }
    return Left(NetworkFailure('Device is offline and no cached data available'));
  }

  // 3. Fetch fresh data and cache it
  try {
    final freshData = await fetchFunction();
    await store(key: key, data: freshData);
    return Right(freshData);
  } catch (e) {
    // Network failed: fallback to stale cache
    final staleData = await retrieve<T>(key: key, ignoreExpiry: true);
    if (staleData.isRight && staleData.right != null) {
      return staleData;
    }
    return Left(ServerFailure('Network failed and no cached data available'));
  }
}
```

## 🖼️ Image Caching Strategy

### Intelligent Image Management

```dart
class ImageCacheStrategy {
  // Maximum cache sizes
  static const int maxImageCacheSize = 50 * 1024 * 1024; // 50MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  
  Future<String> cacheImage({
    required String imageUrl,
    int? maxWidth,
    int? maxHeight,
    ImageQuality quality = ImageQuality.medium,
  }) async {
    // 1. Generate cache key from URL
    final cacheKey = _generateImageKey(imageUrl);
    
    // 2. Check if already cached
    final existingPath = await retrieveImagePath(cacheKey);
    if (existingPath != null && await File(existingPath).exists()) {
      return existingPath;
    }
    
    // 3. Download and optimize image
    final imageData = await _downloadImage(imageUrl);
    final optimizedData = await _optimizeImage(
      imageData,
      maxWidth ?? maxImageWidth,
      maxHeight ?? maxImageHeight,
      quality,
    );
    
    // 4. Store in file system
    final imagePath = await _saveImageToCache(cacheKey, optimizedData);
    
    // 5. Update cache metadata
    await _updateImageCacheMetadata(cacheKey, imagePath, optimizedData.length);
    
    return imagePath;
  }
  
  Future<Uint8List> _optimizeImage(
    Uint8List originalData,
    int maxWidth,
    int maxHeight,
    ImageQuality quality,
  ) async {
    // Image optimization logic here
    // - Resize if too large
    // - Compress based on quality setting
    // - Convert to optimal format (WebP on supported platforms)
    return originalData; // Placeholder
  }
}

enum ImageQuality {
  low(30),      // Heavy compression for slow networks
  medium(70),   // Balanced quality/size
  high(90),     // Minimal compression
  original(100); // No compression
  
  const ImageQuality(this.compressionQuality);
  final int compressionQuality;
}
```

## 🔄 Synchronization Strategy

### Background Sync for Offline-First Experience

```dart
class SynchronizationManager {
  // Queue for operations that failed while offline
  final List<PendingOperation> _pendingOperations = [];
  
  Future<void> queueOperation(PendingOperation operation) async {
    _pendingOperations.add(operation);
    await _persistPendingOperations();
    
    // Try immediate sync if online
    if (await NetworkCacheService.instance.isOnline()) {
      await _syncPendingOperations();
    }
  }
  
  Future<void> _syncPendingOperations() async {
    final operationsToSync = List<PendingOperation>.from(_pendingOperations);
    
    for (final operation in operationsToSync) {
      try {
        await _executeOperation(operation);
        _pendingOperations.remove(operation);
      } catch (e) {
        // Operation failed, keep in queue for retry
        LoggingService.warning('Sync operation failed: ${operation.id} - $e');
      }
    }
    
    await _persistPendingOperations();
  }
  
  // Called when network connectivity is restored
  Future<void> onNetworkRestored() async {
    LoggingService.info('Network restored, starting background sync');
    await _syncPendingOperations();
    await _refreshStaleData();
  }
}
```

## 📊 Cache Warming Strategy

### Proactive Content Loading

```dart
class CacheWarmingService {
  // Warm cache with critical user data on app start
  Future<void> warmCriticalCache(String userId) async {
    final criticalEndpoints = [
      '/users/$userId/profile',
      '/users/$userId/incidents?status=active',
      '/users/$userId/preferences',
      '/emergency-contacts',
      '/education/featured',
    ];
    
    await NetworkCacheService.instance.preloadCriticalResources(
      urls: criticalEndpoints.map((e) => '${ApiConstants.baseUrl}$e').toList(),
      category: CacheCategory.user,
      ttl: Duration(hours: 6),
    );
  }
  
  // Predictive caching based on user behavior
  Future<void> predictiveCaching(String userId) async {
    final userBehavior = await _getUserBehaviorPatterns(userId);
    
    // Cache frequently accessed education modules
    if (userBehavior.frequentlyAccessedEducationModules.isNotEmpty) {
      await _cacheEducationModules(userBehavior.frequentlyAccessedEducationModules);
    }
    
    // Preload likely-to-be-viewed images
    if (userBehavior.likelyImages.isNotEmpty) {
      await NetworkCacheService.instance.preloadImages(
        imageUrls: userBehavior.likelyImages,
        ttl: Duration(days: 3),
      );
    }
  }
}
```

## 🧹 Cache Maintenance

### Automated Cleanup

```dart
class CacheMaintenanceService {
  // Run daily maintenance tasks
  Future<void> performDailyMaintenance() async {
    await _cleanExpiredItems();
    await _optimizeCacheSize();
    await _defragmentCache();
    await _updateCacheStatistics();
  }
  
  Future<void> _cleanExpiredItems() async {
    int cleanedCount = 0;
    
    for (final key in _cacheMetadata.keys) {
      final metadata = _cacheMetadata.get(key);
      if (metadata != null && metadata.isExpired) {
        await _removeExpiredItem(key, metadata);
        cleanedCount++;
      }
    }
    
    LoggingService.info('Cache maintenance: cleaned $cleanedCount expired items');
  }
  
  Future<void> _optimizeCacheSize() async {
    final stats = await CacheService.instance.getStatistics();
    
    if (stats.totalSizeBytes > maxCacheSize * 0.9) {
      // Cache is 90% full, start aggressive cleanup
      await _performAggressiveCleanup();
    } else if (stats.totalSizeBytes > maxCacheSize * 0.7) {
      // Cache is 70% full, start moderate cleanup
      await _performModerateCleanup();
    }
  }
}
```

## 📈 Performance Monitoring

### Cache Performance Metrics

```dart
class CachePerformanceMonitor {
  static final Map<String, CacheMetrics> _metrics = {};
  
  static void recordCacheHit(String key, CacheCategory category) {
    _updateMetrics(key, category, hit: true);
  }
  
  static void recordCacheMiss(String key, CacheCategory category) {
    _updateMetrics(key, category, hit: false);
  }
  
  static CachePerformanceReport generateReport() {
    final hitRate = _calculateHitRate();
    final categoryPerformance = _calculateCategoryPerformance();
    final storageEfficiency = _calculateStorageEfficiency();
    
    return CachePerformanceReport(
      overallHitRate: hitRate,
      categoryPerformance: categoryPerformance,
      storageEfficiency: storageEfficiency,
      recommendations: _generateRecommendations(hitRate, categoryPerformance),
    );
  }
  
  static List<String> _generateRecommendations(
    double hitRate,
    Map<CacheCategory, double> categoryPerformance,
  ) {
    final recommendations = <String>[];
    
    if (hitRate < 0.8) {
      recommendations.add('Consider increasing TTL for frequently accessed data');
    }
    
    if (categoryPerformance[CacheCategory.incidents]! < 0.7) {
      recommendations.add('Implement more aggressive incident data caching');
    }
    
    return recommendations;
  }
}
```

## 🔧 Configuration

### Cache Configuration

```dart
class CacheConfiguration {
  // Maximum cache sizes per category (in bytes)
  static const Map<CacheCategory, int> maxCategorySizes = {
    CacheCategory.general: 20 * 1024 * 1024,    // 20MB
    CacheCategory.incidents: 30 * 1024 * 1024,  // 30MB
    CacheCategory.education: 40 * 1024 * 1024,  // 40MB
    CacheCategory.user: 10 * 1024 * 1024,       // 10MB
    CacheCategory.aiChat: 15 * 1024 * 1024,     // 15MB
    CacheCategory.images: 50 * 1024 * 1024,     // 50MB
  };
  
  // Default TTL values per category
  static const Map<CacheCategory, Duration> defaultTTLs = {
    CacheCategory.general: Duration(hours: 24),
    CacheCategory.incidents: Duration(hours: 6),
    CacheCategory.education: Duration(days: 7),
    CacheCategory.user: Duration(hours: 12),
    CacheCategory.aiChat: Duration(days: 3),
    CacheCategory.images: Duration(days: 7),
  };
  
  // Cache warming configuration
  static const bool enableCacheWarming = true;
  static const Duration cacheWarmingInterval = Duration(hours: 6);
  static const int maxConcurrentWarmingRequests = 3;
  
  // Network-specific configurations
  static const Map<String, CacheSettings> networkSettings = {
    'wifi': CacheSettings(
      aggressiveCaching: true,
      imageQuality: ImageQuality.high,
      preloadImages: true,
    ),
    'mobile': CacheSettings(
      aggressiveCaching: true,
      imageQuality: ImageQuality.medium,
      preloadImages: false,
    ),
    'slow': CacheSettings(
      aggressiveCaching: true,
      imageQuality: ImageQuality.low,
      preloadImages: false,
    ),
  };
}
```

## 🎯 Best Practices

### 1. Cache Key Design
```dart
// Good: Hierarchical, descriptive keys
'user_incidents_${userId}_${status}_page_$pageNumber'
'education_module_${moduleId}_${language}'
'ai_chat_session_${sessionId}_${timestamp}'

// Bad: Generic or collision-prone keys
'data'
'user_$userId'
'cache_item'
```

### 2. Error Handling
```dart
Future<T?> safeCacheRetrieve<T>(String key) async {
  try {
    final result = await cacheService.retrieve<T>(key: key);
    return result.fold(
      (failure) {
        LoggingService.warning('Cache retrieval failed: $key - ${failure.message}');
        return null;
      },
      (data) => data,
    );
  } catch (e) {
    LoggingService.error('Unexpected cache error: $key - $e');
    return null;
  }
}
```

### 3. Memory Management
```dart
// Always dispose of large objects when done
void disposeOfLargeData(String key) async {
  await cacheService.remove(key);
  
  // For images, also remove from memory
  if (key.startsWith('image_')) {
    await PaintingBinding.instance.imageCache.evict(key);
  }
}
```

## 📱 African Mobile Network Optimization

### Network-Aware Strategies

1. **2G/Edge Networks**:
   - Minimal image quality
   - Text-only content preferred
   - Aggressive local caching
   - Batch API requests

2. **3G Networks**:
   - Medium image quality
   - Selective content preloading
   - Moderate cache TTL
   - Background sync when idle

3. **4G/WiFi Networks**:
   - High image quality
   - Proactive content loading
   - Predictive caching
   - Real-time sync

### Data Usage Optimization

```dart
class DataUsageOptimizer {
  static Future<void> optimizeForDataPlan(DataPlanType planType) async {
    switch (planType) {
      case DataPlanType.limited:
        await _enableDataSavingMode();
        break;
      case DataPlanType.unlimited:
        await _enableNormalMode();
        break;
      case DataPlanType.expensive:
        await _enableUltraDataSavingMode();
        break;
    }
  }
  
  static Future<void> _enableDataSavingMode() async {
    // Reduce image quality
    ImageCacheConfig.defaultQuality = ImageQuality.low;
    
    // Disable preloading
    CacheWarmingConfig.enablePreloading = false;
    
    // Increase cache TTL to reduce network requests
    CacheConfiguration.adjustTTLForDataSaving();
  }
}
```

---

## 📊 Monitoring and Analytics

### Cache Performance Dashboard

The caching system provides comprehensive metrics for monitoring and optimization:

- **Hit Rate**: Percentage of requests served from cache
- **Storage Efficiency**: Ratio of useful vs. expired data
- **Network Savings**: Bandwidth saved through caching
- **User Experience**: Impact on app performance and loading times

### Key Performance Indicators

- Target cache hit rate: >85%
- Average response time: <100ms for cached data
- Storage efficiency: >90% non-expired data
- Memory usage: <20% of available device memory

---

This comprehensive caching strategy ensures RethicsAI delivers optimal performance across varying network conditions while maintaining data freshness and minimizing bandwidth usage - critical for African mobile users.