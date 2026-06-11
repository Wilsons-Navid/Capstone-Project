import 'package:flutter/material.dart';
import '../../../../shared/widgets/labeled_dropdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';

class ContentModerationPage extends StatefulWidget {
  const ContentModerationPage({super.key});

  @override
  State<ContentModerationPage> createState() => _ContentModerationPageState();
}

class _ContentModerationPageState extends State<ContentModerationPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<ContentItem> _allContent = [];
  List<ContentItem> _filteredContent = [];
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late TabController _tabController;
  Map<String, int> _moderationStats = {};

  final List<String> _contentStatuses = ['all', 'pending', 'approved', 'rejected', 'flagged', 'under_review'];
  final List<String> _contentTypes = ['all', 'incident_report', 'user_comment', 'evidence_file', 'profile_content'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContent();
    _loadModerationStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      // Load content from multiple sources
      await Future.wait([
        _loadIncidentReports(),
        _loadUserComments(),
        _loadEvidenceFiles(),
        _loadUserProfiles(),
      ]);

      // Sort by creation date
      _allContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _filteredContent = List.from(_allContent);
      
      setState(() => _isLoading = false);
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load content: $e');
    }
  }

  Future<void> _loadIncidentReports() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        _allContent.add(ContentItem(
          id: doc.id,
          type: 'incident_report',
          title: data['title'] ?? 'Untitled Report',
          content: data['description'] ?? '',
          authorId: data['user_id'] ?? '',
          authorName: data['reporter_name'] ?? 'Anonymous',
          createdAt: DateTime.parse(data['created_at']),
          status: _getContentStatus(data),
          flaggedBy: [],
          flaggedCount: 0,
          metadata: {
            'case_number': data['case_number'],
            'incident_type': data['incident_type'],
            'priority': data['priority_level'],
          },
        ));
      }
    } catch (e) {
      print('Failed to load incident reports: $e');
    }
  }

  Future<void> _loadUserComments() async {
    try {
      // Check if there's a comments collection
      final snapshot = await FirebaseFirestore.instance
          .collection('comments')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        _allContent.add(ContentItem(
          id: doc.id,
          type: 'user_comment',
          title: 'User Comment',
          content: data['content'] ?? '',
          authorId: data['user_id'] ?? '',
          authorName: data['author_name'] ?? 'Anonymous',
          createdAt: DateTime.parse(data['created_at']),
          status: data['moderation_status'] ?? 'pending',
          flaggedBy: List<String>.from(data['flagged_by'] ?? []),
          flaggedCount: (data['flagged_by'] as List?)?.length ?? 0,
          metadata: {
            'parent_type': data['parent_type'],
            'parent_id': data['parent_id'],
          },
        ));
      }
    } catch (e) {
      print('Failed to load comments (collection may not exist): $e');
    }
  }

  Future<void> _loadEvidenceFiles() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .where('evidence_files', isNotEqualTo: [])
          .limit(30)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final evidenceFiles = data['evidence_files'] as List? ?? [];
        
        for (final evidence in evidenceFiles) {
          if (evidence is Map<String, dynamic>) {
            _allContent.add(ContentItem(
              id: '${doc.id}_${evidence['id']}',
              type: 'evidence_file',
              title: 'Evidence: ${evidence['file_name']}',
              content: evidence['description'] ?? 'File attachment',
              authorId: data['user_id'] ?? '',
              authorName: data['reporter_name'] ?? 'Anonymous',
              createdAt: DateTime.parse(evidence['uploaded_at']),
              status: 'pending',
              flaggedBy: [],
              flaggedCount: 0,
              metadata: {
                'file_name': evidence['file_name'],
                'file_type': evidence['file_type'],
                'file_size': evidence['file_size'],
                'incident_id': doc.id,
              },
            ));
          }
        }
      }
    } catch (e) {
      print('Failed to load evidence files: $e');
    }
  }

  Future<void> _loadUserProfiles() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('profile_content_flagged', isEqualTo: true)
          .limit(20)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        _allContent.add(ContentItem(
          id: doc.id,
          type: 'profile_content',
          title: 'Profile: ${data['firstName']} ${data['lastName']}',
          content: data['bio'] ?? data['profile_description'] ?? 'Profile content',
          authorId: doc.id,
          authorName: '${data['firstName']} ${data['lastName']}',
          createdAt: DateTime.parse(data['updatedAt'] ?? data['createdAt']),
          status: data['profile_moderation_status'] ?? 'flagged',
          flaggedBy: List<String>.from(data['profile_flagged_by'] ?? []),
          flaggedCount: (data['profile_flagged_by'] as List?)?.length ?? 0,
          metadata: {
            'email': data['email'],
            'role': data['role'],
          },
        ));
      }
    } catch (e) {
      print('Failed to load flagged profiles: $e');
    }
  }

  String _getContentStatus(Map<String, dynamic> data) {
    // Determine content status based on various factors
    if (data['flagged'] == true) return 'flagged';
    if (data['moderation_status'] != null) return data['moderation_status'];
    if (data['priority_level'] == 'high') return 'under_review';
    return 'pending';
  }

  Future<void> _loadModerationStats() async {
    try {
      // Calculate stats based on loaded content
      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'flagged': 0,
        'under_review': 0,
        'incident_reports': 0,
        'user_comments': 0,
        'evidence_files': 0,
        'profile_content': 0,
      };

      for (final item in _allContent) {
        stats['total'] = stats['total']! + 1;
        
        if (stats.containsKey(item.status)) {
          stats[item.status] = stats[item.status]! + 1;
        }
        
        if (stats.containsKey(item.type)) {
          stats[item.type] = stats[item.type]! + 1;
        }
      }

      setState(() => _moderationStats = stats);
    } catch (e) {
      print('Failed to load moderation statistics: $e');
    }
  }

  void _applyFilters() {
    List<ContentItem> filtered = List.from(_allContent);

    if (_selectedStatus != 'all') {
      filtered = filtered.where((item) => item.status == _selectedStatus).toList();
    }

    if (_selectedType != 'all') {
      filtered = filtered.where((item) => item.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) =>
        item.title.toLowerCase().contains(query) ||
        item.content.toLowerCase().contains(query) ||
        item.authorName.toLowerCase().contains(query)
      ).toList();
    }

    setState(() => _filteredContent = filtered);
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
                  title: 'Content Moderation',
                  subtitle: 'Review and moderate user-generated content',
                  icon: Icons.verified_user,
                  gradient: LinearGradient(
                    colors: [AppTheme.baobabBrown, AppTheme.kilimanjaro],
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
                      Expanded(child: _buildStatCard('Total', _moderationStats['total']?.toString() ?? '0', Icons.content_paste, AppTheme.baobabBrown)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Pending', _moderationStats['pending']?.toString() ?? '0', Icons.pending, AppTheme.secondaryColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Flagged', _moderationStats['flagged']?.toString() ?? '0', Icons.flag, AppTheme.clayRed)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Approved', _moderationStats['approved']?.toString() ?? '0', Icons.check_circle, AppTheme.successColor)),
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
                    Tab(text: 'All Content'),
                    Tab(text: 'Pending Review'),
                    Tab(text: 'Flagged'),
                    Tab(text: 'Approved'),
                  ],
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentList(_filteredContent),
                      _buildContentList(_filteredContent.where((c) => c.status == 'pending' || c.status == 'under_review').toList()),
                      _buildContentList(_filteredContent.where((c) => c.status == 'flagged').toList()),
                      _buildContentList(_filteredContent.where((c) => c.status == 'approved').toList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadContent,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        backgroundColor: AppTheme.baobabBrown,
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
              hintText: 'Search content, titles, or authors...',
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
                                    items: _contentStatuses.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == 'all' ? 'All' : status.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
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
                  label: 'Type',                  value: _selectedType,
                                    items: _contentTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type == 'all' ? 'All' : type.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value ?? 'all');
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

  Widget _buildContentList(List<ContentItem> content) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_paste_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No content found',
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
      itemCount: content.length,
      itemBuilder: (context, index) => _buildContentCard(content[index]),
    );
  }

  Widget _buildContentCard(ContentItem item) {
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
              color: _getStatusColor(item.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(_getContentTypeIcon(item.type), size: 24, color: _getStatusColor(item.status)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(item.status),
                if (item.flaggedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.clayRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 12, color: AppTheme.clayRed),
                        const SizedBox(width: 2),
                        Text(
                          item.flaggedCount.toString(),
                          style: const TextStyle(
                            color: AppTheme.clayRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author and date info
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(item.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),

                // Content preview
                Text(
                  item.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewContentDetails(item),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.baobabBrown,
                          side: const BorderSide(color: AppTheme.baobabBrown),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.status == 'pending' || item.status == 'under_review') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveContent(item),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectContent(item),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.clayRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateContentStatus(item),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Update Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.baobabBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
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

  IconData _getContentTypeIcon(String type) {
    switch (type) {
      case 'incident_report':
        return Icons.report;
      case 'user_comment':
        return Icons.comment;
      case 'evidence_file':
        return Icons.attach_file;
      case 'profile_content':
        return Icons.person;
      default:
        return Icons.content_paste;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'under_review':
        return AppTheme.secondaryColor;
      case 'approved':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.clayRed;
      case 'flagged':
        return AppTheme.baobabBrown;
      default:
        return Colors.grey;
    }
  }

  void _viewContentDetails(ContentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildContentDetailsSheet(item),
    );
  }

  Widget _buildContentDetailsSheet(ContentItem item) {
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
                    Icon(_getContentTypeIcon(item.type), color: AppTheme.baobabBrown),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Content Details',
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

                // Content info
                _buildDetailRow('Title', item.title),
                _buildDetailRow('Type', item.type.replaceAll('_', ' ').toUpperCase()),
                _buildDetailRow('Status', item.status.toUpperCase()),
                _buildDetailRow('Author', item.authorName),
                _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(item.createdAt)),
                _buildDetailRow('Flagged Count', item.flaggedCount.toString()),
                
                const Divider(height: 32),

                // Content
                Text(
                  'Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.content),
                ),

                if (item.metadata.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text(
                    'Additional Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...item.metadata.entries.map((entry) => 
                    _buildDetailRow(entry.key.replaceAll('_', ' ').toUpperCase(), entry.value?.toString() ?? 'N/A')
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                if (item.status == 'pending' || item.status == 'under_review')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _approveContent(item);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _rejectContent(item);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.clayRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _approveContent(ContentItem item) async {
    try {
      await _updateContentModerationStatus(item.id, item.type, 'approved');
      _showSuccessSnackBar('Content approved successfully');
      _loadContent();
    } catch (e) {
      _showErrorSnackBar('Failed to approve content: $e');
    }
  }

  void _rejectContent(ContentItem item) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.clayRed),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _updateContentModerationStatus(item.id, item.type, 'rejected', reason: reasonController.text);
        _showSuccessSnackBar('Content rejected successfully');
        _loadContent();
      } catch (e) {
        _showErrorSnackBar('Failed to reject content: $e');
      }
    }
  }

  void _updateContentStatus(ContentItem item) {
    String selectedStatus = item.status;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Content Status'),
            content: LabeledDropdown<String>(
              label: 'New Status',              value: selectedStatus,
                            items: _contentStatuses.where((s) => s != 'all').map((status) => DropdownMenuItem(
                value: status,
                child: Text(status.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (value) {
                setState(() => selectedStatus = value ?? item.status);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _updateContentModerationStatus(item.id, item.type, selectedStatus);
                    Navigator.pop(context);
                    _showSuccessSnackBar('Content status updated successfully');
                    _loadContent();
                  } catch (e) {
                    _showErrorSnackBar('Failed to update status: $e');
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateContentModerationStatus(String contentId, String contentType, String newStatus, {String? reason}) async {
    try {
      final updateData = {
        'moderation_status': newStatus,
        'moderated_at': DateTime.now().toIso8601String(),
        'moderated_by': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      };

      if (reason != null) {
        updateData['moderation_reason'] = reason;
      }

      // Update based on content type
      switch (contentType) {
        case 'incident_report':
          await FirebaseFirestore.instance
              .collection('incidents')
              .doc(contentId)
              .update(updateData);
          break;
        case 'user_comment':
          await FirebaseFirestore.instance
              .collection('comments')
              .doc(contentId)
              .update(updateData);
          break;
        case 'profile_content':
          await FirebaseFirestore.instance
              .collection('users')
              .doc(contentId)
              .update({
            'profile_moderation_status': newStatus,
            'profile_moderated_at': DateTime.now().toIso8601String(),
            'profile_moderated_by': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
            if (reason != null) 'profile_moderation_reason': reason,
          });
          break;
        case 'evidence_file':
          // Handle evidence file moderation (more complex as it's embedded in incidents)
          final parts = contentId.split('_');
          if (parts.length >= 2) {
            final incidentId = parts[0];
            // Update specific evidence file status within the incident
            // This would require more complex logic to update nested arrays
          }
          break;
      }

      // Log moderation action
      await FirebaseFirestore.instance.collection('moderation_logs').add({
        'content_id': contentId,
        'content_type': contentType,
        'action': newStatus,
        'reason': reason,
        'moderator_id': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        'timestamp': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('Failed to update moderation status: $e');
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

class ContentItem {
  final String id;
  final String type;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String status;
  final List<String> flaggedBy;
  final int flaggedCount;
  final Map<String, dynamic> metadata;

  ContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.status,
    required this.flaggedBy,
    required this.flaggedCount,
    required this.metadata,
  });
}