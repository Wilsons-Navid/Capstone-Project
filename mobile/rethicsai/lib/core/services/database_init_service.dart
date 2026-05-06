import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_management_service.dart';
import 'user_service.dart';

class DatabaseInitService {
  static const String _collection = 'users';
  
  static CollectionReference get _users =>
      FirebaseFirestore.instance.collection(_collection);

  /// Initialize the database with required collections and initial data
  static Future<void> initializeDatabase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please login first.');
      }

      print('DatabaseInitService: Starting database initialization for user: ${currentUser.email} (${currentUser.uid})');
      
      // Check if users collection exists and has documents
      final usersSnapshot = await _users.limit(1).get();
      
      if (usersSnapshot.docs.isEmpty) {
        print('DatabaseInitService: No users found. Setting up initial data with current user as super admin...');
        await _createInitialCollections();
      } else {
        print('DatabaseInitService: Users collection already exists. Ensuring current user has super admin access...');
        // Ensure current user exists as super admin
        await createFirstSuperAdmin();
      }
      
      // Ensure role management collections are properly indexed
      await _ensureRoleManagementIndexes();
      
      print('DatabaseInitService: Database initialization completed for ${currentUser.email}');
    } catch (e) {
      print('DatabaseInitService: Error during initialization: $e');
      rethrow;
    }
  }

  /// Create initial collections and current user as super admin
  static Future<void> _createInitialCollections() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please login first.');
      }

      final email = currentUser.email;
      if (email == null) {
        throw Exception('Current user has no email address');
      }

      print('DatabaseInitService: Creating initial collections for user: $email (${currentUser.uid})');

      // Create current user as super admin instead of system user
      await createFirstSuperAdmin();
      
      print('DatabaseInitService: Created initial collections with current user as super admin');
    } catch (e) {
      print('DatabaseInitService: Error creating initial collections: $e');
      rethrow;
    }
  }

  /// Ensure proper indexes exist for role management
  static Future<void> _ensureRoleManagementIndexes() async {
    try {
      // These operations will create the collections if they don't exist
      // Firestore will automatically create indexes for simple queries
      
      final rolesCollection = FirebaseFirestore.instance.collection('user_roles');
      await rolesCollection.limit(1).get();
      
      final historyCollection = FirebaseFirestore.instance.collection('role_history');
      await historyCollection.limit(1).get();
      
      print('DatabaseInitService: Role management collections initialized');
    } catch (e) {
      print('DatabaseInitService: Error ensuring indexes: $e');
      // Non-critical error, continue execution
    }
  }

  /// Create first super admin user from current authenticated user
  static Future<void> createFirstSuperAdmin({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? country,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please login first.');
      }

      final email = currentUser.email;
      if (email == null) {
        throw Exception('Current user has no email address');
      }

      // Check if user already exists
      final existingUser = await UserService.userExists(currentUser.uid);
      if (existingUser) {
        print('DatabaseInitService: User document already exists, updating role to super_admin');
        await UserService.updateUserRole(currentUser.uid, 'super_admin');
        return;
      }

      // Create new super admin user
      await UserService.createUserDocument(
        userId: currentUser.uid,
        email: email,
        firstName: firstName ?? 'Super',
        lastName: lastName ?? 'Admin',
        phoneNumber: phoneNumber,
        country: country,
        role: 'super_admin',
      );

      print('DatabaseInitService: Created first super admin user: $email');
    } catch (e) {
      print('DatabaseInitService: Error creating first super admin: $e');
      rethrow;
    }
  }

  /// Create admin user from existing authenticated user
  static Future<void> createAdminUser({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? country,
    String role = 'admin',
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found. Please login first.');
      }

      final email = currentUser.email;
      if (email == null) {
        throw Exception('Current user has no email address');
      }

      // Validate role
      if (!RoleManagementService.availableRoles.contains(role)) {
        throw Exception('Invalid role: $role');
      }

      // Check if user already exists
      final existingUser = await UserService.userExists(currentUser.uid);
      if (existingUser) {
        print('DatabaseInitService: User document already exists, updating role to $role');
        await UserService.updateUserRole(currentUser.uid, role);
        return;
      }

      // Create new user with specified role
      await UserService.createUserDocument(
        userId: currentUser.uid,
        email: email,
        firstName: firstName ?? 'User',
        lastName: lastName ?? 'Admin',
        phoneNumber: phoneNumber,
        country: country,
        role: role,
      );

      print('DatabaseInitService: Created $role user: $email');
    } catch (e) {
      print('DatabaseInitService: Error creating admin user: $e');
      rethrow;
    }
  }

  /// Setup demo users for testing (optional)
  static Future<void> createDemoUsers() async {
    try {
      final demoUsers = [
        {
          'uid': 'demo_super_admin',
          'email': 'superadmin@rethicsai.com',
          'firstName': 'Demo',
          'lastName': 'Super Admin',
          'role': 'super_admin',
        },
        {
          'uid': 'demo_admin',
          'email': 'admin@rethicsai.com',
          'firstName': 'Demo',
          'lastName': 'Admin',
          'role': 'admin',
        },
        {
          'uid': 'demo_moderator',
          'email': 'moderator@rethicsai.com',
          'firstName': 'Demo',
          'lastName': 'Moderator',
          'role': 'moderator',
        },
        {
          'uid': 'demo_user',
          'email': 'user@rethicsai.com',
          'firstName': 'Demo',
          'lastName': 'User',
          'role': 'user',
        },
      ];

      final batch = FirebaseFirestore.instance.batch();
      
      for (final userData in demoUsers) {
        final userRef = _users.doc(userData['uid']);
        batch.set(userRef, {
          ...userData,
          'permissions': RoleManagementService.rolePermissions[userData['role']] ?? RoleManagementService.rolePermissions['user'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'emailVerified': true,
          'isDemoUser': true,
        });

        // Initialize role management for each demo user
        final roleRef = FirebaseFirestore.instance.collection('user_roles').doc(userData['uid']);
        batch.set(roleRef, {
          'user_id': userData['uid'],
          'email': userData['email'],
          'current_role': userData['role'],
          'previous_role': null,
          'assigned_by': 'system',
          'assigned_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_active': true,
          'permissions': RoleManagementService.rolePermissions[userData['role']] ?? RoleManagementService.rolePermissions['user'],
        });
      }

      await batch.commit();
      print('DatabaseInitService: Created ${demoUsers.length} demo users');
    } catch (e) {
      print('DatabaseInitService: Error creating demo users: $e');
      rethrow;
    }
  }

  /// Check database status and return information
  static Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      final usersSnapshot = await _users.get();
      final rolesSnapshot = await FirebaseFirestore.instance.collection('user_roles').get();
      final historySnapshot = await FirebaseFirestore.instance.collection('role_history').get();

      final superAdmins = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] == 'super_admin';
      }).length;
      final admins = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] == 'admin';
      }).length;
      final moderators = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] == 'moderator';
      }).length;
      final regularUsers = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'] == 'user';
      }).length;

      return {
        'users_collection_exists': usersSnapshot.docs.isNotEmpty,
        'total_users': usersSnapshot.docs.length,
        'roles_collection_exists': rolesSnapshot.docs.isNotEmpty,
        'total_role_documents': rolesSnapshot.docs.length,
        'history_collection_exists': historySnapshot.docs.isNotEmpty,
        'total_history_entries': historySnapshot.docs.length,
        'role_breakdown': {
          'super_admins': superAdmins,
          'admins': admins,
          'moderators': moderators,
          'users': regularUsers,
        },
        'has_super_admin': superAdmins > 0,
        'database_ready': usersSnapshot.docs.isNotEmpty && rolesSnapshot.docs.isNotEmpty,
      };
    } catch (e) {
      print('DatabaseInitService: Error getting database status: $e');
      return {
        'error': e.toString(),
        'database_ready': false,
      };
    }
  }

  /// Clean up demo data (use with caution)
  static Future<void> cleanupDemoData() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Find and delete demo users
      final demoUsersQuery = await _users.where('isDemoUser', isEqualTo: true).get();
      for (final doc in demoUsersQuery.docs) {
        batch.delete(doc.reference);
        
        // Also delete their role documents
        final roleDoc = FirebaseFirestore.instance.collection('user_roles').doc(doc.id);
        batch.delete(roleDoc);
      }
      
      await batch.commit();
      print('DatabaseInitService: Cleaned up ${demoUsersQuery.docs.length} demo users');
    } catch (e) {
      print('DatabaseInitService: Error cleaning up demo data: $e');
      rethrow;
    }
  }
}