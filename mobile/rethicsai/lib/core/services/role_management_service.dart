import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleManagementService {
  static const String _rolesCollection = 'user_roles';
  static const String _roleHistoryCollection = 'role_history';
  static const String _usersCollection = 'users';
  
  static CollectionReference get _roles =>
      FirebaseFirestore.instance.collection(_rolesCollection);
  
  static CollectionReference get _roleHistory =>
      FirebaseFirestore.instance.collection(_roleHistoryCollection);
  
  static CollectionReference get _users =>
      FirebaseFirestore.instance.collection(_usersCollection);

  /// Available roles in the system
  static const List<String> availableRoles = [
    'user',
    'admin',
    'super_admin',
    'moderator',
  ];

  /// Role permissions mapping
  static const Map<String, List<String>> rolePermissions = {
    'user': [
      'submit_incident',
      'view_own_incidents',
      'update_own_profile',
      'view_education_content',
    ],
    'moderator': [
      'submit_incident',
      'view_own_incidents',
      'update_own_profile',
      'view_education_content',
      'moderate_content',
      'view_all_incidents',
    ],
    'admin': [
      'submit_incident',
      'view_own_incidents',
      'update_own_profile',
      'view_education_content',
      'moderate_content',
      'view_all_incidents',
      'assign_cases',
      'manage_users',
      'view_analytics',
      'change_user_roles',
    ],
    'super_admin': [
      'submit_incident',
      'view_own_incidents',
      'update_own_profile',
      'view_education_content',
      'moderate_content',
      'view_all_incidents',
      'assign_cases',
      'manage_users',
      'view_analytics',
      'change_user_roles',
      'system_administration',
      'delete_users',
      'backup_data',
    ],
  };

  /// Initialize role for a new user
  static Future<void> initializeUserRole({
    required String userId,
    required String email,
    String role = 'user',
    String? assignedBy,
  }) async {
    try {
      final now = DateTime.now();
      final batch = FirebaseFirestore.instance.batch();

      // Create role document
      final roleDoc = _roles.doc(userId);
      batch.set(roleDoc, {
        'user_id': userId,
        'email': email,
        'current_role': role,
        'previous_role': null,
        'assigned_by': assignedBy ?? 'system',
        'assigned_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'is_active': true,
        'permissions': rolePermissions[role] ?? rolePermissions['user'],
      });

      // Create role history entry
      final historyDoc = _roleHistory.doc();
      batch.set(historyDoc, {
        'user_id': userId,
        'email': email,
        'action': 'role_assigned',
        'from_role': null,
        'to_role': role,
        'assigned_by': assignedBy ?? 'system',
        'timestamp': now.toIso8601String(),
        'reason': 'Initial role assignment',
      });

      // Update user document
      final userDoc = _users.doc(userId);
      batch.update(userDoc, {
        'role': role,
        'permissions': rolePermissions[role] ?? rolePermissions['user'],
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('RoleManagementService: Role initialized for user: $userId as $role');
    } catch (e) {
      print('RoleManagementService: Error initializing user role: $e');
      rethrow;
    }
  }

  /// Change user role (admin function)
  static Future<void> changeUserRole({
    required String targetUserId,
    required String newRole,
    String? reason,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Check if current user has permission to change roles
      final canChangeRoles = await hasPermission(currentUser.uid, 'change_user_roles');
      if (!canChangeRoles) {
        throw Exception('Insufficient permissions to change user roles');
      }

      // Validate new role
      if (!availableRoles.contains(newRole)) {
        throw Exception('Invalid role: $newRole');
      }

      // Get current role data
      final roleDoc = await _roles.doc(targetUserId).get();
      if (!roleDoc.exists) {
        throw Exception('User role document not found');
      }

      final roleData = roleDoc.data() as Map<String, dynamic>;
      final currentRole = roleData['current_role'] as String;

      if (currentRole == newRole) {
        throw Exception('User already has role: $newRole');
      }

      // Get user email for logging
      final userDoc = await _users.doc(targetUserId).get();
      final userEmail = userDoc.exists 
          ? (userDoc.data() as Map<String, dynamic>)['email'] as String
          : 'unknown';

      final now = DateTime.now();
      final batch = FirebaseFirestore.instance.batch();

      // Update role document
      batch.update(_roles.doc(targetUserId), {
        'previous_role': currentRole,
        'current_role': newRole,
        'assigned_by': currentUser.uid,
        'assigned_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'permissions': rolePermissions[newRole] ?? rolePermissions['user'],
      });

      // Create role history entry
      final historyDoc = _roleHistory.doc();
      batch.set(historyDoc, {
        'user_id': targetUserId,
        'email': userEmail,
        'action': 'role_changed',
        'from_role': currentRole,
        'to_role': newRole,
        'assigned_by': currentUser.uid,
        'timestamp': now.toIso8601String(),
        'reason': reason ?? 'Role change by admin',
      });

      // Update user document
      batch.update(_users.doc(targetUserId), {
        'role': newRole,
        'permissions': rolePermissions[newRole] ?? rolePermissions['user'],
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('RoleManagementService: Role changed for user: $targetUserId from $currentRole to $newRole');
    } catch (e) {
      print('RoleManagementService: Error changing user role: $e');
      rethrow;
    }
  }

  /// Get user role information
  static Future<Map<String, dynamic>?> getUserRoleInfo(String userId) async {
    try {
      final doc = await _roles.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('RoleManagementService: Error getting user role info: $e');
      return null;
    }
  }

  /// Check if user has a specific permission
  static Future<bool> hasPermission(String userId, String permission) async {
    try {
      final roleInfo = await getUserRoleInfo(userId);
      if (roleInfo == null) return false;

      final permissions = List<String>.from(roleInfo['permissions'] ?? []);
      return permissions.contains(permission);
    } catch (e) {
      print('RoleManagementService: Error checking permission: $e');
      return false;
    }
  }

  /// Check if current user has a specific role
  static Future<bool> hasRole(String userId, String role) async {
    try {
      final roleInfo = await getUserRoleInfo(userId);
      if (roleInfo == null) return false;

      return roleInfo['current_role'] == role;
    } catch (e) {
      print('RoleManagementService: Error checking role: $e');
      return false;
    }
  }

  /// Get users by role
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await _roles
          .where('current_role', isEqualTo: role)
          .where('is_active', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('RoleManagementService: Error getting users by role: $e');
      return [];
    }
  }

  /// Get role history for a user
  static Future<List<Map<String, dynamic>>> getUserRoleHistory(String userId) async {
    try {
      final querySnapshot = await _roleHistory
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('RoleManagementService: Error getting user role history: $e');
      return [];
    }
  }

  /// Get all role changes (admin function)
  static Future<List<Map<String, dynamic>>> getAllRoleHistory({
    int limit = 50,
    String? filterByRole,
  }) async {
    try {
      Query query = _roleHistory.orderBy('timestamp', descending: true);

      if (filterByRole != null) {
        query = query.where('to_role', isEqualTo: filterByRole);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('RoleManagementService: Error getting all role history: $e');
      return [];
    }
  }

  /// Deactivate user role (soft delete)
  static Future<void> deactivateUser(String userId, {String? reason}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final canManageUsers = await hasPermission(currentUser.uid, 'manage_users');
      if (!canManageUsers) {
        throw Exception('Insufficient permissions to deactivate users');
      }

      final now = DateTime.now();
      final batch = FirebaseFirestore.instance.batch();

      // Update role document
      batch.update(_roles.doc(userId), {
        'is_active': false,
        'deactivated_by': currentUser.uid,
        'deactivated_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Create history entry
      final historyDoc = _roleHistory.doc();
      batch.set(historyDoc, {
        'user_id': userId,
        'action': 'user_deactivated',
        'assigned_by': currentUser.uid,
        'timestamp': now.toIso8601String(),
        'reason': reason ?? 'User deactivated by admin',
      });

      // Update user document
      batch.update(_users.doc(userId), {
        'isActive': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('RoleManagementService: User deactivated: $userId');
    } catch (e) {
      print('RoleManagementService: Error deactivating user: $e');
      rethrow;
    }
  }

  /// Reactivate user
  static Future<void> reactivateUser(String userId, {String? reason}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final canManageUsers = await hasPermission(currentUser.uid, 'manage_users');
      if (!canManageUsers) {
        throw Exception('Insufficient permissions to reactivate users');
      }

      final now = DateTime.now();
      final batch = FirebaseFirestore.instance.batch();

      // Update role document
      batch.update(_roles.doc(userId), {
        'is_active': true,
        'reactivated_by': currentUser.uid,
        'reactivated_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      // Create history entry
      final historyDoc = _roleHistory.doc();
      batch.set(historyDoc, {
        'user_id': userId,
        'action': 'user_reactivated',
        'assigned_by': currentUser.uid,
        'timestamp': now.toIso8601String(),
        'reason': reason ?? 'User reactivated by admin',
      });

      // Update user document
      batch.update(_users.doc(userId), {
        'isActive': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('RoleManagementService: User reactivated: $userId');
    } catch (e) {
      print('RoleManagementService: Error reactivating user: $e');
      rethrow;
    }
  }

  /// Get role statistics
  static Future<Map<String, int>> getRoleStatistics() async {
    try {
      final stats = <String, int>{};
      
      for (final role in availableRoles) {
        final querySnapshot = await _roles
            .where('current_role', isEqualTo: role)
            .where('is_active', isEqualTo: true)
            .get();
        stats[role] = querySnapshot.docs.length;
      }
      
      return stats;
    } catch (e) {
      print('RoleManagementService: Error getting role statistics: $e');
      return {};
    }
  }

  /// Bulk role assignment (super admin function)
  static Future<void> bulkAssignRoles({
    required List<String> userIds,
    required String newRole,
    String? reason,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final isSuperAdmin = await hasRole(currentUser.uid, 'super_admin');
      if (!isSuperAdmin) {
        throw Exception('Only super admins can perform bulk role assignments');
      }

      for (final userId in userIds) {
        await changeUserRole(
          targetUserId: userId,
          newRole: newRole,
          reason: reason ?? 'Bulk role assignment',
        );
      }

      print('RoleManagementService: Bulk role assignment completed for ${userIds.length} users');
    } catch (e) {
      print('RoleManagementService: Error in bulk role assignment: $e');
      rethrow;
    }
  }
}