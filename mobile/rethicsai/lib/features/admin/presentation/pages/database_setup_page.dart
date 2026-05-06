import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../core/services/database_init_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/cloud_functions_service.dart';

class DatabaseSetupPage extends StatefulWidget {
  const DatabaseSetupPage({super.key});

  @override
  State<DatabaseSetupPage> createState() => _DatabaseSetupPageState();
}

class _DatabaseSetupPageState extends State<DatabaseSetupPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _databaseStatus;
  String? _statusMessage;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkDatabaseStatus();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _checkDatabaseStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await DatabaseInitService.getDatabaseStatus();
      setState(() {
        _databaseStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking database status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeDatabase() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseInitService.initializeDatabase();
      setState(() => _statusMessage = 'Database initialized successfully!');
      await _checkDatabaseStatus();
    } catch (e) {
      setState(() => _statusMessage = 'Error initializing database: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createFirstSuperAdmin() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseInitService.createFirstSuperAdmin(
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      );
      setState(() => _statusMessage = 'Super Admin account created successfully!');
      await _checkDatabaseStatus();
    } catch (e) {
      setState(() => _statusMessage = 'Error creating Super Admin: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createDemoUsers() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseInitService.createDemoUsers();
      setState(() => _statusMessage = 'Demo users created successfully!');
      await _checkDatabaseStatus();
    } catch (e) {
      setState(() => _statusMessage = 'Error creating demo users: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _initializeWithCloudFunction() async {
    setState(() => _isLoading = true);
    try {
      final result = await CloudFunctionsService.initializeDatabase(
        firstName: _firstNameController.text.trim().isEmpty ? null : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? null : _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      );

      if (result['success'] == true) {
        setState(() => _statusMessage = 'Database initialized successfully with Cloud Function!');
        await _checkDatabaseStatus();
      } else {
        setState(() => _statusMessage = 'Cloud Function error: ${result['error']}');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error calling Cloud Function: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createDemoUsersWithCloudFunction() async {
    setState(() => _isLoading = true);
    try {
      final result = await CloudFunctionsService.createDemoUsers();

      if (result['success'] == true) {
        setState(() => _statusMessage = 'Demo users created successfully with Cloud Function!');
        await _checkDatabaseStatus();
      } else {
        setState(() => _statusMessage = 'Cloud Function error: ${result['error']}');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error calling Cloud Function: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: Stack(
        children: [
          const AfricanPatternBackground(opacity: 0.03),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Current User Info
                  _buildCurrentUserInfo(currentUser),
                  const SizedBox(height: 24),

                  // Database Status
                  _buildDatabaseStatus(),
                  const SizedBox(height: 24),

                  // Setup Actions
                  if (!_isSetupComplete()) ...[
                    _buildSetupActions(),
                    const SizedBox(height: 24),
                  ],

                  // Admin Creation Form
                  if (_databaseStatus?['users_collection_exists'] == true && !_hasAnySuperAdmin())
                    _buildAdminCreationForm(),

                  // Status Messages
                  if (_statusMessage != null) _buildStatusMessage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.storage, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database Setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Initialize Firebase collections and create admin users',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserInfo(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current User',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (user != null) ...[
            Text('Email: ${user.email ?? 'No email'}'),
            Text('UID: ${user.uid}'),
            Text('Email Verified: ${user.emailVerified ? 'Yes' : 'No'}'),
          ] else
            const Text('Not logged in', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildDatabaseStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Database Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _checkDatabaseStatus,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_databaseStatus != null) ...[
            _buildStatusRow('Users Collection', _databaseStatus!['users_collection_exists'] == true),
            _buildStatusRow('Roles Collection', _databaseStatus!['roles_collection_exists'] == true),
            _buildStatusRow('History Collection', _databaseStatus!['history_collection_exists'] == true),
            const SizedBox(height: 12),
            Text('Total Users: ${_databaseStatus!['total_users'] ?? 0}'),
            if (_databaseStatus!['role_breakdown'] != null) ...[
              const SizedBox(height: 8),
              Text('Super Admins: ${_databaseStatus!['role_breakdown']['super_admins'] ?? 0}'),
              Text('Admins: ${_databaseStatus!['role_breakdown']['admins'] ?? 0}'),
              Text('Moderators: ${_databaseStatus!['role_breakdown']['moderators'] ?? 0}'),
              Text('Regular Users: ${_databaseStatus!['role_breakdown']['users'] ?? 0}'),
            ],
          ] else
            const Text('Unable to load database status'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.error,
            color: isOk ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSetupActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Setup Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _initializeDatabase,
          icon: const Icon(Icons.storage),
          label: const Text('Initialize Database'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _createDemoUsers,
          icon: const Icon(Icons.people),
          label: const Text('Create Demo Users'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(height: 16),
        
        const Divider(),
        const Text(
          'Cloud Function Options (Bypasses Security Rules)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 12),
        
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _initializeWithCloudFunction,
          icon: const Icon(Icons.cloud),
          label: const Text('Initialize with Cloud Function'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _createDemoUsersWithCloudFunction,
          icon: const Icon(Icons.cloud_queue),
          label: const Text('Create Demo Users (Cloud Function)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminCreationForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Your Super Admin Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _countryController,
            decoration: const InputDecoration(
              labelText: 'Country (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createFirstSuperAdmin,
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Create (Direct)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _initializeWithCloudFunction,
                  icon: const Icon(Icons.cloud),
                  label: const Text('Create (Cloud)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusMessage!.contains('Error') 
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusMessage!.contains('Error') ? Icons.error : Icons.check_circle,
            color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_statusMessage!)),
        ],
      ),
    );
  }

  bool _isSetupComplete() {
    return _databaseStatus?['database_ready'] == true && _hasAnySuperAdmin();
  }

  bool _hasAnySuperAdmin() {
    return (_databaseStatus?['role_breakdown']?['super_admins'] ?? 0) > 0;
  }
}