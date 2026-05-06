import 'package:firebase_auth/firebase_auth.dart';
import '../services/role_management_service.dart';
import '../services/user_service.dart';

/// Role-based access control utilities
class RoleAccessControl {
  /// Check if current user can access admin features
  static Future<bool> canAccessAdminFeatures() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    return await UserService.currentUserHasPermission('view_analytics') ||
           await UserService.currentUserHasPermission('manage_users');
  }

  /// Check if current user can view all incidents
  static Future<bool> canViewAllIncidents() async {
    return await UserService.currentUserHasPermission('view_all_incidents');
  }

  /// Check if current user can assign cases
  static Future<bool> canAssignCases() async {
    return await UserService.currentUserHasPermission('assign_cases');
  }

  /// Check if current user can manage other users
  static Future<bool> canManageUsers() async {
    return await UserService.currentUserHasPermission('manage_users');
  }

  /// Check if current user can change user roles
  static Future<bool> canChangeUserRoles() async {
    return await UserService.currentUserHasPermission('change_user_roles');
  }

  /// Check if current user can moderate content
  static Future<bool> canModerateContent() async {
    return await UserService.currentUserHasPermission('moderate_content');
  }

  /// Check if current user can access system administration features
  static Future<bool> canAccessSystemAdmin() async {
    return await UserService.currentUserHasPermission('system_administration');
  }

  /// Check if current user can delete users
  static Future<bool> canDeleteUsers() async {
    return await UserService.currentUserHasPermission('delete_users');
  }

  /// Get current user's role display name
  static Future<String> getCurrentUserRoleDisplayName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'Guest';
      
      final role = await UserService.getUserRole(currentUser.uid);
      return _getRoleDisplayName(role);
    } catch (e) {
      return 'User';
    }
  }

  /// Get role display name
  static String _getRoleDisplayName(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrator';
      case 'admin':
        return 'Administrator';
      case 'moderator':
        return 'Moderator';
      case 'user':
        return 'User';
      default:
        return 'User';
    }
  }

  /// Get all available roles for dropdown/selection
  static List<Map<String, String>> getAvailableRoles() {
    return RoleManagementService.availableRoles.map((role) => {
      'value': role,
      'label': _getRoleDisplayName(role),
    }).toList();
  }

  /// Check if current user can change a specific user's role
  static Future<bool> canChangeSpecificUserRole(String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      // Check basic permission first
      final canChangeRoles = await canChangeUserRoles();
      if (!canChangeRoles) return false;
      
      // Check specific role hierarchy
      return await UserService.canManageUserRole(currentUser.uid, targetUserId);
    } catch (e) {
      return false;
    }
  }

  /// Get available roles that current user can assign to target user
  static Future<List<String>> getAssignableRoles(String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];
      
      final currentUserRole = await UserService.getUserRole(currentUser.uid);
      final canManage = await canChangeSpecificUserRole(targetUserId);
      
      if (!canManage) return [];
      
      switch (currentUserRole) {
        case 'super_admin':
          return ['user', 'moderator', 'admin', 'super_admin'];
        case 'admin':
          return ['user', 'moderator', 'admin'];
        case 'moderator':
          return ['user'];
        default:
          return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get permission descriptions for UI
  static Map<String, String> getPermissionDescriptions() {
    return {
      'submit_incident': 'Can submit new incident reports',
      'view_own_incidents': 'Can view their own submitted incidents',
      'update_own_profile': 'Can update their own profile information',
      'view_education_content': 'Can access educational resources',
      'moderate_content': 'Can moderate and review content',
      'view_all_incidents': 'Can view all incident reports in the system',
      'assign_cases': 'Can assign incident cases to officers',
      'manage_users': 'Can manage user accounts and profiles',
      'view_analytics': 'Can access system analytics and reports',
      'change_user_roles': 'Can change user roles and permissions',
      'system_administration': 'Can access system administration features',
      'delete_users': 'Can permanently delete user accounts',
      'backup_data': 'Can create and manage system backups',
    };
  }

  /// Get role hierarchy for UI display
  static List<Map<String, dynamic>> getRoleHierarchy() {
    return [
      {
        'role': 'super_admin',
        'name': 'Super Administrator',
        'description': 'Full system access with all permissions',
        'level': 4,
        'color': '#dc2626', // Red
      },
      {
        'role': 'admin',
        'name': 'Administrator',
        'description': 'Administrative access with user management capabilities',
        'level': 3,
        'color': '#ea580c', // Orange
      },
      {
        'role': 'moderator',
        'name': 'Moderator',
        'description': 'Content moderation and incident viewing capabilities',
        'level': 2,
        'color': '#ca8a04', // Yellow
      },
      {
        'role': 'user',
        'name': 'User',
        'description': 'Standard user with basic incident reporting capabilities',
        'level': 1,
        'color': '#16a34a', // Green
      },
    ];
  }

  /// Validate role transition
  static bool isValidRoleTransition(String fromRole, String toRole) {
    final hierarchy = getRoleHierarchy();
    final fromLevel = hierarchy.firstWhere((r) => r['role'] == fromRole, orElse: () => {'level': 0})['level'];
    final toLevel = hierarchy.firstWhere((r) => r['role'] == toRole, orElse: () => {'level': 0})['level'];
    
    // Allow transitions between adjacent levels or to lower levels
    return (toLevel - fromLevel).abs() <= 2;
  }

  /// Get current user's permissions list
  static Future<List<String>> getCurrentUserPermissions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];
      
      final roleInfo = await UserService.getCurrentUserRoleInfo();
      if (roleInfo == null) return [];
      
      return List<String>.from(roleInfo['permissions'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Check multiple permissions at once
  static Future<Map<String, bool>> checkMultiplePermissions(List<String> permissions) async {
    final results = <String, bool>{};
    
    for (final permission in permissions) {
      results[permission] = await UserService.currentUserHasPermission(permission);
    }
    
    return results;
  }

  /// Get role-specific navigation items
  static Future<List<Map<String, dynamic>>> getRoleBasedNavigation() async {
    final permissions = await getCurrentUserPermissions();
    final navigation = <Map<String, dynamic>>[];

    // Always available
    navigation.addAll([
      {'title': 'Dashboard', 'icon': 'dashboard', 'route': '/dashboard'},
      {'title': 'Report Incident', 'icon': 'report', 'route': '/report'},
      {'title': 'My Cases', 'icon': 'cases', 'route': '/cases'},
      {'title': 'Profile', 'icon': 'person', 'route': '/profile'},
    ]);

    // Role-based items
    if (permissions.contains('view_all_incidents')) {
      navigation.add({'title': 'All Incidents', 'icon': 'list', 'route': '/admin/incidents'});
    }

    if (permissions.contains('manage_users')) {
      navigation.add({'title': 'User Management', 'icon': 'people', 'route': '/admin/users'});
    }

    if (permissions.contains('view_analytics')) {
      navigation.add({'title': 'Analytics', 'icon': 'analytics', 'route': '/admin/analytics'});
    }

    if (permissions.contains('system_administration')) {
      navigation.add({'title': 'System Admin', 'icon': 'settings', 'route': '/admin/system'});
    }

    return navigation;
  }
}

/// Extension methods for easier role checking
extension RoleExtensions on User {
  /// Check if user has a specific role
  Future<bool> hasRole(String role) async {
    return await RoleManagementService.hasRole(uid, role);
  }

  /// Check if user has a specific permission
  Future<bool> hasPermission(String permission) async {
    return await RoleManagementService.hasPermission(uid, permission);
  }

  /// Get user's current role
  Future<String> getCurrentRole() async {
    return await UserService.getUserRole(uid);
  }

  /// Check if user is admin (admin or super_admin)
  Future<bool> get isAdmin async {
    final role = await getCurrentRole();
    return role == 'admin' || role == 'super_admin';
  }

  /// Check if user is super admin
  Future<bool> get isSuperAdmin async {
    return await hasRole('super_admin');
  }

  /// Check if user is moderator or higher
  Future<bool> get canModerate async {
    return await hasPermission('moderate_content');
  }
}