import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/role_management_service.dart';
import '../../../../core/utils/role_access_control.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';
  bool _showInactive = false;
  final TextEditingController _searchController = TextEditingController();
  String _currentUserRole = 'user';
  Set<String> _selectedUsers = {};
  bool _isBulkMode = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _loadUsers();
  }

  Future<void> _loadCurrentUserRole() async {
    final role = await UserService.getUserRole(
      FirebaseAuth.instance.currentUser?.uid ?? '',
    );
    setState(() {
      _currentUserRole = role;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> users;
      if (_selectedRoleFilter == 'all') {
        users = await UserService.getUsersWithRoleInfo();
      } else {
        users = await RoleManagementService.getUsersByRole(_selectedRoleFilter);
        // Enhance with user info
        for (int i = 0; i < users.length; i++) {
          final userProfile = await UserService.getUserProfile(users[i]['user_id']);
          if (userProfile != null) {
            users[i] = {...users[i], ...userProfile};
          }
        }
      }
      
      // Filter inactive users if needed
      if (!_showInactive) {
        users = users.where((user) => user['is_active'] != false).toList();
      }
      
      setState(() {
        _users = users;
        _isLoading = false;
        _selectedUsers.clear();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _loadUsers();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final users = await UserService.searchUsers(query);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }
  }

  Future<void> _updateUserRole(String userId, String currentRole) async {
    final availableRoles = await RoleAccessControl.getAssignableRoles(userId);
    if (availableRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to change this user\'s role'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final newRole = await _showRoleSelectionDialog(currentRole, availableRoles);
    if (newRole != null && newRole != currentRole) {
      final reason = await _showReasonDialog();
      try {
        await RoleManagementService.changeUserRole(
          targetUserId: userId,
          newRole: newRole,
          reason: reason,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to $newRole successfully'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRoleSelectionDialog(String currentRole, List<String> availableRoles) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Select User Role'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Role: ${RoleAccessControl.getAvailableRoles().firstWhere((r) => r['value'] == currentRole)['label']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...RoleAccessControl.getRoleHierarchy().where((role) => 
              availableRoles.contains(role['role'])).map((roleInfo) =>
              _buildEnhancedRoleOption(
                roleInfo['role'],
                roleInfo['name'],
                roleInfo['description'],
                roleInfo['color'],
                currentRole,
              )
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reason for Role Change'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String role, String title, String description, String currentRole) {
    final isSelected = role == currentRole;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppTheme.primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
        ),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      onTap: () => Navigator.pop(context, role),
    );
  }

  Widget _buildEnhancedRoleOption(String role, String title, String description, String colorHex, String currentRole) {
    final isSelected = role == currentRole;
    final color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? color.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: role != currentRole ? () => Navigator.pop(context, role) : null,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final email = user['email']?.toString().toLowerCase() ?? '';
      final firstName = user['firstName']?.toString().toLowerCase() ?? '';
      final lastName = user['lastName']?.toString().toLowerCase() ?? '';
      final role = user['current_role']?.toString().toLowerCase() ?? user['role']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return email.contains(query) || firstName.contains(query) || lastName.contains(query) || role.contains(query);
    }).toList();
  }

  Future<void> _toggleUserActivation(String userId, bool isActive) async {
    try {
      if (isActive) {
        await RoleManagementService.deactivateUser(userId, reason: 'Deactivated via admin panel');
      } else {
        await RoleManagementService.reactivateUser(userId, reason: 'Reactivated via admin panel');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${isActive ? 'deactivated' : 'reactivated'} successfully'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkUpdateRoles() async {
    if (_selectedUsers.isEmpty) return;
    
    final availableRoles = RoleAccessControl.getAvailableRoles()
        .where((role) => role['value'] != 'super_admin' || _currentUserRole == 'super_admin')
        .toList();
        
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select Role for ${_selectedUsers.length} users'),
        children: availableRoles.map((role) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, role['value']),
          child: Text(role['label'] as String),
        )).toList(),
      ),
    );
    
    if (selectedRole != null) {
      final reason = await _showReasonDialog();
      try {
        await RoleManagementService.bulkAssignRoles(
          userIds: _selectedUsers.toList(),
          newRole: selectedRole,
          reason: reason ?? 'Bulk role assignment via admin panel',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk role update completed for ${_selectedUsers.length} users'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        setState(() {
          _isBulkMode = false;
          _selectedUsers.clear();
        });
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: const AfricanPatternBackground(opacity: 0.03),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),
                
                // Search bar and filters
                _buildSearchBar(),
                _buildFiltersBar(),
                
                // Users list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredUsers.isEmpty
                          ? _buildEmptyState()
                          : _buildUsersList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Icon(Icons.people, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBulkMode ? 'Bulk Operations (${_selectedUsers.length} selected)' : 'User Management',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isBulkMode ? 'Select users for bulk operations' : 'Manage user roles and permissions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_isBulkMode) ...[
            if (_selectedUsers.isNotEmpty)
              IconButton(
                onPressed: _bulkUpdateRoles,
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Update Roles',
              ),
            IconButton(
              onPressed: () => setState(() {
                _isBulkMode = false;
                _selectedUsers.clear();
              }),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Exit Bulk Mode',
            ),
          ] else ...[
            if (_currentUserRole == 'super_admin')
              IconButton(
                onPressed: () => setState(() => _isBulkMode = true),
                icon: const Icon(Icons.checklist, color: Colors.white),
                tooltip: 'Bulk Operations',
              ),
            IconButton(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildFiltersBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRoleFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Role',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Roles')),
                ...RoleManagementService.availableRoles.map((role) =>
                  DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedRoleFilter = value!);
                _loadUsers();
              },
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: Text('Show Inactive'),
            selected: _showInactive,
            onSelected: (selected) {
              setState(() => _showInactive = selected);
              _loadUsers();
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms);
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users by email or name...',
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadUsers();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          if (value.length >= 3 || value.isEmpty) {
            _searchUsers(value);
          }
        },
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No users found' : 'No users match your search',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Users will appear here once they register'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final role = user['current_role'] ?? user['role'] ?? 'user';
    final userId = user['user_id'] ?? user['uid'] ?? user['id'];
    final isActive = user['is_active'] != false;
    final isSelected = _selectedUsers.contains(userId);
    final roleInfo = RoleAccessControl.getRoleHierarchy().firstWhere(
      (r) => r['role'] == role,
      orElse: () => {'role': role, 'name': role.toUpperCase(), 'color': '#16a34a'},
    );
    final roleColor = Color(int.parse(roleInfo['color'].substring(1), radix: 16) + 0xFF000000);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: _isBulkMode && isSelected 
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _isBulkMode 
            ? Checkbox(
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedUsers.add(userId);
                    } else {
                      _selectedUsers.remove(userId);
                    }
                  });
                },
              )
            : CircleAvatar(
                radius: 25,
                backgroundColor: roleColor,
                child: Icon(
                  _getRoleIcon(role),
                  color: Colors.white,
                ),
              ),
        title: Text(
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'] ?? '',
              style: TextStyle(
                color: isActive ? Colors.black54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleColor),
                  ),
                  child: Text(
                    roleInfo['name'],
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: _isBulkMode 
            ? null
            : PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.primaryColor),
                onSelected: (value) async {
                  switch (value) {
                    case 'edit_role':
                      await _updateUserRole(userId, role);
                      break;
                    case 'toggle_active':
                      await _toggleUserActivation(userId, isActive);
                      break;
                    case 'view_history':
                      await _showUserRoleHistory(userId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_role',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Change Role'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_active',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                          color: isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Deactivate' : 'Reactivate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view_history',
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 8),
                        Text('Role History'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: (100 * index).ms).slideX(begin: 0.3, end: 0);
  }

  Color _getRoleColor(String role) {
    final roleInfo = RoleAccessControl.getRoleHierarchy().firstWhere(
      (r) => r['role'] == role,
      orElse: () => {'color': '#16a34a'},
    );
    return Color(int.parse(roleInfo['color'].substring(1), radix: 16) + 0xFF000000);
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.security;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'moderator':
        return Icons.verified_user;
      default:
        return Icons.person;
    }
  }

  Future<void> _showUserRoleHistory(String userId) async {
    try {
      final history = await RoleManagementService.getUserRoleHistory(userId);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Role History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: history.isEmpty
                ? const Center(child: Text('No role history found'))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final date = DateTime.parse(item['timestamp']).toLocal();
                      return ListTile(
                        leading: Icon(_getActionIcon(item['action'])),
                        title: Text(item['action'].toString().replaceAll('_', ' ').toUpperCase()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['from_role'] != null)
                              Text('From: ${item['from_role']} → To: ${item['to_role']}'),
                            Text('Date: ${date.day}/${date.month}/${date.year}'),
                            if (item['reason'] != null)
                              Text('Reason: ${item['reason']}'),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'role_assigned':
        return Icons.assignment;
      case 'role_changed':
        return Icons.swap_horiz;
      case 'user_deactivated':
        return Icons.block;
      case 'user_reactivated':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}