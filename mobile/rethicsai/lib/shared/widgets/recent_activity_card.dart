import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/themes/app_theme.dart';
import '../../core/services/activity_service.dart';
import '../../core/services/logging_service.dart';
import '../models/activity_model.dart';

class RecentActivityCard extends StatefulWidget {
  const RecentActivityCard({super.key});

  @override
  State<RecentActivityCard> createState() => _RecentActivityCardState();
}

class _RecentActivityCardState extends State<RecentActivityCard> {
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
  }

  Future<void> _loadRecentActivities() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final activities = await ActivityService.getRecentActivities(limit: 5);
      
      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }

      LoggingService.info('RecentActivityCard', 'Loaded ${activities.length} recent activities');

    } catch (e, stackTrace) {
      LoggingService.error('RecentActivityCard', 'Failed to load recent activities', e, stackTrace);
      
      if (mounted) {
        setState(() {
          _error = 'Failed to load recent activities';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshActivities() async {
    await _loadRecentActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dashboard.recent_activity'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full activity list
                },
                child: Text(
                  'common.view_all'.tr(),
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Content based on state
          if (_isLoading)
            _buildLoadingState(context)
          else if (_error != null)
            _buildErrorState(context)
          else if (_activities.isEmpty)
            _buildEmptyState(context)
          else
            _buildActivitiesList(context),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 120,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[300],
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _refreshActivities,
            icon: const Icon(Icons.refresh),
            label: Text('common.retry'.tr()),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(BuildContext context) {
    return Column(
      children: [
        ...List.generate(_activities.length, (index) {
          return _buildActivityItem(
            context,
            activity: _activities[index],
          ).animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.2, end: 0);
        }),
        
        const SizedBox(height: 8),
        
        // Refresh button
        Center(
          child: TextButton.icon(
            onPressed: _refreshActivities,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text('common.refresh'.tr()),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, {required ActivityModel activity}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity.type.icon,
              color: activity.status.color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(activity.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Action button for certain activities
          if (_hasAction(activity))
            IconButton(
              onPressed: () => _handleActivityAction(activity),
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'dashboard.no_recent_activity'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'dashboard.start_using_app'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _createSampleActivity(),
            child: Text('Generate Sample Activity'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat.yMMMd().format(timestamp);
    }
  }

  bool _hasAction(ActivityModel activity) {
    // Determine which activities should have action buttons
    switch (activity.type) {
      case ActivityType.incidentReported:
      case ActivityType.incidentUpdated:
        return true;
      default:
        return false;
    }
  }

  void _handleActivityAction(ActivityModel activity) {
    // Handle activity-specific actions
    LoggingService.info('RecentActivityCard', 'Activity action tapped: ${activity.title}');
    
    switch (activity.type) {
      case ActivityType.incidentReported:
      case ActivityType.incidentUpdated:
        // Navigate to incident details
        if (activity.relatedEntityId != null) {
          // Navigator.pushNamed(context, '/incident/${activity.relatedEntityId}');
        }
        break;
      default:
        break;
    }
  }

  // For testing purposes - create sample activity
  Future<void> _createSampleActivity() async {
    await ActivityService.recordActivity(
      type: ActivityType.securityScan,
      title: 'AI Security Scan Completed',
      description: 'Routine security scan completed successfully with 0 threats detected',
      status: ActivityStatus.success,
    );
    
    // Refresh the list
    await _refreshActivities();
  }
}