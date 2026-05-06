import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/models/incident_model.dart';
import '../../features/education/presentation/models/education_models.dart';
import 'incident_service.dart';
import 'education_service.dart';
import 'emergency_contacts_service.dart';

class OfflineService {
  static const String _incidentsBox = 'offline_incidents';
  static const String _educationBox = 'offline_education';
  static const String _contactsBox = 'offline_contacts';
  static const String _cacheBox = 'app_cache';
  static const String _syncQueueBox = 'sync_queue';

  static late Box<String> _incidentsCache;
  static late Box<String> _educationCache;
  static late Box<String> _contactsCache;
  static late Box<String> _appCache;
  static late Box<String> _syncQueue;

  static bool _isInitialized = false;

  // Initialize offline storage
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      
      _incidentsCache = await Hive.openBox<String>(_incidentsBox);
      _educationCache = await Hive.openBox<String>(_educationBox);
      _contactsCache = await Hive.openBox<String>(_contactsBox);
      _appCache = await Hive.openBox<String>(_cacheBox);
      _syncQueue = await Hive.openBox<String>(_syncQueueBox);

      _isInitialized = true;
      
      // Start background sync
      _startBackgroundSync();
      
      print('Offline service initialized successfully');
    } catch (e) {
      print('Failed to initialize offline service: $e');
    }
  }

  // Connectivity checking
  static Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Incident offline support
  static Future<String> saveIncidentOffline(Map<String, dynamic> incidentData, List<EvidenceFile>? evidenceFiles) async {
    final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
    final caseNumber = 'OFFLINE_${DateTime.now().millisecondsSinceEpoch}';
    
    final incident = IncidentModel(
      id: incidentId,
      caseNumber: caseNumber,
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'offline_user',
      incidentType: incidentData['incident_type'],
      title: incidentData['title'],
      description: incidentData['description'],
      dateOccurred: DateTime.parse(incidentData['date_occurred']),
      locationOccurred: incidentData['location_occurred'],
      financialLoss: incidentData['financial_loss']?.toDouble(),
      suspectInformation: incidentData['suspect_information'],
      evidenceFiles: evidenceFiles ?? [],
      contactPreference: incidentData['contact_preference'],
      contactDetails: incidentData['contact_details'],
      priorityLevel: incidentData['priority_level'],
      status: 'offline_pending',
      investigationNotes: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Store incident locally
    await _incidentsCache.put(incidentId, jsonEncode(incident.toJson()));
    
    // Add to sync queue
    await _addToSyncQueue('create_incident', {
      'incident_data': incidentData,
      'evidence_files': evidenceFiles?.map((e) => e.toJson()).toList(),
      'local_id': incidentId,
    });

    return incidentId;
  }

  static Future<List<IncidentModel>> getOfflineIncidents() async {
    if (!_isInitialized) await initialize();
    
    try {
      final incidents = <IncidentModel>[];
      
      for (final key in _incidentsCache.keys) {
        final incidentJson = _incidentsCache.get(key);
        if (incidentJson != null) {
          final incident = IncidentModel.fromJson(jsonDecode(incidentJson));
          incidents.add(incident);
        }
      }
      
      incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return incidents;
    } catch (e) {
      print('Failed to load offline incidents: $e');
      return [];
    }
  }

  // Education content caching
  static Future<void> cacheEducationContent(List<EducationCategory> categories) async {
    if (!_isInitialized) await initialize();
    
    try {
      final categoriesJson = jsonEncode(categories.map((c) => c.toJson()).toList());
      await _educationCache.put('categories', categoriesJson);
      await _appCache.put('education_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to cache education content: $e');
    }
  }

  static Future<List<EducationCategory>> getCachedEducationContent() async {
    if (!_isInitialized) await initialize();
    
    try {
      final categoriesJson = _educationCache.get('categories');
      if (categoriesJson != null) {
        final categoriesList = jsonDecode(categoriesJson) as List;
        return categoriesList.map((c) => EducationCategory.fromJson(c)).toList();
      }
    } catch (e) {
      print('Failed to load cached education content: $e');
    }
    
    return [];
  }

  // Emergency contacts caching
  static Future<void> cacheEmergencyContacts(Map<String, List<EmergencyContact>> contacts) async {
    if (!_isInitialized) await initialize();
    
    try {
      final contactsJson = jsonEncode(
        contacts.map((country, contactsList) => 
          MapEntry(country, contactsList.map((c) => c.toJson()).toList())
        )
      );
      await _contactsCache.put('all_contacts', contactsJson);
      await _appCache.put('contacts_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      print('Failed to cache emergency contacts: $e');
    }
  }

  static Future<List<EmergencyContact>> getCachedEmergencyContacts(String country) async {
    if (!_isInitialized) await initialize();
    
    try {
      final contactsJson = _contactsCache.get('all_contacts');
      if (contactsJson != null) {
        final allContacts = jsonDecode(contactsJson) as Map<String, dynamic>;
        final countryContacts = allContacts[country] as List?;
        
        if (countryContacts != null) {
          return countryContacts.map((c) => EmergencyContact.fromJson(c)).toList();
        }
      }
    } catch (e) {
      print('Failed to load cached emergency contacts: $e');
    }
    
    return [];
  }

  // General cache management
  static Future<void> setCacheData(String key, dynamic data) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _appCache.put(key, jsonEncode(data));
    } catch (e) {
      print('Failed to set cache data: $e');
    }
  }

  static Future<T?> getCacheData<T>(String key) async {
    if (!_isInitialized) await initialize();
    
    try {
      final data = _appCache.get(key);
      if (data != null) {
        return jsonDecode(data) as T;
      }
    } catch (e) {
      print('Failed to get cache data: $e');
    }
    
    return null;
  }

  static Future<bool> isCacheExpired(String cacheKey, {Duration expiry = const Duration(hours: 24)}) async {
    try {
      final cacheTimeStr = _appCache.get(cacheKey);
      if (cacheTimeStr == null) return true;
      
      final cacheTime = DateTime.parse(cacheTimeStr);
      final now = DateTime.now();
      
      return now.difference(cacheTime) > expiry;
    } catch (e) {
      return true;
    }
  }

  // Sync queue management
  static Future<void> _addToSyncQueue(String operation, Map<String, dynamic> data) async {
    try {
      final syncItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'operation': operation,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'attempts': 0,
        'max_attempts': 3,
      };
      
      await _syncQueue.put(syncItem['id'] as String, jsonEncode(syncItem));
    } catch (e) {
      print('Failed to add to sync queue: $e');
    }
  }

  static Future<void> _startBackgroundSync() async {
    // Check connectivity and sync every 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      await _processSyncQueue();
      _startBackgroundSync(); // Schedule next sync
    });
  }

  static Future<void> _processSyncQueue() async {
    if (!await isConnected()) return;

    try {
      final itemsToSync = <String, Map<String, dynamic>>{};
      
      for (final key in _syncQueue.keys) {
        final itemJson = _syncQueue.get(key);
        if (itemJson != null) {
          final item = jsonDecode(itemJson) as Map<String, dynamic>;
          itemsToSync[key] = item;
        }
      }

      for (final entry in itemsToSync.entries) {
        final key = entry.key;
        final item = entry.value;
        
        try {
          await _processSyncItem(item);
          await _syncQueue.delete(key); // Remove from queue on success
        } catch (e) {
          print('Failed to sync item $key: $e');
          
          final attempts = (item['attempts'] as int? ?? 0) + 1;
          final maxAttempts = item['max_attempts'] as int? ?? 3;
          
          if (attempts >= maxAttempts) {
            await _syncQueue.delete(key); // Remove after max attempts
            print('Removed item $key after $maxAttempts failed attempts');
          } else {
            item['attempts'] = attempts;
            await _syncQueue.put(key, jsonEncode(item));
          }
        }
      }
    } catch (e) {
      print('Error processing sync queue: $e');
    }
  }

  static Future<void> _processSyncItem(Map<String, dynamic> item) async {
    final operation = item['operation'] as String;
    final data = item['data'] as Map<String, dynamic>;

    switch (operation) {
      case 'create_incident':
        final incidentData = data['incident_data'] as Map<String, dynamic>;
        final evidenceFiles = (data['evidence_files'] as List?)
            ?.map((e) => EvidenceFile.fromJson(e))
            .toList();
        
        await IncidentService.createIncident(
          incidentData: incidentData,
          evidenceFiles: evidenceFiles,
        );
        
        // Remove from local storage after successful sync
        final localId = data['local_id'] as String;
        await _incidentsCache.delete(localId);
        break;
        
      default:
        print('Unknown sync operation: $operation');
    }
  }

  // Force sync all offline data
  static Future<void> forceSyncAll() async {
    if (!await isConnected()) {
      throw Exception('No internet connection available');
    }
    
    await _processSyncQueue();
  }

  // Get sync status
  static Future<Map<String, dynamic>> getSyncStatus() async {
    if (!_isInitialized) await initialize();
    
    final queueSize = _syncQueue.keys.length;
    final isOnline = await isConnected();
    final lastSyncTime = _appCache.get('last_sync_time');
    
    return {
      'queue_size': queueSize,
      'is_online': isOnline,
      'last_sync_time': lastSyncTime,
      'has_pending_items': queueSize > 0,
    };
  }

  // Clear all offline data
  static Future<void> clearAllOfflineData() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _incidentsCache.clear();
      await _educationCache.clear();
      await _contactsCache.clear();
      await _appCache.clear();
      await _syncQueue.clear();
      
      print('All offline data cleared');
    } catch (e) {
      print('Failed to clear offline data: $e');
    }
  }

  // Get storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    if (!_isInitialized) await initialize();
    
    return {
      'incidents_count': _incidentsCache.keys.length,
      'education_cached': _educationCache.keys.isNotEmpty,
      'contacts_cached': _contactsCache.keys.isNotEmpty,
      'cache_keys': _appCache.keys.length,
      'sync_queue_size': _syncQueue.keys.length,
    };
  }

  // Dispose resources
  static Future<void> dispose() async {
    if (_isInitialized) {
      await Hive.close();
      _isInitialized = false;
    }
  }
}