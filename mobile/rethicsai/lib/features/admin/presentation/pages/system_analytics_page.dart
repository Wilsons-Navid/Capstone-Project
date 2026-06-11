import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';

class SystemAnalyticsPage extends StatefulWidget {
  const SystemAnalyticsPage({super.key});

  @override
  State<SystemAnalyticsPage> createState() => _SystemAnalyticsPageState();
}

class _SystemAnalyticsPageState extends State<SystemAnalyticsPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedTimeframe = 'week';
  
  // Analytics data
  Map<String, dynamic> _overviewStats = {};
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _incidentStats = {};
  Map<String, dynamic> _performanceStats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _trendData = [];

  final List<String> _timeframes = ['day', 'week', 'month', 'year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadOverviewStats(),
        _loadUserStats(),
        _loadIncidentStats(),
        _loadPerformanceStats(),
        _loadRecentActivity(),
        _loadTrendData(),
      ]);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load analytics data: $e');
    }
  }

  Future<void> _loadOverviewStats() async {
    try {
      // Get current date for filtering
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: 7));
      
      // Load basic counts
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final incidentsSnapshot = await FirebaseFirestore.instance.collection('incidents').get();
      final casesSnapshot = await FirebaseFirestore.instance.collection('cases').get();
      
      // Calculate weekly incidents
      final weeklyIncidents = incidentsSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = DateTime.parse(data['created_at']);
        return createdAt.isAfter(startOfWeek);
      }).length;

      // Calculate resolution rate
      final resolvedCases = casesSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'resolved' || data['status'] == 'closed';
      }).length;
      final resolutionRate = casesSnapshot.docs.isNotEmpty 
          ? (resolvedCases / casesSnapshot.docs.length * 100).round()
          : 0;

      setState(() {
        _overviewStats = {
          'total_users': usersSnapshot.docs.length,
          'total_incidents': incidentsSnapshot.docs.length,
          'active_cases': casesSnapshot.docs.where((doc) => 
            (doc.data()['status'] == 'in_progress' || doc.data()['status'] == 'investigating')).length,
          'weekly_incidents': weeklyIncidents,
          'resolution_rate': resolutionRate,
          'system_uptime': 99.8,
        };
      });
    } catch (e) {
      print('Failed to load overview stats: $e');
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = snapshot.docs.map((doc) => doc.data()).toList();

      // Calculate user statistics
      final roleBreakdown = <String, int>{
        'super_admin': 0,
        'admin': 0,
        'moderator': 0,
        'user': 0,
      };

      int activeUsers = 0;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (final user in users) {
        final role = user['role'] as String? ?? 'user';
        if (roleBreakdown.containsKey(role)) {
          roleBreakdown[role] = roleBreakdown[role]! + 1;
        }

        // Check if user is active (logged in within 30 days)
        final lastLoginField = user['lastLoginAt'];
        if (lastLoginField != null) {
          try {
            DateTime loginDate;
            if (lastLoginField is String) {
              loginDate = DateTime.parse(lastLoginField);
            } else {
              // Handle Firestore Timestamp
              loginDate = (lastLoginField as dynamic).toDate();
            }
            if (loginDate.isAfter(thirtyDaysAgo)) {
              activeUsers++;
            }
          } catch (e) {
            // Handle parsing error, skip this user
          }
        }
      }

      setState(() {
        _userStats = {
          'total_users': users.length,
          'active_users': activeUsers,
          'new_users_this_month': _calculateNewUsersThisMonth(users),
          'role_breakdown': roleBreakdown,
          'user_growth_rate': 12.5, // Placeholder
        };
      });
    } catch (e) {
      print('Failed to load user stats: $e');
    }
  }

  Future<void> _loadIncidentStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('incidents').get();
      final incidents = snapshot.docs.map((doc) => doc.data()).toList();

      // Calculate incident statistics
      final typeBreakdown = <String, int>{};
      final priorityBreakdown = <String, int>{'high': 0, 'medium': 0, 'low': 0};
      final statusBreakdown = <String, int>{};

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      int thisMonthIncidents = 0;

      for (final incident in incidents) {
        // Type breakdown
        final type = incident['incident_type'] as String? ?? 'unknown';
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;

        // Priority breakdown
        final priority = incident['priority_level'] as String? ?? 'medium';
        if (priorityBreakdown.containsKey(priority)) {
          priorityBreakdown[priority] = priorityBreakdown[priority]! + 1;
        }

        // Status breakdown
        final status = incident['status'] as String? ?? 'submitted';
        statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;

        // This month incidents
        DateTime? createdAt;
        try {
          final createdAtField = incident['created_at'];
          if (createdAtField is String) {
            createdAt = DateTime.parse(createdAtField);
          } else if (createdAtField != null) {
            // Handle Firestore Timestamp
            createdAt = (createdAtField as dynamic).toDate();
          }
        } catch (e) {
          continue; // Skip this incident if date parsing fails
        }
        if (createdAt != null && createdAt.isAfter(thisMonth)) {
          thisMonthIncidents++;
        }
      }

      // Calculate average resolution time (placeholder)
      const avgResolutionTime = 4.2;

      setState(() {
        _incidentStats = {
          'total_incidents': incidents.length,
          'this_month_incidents': thisMonthIncidents,
          'avg_resolution_time': avgResolutionTime,
          'type_breakdown': typeBreakdown,
          'priority_breakdown': priorityBreakdown,
          'status_breakdown': statusBreakdown,
        };
      });
    } catch (e) {
      print('Failed to load incident stats: $e');
    }
  }

  Future<void> _loadPerformanceStats() async {
    try {
      // Simulate performance data
      setState(() {
        _performanceStats = {
          'response_time': 245, // ms
          'database_queries': 1234,
          'api_calls': 5678,
          'error_rate': 0.5, // percentage
          'cache_hit_rate': 94.2, // percentage
          'concurrent_users': 89,
          'peak_concurrent_users': 156,
          'data_processed': 2.3, // GB
        };
      });
    } catch (e) {
      print('Failed to load performance stats: $e');
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      // Get recent activities from various collections
      final activities = <Map<String, dynamic>>[];

      // Recent incidents
      final incidentSnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      for (final doc in incidentSnapshot.docs) {
        final data = doc.data();
        DateTime timestamp;
        try {
          final createdAtField = data['created_at'];
          if (createdAtField is String) {
            timestamp = DateTime.parse(createdAtField);
          } else {
            timestamp = (createdAtField as dynamic).toDate();
          }
        } catch (e) {
          timestamp = DateTime.now(); // Fallback to now if parsing fails
        }
        
        activities.add({
          'type': 'incident_created',
          'description': 'New incident reported: ${data['title']}',
          'timestamp': timestamp,
          'icon': Icons.report,
          'color': AppTheme.secondaryColor,
        });
      }

      // Recent user registrations
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (final doc in userSnapshot.docs) {
        final data = doc.data();
        DateTime timestamp;
        try {
          final createdAtField = data['createdAt'];
          if (createdAtField is String) {
            timestamp = DateTime.parse(createdAtField);
          } else {
            timestamp = (createdAtField as dynamic).toDate();
          }
        } catch (e) {
          timestamp = DateTime.now(); // Fallback to now if parsing fails
        }
        
        activities.add({
          'type': 'user_registered',
          'description': 'New user registered: ${data['email']}',
          'timestamp': timestamp,
          'icon': Icons.person_add,
          'color': AppTheme.successColor,
        });
      }

      // Sort by timestamp
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _recentActivity = activities.take(15).toList();
      });
    } catch (e) {
      print('Failed to load recent activity: $e');
    }
  }

  Future<void> _loadTrendData() async {
    try {
      // Generate trend data for the past 30 days
      final trends = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        trends.add({
          'date': date,
          'incidents': (20 + (i % 10)) + (DateTime.now().millisecondsSinceEpoch % 15),
          'users': (5 + (i % 3)) + (DateTime.now().millisecondsSinceEpoch % 5),
          'cases_resolved': (8 + (i % 5)) + (DateTime.now().millisecondsSinceEpoch % 8),
        });
      }

      setState(() => _trendData = trends);
    } catch (e) {
      print('Failed to load trend data: $e');
    }
  }

  int _calculateNewUsersThisMonth(List<Map<String, dynamic>> users) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    
    return users.where((user) {
      final createdAtField = user['createdAt'];
      if (createdAtField != null) {
        try {
          DateTime date;
          if (createdAtField is String) {
            date = DateTime.parse(createdAtField);
          } else {
            // Handle Firestore Timestamp
            date = (createdAtField as dynamic).toDate();
          }
          return date.isAfter(thisMonth);
        } catch (e) {
          return false;
        }
      }
      return false;
    }).length;
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
                  title: 'System Analytics',
                  subtitle: 'Platform usage and performance statistics',
                  icon: Icons.analytics,
                  gradient: LinearGradient(
                    colors: [AppTheme.successColor, AppTheme.accentDark],
                  ),
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedTimeframe,
                        dropdownColor: Colors.white,
                        underline: Container(),
                        style: const TextStyle(color: Colors.white),
                        items: _timeframes.map((timeframe) => DropdownMenuItem(
                          value: timeframe,
                          child: Text(
                            timeframe.toUpperCase(),
                            style: const TextStyle(color: Colors.black),
                          ),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTimeframe = value);
                            _loadAnalyticsData();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _downloadReport,
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

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Users'),
                    Tab(text: 'Incidents'),
                    Tab(text: 'Performance'),
                  ],
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildUsersTab(),
                            _buildIncidentsTab(),
                            _buildPerformanceTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadAnalyticsData,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Total Users',
                _overviewStats['total_users']?.toString() ?? '0',
                Icons.people,
                AppTheme.victoriaBlue,
              ),
              _buildMetricCard(
                'Total Incidents',
                _overviewStats['total_incidents']?.toString() ?? '0',
                Icons.report_problem,
                AppTheme.secondaryColor,
              ),
              _buildMetricCard(
                'Active Cases',
                _overviewStats['active_cases']?.toString() ?? '0',
                Icons.work,
                AppTheme.baobabBrown,
              ),
              _buildMetricCard(
                'Resolution Rate',
                '${_overviewStats['resolution_rate'] ?? 0}%',
                Icons.check_circle,
                AppTheme.successColor,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Trend Chart
          _buildTrendChart(),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Users',
                  _userStats['total_users']?.toString() ?? '0',
                  Icons.people,
                  AppTheme.victoriaBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Active Users',
                  _userStats['active_users']?.toString() ?? '0',
                  Icons.person,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'New This Month',
                  _userStats['new_users_this_month']?.toString() ?? '0',
                  Icons.person_add,
                  AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Growth Rate',
                  '${_userStats['user_growth_rate'] ?? 0}%',
                  Icons.trending_up,
                  AppTheme.baobabBrown,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Role breakdown
          _buildRoleBreakdownChart(),
        ],
      ),
    );
  }

  Widget _buildIncidentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incident metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Incidents',
                  _incidentStats['total_incidents']?.toString() ?? '0',
                  Icons.report,
                  AppTheme.clayRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'This Month',
                  _incidentStats['this_month_incidents']?.toString() ?? '0',
                  Icons.calendar_today,
                  AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildMetricCard(
            'Avg Resolution Time',
            '${_incidentStats['avg_resolution_time'] ?? 0} days',
            Icons.timer,
            AppTheme.successColor,
          ),
          
          const SizedBox(height: 24),
          
          // Incident type breakdown
          _buildIncidentTypeBreakdown(),
          
          const SizedBox(height: 24),
          
          // Priority and status breakdown
          Row(
            children: [
              Expanded(child: _buildPriorityBreakdown()),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusBreakdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                'Response Time',
                '${_performanceStats['response_time'] ?? 0}ms',
                Icons.speed,
                AppTheme.victoriaBlue,
              ),
              _buildMetricCard(
                'Error Rate',
                '${_performanceStats['error_rate'] ?? 0}%',
                Icons.error,
                AppTheme.clayRed,
              ),
              _buildMetricCard(
                'Cache Hit Rate',
                '${_performanceStats['cache_hit_rate'] ?? 0}%',
                Icons.storage,
                AppTheme.successColor,
              ),
              _buildMetricCard(
                'Concurrent Users',
                _performanceStats['concurrent_users']?.toString() ?? '0',
                Icons.people,
                AppTheme.baobabBrown,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Additional performance info
          _buildPerformanceDetails(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend Analysis (Past 30 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            child: const Center(
              child: Text(
                'Chart visualization would be implemented here\nwith a charting library like fl_chart',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...(_recentActivity.take(5).map((activity) => _buildActivityItem(activity))),
          if (_recentActivity.length > 5)
            TextButton(
              onPressed: () => _showAllActivity(),
              child: const Text('View All Activity'),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activity['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'],
              size: 16,
              color: activity['color'],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('MMM dd, HH:mm').format(activity['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBreakdownChart() {
    final roleBreakdown = _userStats['role_breakdown'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Roles Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...roleBreakdown.entries.map((entry) => 
            _buildProgressItem(entry.key.replaceAll('_', ' ').toUpperCase(), entry.value, _getRoleColor(entry.key))
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTypeBreakdown() {
    final typeBreakdown = _incidentStats['type_breakdown'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incident Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...typeBreakdown.entries.take(5).map((entry) => 
            _buildProgressItem(entry.key.replaceAll('_', ' ').toUpperCase(), entry.value, AppTheme.secondaryColor)
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown() {
    final priorityBreakdown = _incidentStats['priority_breakdown'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Levels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...priorityBreakdown.entries.map((entry) => 
            _buildProgressItem(entry.key.toUpperCase(), entry.value, _getPriorityColor(entry.key))
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final statusBreakdown = _incidentStats['status_breakdown'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...statusBreakdown.entries.take(4).map((entry) => 
            _buildProgressItem(entry.key.replaceAll('_', ' ').toUpperCase(), entry.value, _getStatusColor(entry.key))
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Database Queries', '${_performanceStats['database_queries'] ?? 0}'),
          _buildDetailRow('API Calls', '${_performanceStats['api_calls'] ?? 0}'),
          _buildDetailRow('Peak Concurrent Users', '${_performanceStats['peak_concurrent_users'] ?? 0}'),
          _buildDetailRow('Data Processed', '${_performanceStats['data_processed'] ?? 0} GB'),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int value, Color color) {
    final maxValue = 100; // Placeholder max value
    final percentage = maxValue > 0 ? (value / maxValue * 100).clamp(0, 100) : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin': return AppTheme.clayRed;
      case 'admin': return AppTheme.secondaryColor;
      case 'moderator': return AppTheme.victoriaBlue;
      case 'user': return AppTheme.successColor;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return AppTheme.clayRed;
      case 'medium': return AppTheme.secondaryColor;
      case 'low': return AppTheme.successColor;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted': return AppTheme.victoriaBlue;
      case 'under_review': return AppTheme.secondaryColor;
      case 'investigating': return AppTheme.baobabBrown;
      case 'resolved': return AppTheme.successColor;
      default: return Colors.grey;
    }
  }

  void _showAllActivity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                    const Expanded(
                      child: Text(
                        'All Recent Activity',
                        style: TextStyle(
                          fontSize: 20,
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
                
                // Activity list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _recentActivity.length,
                    itemBuilder: (context, index) => _buildActivityItem(_recentActivity[index]),
                  ),
                ),
              ],
            ),
          );
        },
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadReport() async {
    try {
      final reportData = _generateReportData();
      await _showDownloadOptions(reportData);
    } catch (e) {
      _showErrorSnackBar('Failed to generate report: $e');
    }
  }

  Map<String, dynamic> _generateReportData() {
    final now = DateTime.now();
    
    return {
      'report_info': {
        'title': 'Rethicssec System Analytics Report',
        'generated_at': now.toIso8601String(),
        'timeframe': _selectedTimeframe,
        'generated_by': 'System Administrator',
      },
      'overview_statistics': _overviewStats,
      'user_statistics': _userStats,
      'incident_statistics': _incidentStats,
      'performance_statistics': _performanceStats,
      'recent_activity': _recentActivity.map((activity) => {
        'type': activity['type'],
        'description': activity['description'],
        'timestamp': activity['timestamp'].toIso8601String(),
      }).toList(),
      'trend_data': _trendData.map((trend) => {
        'date': trend['date'].toIso8601String(),
        'incidents': trend['incidents'],
        'users': trend['users'],
        'cases_resolved': trend['cases_resolved'],
      }).toList(),
    };
  }

  Future<void> _showDownloadOptions(Map<String, dynamic> reportData) async {
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
              'Download System Analytics Report',
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
                _downloadAsCSV(reportData);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.code, color: AppTheme.victoriaBlue),
              title: const Text('Download as JSON'),
              subtitle: const Text('Structured data format'),
              onTap: () {
                Navigator.pop(context);
                _downloadAsJSON(reportData);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.description, color: AppTheme.secondaryColor),
              title: const Text('Generate Summary Report'),
              subtitle: const Text('Human-readable summary'),
              onTap: () {
                Navigator.pop(context);
                _downloadAsSummary(reportData);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAsCSV(Map<String, dynamic> reportData) async {
    try {
      final csvData = <List<String>>[];
      
      // Header
      csvData.add(['Rethicssec System Analytics Report']);
      csvData.add(['Generated:', reportData['report_info']['generated_at']]);
      csvData.add(['Timeframe:', reportData['report_info']['timeframe']]);
      csvData.add(['']); // Empty row
      
      // Overview Statistics
      csvData.add(['Overview Statistics']);
      csvData.add(['Metric', 'Value']);
      final overview = reportData['overview_statistics'] as Map<String, dynamic>;
      overview.forEach((key, value) {
        csvData.add([key.replaceAll('_', ' ').toUpperCase(), value.toString()]);
      });
      csvData.add(['']); // Empty row
      
      // User Statistics
      csvData.add(['User Statistics']);
      csvData.add(['Metric', 'Value']);
      final userStats = reportData['user_statistics'] as Map<String, dynamic>;
      userStats.forEach((key, value) {
        if (key != 'role_breakdown') {
          csvData.add([key.replaceAll('_', ' ').toUpperCase(), value.toString()]);
        }
      });
      
      // Role breakdown
      if (userStats.containsKey('role_breakdown')) {
        csvData.add(['']);
        csvData.add(['Role Distribution']);
        csvData.add(['Role', 'Count']);
        final roleBreakdown = userStats['role_breakdown'] as Map<String, dynamic>;
        roleBreakdown.forEach((role, count) {
          csvData.add([role.replaceAll('_', ' ').toUpperCase(), count.toString()]);
        });
      }
      csvData.add(['']); // Empty row
      
      // Incident Statistics
      csvData.add(['Incident Statistics']);
      csvData.add(['Metric', 'Value']);
      final incidentStats = reportData['incident_statistics'] as Map<String, dynamic>;
      incidentStats.forEach((key, value) {
        if (key != 'type_breakdown' && key != 'priority_breakdown' && key != 'status_breakdown') {
          csvData.add([key.replaceAll('_', ' ').toUpperCase(), value.toString()]);
        }
      });
      
      // Performance Statistics
      csvData.add(['']);
      csvData.add(['Performance Statistics']);
      csvData.add(['Metric', 'Value']);
      final perfStats = reportData['performance_statistics'] as Map<String, dynamic>;
      perfStats.forEach((key, value) {
        csvData.add([key.replaceAll('_', ' ').toUpperCase(), value.toString()]);
      });
      
      // Recent Activity
      csvData.add(['']);
      csvData.add(['Recent Activity']);
      csvData.add(['Type', 'Description', 'Timestamp']);
      final activities = reportData['recent_activity'] as List<dynamic>;
      for (final activity in activities) {
        csvData.add([
          activity['type'].toString(),
          activity['description'].toString(),
          activity['timestamp'].toString(),
        ]);
      }
      
      final csvString = const ListToCsvConverter().convert(csvData);
      await _saveAndShareFile(csvString, 'system_analytics_report.csv', 'text/csv');
      
    } catch (e) {
      _showErrorSnackBar('Failed to generate CSV report: $e');
    }
  }

  Future<void> _downloadAsJSON(Map<String, dynamic> reportData) async {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(reportData);
      await _saveAndShareFile(jsonString, 'system_analytics_report.json', 'application/json');
    } catch (e) {
      _showErrorSnackBar('Failed to generate JSON report: $e');
    }
  }

  Future<void> _downloadAsSummary(Map<String, dynamic> reportData) async {
    try {
      final buffer = StringBuffer();
      final reportInfo = reportData['report_info'] as Map<String, dynamic>;
      final overview = reportData['overview_statistics'] as Map<String, dynamic>;
      final userStats = reportData['user_statistics'] as Map<String, dynamic>;
      final incidentStats = reportData['incident_statistics'] as Map<String, dynamic>;
      final perfStats = reportData['performance_statistics'] as Map<String, dynamic>;
      
      // Header
      buffer.writeln('RETHICSAI SYSTEM ANALYTICS REPORT');
      buffer.writeln('=' * 50);
      buffer.writeln('Generated: ${reportInfo['generated_at']}');
      buffer.writeln('Timeframe: ${reportInfo['timeframe']?.toString().toUpperCase()}');
      buffer.writeln('Generated by: ${reportInfo['generated_by']}');
      buffer.writeln();
      
      // Executive Summary
      buffer.writeln('EXECUTIVE SUMMARY');
      buffer.writeln('-' * 20);
      buffer.writeln('• Total Users: ${overview['total_users'] ?? 0}');
      buffer.writeln('• Total Incidents: ${overview['total_incidents'] ?? 0}');
      buffer.writeln('• Active Cases: ${overview['active_cases'] ?? 0}');
      buffer.writeln('• Resolution Rate: ${overview['resolution_rate'] ?? 0}%');
      buffer.writeln('• System Uptime: ${overview['system_uptime'] ?? 0}%');
      buffer.writeln();
      
      // User Analytics
      buffer.writeln('USER ANALYTICS');
      buffer.writeln('-' * 15);
      buffer.writeln('• Active Users (30 days): ${userStats['active_users'] ?? 0}');
      buffer.writeln('• New Users This Month: ${userStats['new_users_this_month'] ?? 0}');
      buffer.writeln('• Growth Rate: ${userStats['user_growth_rate'] ?? 0}%');
      
      if (userStats.containsKey('role_breakdown')) {
        buffer.writeln('\nUser Role Distribution:');
        final roleBreakdown = userStats['role_breakdown'] as Map<String, dynamic>;
        roleBreakdown.forEach((role, count) {
          buffer.writeln('  - ${role.replaceAll('_', ' ').toUpperCase()}: $count');
        });
      }
      buffer.writeln();
      
      // Incident Analytics
      buffer.writeln('INCIDENT ANALYTICS');
      buffer.writeln('-' * 18);
      buffer.writeln('• Total Incidents: ${incidentStats['total_incidents'] ?? 0}');
      buffer.writeln('• This Month: ${incidentStats['this_month_incidents'] ?? 0}');
      buffer.writeln('• Avg Resolution Time: ${incidentStats['avg_resolution_time'] ?? 0} days');
      
      if (incidentStats.containsKey('type_breakdown')) {
        buffer.writeln('\nTop Incident Types:');
        final typeBreakdown = incidentStats['type_breakdown'] as Map<String, dynamic>;
        final sortedTypes = typeBreakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (final entry in sortedTypes.take(5)) {
          buffer.writeln('  - ${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value}');
        }
      }
      buffer.writeln();
      
      // Performance Metrics
      buffer.writeln('PERFORMANCE METRICS');
      buffer.writeln('-' * 19);
      buffer.writeln('• Response Time: ${perfStats['response_time'] ?? 0}ms');
      buffer.writeln('• Error Rate: ${perfStats['error_rate'] ?? 0}%');
      buffer.writeln('• Cache Hit Rate: ${perfStats['cache_hit_rate'] ?? 0}%');
      buffer.writeln('• Peak Concurrent Users: ${perfStats['peak_concurrent_users'] ?? 0}');
      buffer.writeln('• Data Processed: ${perfStats['data_processed'] ?? 0} GB');
      buffer.writeln();
      
      // Key Recommendations
      buffer.writeln('KEY RECOMMENDATIONS');
      buffer.writeln('-' * 20);
      
      // Generate smart recommendations based on data
      final errorRate = perfStats['error_rate'] as num? ?? 0;
      final resolutionRate = overview['resolution_rate'] as num? ?? 0;
      final responseTime = perfStats['response_time'] as num? ?? 0;
      
      if (errorRate > 1.0) {
        buffer.writeln('• HIGH PRIORITY: Error rate (${errorRate}%) exceeds threshold. Investigate system stability.');
      }
      
      if (resolutionRate < 80) {
        buffer.writeln('• MEDIUM PRIORITY: Resolution rate (${resolutionRate}%) below target. Review case management processes.');
      }
      
      if (responseTime > 500) {
        buffer.writeln('• MEDIUM PRIORITY: Response time (${responseTime}ms) above optimal. Consider performance optimization.');
      }
      
      buffer.writeln('• Continue monitoring user growth and incident patterns.');
      buffer.writeln('• Regular system health checks recommended.');
      buffer.writeln();
      
      buffer.writeln('End of Report');
      buffer.writeln('Generated by Rethicssec Analytics System');
      
      await _saveAndShareFile(buffer.toString(), 'system_analytics_summary.txt', 'text/plain');
      
    } catch (e) {
      _showErrorSnackBar('Failed to generate summary report: $e');
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
        subject: 'Rethicssec System Analytics Report',
        text: 'System analytics report generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );
      
      _showSuccessSnackBar('Report downloaded and ready to share');
      
    } catch (e) {
      _showErrorSnackBar('Failed to save report: $e');
    }
  }
}