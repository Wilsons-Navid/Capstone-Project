import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_management_service.dart';

class UserService {
  static const String _collection = 'users';
  
  static CollectionReference get _users =>
      FirebaseFirestore.instance.collection(_collection);

  /// Create user document with role when user signs up
  static Future<void> createUserDocument({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? country,
    String role = 'user', // Default role is 'user'
  }) async {
    try {
      final userData = {
        'uid': userId,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'country': country,
        'role': role,
        'permissions': RoleManagementService.rolePermissions[role] ?? RoleManagementService.rolePermissions['user'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': false,
      };

      await _users.doc(userId).set(userData);
      
      // Initialize role management for the new user
      await RoleManagementService.initializeUserRole(
        userId: userId,
        email: email,
        role: role,
        assignedBy: 'system',
      );
      
      print('UserService: User document created with role: $role');
    } catch (e) {
      print('UserService: Error creating user document: $e');
      rethrow;
    }
  }

  /// Get user role from Firestore
  static Future<String> getUserRole(String userId) async {
    try {
      final roleInfo = await RoleManagementService.getUserRoleInfo(userId);
      if (roleInfo != null) {
        return roleInfo['current_role'] ?? 'user';
      }
      
      // Fallback to users collection
      final doc = await _users.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] ?? 'user';
      }
      return 'user'; // Default role
    } catch (e) {
      print('UserService: Error getting user role: $e');
      return 'user';
    }
  }

  /// Update user role (for admin use) - now uses RoleManagementService
  static Future<void> updateUserRole(String userId, String newRole, {String? reason}) async {
    try {
      await RoleManagementService.changeUserRole(
        targetUserId: userId,
        newRole: newRole,
        reason: reason,
      );
      print('UserService: User role updated to: $newRole');
    } catch (e) {
      print('UserService: Error updating user role: $e');
      rethrow;
    }
  }

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      final hasAdminRole = await RoleManagementService.hasRole(currentUser.uid, 'admin');
      final hasSuperAdminRole = await RoleManagementService.hasRole(currentUser.uid, 'super_admin');
      return hasAdminRole || hasSuperAdminRole;
    } catch (e) {
      print('UserService: Error checking admin status: $e');
      return false;
    }
  }

  /// Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('UserService: Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _users.doc(userId).update(data);
      print('UserService: User profile updated');
    } catch (e) {
      print('UserService: Error updating user profile: $e');
      rethrow;
    }
  }

  /// Get all users (admin only)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await _users.orderBy('createdAt', descending: true).get();
      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('UserService: Error getting all users: $e');
      return [];
    }
  }

  /// Search users by email or name (admin only)
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final querySnapshot = await _users
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
          
      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('UserService: Error searching users: $e');
      return [];
    }
  }

  /// Delete user document (admin only)
  static Future<void> deleteUser(String userId) async {
    try {
      await _users.doc(userId).delete();
      print('UserService: User document deleted');
    } catch (e) {
      print('UserService: Error deleting user: $e');
      rethrow;
    }
  }

  /// Get users by role
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await _users
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: true)
          .get();
          
      return querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('UserService: Error getting users by role: $e');
      return [];
    }
  }

  /// Verify user exists
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('UserService: Error checking if user exists: $e');
      return false;
    }
  }

  /// Check if current user has specific permission
  static Future<bool> currentUserHasPermission(String permission) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      return await RoleManagementService.hasPermission(currentUser.uid, permission);
    } catch (e) {
      print('UserService: Error checking permission: $e');
      return false;
    }
  }

  /// Get current user's role info with permissions
  static Future<Map<String, dynamic>?> getCurrentUserRoleInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;
      
      return await RoleManagementService.getUserRoleInfo(currentUser.uid);
    } catch (e) {
      print('UserService: Error getting current user role info: $e');
      return null;
    }
  }

  /// Check if user can manage another user's role
  static Future<bool> canManageUserRole(String currentUserId, String targetUserId) async {
    try {
      final currentUserRole = await getUserRole(currentUserId);
      final targetUserRole = await getUserRole(targetUserId);
      
      // Super admins can manage everyone
      if (currentUserRole == 'super_admin') return true;
      
      // Admins can manage users and moderators, but not other admins or super admins
      if (currentUserRole == 'admin') {
        return targetUserRole == 'user' || targetUserRole == 'moderator';
      }
      
      // Other roles cannot manage user roles
      return false;
    } catch (e) {
      print('UserService: Error checking role management permission: $e');
      return false;
    }
  }

  /// Get users with enhanced role information
  static Future<List<Map<String, dynamic>>> getUsersWithRoleInfo() async {
    try {
      final users = await getAllUsers();
      final enhancedUsers = <Map<String, dynamic>>[];
      
      for (final user in users) {
        final userId = user['uid'] ?? user['id'];
        final roleInfo = await RoleManagementService.getUserRoleInfo(userId);
        
        enhancedUsers.add({
          ...user,
          'role_info': roleInfo,
          'permissions': roleInfo?['permissions'] ?? [],
        });
      }
      
      return enhancedUsers;
    } catch (e) {
      print('UserService: Error getting users with role info: $e');
      return [];
    }
  }

  /// Deactivate user (admin function)
  static Future<void> deactivateUser(String userId, {String? reason}) async {
    try {
      await RoleManagementService.deactivateUser(userId, reason: reason);
      print('UserService: User deactivated: $userId');
    } catch (e) {
      print('UserService: Error deactivating user: $e');
      rethrow;
    }
  }

  /// Reactivate user (admin function)
  static Future<void> reactivateUser(String userId, {String? reason}) async {
    try {
      await RoleManagementService.reactivateUser(userId, reason: reason);
      print('UserService: User reactivated: $userId');
    } catch (e) {
      print('UserService: Error reactivating user: $e');
      rethrow;
    }
  }
}