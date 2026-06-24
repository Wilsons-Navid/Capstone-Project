import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/labeled_dropdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../shared/models/incident_model.dart';

class IncidentReportsPage extends StatefulWidget {
  const IncidentReportsPage({super.key});

  @override
  State<IncidentReportsPage> createState() => _IncidentReportsPageState();
}

class _IncidentReportsPageState extends State<IncidentReportsPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<IncidentModel> _allIncidents = [];
  List<IncidentModel> _filteredIncidents = [];
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late TabController _tabController;
  Map<String, int> _statistics = {};

  final List<String> _statusOptions = ['all', 'Submitted', 'under_review', 'in_progress', 'investigating', 'resolved', 'closed'];
  final List<String> _priorityOptions = ['all', 'high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadIncidents();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final incidents = await IncidentService.getAllIncidents();
      setState(() {
        _allIncidents = incidents;
        _filteredIncidents = incidents;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load incidents: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await IncidentService.getIncidentStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      print('Failed to load statistics: $e');
    }
  }

  void _applyFilters() {
    List<IncidentModel> filtered = List.from(_allIncidents);

    // Apply status filter
    if (_selectedStatus != 'all') {
      filtered = filtered.where((incident) => 
        incident.status.toLowerCase() == _selectedStatus.toLowerCase()).toList();
    }

    // Apply priority filter
    if (_selectedPriority != 'all') {
      filtered = filtered.where((incident) => 
        incident.priorityLevel.toLowerCase() == _selectedPriority).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((incident) =>
        incident.title.toLowerCase().contains(query) ||
        incident.caseNumber.toLowerCase().contains(query) ||
        incident.description.toLowerCase().contains(query) ||
        (incident.reporterName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    setState(() => _filteredIncidents = filtered);
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
                  title: 'Incident Reports',
                  subtitle: 'Manage and review incident reports',
                  icon: Icons.report_problem,
                  gradient: LinearGradient(
                    colors: [AppTheme.secondaryColor, Colors.deepOrange],
                  ),
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _downloadIncidentReports,
                        icon: const Icon(Icons.download, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Statistics Cards
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard('Total', _statistics['total']?.toString() ?? '0', Icons.report, AppTheme.victoriaBlue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Pending', _statistics['submitted']?.toString() ?? '0', Icons.pending, AppTheme.secondaryColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('In Progress', _statistics['in_progress']?.toString() ?? '0', Icons.work, AppTheme.successColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Resolved', _statistics['resolved']?.toString() ?? '0', Icons.check_circle, AppTheme.accentDark)),
                    ],
                  ),
                ),

                // Filters and Search
                _buildFiltersSection(),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: const [
                    Tab(text: 'All Reports'),
                    Tab(text: 'High Priority'),
                    Tab(text: 'Recent'),
                  ],
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIncidentsList(_filteredIncidents),
                      _buildIncidentsList(_filteredIncidents.where((i) => i.priorityLevel.toLowerCase() == 'high').toList()),
                      _buildIncidentsList(_filteredIncidents.take(20).toList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadIncidents,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search incidents, case numbers, or reporters...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter Dropdowns
          Row(
            children: [
              Expanded(
                child: LabeledDropdown<String>(
                  label: 'Status',                  value: _selectedStatus,
                                    items: _statusOptions.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status == 'all' ? 'All Status' : status.replaceAll('_', ' '), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value ?? 'all');
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledDropdown<String>(
                  label: 'Priority',                  value: _selectedPriority,
                                    items: _priorityOptions.map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority == 'all' ? 'All Priorities' : priority.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value ?? 'all');
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

  Widget _buildIncidentsList(List<IncidentModel> incidents) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No incidents found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search criteria',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: incidents.length,
      itemBuilder: (context, index) => _buildIncidentCard(incidents[index]),
    );
  }

  Widget _buildIncidentCard(IncidentModel incident) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and priority
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(incident.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.caseNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        incident.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(incident.status),
                const SizedBox(width: 8),
                _buildPriorityChip(incident.priorityLevel),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Incident details
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        incident.reporterName ?? 'Anonymous Reporter',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(incident.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(incident.incidentType.replaceAll('_', ' ').toUpperCase())),
                    if (incident.financialLoss != null) ...[
                      Icon(Icons.attach_money, size: 16, color: AppTheme.clayRed),
                      Text(
                        '\$${incident.financialLoss!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.clayRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  incident.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewIncidentDetails(incident),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateIncidentStatus(incident),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Update Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return AppTheme.victoriaBlue;
      case 'under_review':
        return AppTheme.secondaryColor;
      case 'in_progress':
      case 'investigating':
        return AppTheme.baobabBrown;
      case 'resolved':
        return AppTheme.successColor;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.clayRed;
      case 'medium':
        return AppTheme.secondaryColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  void _viewIncidentDetails(IncidentModel incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildIncidentDetailsSheet(incident),
    );
  }

  Widget _buildIncidentDetailsSheet(IncidentModel incident) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Incident Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Case info
                _buildDetailRow('Case Number', incident.caseNumber),
                _buildDetailRow('Status', incident.status),
                _buildDetailRow('Priority', incident.priorityLevel),
                _buildDetailRow('Type', incident.incidentType.replaceAll('_', ' ')),
                _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(incident.createdAt)),
                
                if (incident.financialLoss != null)
                  _buildDetailRow('Financial Loss', '\$${incident.financialLoss!.toStringAsFixed(2)}'),
                
                const Divider(height: 32),

                // Reporter info
                Text(
                  'Reporter Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildDetailRow('Name', incident.reporterName ?? 'Anonymous'),
                _buildDetailRow('Phone', incident.reporterPhone ?? 'Not provided'),
                _buildDetailRow('Country', incident.reporterCountry ?? 'Not specified'),
                _buildDetailRow('Contact Preference', incident.contactPreference),
                _buildDetailRow('Contact Details', incident.contactDetails),

                const Divider(height: 32),

                // Incident details
                Text(
                  'Incident Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildDetailRow('Title', incident.title),
                _buildDetailRow('Description', incident.description, isLongText: true),
                _buildDetailRow('Date Occurred', DateFormat('MMM dd, yyyy').format(incident.dateOccurred)),
                
                if (incident.locationOccurred != null)
                  _buildDetailRow('Location', incident.locationOccurred!),
                
                if (incident.suspectInformation != null)
                  _buildDetailRow('Suspect Information', incident.suspectInformation!, isLongText: true),

                if (incident.evidenceFiles.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text(
                    'Evidence Files (${incident.evidenceFiles.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...incident.evidenceFiles.map(_buildEvidenceFileItem),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isLongText ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceFileItem(EvidenceFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            file.isImage ? Icons.image : file.isDocument ? Icons.description : Icons.attach_file,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  file.formattedSize,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (file.fileData != null)
            IconButton(
              onPressed: () => _downloadFile(file),
              icon: const Icon(Icons.download),
            ),
        ],
      ),
    );
  }

  void _updateIncidentStatus(IncidentModel incident) {
    showDialog(
      context: context,
      builder: (context) => _buildUpdateStatusDialog(incident),
    );
  }

  Widget _buildUpdateStatusDialog(IncidentModel incident) {
    String selectedStatus = incident.status;
    final noteController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Update Status - ${incident.caseNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Status: ${incident.status}'),
              const SizedBox(height: 16),
              
              LabeledDropdown<String>(
                label: 'New Status',                value: selectedStatus,
                                items: _statusOptions.where((s) => s != 'all').map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.replaceAll('_', ' ')),
                )).toList(),
                onChanged: (value) {
                  setState(() => selectedStatus = value ?? incident.status);
                },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add update notes...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await IncidentService.updateIncidentStatus(
                    incident.id,
                    selectedStatus,
                    notes: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  );
                  
                  Navigator.pop(context);
                  _showSuccessSnackBar('Status updated successfully');
                  _loadIncidents();
                } catch (e) {
                  _showErrorSnackBar('Failed to update status: $e');
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _downloadFile(EvidenceFile file) async {
    try {
      // Check if we have file data or need to download from path
      if (file.fileData != null) {
        // File data is available as base64
        await _downloadFromBase64(file);
      } else if (file.filePath != null) {
        // File needs to be downloaded from storage
        await _downloadFromPath(file);
      } else {
        _showErrorSnackBar('File data not available for download');
        return;
      }
    } catch (e) {
      _showErrorSnackBar('Failed to download file: $e');
    }
  }

  Future<void> _downloadFromBase64(EvidenceFile file) async {
    try {
      // Get bytes from base64
      final bytes = file.fileBytes;
      if (bytes == null) {
        _showErrorSnackBar('Invalid file data');
        return;
      }

      // Request storage permission
      if (Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (permission != PermissionStatus.granted) {
          final managePermission = await Permission.manageExternalStorage.request();
          if (managePermission != PermissionStatus.granted) {
            _showErrorSnackBar('Storage permission is required to download files');
            return;
          }
        }
      }

      // Get downloads directory
      String? downloadsPath;
      
      if (Platform.isAndroid) {
        downloadsPath = '/storage/emulated/0/Download';
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        downloadsPath = directory.path;
      } else {
        final directory = await getDownloadsDirectory();
        downloadsPath = directory?.path;
      }

      if (downloadsPath == null) {
        _showErrorSnackBar('Unable to access downloads folder');
        return;
      }

      // Create unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = file.fileName.split('.').last;
      final baseFileName = file.fileName.split('.').first;
      final fileName = '${baseFileName}_$timestamp.$fileExtension';
      
      final filePath = '$downloadsPath/$fileName';
      final downloadFile = File(filePath);

      // Write the file
      await downloadFile.writeAsBytes(bytes);

      _showSuccessSnackBar('File downloaded to: $fileName');
      
      // Optionally open the file
      if (await downloadFile.exists()) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Complete'),
            content: Text('File saved as: $fileName\n\nWould you like to open it?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open'),
              ),
            ],
          ),
        );

        if (result == true) {
          await _openFile(filePath);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save file: $e');
    }
  }

  Future<void> _downloadFromPath(EvidenceFile file) async {
    try {
      // This would typically download from Firebase Storage or another cloud service
      // For now, show that this feature needs cloud storage integration
      _showInfoSnackBar('Cloud storage download integration needed for remote files');
    } catch (e) {
      _showErrorSnackBar('Failed to download from path: $e');
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use url_launcher to open the file with default app
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showInfoSnackBar('No app available to open this file type');
        }
      } else {
        _showInfoSnackBar('File opening not supported on this platform');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open file: $e');
    }
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.victoriaBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadIncidentReports() async {
    try {
      await _showDownloadOptionsDialog();
    } catch (e) {
      _showErrorSnackBar('Failed to generate report: $e');
    }
  }

  Future<void> _showDownloadOptionsDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Download Incident Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppTheme.successColor),
              title: const Text('Download as CSV'),
              subtitle: const Text('Spreadsheet format for data analysis'),
              onTap: () {
                Navigator.pop(context);
                _downloadAsCSV();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTheme.clayRed),
              title: const Text('Download as PDF'),
              subtitle: const Text('Beautiful formatted report with colors'),
              trailing: const Icon(Icons.star, color: AppTheme.saharaGold, size: 20),
              onTap: () {
                Navigator.pop(context);
                _downloadAsPDF();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.code, color: AppTheme.victoriaBlue),
              title: const Text('Download as JSON'),
              subtitle: const Text('Structured data format'),
              onTap: () {
                Navigator.pop(context);
                _downloadAsJSON();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.description, color: AppTheme.secondaryColor),
              title: const Text('Generate Summary Report'),
              subtitle: const Text('Human-readable incident summary'),
              onTap: () {
                Navigator.pop(context);
                _downloadAsSummary();
              },
            ),

            ListTile(
              leading: const Icon(Icons.filter_list, color: AppTheme.baobabBrown),
              title: const Text('Download Filtered Results'),
              subtitle: const Text('Export currently visible incidents only'),
              onTap: () {
                Navigator.pop(context);
                _downloadFilteredResults();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAsCSV() async {
    try {
      final csvData = <List<String>>[];
      
      // Header
      csvData.add([
        'Case Number',
        'Title',
        'Status',
        'Priority',
        'Type',
        'Reporter Name',
        'Reporter Phone',
        'Reporter Country',
        'Contact Preference',
        'Description',
        'Financial Loss',
        'Date Occurred',
        'Location',
        'Suspect Information',
        'Created At',
        'Evidence Files Count'
      ]);
      
      // Add incident data
      for (final incident in _allIncidents) {
        csvData.add([
          incident.caseNumber,
          incident.title,
          incident.status,
          incident.priorityLevel,
          incident.incidentType,
          incident.reporterName ?? 'Anonymous',
          incident.reporterPhone ?? 'Not provided',
          incident.reporterCountry ?? 'Not specified',
          incident.contactPreference,
          incident.description,
          incident.financialLoss?.toString() ?? '0',
          DateFormat('yyyy-MM-dd').format(incident.dateOccurred),
          incident.locationOccurred ?? 'Not specified',
          incident.suspectInformation ?? 'None provided',
          DateFormat('yyyy-MM-dd HH:mm:ss').format(incident.createdAt),
          incident.evidenceFiles.length.toString(),
        ]);
      }
      
      final csvString = const ListToCsvConverter().convert(csvData);
      await _saveAndShareFile(csvString, 'incident_reports.csv', 'text/csv');
      
    } catch (e) {
      _showErrorSnackBar('Failed to generate CSV report: $e');
    }
  }

  Future<void> _downloadAsJSON() async {
    try {
      final reportData = {
        'report_info': {
          'title': 'Rethicsec Incident Reports',
          'generated_at': DateTime.now().toIso8601String(),
          'total_incidents': _allIncidents.length,
          'generated_by': 'System Administrator',
        },
        'statistics': _statistics,
        'incidents': _allIncidents.map((incident) => {
          'case_number': incident.caseNumber,
          'title': incident.title,
          'status': incident.status,
          'priority_level': incident.priorityLevel,
          'incident_type': incident.incidentType,
          'reporter_name': incident.reporterName,
          'reporter_phone': incident.reporterPhone,
          'reporter_country': incident.reporterCountry,
          'contact_preference': incident.contactPreference,
          'contact_details': incident.contactDetails,
          'description': incident.description,
          'financial_loss': incident.financialLoss,
          'date_occurred': incident.dateOccurred.toIso8601String(),
          'location_occurred': incident.locationOccurred,
          'suspect_information': incident.suspectInformation,
          'created_at': incident.createdAt.toIso8601String(),
          'evidence_files': incident.evidenceFiles.map((file) => {
            'file_name': file.fileName,
            'file_size': file.fileSize,
            'file_type': file.fileType,
          }).toList(),
        }).toList(),
      };

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(reportData);
      await _saveAndShareFile(jsonString, 'incident_reports.json', 'application/json');
      
    } catch (e) {
      _showErrorSnackBar('Failed to generate JSON report: $e');
    }
  }

  Future<void> _downloadAsSummary() async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('RETHICSEC INCIDENT REPORTS SUMMARY');
      buffer.writeln('=' * 50);
      buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('Total Incidents: ${_allIncidents.length}');
      buffer.writeln();
      
      // Statistics Summary
      buffer.writeln('INCIDENT STATISTICS');
      buffer.writeln('-' * 20);
      _statistics.forEach((key, value) {
        buffer.writeln('• ${key.replaceAll('_', ' ').toUpperCase()}: $value');
      });
      buffer.writeln();
      
      // Status Distribution
      final statusCounts = <String, int>{};
      final priorityCounts = <String, int>{};
      final typeCounts = <String, int>{};
      
      for (final incident in _allIncidents) {
        statusCounts[incident.status] = (statusCounts[incident.status] ?? 0) + 1;
        priorityCounts[incident.priorityLevel] = (priorityCounts[incident.priorityLevel] ?? 0) + 1;
        typeCounts[incident.incidentType] = (typeCounts[incident.incidentType] ?? 0) + 1;
      }
      
      buffer.writeln('STATUS BREAKDOWN');
      buffer.writeln('-' * 16);
      statusCounts.entries.forEach((entry) {
        final percentage = (_allIncidents.length > 0 ? (entry.value / _allIncidents.length * 100).toStringAsFixed(1) : '0.0');
        buffer.writeln('• ${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value} (${percentage}%)');
      });
      buffer.writeln();
      
      buffer.writeln('PRIORITY BREAKDOWN');
      buffer.writeln('-' * 18);
      priorityCounts.entries.forEach((entry) {
        final percentage = (_allIncidents.length > 0 ? (entry.value / _allIncidents.length * 100).toStringAsFixed(1) : '0.0');
        buffer.writeln('• ${entry.key.toUpperCase()}: ${entry.value} (${percentage}%)');
      });
      buffer.writeln();
      
      buffer.writeln('INCIDENT TYPE BREAKDOWN');
      buffer.writeln('-' * 23);
      final sortedTypes = typeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedTypes.take(10)) {
        final percentage = (_allIncidents.length > 0 ? (entry.value / _allIncidents.length * 100).toStringAsFixed(1) : '0.0');
        buffer.writeln('• ${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value} (${percentage}%)');
      }
      buffer.writeln();
      
      // Financial Impact
      final totalFinancialLoss = _allIncidents
          .map((i) => i.financialLoss ?? 0)
          .fold(0.0, (sum, loss) => sum + loss);
      
      if (totalFinancialLoss > 0) {
        buffer.writeln('FINANCIAL IMPACT');
        buffer.writeln('-' * 16);
        buffer.writeln('• Total Financial Loss: \$${totalFinancialLoss.toStringAsFixed(2)}');
        buffer.writeln('• Average Loss per Incident: \$${(_allIncidents.length > 0 ? totalFinancialLoss / _allIncidents.length : 0).toStringAsFixed(2)}');
        
        final incidentsWithLoss = _allIncidents.where((i) => (i.financialLoss ?? 0) > 0).length;
        if (incidentsWithLoss > 0) {
          buffer.writeln('• Incidents with Financial Loss: $incidentsWithLoss');
          buffer.writeln('• Average Loss (affected incidents): \$${(totalFinancialLoss / incidentsWithLoss).toStringAsFixed(2)}');
        }
        buffer.writeln();
      }
      
      // Recent High Priority Incidents
      final highPriorityIncidents = _allIncidents
          .where((i) => i.priorityLevel.toLowerCase() == 'high')
          .take(10)
          .toList();
      
      if (highPriorityIncidents.isNotEmpty) {
        buffer.writeln('HIGH PRIORITY INCIDENTS (Recent)');
        buffer.writeln('-' * 33);
        for (final incident in highPriorityIncidents) {
          buffer.writeln('• ${incident.caseNumber}: ${incident.title}');
          buffer.writeln('  Status: ${incident.status} | Created: ${DateFormat('MMM dd, yyyy').format(incident.createdAt)}');
          if ((incident.financialLoss ?? 0) > 0) {
            buffer.writeln('  Financial Impact: \$${incident.financialLoss!.toStringAsFixed(2)}');
          }
          buffer.writeln();
        }
      }
      
      // Key Recommendations
      buffer.writeln('KEY RECOMMENDATIONS');
      buffer.writeln('-' * 20);
      
      final pendingCount = statusCounts['Submitted'] ?? 0;
      final inProgressCount = (statusCounts['under_review'] ?? 0) + (statusCounts['in_progress'] ?? 0) + (statusCounts['investigating'] ?? 0);
      final highPriorityCount = priorityCounts['high'] ?? 0;
      
      if (pendingCount > 0) {
        buffer.writeln('• PRIORITY: $pendingCount incidents pending review - requires immediate attention');
      }
      
      if (inProgressCount > pendingCount * 2) {
        buffer.writeln('• WORKFLOW: High number of in-progress cases - consider resource allocation review');
      }
      
      if (highPriorityCount > _allIncidents.length * 0.3) {
        buffer.writeln('• ALERT: High percentage of high-priority incidents - investigate systemic issues');
      }
      
      if (totalFinancialLoss > 10000) {
        buffer.writeln('• FINANCIAL: Significant financial losses detected - enhance prevention measures');
      }
      
      buffer.writeln('• Regular case review and status updates recommended');
      buffer.writeln('• Consider implementing preventive measures for common incident types');
      buffer.writeln();
      
      buffer.writeln('End of Report');
      buffer.writeln('Generated by Rethicsec Incident Management System');
      
      await _saveAndShareFile(buffer.toString(), 'incident_reports_summary.txt', 'text/plain');
      
    } catch (e) {
      _showErrorSnackBar('Failed to generate summary report: $e');
    }
  }

  Future<void> _downloadFilteredResults() async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('RETHICSEC FILTERED INCIDENT REPORTS');
      buffer.writeln('=' * 50);
      buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('Total Results: ${_filteredIncidents.length}');
      buffer.writeln('Filters Applied:');
      buffer.writeln('• Status: ${_selectedStatus == 'all' ? 'All' : _selectedStatus}');
      buffer.writeln('• Priority: ${_selectedPriority == 'all' ? 'All' : _selectedPriority}');
      if (_searchQuery.isNotEmpty) {
        buffer.writeln('• Search Query: "$_searchQuery"');
      }
      buffer.writeln();
      
      // List all filtered incidents
      buffer.writeln('INCIDENT DETAILS');
      buffer.writeln('-' * 16);
      
      for (int i = 0; i < _filteredIncidents.length; i++) {
        final incident = _filteredIncidents[i];
        
        buffer.writeln('${i + 1}. ${incident.caseNumber} - ${incident.title}');
        buffer.writeln('   Status: ${incident.status} | Priority: ${incident.priorityLevel.toUpperCase()}');
        buffer.writeln('   Type: ${incident.incidentType.replaceAll('_', ' ')}');
        buffer.writeln('   Reporter: ${incident.reporterName ?? 'Anonymous'}');
        buffer.writeln('   Created: ${DateFormat('MMM dd, yyyy HH:mm').format(incident.createdAt)}');
        
        if ((incident.financialLoss ?? 0) > 0) {
          buffer.writeln('   Financial Loss: \$${incident.financialLoss!.toStringAsFixed(2)}');
        }
        
        buffer.writeln('   Description: ${incident.description}');
        
        if (incident.evidenceFiles.isNotEmpty) {
          buffer.writeln('   Evidence Files: ${incident.evidenceFiles.length} file(s)');
        }
        
        buffer.writeln();
      }
      
      buffer.writeln('End of Filtered Results');
      buffer.writeln('Generated by Rethicsec Incident Management System');
      
      await _saveAndShareFile(buffer.toString(), 'filtered_incident_reports.txt', 'text/plain');
      
    } catch (e) {
      _showErrorSnackBar('Failed to generate filtered report: $e');
    }
  }

  Future<void> _saveAndShareFile(String content, String filename, String mimeType) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Rethicsec Incident Reports',
        text: 'Incident reports generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );
      
      _showSuccessSnackBar('Report downloaded and ready to share');
      
    } catch (e) {
      _showErrorSnackBar('Failed to save report: $e');
    }
  }

  Future<void> _downloadAsPDF() async {
    try {
      _showLoadingDialog('Generating beautiful PDF report...');

      final pdf = pw.Document();
      await _generateIncidentReportsPDF(pdf);

      // Save to Downloads folder
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'rethicsec_incident_reports_$timestamp.pdf';
      
      // Get external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Unable to access external storage');
      }
      
      // Create Downloads folder in external storage
      final downloadsFolder = Directory('${directory.parent!.parent!.parent!.parent!.path}/Download');
      if (!await downloadsFolder.exists()) {
        await downloadsFolder.create(recursive: true);
      }
      
      final file = File('${downloadsFolder.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context); // Close loading

      _showSuccessDialog(fileName, 'PDF', 'Incident Reports PDF');

    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('PDF generation failed: ${e.toString()}');
    }
  }

  Future<void> _generateIncidentReportsPDF(pw.Document pdf) async {
    // Beautiful colors for the PDF
    final primaryColor = PdfColor.fromHex('#C62828'); // Red
    final secondaryColor = PdfColor.fromHex('#1976D2'); // Blue
    final accentColor = PdfColor.fromHex('#F57C00'); // Orange
    final successColor = PdfColor.fromHex('#2E7D32'); // Green
    final warningColor = PdfColor.fromHex('#F9A825'); // Yellow
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RETHICSEC ADMIN',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Incident Reports Summary',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
                _buildFallbackLogo(),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Summary Statistics
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildPDFStatCard('Total Incidents', _allIncidents.length.toString(), primaryColor),
              ),
              pw.SizedBox(width: 15),
              pw.Expanded(
                child: _buildPDFStatCard('Pending Review', _allIncidents.where((i) => i.status == 'Submitted').length.toString(), warningColor),
              ),
            ],
          ),

          pw.SizedBox(height: 15),

          pw.Row(
            children: [
              pw.Expanded(
                child: _buildPDFStatCard('In Progress', _allIncidents.where((i) => ['under_review', 'in_progress', 'investigating'].contains(i.status)).length.toString(), secondaryColor),
              ),
              pw.SizedBox(width: 15),
              pw.Expanded(
                child: _buildPDFStatCard('Resolved', _allIncidents.where((i) => i.status == 'resolved').length.toString(), successColor),
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          // Financial Impact Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Financial Impact Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      _buildFinancialRow('Total Reported Loss', _calculateTotalLoss(), PdfColor.fromHex('#424242')),
                      _buildFinancialRow('Average Loss per Case', _calculateAverageLoss(), PdfColor.fromHex('#424242')),
                      _buildFinancialRow('Cases with Financial Impact', _getFinancialCasesCount().toString(), PdfColor.fromHex('#424242')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Incidents Table
          pw.Text(
            'Recent Incident Reports',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          
          pw.SizedBox(height: 15),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
                children: [
                  _buildTableHeader('Case #'),
                  _buildTableHeader('Type'),
                  _buildTableHeader('Status'),
                  _buildTableHeader('Priority'),
                  _buildTableHeader('Financial Loss'),
                  _buildTableHeader('Date'),
                ].map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: cell,
                )).toList(),
              ),
              // Data rows (show first 20 incidents)
              ..._allIncidents.take(20).map((incident) => pw.TableRow(
                children: [
                  _buildTableCell(incident.caseNumber),
                  _buildTableCell(incident.incidentType),
                  _buildTableCell(_getStatusDisplay(incident.status)),
                  _buildTableCell(_getPriorityDisplay(incident.priority)),
                  _buildTableCell(incident.financialLoss != null ? '\$${incident.financialLoss!.toStringAsFixed(2)}' : 'N/A'),
                  _buildTableCell(DateFormat('MMM dd, yyyy').format(incident.createdAt)),
                ].map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: cell,
                )).toList(),
              )),
            ],
          ),

          pw.SizedBox(height: 25),

          // Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5F5F5'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Report generated on ${DateFormat('MMMM dd, yyyy at HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#666666')),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Rethicsec Admin Dashboard • Confidential Document',
                  style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#888888')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFStatCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFinancialRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: color)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColor.fromHex('#333333'),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        color: PdfColor.fromHex('#555555'),
      ),
    );
  }

  String _calculateTotalLoss() {
    double total = 0;
    for (final incident in _allIncidents) {
      if (incident.financialLoss != null) {
        total += incident.financialLoss!;
      }
    }
    return '\$${total.toStringAsFixed(2)}';
  }

  String _calculateAverageLoss() {
    double total = 0;
    int count = 0;
    for (final incident in _allIncidents) {
      if (incident.financialLoss != null && incident.financialLoss! > 0) {
        total += incident.financialLoss!;
        count++;
      }
    }
    if (count == 0) return '\$0.00';
    return '\$${(total / count).toStringAsFixed(2)}';
  }

  int _getFinancialCasesCount() {
    return _allIncidents.where((i) => i.financialLoss != null && i.financialLoss! > 0).length;
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'under_review': return 'Under Review';
      case 'in_progress': return 'In Progress';
      case 'investigating': return 'Investigating';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  String _getPriorityDisplay(String? priority) {
    if (priority == null) return 'Normal';
    return priority.toUpperCase();
  }

  void _showSuccessDialog(String fileName, String format, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            SizedBox(width: 8),
            Expanded(child: Text('$format Generated')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title has been successfully generated:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: AppTheme.secondaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Downloads/$fileName',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Report includes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Summary statistics & financial impact'),
            Text('• Detailed incident reports table'),
            Text('• Professional formatting with colors'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$format report saved to Downloads folder'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFallbackLogo() {
    return pw.Container(
      width: 60,
      height: 60,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(30),
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0'), width: 2),
      ),
      child: pw.Center(
        child: pw.Text(
          'RETHICSEC',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#C62828'),
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  Future<pw.Widget> _buildPDFLogo() async {
    try {
      // Load the Rethicsec logo from assets
      final ByteData logoData = await rootBundle.load('assets/images/Rethicsec.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

      return pw.Container(
        width: 60,
        height: 60,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(30),
          border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0'), width: 2),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Image(logoImage, fit: pw.BoxFit.cover),
        ),
      );
    } catch (e) {
      return _buildFallbackLogo();
    }
  }
}
