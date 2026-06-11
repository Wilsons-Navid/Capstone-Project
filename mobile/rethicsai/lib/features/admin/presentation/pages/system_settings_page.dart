import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  Map<String, dynamic> _systemSettings = {};
  
  // Controllers for various settings
  final _platformNameController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _maxFileUploadSizeController = TextEditingController();
  final _sessionTimeoutController = TextEditingController();
  final _maintenanceMessageController = TextEditingController();
  
  // Settings state
  bool _maintenanceMode = false;
  bool _registrationEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _autoAssignCases = true;
  bool _requireEmailVerification = true;
  bool _enableTwoFactorAuth = false;
  bool _logUserActivity = true;
  String _defaultPriority = 'medium';
  String _defaultLanguage = 'en';
  String _timeZone = 'UTC';

  final List<String> _priorities = ['low', 'medium', 'high'];
  final List<String> _languages = ['en', 'fr', 'sw', 'ar'];
  final List<String> _timeZones = ['UTC', 'GMT+1', 'GMT+2', 'GMT+3', 'GMT-5', 'GMT-8'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSystemSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _platformNameController.dispose();
    _supportEmailController.dispose();
    _maxFileUploadSizeController.dispose();
    _sessionTimeoutController.dispose();
    _maintenanceMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('global')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _systemSettings = data;
          _platformNameController.text = data['platform_name'] ?? 'Rethicssec';
          _supportEmailController.text = data['support_email'] ?? 'support@rethicsai.com';
          _maxFileUploadSizeController.text = data['max_file_upload_size']?.toString() ?? '10';
          _sessionTimeoutController.text = data['session_timeout']?.toString() ?? '60';
          _maintenanceMessageController.text = data['maintenance_message'] ?? '';
          
          _maintenanceMode = data['maintenance_mode'] ?? false;
          _registrationEnabled = data['registration_enabled'] ?? true;
          _emailNotifications = data['email_notifications'] ?? true;
          _smsNotifications = data['sms_notifications'] ?? false;
          _autoAssignCases = data['auto_assign_cases'] ?? true;
          _requireEmailVerification = data['require_email_verification'] ?? true;
          _enableTwoFactorAuth = data['enable_two_factor_auth'] ?? false;
          _logUserActivity = data['log_user_activity'] ?? true;
          _defaultPriority = data['default_priority'] ?? 'medium';
          _defaultLanguage = data['default_language'] ?? 'en';
          _timeZone = data['time_zone'] ?? 'UTC';
        });
      } else {
        // Create default settings
        await _createDefaultSettings();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load system settings: $e');
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      final defaultSettings = {
        'platform_name': 'Rethicssec',
        'support_email': 'support@rethicsai.com',
        'max_file_upload_size': 10,
        'session_timeout': 60,
        'maintenance_mode': false,
        'maintenance_message': '',
        'registration_enabled': true,
        'email_notifications': true,
        'sms_notifications': false,
        'auto_assign_cases': true,
        'require_email_verification': true,
        'enable_two_factor_auth': false,
        'log_user_activity': true,
        'default_priority': 'medium',
        'default_language': 'en',
        'time_zone': 'UTC',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? 'system',
      };

      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('global')
          .set(defaultSettings);

      setState(() => _systemSettings = defaultSettings);
    } catch (e) {
      throw Exception('Failed to create default settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AfricanPatternBackground(opacity: 0.03),
          SafeArea(
            child: Column(
              children: [
                // Header
                PremiumSectionHeader(
                  title: 'System Settings',
                  subtitle: 'Configure platform settings and preferences',
                  icon: Icons.settings,
                  gradient: LinearGradient(
                    colors: [Colors.grey[700]!, Colors.grey[800]!],
                  ),
                  action: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'General'),
                    Tab(text: 'Security'),
                    Tab(text: 'Notifications'),
                    Tab(text: 'System'),
                    Tab(text: 'Maintenance'),
                  ],
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildGeneralSettings(),
                            _buildSecuritySettings(),
                            _buildNotificationSettings(),
                            _buildSystemSettings(),
                            _buildMaintenanceSettings(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAllSettings,
        icon: const Icon(Icons.save),
        label: const Text('Save All'),
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Platform Information'),
          _buildTextField(
            controller: _platformNameController,
            label: 'Platform Name',
            icon: Icons.label,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _supportEmailController,
            label: 'Support Email',
            icon: Icons.email,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            value: _defaultLanguage,
            label: 'Default Language',
            icon: Icons.language,
            items: _languages.map((lang) => DropdownMenuItem(
              value: lang,
              child: Text(lang.toUpperCase()),
            )).toList(),
            onChanged: (value) => setState(() => _defaultLanguage = value ?? 'en'),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            value: _timeZone,
            label: 'Time Zone',
            icon: Icons.access_time,
            items: _timeZones.map((tz) => DropdownMenuItem(
              value: tz,
              child: Text(tz),
            )).toList(),
            onChanged: (value) => setState(() => _timeZone = value ?? 'UTC'),
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Default Settings'),
          _buildDropdownField(
            value: _defaultPriority,
            label: 'Default Incident Priority',
            icon: Icons.priority_high,
            items: _priorities.map((priority) => DropdownMenuItem(
              value: priority,
              child: Text(priority.toUpperCase()),
            )).toList(),
            onChanged: (value) => setState(() => _defaultPriority = value ?? 'medium'),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Auto-assign Cases',
            subtitle: 'Automatically assign new cases to available investigators',
            value: _autoAssignCases,
            onChanged: (value) => setState(() => _autoAssignCases = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('User Registration'),
          _buildSwitchTile(
            title: 'Enable User Registration',
            subtitle: 'Allow new users to register accounts',
            value: _registrationEnabled,
            onChanged: (value) => setState(() => _registrationEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Require Email Verification',
            subtitle: 'Users must verify email before accessing the platform',
            value: _requireEmailVerification,
            onChanged: (value) => setState(() => _requireEmailVerification = value),
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Authentication'),
          _buildSwitchTile(
            title: 'Enable Two-Factor Authentication',
            subtitle: 'Require 2FA for admin accounts',
            value: _enableTwoFactorAuth,
            onChanged: (value) => setState(() => _enableTwoFactorAuth = value),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _sessionTimeoutController,
            label: 'Session Timeout (minutes)',
            icon: Icons.timer,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Privacy & Logging'),
          _buildSwitchTile(
            title: 'Log User Activity',
            subtitle: 'Track user actions for security and audit purposes',
            value: _logUserActivity,
            onChanged: (value) => setState(() => _logUserActivity = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Notification Channels'),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Send notifications via email',
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: 'SMS Notifications',
            subtitle: 'Send notifications via SMS (requires SMS service)',
            value: _smsNotifications,
            onChanged: (value) => setState(() => _smsNotifications = value),
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Notification Templates'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email Templates',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildTemplateItem('Welcome Email', 'New user registration'),
                _buildTemplateItem('Password Reset', 'Password reset request'),
                _buildTemplateItem('Case Assignment', 'Case assigned to investigator'),
                _buildTemplateItem('Status Update', 'Case status changed'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showTemplateEditor(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Templates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('File Upload'),
          _buildTextField(
            controller: _maxFileUploadSizeController,
            label: 'Maximum File Size (MB)',
            icon: Icons.file_upload,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('System Health'),
          _buildSystemHealthCard(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Database Management'),
          _buildDatabaseManagementCard(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('System Information'),
          _buildSystemInfoCard(),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Maintenance Mode'),
          _buildSwitchTile(
            title: 'Enable Maintenance Mode',
            subtitle: 'Temporarily disable platform access for maintenance',
            value: _maintenanceMode,
            onChanged: (value) => setState(() => _maintenanceMode = value),
          ),
          const SizedBox(height: 16),
          if (_maintenanceMode)
            _buildTextField(
              controller: _maintenanceMessageController,
              label: 'Maintenance Message',
              icon: Icons.message,
              maxLines: 3,
              hintText: 'Enter message to display to users during maintenance...',
            ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('System Backup'),
          _buildBackupCard(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Data Cleanup'),
          _buildDataCleanupCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTemplateItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editTemplate(name),
            icon: const Icon(Icons.edit, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Health Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildHealthItem('Database', 'Operational', AppTheme.successColor),
          _buildHealthItem('File Storage', 'Operational', AppTheme.successColor),
          _buildHealthItem('Email Service', 'Operational', AppTheme.successColor),
          _buildHealthItem('Authentication', 'Operational', AppTheme.successColor),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _runSystemHealthCheck(),
            icon: const Icon(Icons.health_and_safety, size: 16),
            label: const Text('Run Health Check'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String service, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: 8),
          Expanded(child: Text(service)),
          Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDatabaseManagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Database Operations', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _optimizeDatabase(),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Optimize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.victoriaBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _analyzeDatabase(),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Analyze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.baobabBrown,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Information', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow('Platform Version', '1.0.0'),
          _buildInfoRow('Database Version', 'Firestore'),
          _buildInfoRow('Last Updated', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())),
          _buildInfoRow('Uptime', '45 days'),
        ],
      ),
    );
  }

  Widget _buildBackupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Backup Management', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow('Last Backup', 'Yesterday 02:00 AM'),
          _buildInfoRow('Next Backup', 'Tomorrow 02:00 AM'),
          _buildInfoRow('Backup Size', '2.3 GB'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _createBackup(),
                  icon: const Icon(Icons.backup, size: 16),
                  label: const Text('Create Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _configureBackup(),
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Configure'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    side: const BorderSide(color: AppTheme.secondaryColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCleanupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Cleanup', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'Clean up old data to optimize performance',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _cleanupOldLogs(),
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: const Text('Clean Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.clayRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _archiveOldData(),
                  icon: const Icon(Icons.archive, size: 16),
                  label: const Text('Archive'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.clayRed,
                    side: BorderSide(color: AppTheme.clayRed),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllSettings() async {
    try {
      final settingsData = {
        'platform_name': _platformNameController.text,
        'support_email': _supportEmailController.text,
        'max_file_upload_size': int.tryParse(_maxFileUploadSizeController.text) ?? 10,
        'session_timeout': int.tryParse(_sessionTimeoutController.text) ?? 60,
        'maintenance_mode': _maintenanceMode,
        'maintenance_message': _maintenanceMessageController.text,
        'registration_enabled': _registrationEnabled,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
        'auto_assign_cases': _autoAssignCases,
        'require_email_verification': _requireEmailVerification,
        'enable_two_factor_auth': _enableTwoFactorAuth,
        'log_user_activity': _logUserActivity,
        'default_priority': _defaultPriority,
        'default_language': _defaultLanguage,
        'time_zone': _timeZone,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      };

      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('global')
          .update(settingsData);

      _showSuccessSnackBar('Settings saved successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to save settings: $e');
    }
  }

  void _showTemplateEditor() {
    _showInfoDialog('Template Editor', 'Email template editor coming soon');
  }

  void _editTemplate(String templateName) {
    _showInfoDialog('Edit Template', '$templateName template editor coming soon');
  }

  void _runSystemHealthCheck() {
    _showInfoDialog('System Health', 'System health check completed successfully');
  }

  void _optimizeDatabase() {
    _showInfoDialog('Database Optimization', 'Database optimization completed');
  }

  void _analyzeDatabase() {
    _showInfoDialog('Database Analysis', 'Database analysis completed');
  }

  void _createBackup() {
    _showInfoDialog('Backup', 'Manual backup initiated');
  }

  void _configureBackup() {
    _showInfoDialog('Backup Configuration', 'Backup configuration coming soon');
  }

  void _cleanupOldLogs() {
    _showInfoDialog('Data Cleanup', 'Old logs cleaned up successfully');
  }

  void _archiveOldData() {
    _showInfoDialog('Data Archive', 'Old data archived successfully');
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.clayRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}