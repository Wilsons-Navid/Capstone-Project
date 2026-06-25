import 'package:flutter/material.dart';
import '../../../../shared/widgets/labeled_dropdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';

class CaseManagementPage extends StatefulWidget {
  const CaseManagementPage({super.key});

  @override
  State<CaseManagementPage> createState() => _CaseManagementPageState();
}

class _CaseManagementPageState extends State<CaseManagementPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<CaseModel> _allCases = [];
  List<CaseModel> _filteredCases = [];
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late TabController _tabController;
  Map<String, int> _caseStats = {};

  final List<String> _caseStatuses = ['all', 'pending_review', 'assigned', 'in_progress', 'investigating', 'resolved', 'closed'];
  final List<String> _priorityOptions = ['all', 'high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCases();
    _loadCaseStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      // Load from incidents collection and convert to case format
      final incidentsSnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .get();

      final cases = incidentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return CaseModel(
          id: doc.id,
          caseNumber: data['case_number'] ?? 'N/A',
          userId: data['user_id'] ?? '',
          status: data['status'] ?? 'Submitted',
          priority: data['priority_level'] ?? 'medium',
          caseType: data['incident_type'] ?? 'unknown',
          title: data['title'] ?? 'Untitled',
          description: data['description'] ?? '',
          reporterEmail: data['contact_details'],
          reporterName: data['reporter_name'],
          reporterPhone: data['reporter_phone'],
          reporterCountry: data['reporter_country'],
          locationOccurred: data['location_occurred'],
          financialLoss: data['financial_loss']?.toDouble(),
          createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
          lastUpdated: data['updated_at'] ?? DateTime.now().toIso8601String(),
          timeline: [
            {
              'status': data['status'] ?? 'Submitted',
              'timestamp': data['created_at'] ?? DateTime.now().toIso8601String(),
              'description': 'Case created from incident report',
              'actor': 'system',
            }
          ],
          investigationStatus: 'pending_review',
          assignedInvestigator: data['assigned_officer'],
          assignedToUid: data['assignedTo'],
          evidenceCount: (data['evidence_files'] as List?)?.length ?? 0,
        );
      }).toList();

      setState(() {
        _allCases = cases;
        _filteredCases = cases;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load cases: $e');
    }
  }

  Future<void> _loadCaseStatistics() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('incidents').get();
      final cases = snapshot.docs.map((doc) => doc.data()).toList();
      
      final stats = <String, int>{
        'total': cases.length,
        'pending_review': 0,
        'assigned': 0,
        'in_progress': 0,
        'resolved': 0,
        'high_priority': 0,
        'medium_priority': 0,
        'low_priority': 0,
        'unassigned': 0,
      };
      
      for (final caseData in cases) {
        final status = caseData['status'] as String?;
        final priority = caseData['priority_level'] as String?;
        final investigator = caseData['assigned_officer'];
        
        if (status != null && stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
        
        if (priority != null && stats.containsKey('${priority}_priority')) {
          stats['${priority}_priority'] = stats['${priority}_priority']! + 1;
        }
        
        if (investigator == null) {
          stats['unassigned'] = stats['unassigned']! + 1;
        }
      }
      
      setState(() => _caseStats = stats);
    } catch (e) {
      print('Failed to load case statistics: $e');
    }
  }

  void _applyFilters() {
    List<CaseModel> filtered = List.from(_allCases);

    if (_selectedStatus != 'all') {
      filtered = filtered.where((caseModel) => 
        caseModel.status.toLowerCase() == _selectedStatus).toList();
    }

    if (_selectedPriority != 'all') {
      filtered = filtered.where((caseModel) => 
        caseModel.priority.toLowerCase() == _selectedPriority).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((caseModel) =>
        caseModel.title.toLowerCase().contains(query) ||
        caseModel.caseNumber.toLowerCase().contains(query) ||
        caseModel.caseType.toLowerCase().contains(query) ||
        (caseModel.reporterName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    setState(() => _filteredCases = filtered);
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
                  title: 'Case Management',
                  subtitle: 'Assign and track investigation cases',
                  icon: Icons.folder_open,
                  gradient: LinearGradient(
                    colors: [AppTheme.victoriaBlue, AppTheme.victoriaBlueDark],
                  ),
                  action: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),

                // Statistics Cards
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard('Total', _caseStats['total']?.toString() ?? '0', Icons.folder, AppTheme.victoriaBlue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Pending', _caseStats['pending_review']?.toString() ?? '0', Icons.pending, AppTheme.secondaryColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Active', _caseStats['in_progress']?.toString() ?? '0', Icons.work, AppTheme.baobabBrown)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Unassigned', _caseStats['unassigned']?.toString() ?? '0', Icons.person_off, AppTheme.clayRed)),
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
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'All Cases'),
                    Tab(text: 'Pending Review'),
                    Tab(text: 'Active'),
                    Tab(text: 'Resolved'),
                  ],
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCasesList(_filteredCases),
                      _buildCasesList(_filteredCases.where((c) => c.status == 'pending_review').toList()),
                      _buildCasesList(_filteredCases.where((c) => c.status == 'in_progress' || c.status == 'investigating').toList()),
                      _buildCasesList(_filteredCases.where((c) => c.status == 'resolved' || c.status == 'closed').toList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadCases,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        backgroundColor: AppTheme.victoriaBlue,
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
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search cases, numbers, or reporters...',
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
          
          Row(
            children: [
              Expanded(
                child: LabeledDropdown<String>(
                  label: 'Status',                  value: _selectedStatus,
                                    items: _caseStatuses.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status == 'all' ? 'All Status' : status.replaceAll('_', ' ').toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Widget _buildCasesList(List<CaseModel> cases) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No cases found',
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
      itemCount: cases.length,
      itemBuilder: (context, index) => _buildCaseCard(cases[index]),
    );
  }

  Widget _buildCaseCard(CaseModel caseModel) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCaseStatusColor(caseModel.status).withOpacity(0.1),
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
                        caseModel.caseNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        caseModel.title,
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
                _buildCaseStatusChip(caseModel.status),
                const SizedBox(width: 8),
                _buildPriorityChip(caseModel.priority),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Case details
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        caseModel.reporterName ?? 'Anonymous Reporter',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(DateTime.parse(caseModel.createdAt)),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(child: Text(caseModel.caseType.replaceAll('_', ' ').toUpperCase())),
                    if (caseModel.financialLoss != null) ...[
                      Icon(Icons.attach_money, size: 16, color: AppTheme.clayRed),
                      Text(
                        '\$${caseModel.financialLoss!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.clayRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Assigned investigator
                Row(
                  children: [
                    Icon(Icons.person_pin, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        caseModel.assignedInvestigator ?? 'Unassigned',
                        style: TextStyle(
                          color: caseModel.assignedInvestigator != null ? AppTheme.successColor : AppTheme.clayRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  caseModel.description,
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
                        onPressed: () => _viewCaseDetails(caseModel),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.victoriaBlue,
                          side: const BorderSide(color: AppTheme.victoriaBlue),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _assignInvestigator(caseModel),
                        icon: const Icon(Icons.assignment_ind, size: 16),
                        label: const Text('Assign'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.victoriaBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _updateCaseStatus(caseModel),
                      icon: const Icon(Icons.edit, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Colors.grey[700],
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

  Widget _buildCaseStatusChip(String status) {
    final color = _getCaseStatusColor(status);
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

  Color _getCaseStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_review':
        return AppTheme.victoriaBlue;
      case 'assigned':
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

  void _viewCaseDetails(CaseModel caseModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCaseDetailsSheet(caseModel),
    );
  }

  Widget _buildCaseDetailsSheet(CaseModel caseModel) {
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
                        'Case Details',
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
                _buildDetailRow('Case Number', caseModel.caseNumber),
                _buildDetailRow('Status', caseModel.status),
                _buildDetailRow('Priority', caseModel.priority),
                _buildDetailRow('Type', caseModel.caseType.replaceAll('_', ' ')),
                _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(caseModel.createdAt))),
                _buildDetailRow('Assigned To', caseModel.assignedInvestigator ?? 'Unassigned'),
                
                if (caseModel.financialLoss != null)
                  _buildDetailRow('Financial Loss', '\$${caseModel.financialLoss!.toStringAsFixed(2)}'),
                
                const Divider(height: 32),

                // Reporter info
                Text(
                  'Reporter Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildDetailRow('Name', caseModel.reporterName ?? 'Anonymous'),
                _buildDetailRow('Email', caseModel.reporterEmail ?? 'Not provided'),
                _buildDetailRow('Phone', caseModel.reporterPhone ?? 'Not provided'),
                _buildDetailRow('Country', caseModel.reporterCountry ?? 'Not specified'),

                const Divider(height: 32),

                // Case details
                Text(
                  'Case Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildDetailRow('Title', caseModel.title),
                _buildDetailRow('Description', caseModel.description, isLongText: true),
                
                if (caseModel.locationOccurred != null)
                  _buildDetailRow('Location', caseModel.locationOccurred!),

                if (caseModel.timeline.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text(
                    'Case Timeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...caseModel.timeline.map(_buildTimelineItem),
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

  Widget _buildTimelineItem(Map<String, dynamic> timelineItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.victoriaBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timelineItem['status'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, HH:mm').format(DateTime.parse(timelineItem['timestamp'])),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            timelineItem['description'] ?? '',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Future<void> _assignInvestigator(CaseModel caseModel) async {
    // Load assignable staff (moderators + admins) from the users collection.
    // A single whereIn on `role` avoids needing a composite index.
    List<Map<String, dynamic>> staff;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['moderator', 'admin'])
          .get();
      staff = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      _showErrorSnackBar('Failed to load staff: $e');
      return;
    }

    if (!mounted) return;

    if (staff.isEmpty) {
      _showErrorSnackBar('No moderators or admins available to assign');
      return;
    }

    String uidOf(Map<String, dynamic> u) => (u['uid'] ?? u['id'] ?? '') as String;
    String nameOf(Map<String, dynamic> u) {
      final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
      return name.isEmpty ? (u['email'] as String? ?? uidOf(u)) : name;
    }

    // Pre-select the current assignee only if they are still in the staff list.
    String? selectedUid =
        staff.any((u) => uidOf(u) == caseModel.assignedToUid) ? caseModel.assignedToUid : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Assign Investigator - ${caseModel.caseNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedUid,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assign to (moderator or admin)',
                  border: OutlineInputBorder(),
                ),
                items: staff.map((u) {
                  final role = (u['role'] as String? ?? 'user');
                  return DropdownMenuItem(
                    value: uidOf(u),
                    child: Text('${nameOf(u)} ($role)',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => setLocalState(() => selectedUid = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUid == null
                  ? null
                  : () async {
                      final chosen = staff.firstWhere((u) => uidOf(u) == selectedUid);
                      Navigator.pop(context);
                      await _updateCaseAssignment(
                          caseModel.id, selectedUid!, nameOf(chosen));
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCaseStatus(CaseModel caseModel) {
    String selectedStatus = caseModel.status;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Update Status - ${caseModel.caseNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabeledDropdown<String>(
                  label: 'Status',                  value: selectedStatus,
                                    items: _caseStatuses.where((s) => s != 'all').map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.replaceAll('_', ' ').toUpperCase()),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => selectedStatus = value ?? caseModel.status);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
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
                  await _updateCaseStatusInDatabase(
                    caseModel.id,
                    selectedStatus,
                    noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateCaseAssignment(
      String caseId, String assigneeUid, String assigneeName) async {
    try {
      // Store both the display name (assigned_officer) and the UID (assignedTo).
      // assignedTo is what the Firestore rules use to let the assigned staff
      // member update their own case.
      await FirebaseFirestore.instance.collection('incidents').doc(caseId).update({
        'assigned_officer': assigneeName,
        'assignedTo': assigneeUid,
        'status': 'assigned',
        'updated_at': DateTime.now().toIso8601String(),
      });

      _showSuccessSnackBar('Investigator assigned successfully');
      _loadCases();
      _loadCaseStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to assign investigator: $e');
    }
  }

  Future<void> _updateCaseStatusInDatabase(String caseId, String newStatus, String? notes) async {
    try {
      await FirebaseFirestore.instance.collection('incidents').doc(caseId).update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      _showSuccessSnackBar('Case status updated successfully');
      _loadCases();
      _loadCaseStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to update case status: $e');
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
}

class CaseModel {
  final String id;
  final String caseNumber;
  final String userId;
  final String status;
  final String priority;
  final String caseType;
  final String title;
  final String description;
  final String? reporterEmail;
  final String? reporterName;
  final String? reporterPhone;
  final String? reporterCountry;
  final String? locationOccurred;
  final double? financialLoss;
  final String createdAt;
  final String lastUpdated;
  final List<Map<String, dynamic>> timeline;
  final String investigationStatus;
  final String? assignedInvestigator;
  final String? assignedToUid;
  final int evidenceCount;

  CaseModel({
    required this.id,
    required this.caseNumber,
    required this.userId,
    required this.status,
    required this.priority,
    required this.caseType,
    required this.title,
    required this.description,
    this.reporterEmail,
    this.reporterName,
    this.reporterPhone,
    this.reporterCountry,
    this.locationOccurred,
    this.financialLoss,
    required this.createdAt,
    required this.lastUpdated,
    required this.timeline,
    required this.investigationStatus,
    this.assignedInvestigator,
    this.assignedToUid,
    required this.evidenceCount,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      caseNumber: json['case_number'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      caseType: json['case_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      reporterEmail: json['reporter_email'] as String?,
      reporterName: json['reporter_name'] as String?,
      reporterPhone: json['reporter_phone'] as String?,
      reporterCountry: json['reporter_country'] as String?,
      locationOccurred: json['location_occurred'] as String?,
      financialLoss: (json['financial_loss'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String,
      lastUpdated: json['last_updated'] as String,
      timeline: List<Map<String, dynamic>>.from(json['timeline'] ?? []),
      investigationStatus: json['investigation_status'] as String,
      assignedInvestigator: json['assigned_investigator'] as String?,
      assignedToUid: json['assignedTo'] as String?,
      evidenceCount: json['evidence_count'] as int,
    );
  }
}
