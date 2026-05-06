import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../shared/models/incident_model.dart';

class CaseTrackingPage extends StatefulWidget {
  const CaseTrackingPage({super.key});

  @override
  State<CaseTrackingPage> createState() => _CaseTrackingPageState();
}

class _CaseTrackingPageState extends State<CaseTrackingPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  List<IncidentModel> _allCases = [];
  bool _isLoading = true;
  String? _userId;

  final List<String> _filters = ['All', 'Submitted', 'Under Review', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _loadCases();
    } else {
      // Redirect to login if user not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> _loadCases() async {
    if (_userId == null) return;
    
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      // Load real cases from Firestore for current user
      final cases = await IncidentService.getUserIncidents(_userId!);
      
      if (mounted) {
        setState(() {
          _allCases = cases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cases: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Fallback to mock data if Firestore fails (for demo purposes)
      _loadMockData();
    }
  }

  void _loadMockData() {
    // Fallback mock data for demonstration
    final mockCases = [
      IncidentModel(
        id: 'mock_001',
        caseNumber: 'RET20240122001',
        userId: _userId ?? 'demo_user',
        incidentType: 'Mobile Money Scam',
        title: 'Mobile Money Scam',
        description: 'Fraudulent transaction on MTN Mobile Money',
        dateOccurred: DateTime.parse('2024-01-22'),
        locationOccurred: 'Lagos, Nigeria',
        financialLoss: 25000,
        priorityLevel: 'High',
        status: 'Under Review',
        contactPreference: 'email',
        contactDetails: 'user@example.com',
        createdAt: DateTime.parse('2024-01-22'),
        updatedAt: DateTime.parse('2024-01-22'),
        assignedOfficer: 'Detective Sarah Okafor',
        evidenceFiles: const [],
      ),
      IncidentModel(
        id: 'mock_002',
        caseNumber: 'RET20240121003',
        userId: _userId ?? 'demo_user',
        incidentType: 'Fake Loan App',
        title: 'Fake Loan App',
        description: 'Illegal loan app stealing personal data',
        dateOccurred: DateTime.parse('2024-01-21'),
        locationOccurred: 'Abuja, Nigeria',
        financialLoss: 50000,
        priorityLevel: 'Critical',
        status: 'In Progress',
        contactPreference: 'email',
        contactDetails: 'user@example.com',
        createdAt: DateTime.parse('2024-01-21'),
        updatedAt: DateTime.parse('2024-01-21'),
        assignedOfficer: 'Detective John Adebayo',
        evidenceFiles: const [],
      ),
    ];
    
    if (mounted) {
      setState(() {
        _allCases = mockCases;
      });
    }
  }

  List<IncidentModel> get _filteredCases {
    var filtered = _allCases.where((case_) {
      final matchesFilter = _selectedFilter == 'All' || case_.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          case_.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (case_.caseNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                
                // Search and Filter Section
                _buildSearchAndFilter(),
                
                // Cases List
                Expanded(
                  child: _buildCasesList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/incident-report'),
        backgroundColor: AppTheme.secondaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
          Icon(Icons.track_changes, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Cases',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track your cybercrime reports',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Stats badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_allCases.length} Cases',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by case ID or title...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        }
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (value) {
              if (mounted) {
                setState(() => _searchQuery = value);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    if (mounted) {
                      setState(() => _selectedFilter = filter);
                    }
                  },
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildCasesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your cases...'),
          ],
        ),
      );
    }
    
    final filteredCases = _filteredCases;
    
    if (filteredCases.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadCases,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: filteredCases.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final case_ = filteredCases[index];
          return _buildCaseCard(case_, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No cases found' : 'No cases yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
              ? 'Try adjusting your search or filters'
              : 'Create your first case report to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/incident-report'),
              icon: const Icon(Icons.add),
              label: const Text('Report Incident'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  double getProgress(String status) {
    switch (status.toLowerCase()) {
      case 'submitted': return 0.15;
      case 'under review': return 0.4;
      case 'in progress': 
      case 'investigating': return 0.75;
      case 'resolved':
      case 'closed': return 1.0;
      default: return 0.0;
    }
  }

  Widget _buildCaseCard(IncidentModel case_, int index) {
    final statusColor = _getStatusColor(case_.status);
    final priorityColor = _getPriorityColor(case_.priority);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCaseDetails(case_),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Case ID badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        case_.caseNumber ?? case_.id,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        case_.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title and description
                Text(
                  case_.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  case_.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Progress bar with enhanced styling
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: LinearProgressIndicator(
                          value: getProgress(case_.status),
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          '${(getProgress(case_.status) * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        if (case_.status.toLowerCase() == 'resolved' || case_.status.toLowerCase() == 'closed') ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            color: statusColor,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Bottom row
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${case_.createdAt.day}/${case_.createdAt.month}/${case_.createdAt.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        case_.assignedOfficer ?? 'Pending Assignment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        case_.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.3, end: 0);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'under review':
        return Colors.orange;
      case 'in progress':
      case 'investigating':
        return AppTheme.primaryColor;
      case 'resolved':
        return const Color(0xFF4CAF50); // Success green
      case 'closed':
        return const Color(0xFF2E7D32); // Dark green
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  void _showCaseDetails(IncidentModel case_) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  case_.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Case ID: ${case_.caseNumber ?? case_.id}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(case_.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              case_.status,
                              style: TextStyle(
                                color: _getStatusColor(case_.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Details
                      _buildDetailRow('Description', case_.description),
                      _buildDetailRow('Date Reported', '${case_.createdAt.day}/${case_.createdAt.month}/${case_.createdAt.year}'),
                      _buildDetailRow('Amount Involved', case_.amountLost != null ? '₦${case_.amountLost!.toStringAsFixed(0)}' : 'Not specified'),
                      _buildDetailRow('Priority', case_.priority),
                      _buildDetailRow('Assigned Officer', case_.assignedOfficer ?? 'Pending Assignment'),
                      
                      const SizedBox(height: 20),
                      
                      // Progress
                      Text(
                        'Investigation Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: LinearProgressIndicator(
                          value: getProgress(case_.status),
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(case_.status)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${(getProgress(case_.status) * 100).toInt()}% Complete',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (case_.status.toLowerCase() == 'resolved' || case_.status.toLowerCase() == 'closed') ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              color: _getStatusColor(case_.status),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Case Resolved',
                              style: TextStyle(
                                fontSize: 14,
                                color: _getStatusColor(case_.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Case details downloaded')),
                                );
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Officer contacted')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.message),
                              label: const Text('Contact Officer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}