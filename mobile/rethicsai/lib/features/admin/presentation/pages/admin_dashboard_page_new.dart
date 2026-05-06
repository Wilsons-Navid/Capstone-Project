import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../core/services/emergency_contacts_service.dart';
import '../../../../core/services/education_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/models/incident_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _incidentStats = {};
  bool _isLoading = true;
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  List<IncidentModel> _filteredIncidents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await IncidentService.getIncidentStatistics();
      setState(() {
        _incidentStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    // This will trigger a rebuild of the FutureBuilder with new filters
    setState(() {});
  }

  List<IncidentModel> _filterIncidents(List<IncidentModel> incidents) {
    return incidents.where((incident) {
      // Filter by status
      bool statusMatch = _selectedStatus == 'all' || incident.status == _selectedStatus;
      
      // Filter by priority
      bool priorityMatch = _selectedPriority == 'all' || incident.priority == _selectedPriority;
      
      return statusMatch && priorityMatch;
    }).toList();
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
                _buildHeader(),
                _buildStatsCards(),
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
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
        gradient: AppTheme.primaryGradient.scale(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'System Management & Overview',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            tabs: const [
              Tab(text: 'Incidents'),
              Tab(text: 'Contacts'),
              Tab(text: 'Education'),
              Tab(text: 'Analytics'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatsCards() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Cases',
              _incidentStats['total']?.toString() ?? '0',
              Icons.folder,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              'Active',
              ((_incidentStats['submitted'] ?? 0) + 
               (_incidentStats['in_progress'] ?? 0)).toString(),
              Icons.trending_up,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              'Resolved',
              _incidentStats['resolved']?.toString() ?? '0',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              'High Priority',
              _incidentStats['high_priority']?.toString() ?? '0',
              Icons.priority_high,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildIncidentManagement(),
        _buildContactsManagement(),
        _buildEducationManagement(),
        _buildAnalytics(),
      ],
    );
  }

  Widget _buildIncidentManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incident Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildIncidentFilters(),
          const SizedBox(height: 20),
          _buildIncidentsList(),
        ],
      ),
    );
  }

  Widget _buildIncidentFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    'all',
                    'submitted',
                    'under_review',
                    'in_progress',
                    'investigating',
                    'resolved',
                    'closed'
                  ].map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.replaceAll('_', ' ').toUpperCase()),
                  )).toList(),
                  value: _selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'all';
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['all', 'high', 'medium', 'low'].map((priority) => 
                    DropdownMenuItem(
                      value: priority,
                      child: Text(priority.toUpperCase()),
                    )).toList(),
                  value: _selectedPriority,
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value ?? 'all';
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList() {
    return FutureBuilder<List<IncidentModel>>(
      future: IncidentService.getAllIncidents(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading incidents: ${snapshot.error}'),
          );
        }

        final allIncidents = snapshot.data ?? [];
        final incidents = _filterIncidents(allIncidents);

        if (incidents.isEmpty) {
          return const Center(
            child: Text('No incidents match the selected filters'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            return _buildIncidentCard(incident);
          },
        );
      },
    );
  }

  Widget _buildIncidentCard(IncidentModel incident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getPriorityColor(incident.priorityLevel).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIncidentTypeIcon(incident.incidentType),
            color: _getPriorityColor(incident.priorityLevel),
          ),
        ),
        title: Text(
          incident.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Case: ${incident.caseNumber}'),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(incident.status),
                const SizedBox(width: 8),
                _buildPriorityChip(incident.priorityLevel),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleIncidentAction(action, incident),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'assign',
              child: ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Assign Officer'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'status',
              child: ListTile(
                leading: Icon(Icons.update),
                title: Text('Update Status'),
                dense: true,
              ),
            ),
          ],
        ),
        onTap: () => _showIncidentDetails(incident),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIncidentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'phishing':
        return Icons.phishing;
      case 'malware':
        return Icons.bug_report;
      case 'fraud':
        return Icons.warning;
      case 'identity_theft':
        return Icons.person_off;
      case 'cyberbullying':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.security;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'submitted':
        color = Colors.blue;
        break;
      case 'under_review':
        color = Colors.orange;
        break;
      case 'in_progress':
      case 'investigating':
        color = Colors.purple;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);
    return Chip(
      label: Text(
        priority.toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }

  void _handleIncidentAction(String action, IncidentModel incident) {
    switch (action) {
      case 'view':
        _showIncidentDetails(incident);
        break;
      case 'assign':
        _showAssignOfficerDialog(incident);
        break;
      case 'status':
        _showUpdateStatusDialog(incident);
        break;
    }
  }

  void _showIncidentDetails(IncidentModel incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Case ${incident.caseNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', incident.title),
              _buildDetailRow('Type', incident.incidentType),
              _buildDetailRow('Status', incident.status),
              _buildDetailRow('Priority', incident.priorityLevel),
              _buildDetailRow('Date Occurred', 
                DateFormat('MMM dd, yyyy').format(incident.dateOccurred)),
              _buildDetailRow('Location', incident.locationOccurred ?? 'Not specified'),
              _buildDetailRow('Financial Loss', 
                incident.financialLoss != null 
                  ? '${_inferCurrencyFromCountry(incident.reporterCountry ?? '')} ${incident.financialLoss!.toStringAsFixed(2)}' 
                  : 'None'),
              const SizedBox(height: 12),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(incident.description),
              if (incident.investigationNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Investigation Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...incident.investigationNotes.map((note) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${note.note}'),
                )),
              ],
            ],
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
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Infer likely currency from reporter country (best-effort)
  String _inferCurrencyFromCountry(String country) {
    final c = (country).toLowerCase();
    if (c.contains('nigeria')) return 'NGN';
    if (c.contains('kenya')) return 'KES';
    if (c.contains('south africa')) return 'ZAR';
    if (c.contains('tanzania')) return 'TZS';
    if (c.contains('uganda')) return 'UGX';
    if (c.contains('ghana')) return 'GHS';
    if (c.contains('morocco')) return 'MAD';
    if (c.contains('egypt')) return 'EGP';
    if (c.contains('senegal') || c.contains("cote d") || c.contains('côte d')) return 'XOF';
    if (c.contains('cameroon') || c.contains('gabon') || c.contains('congo')) return 'XAF';
    return 'USD';
  }

  void _showAssignOfficerDialog(IncidentModel incident) {
    showDialog(
      context: context,
      builder: (context) => _AssignOfficerDialog(
        incident: incident,
        onAssigned: () {
          _applyFilters(); // Refresh the incidents list
        },
      ),
    );
  }

  void _showUpdateStatusDialog(IncidentModel incident) {
    showDialog(
      context: context,
      builder: (context) => _UpdateStatusDialog(
        incident: incident,
        onUpdated: () {
          _applyFilters(); // Refresh the incidents list
        },
      ),
    );
  }

  Widget _buildContactsManagement() {
    return const Center(
      child: Text('Emergency Contacts Management - Coming Soon'),
    );
  }

  Widget _buildEducationManagement() {
    return const Center(
      child: Text('Education Content Management - Coming Soon'),
    );
  }

  Widget _buildAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildAnalyticsCards(),
          const SizedBox(height: 30),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.2,
      children: [
        _buildAnalyticsCard(
          'Total Users',
          '1,234',
          Icons.people,
          Colors.blue,
          '+12%',
        ),
        _buildAnalyticsCard(
          'Active Cases',
          '56',
          Icons.folder_open,
          Colors.orange,
          '+8%',
        ),
        _buildAnalyticsCard(
          'Resolved Today',
          '23',
          Icons.check_circle,
          Colors.green,
          '+15%',
        ),
        _buildAnalyticsCard(
          'Response Time',
          '2.4h',
          Icons.timer,
          Colors.purple,
          '-5%',
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                change,
                style: TextStyle(
                  color: change.startsWith('+') ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      'New incident reported: Phishing attempt',
      'Case #RET20241234 resolved',
      'Officer assigned to Case #RET20241235',
      'System maintenance completed',
      'New user registered from Lagos',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.circle, size: 8, color: Colors.blue),
            title: Text(
              activities[index],
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Text(
              '${index + 1}h ago',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssignOfficerDialog extends StatefulWidget {
  final IncidentModel incident;
  final VoidCallback onAssigned;

  const _AssignOfficerDialog({
    required this.incident,
    required this.onAssigned,
  });

  @override
  State<_AssignOfficerDialog> createState() => _AssignOfficerDialogState();
}

class _AssignOfficerDialogState extends State<_AssignOfficerDialog> {
  String? _selectedOfficerId;
  String? _selectedOfficerName;
  List<Map<String, dynamic>> _officers = [];
  bool _isLoading = true;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadOfficers();
  }

  Future<void> _loadOfficers() async {
    try {
      final users = await UserService.getAllUsers();
      
      // Filter for admin users and officers
      _officers = users.where((user) {
        final role = user['role'] as String?;
        final isAdmin = user['isAdmin'] as bool? ?? false;
        return isAdmin || role == 'officer' || role == 'admin';
      }).toList();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load officers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignOfficer() async {
    if (_selectedOfficerId == null) return;

    setState(() {
      _isAssigning = true;
    });

    try {
      // Update incident with assigned officer
      await IncidentService.updateIncidentStatus(
        widget.incident.id,
        'in_progress', // Change status to in_progress when assigned
        assignedTo: _selectedOfficerId,
        notes: 'Incident assigned to $_selectedOfficerName',
      );

      Navigator.of(context).pop();
      widget.onAssigned();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incident assigned to $_selectedOfficerName successfully'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isAssigning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign incident: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Officer'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident: ${widget.incident.title}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Officer:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_officers.isEmpty)
              const Text(
                'No officers available',
                style: TextStyle(color: Colors.grey),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _officers.length,
                  itemBuilder: (context, index) {
                    final officer = _officers[index];
                    final officerId = officer['uid'] as String;
                    final firstName = officer['firstName'] as String? ?? '';
                    final lastName = officer['lastName'] as String? ?? '';
                    final email = officer['email'] as String;
                    final role = officer['role'] as String? ?? 'user';
                    final fullName = '$firstName $lastName'.trim();
                    final displayName = fullName.isNotEmpty ? fullName : email;

                    return RadioListTile<String>(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      value: officerId,
                      groupValue: _selectedOfficerId,
                      onChanged: (value) {
                        setState(() {
                          _selectedOfficerId = value;
                          _selectedOfficerName = displayName;
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedOfficerId != null && !_isAssigning
              ? _assignOfficer
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isAssigning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}

class _UpdateStatusDialog extends StatefulWidget {
  final IncidentModel incident;
  final VoidCallback onUpdated;

  const _UpdateStatusDialog({
    required this.incident,
    required this.onUpdated,
  });

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  String? _selectedStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isUpdating = false;

  final List<String> _statusOptions = [
    'submitted',
    'under_review',
    'in_progress',
    'investigating',
    'resolved',
    'closed',
  ];

  final Map<String, String> _statusDescriptions = {
    'submitted': 'Incident has been submitted and awaiting review',
    'under_review': 'Incident is being reviewed by administrators',
    'in_progress': 'Incident is currently being investigated',
    'investigating': 'Active investigation is underway',
    'resolved': 'Incident has been resolved',
    'closed': 'Incident is closed and archived',
  };

  final Map<String, Color> _statusColors = {
    'submitted': Colors.blue,
    'under_review': Colors.orange,
    'in_progress': Colors.purple,
    'investigating': Colors.amber,
    'resolved': Colors.green,
    'closed': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.incident.status;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final notes = _notesController.text.trim();
      
      await IncidentService.updateIncidentStatus(
        widget.incident.id,
        _selectedStatus!,
        notes: notes.isNotEmpty ? notes : null,
      );

      Navigator.of(context).pop();
      widget.onUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incident status updated to ${_selectedStatus!.replaceAll('_', ' ').toUpperCase()}'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusOption(String status) {
    final isSelected = _selectedStatus == status;
    final color = _statusColors[status] ?? Colors.grey;
    final description = _statusDescriptions[status] ?? '';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Status'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident: ${widget.incident.title}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current Status: ${widget.incident.status.replaceAll('_', ' ').toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select New Status:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              child: ListView(
                children: _statusOptions
                    .map((status) => _buildStatusOption(status))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notes (optional):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add notes about this status update...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedStatus != null && !_isUpdating
              ? _updateStatus
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Status'),
        ),
      ],
    );
  }
}
