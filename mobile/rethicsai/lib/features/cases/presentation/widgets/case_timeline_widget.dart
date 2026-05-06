import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../shared/models/incident_model.dart';

class CaseTimelineWidget extends StatelessWidget {
  final IncidentModel incident;

  const CaseTimelineWidget({
    super.key,
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    final timelineEvents = _getTimelineEvents();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Case Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...timelineEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == timelineEvents.length - 1;
            
            return _buildTimelineItem(
              event['title'] as String,
              event['description'] as String,
              event['icon'] as IconData,
              event['date'] as DateTime,
              event['status'] as String,
              isLast,
              index,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String description,
    IconData icon,
    DateTime date,
    String status,
    bool isLast,
    int index,
  ) {
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppTheme.primaryColor
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isCompleted || isCurrent ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted
                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                    : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isCurrent
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'In Progress',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(
      duration: 500.ms,
      delay: Duration(milliseconds: index * 200),
    ).slideX(begin: -0.3, end: 0);
  }

  List<Map<String, dynamic>> _getTimelineEvents() {
    final now = DateTime.now();
    final events = <Map<String, dynamic>>[];

    // Case submitted
    events.add({
      'title': 'Case Submitted',
      'description': 'Your incident report has been successfully submitted',
      'icon': Icons.upload,
      'date': incident.createdAt,
      'status': 'completed',
    });

    // Case under review (if applicable)
    if (_isStatusReached('under_review')) {
      events.add({
        'title': 'Under Review',
        'description': 'Your case is being reviewed by our team',
        'icon': Icons.visibility,
        'date': incident.createdAt.add(const Duration(hours: 2)),
        'status': incident.status == 'submitted' ? 'pending' : 'completed',
      });
    }

    // Investigation started
    if (_isStatusReached('investigating')) {
      events.add({
        'title': 'Investigation Started',
        'description': incident.assignedOfficer != null 
            ? 'Assigned to ${incident.assignedOfficer}'
            : 'Investigation has begun',
        'icon': Icons.search,
        'date': incident.createdAt.add(const Duration(days: 1)),
        'status': incident.status == 'investigating' ? 'current' : 
                  _isStatusReached('investigating') ? 'completed' : 'pending',
      });
    }

    // Additional investigation notes
    if (incident.investigationNotes.isNotEmpty) {
      for (int i = 0; i < incident.investigationNotes.length; i++) {
        final note = incident.investigationNotes[i];
        events.add({
          'title': 'Investigation Update',
          'description': note.note,
          'icon': Icons.note_add,
          'date': note.createdAt,
          'status': 'completed',
        });
      }
    }

    // Case resolved
    if (_isStatusReached('resolved')) {
      events.add({
        'title': 'Case Resolved',
        'description': 'Your case has been successfully resolved',
        'icon': Icons.check_circle,
        'date': incident.resolvedAt ?? now,
        'status': incident.status == 'resolved' ? 'current' : 'completed',
      });
    }

    // Case closed
    if (incident.status == 'closed') {
      events.add({
        'title': 'Case Closed',
        'description': 'This case has been officially closed',
        'icon': Icons.lock,
        'date': incident.resolvedAt ?? now,
        'status': 'completed',
      });
    }

    return events;
  }

  bool _isStatusReached(String status) {
    const statusOrder = [
      'submitted',
      'under_review',
      'investigating',
      'resolved',
      'closed',
    ];
    
    final currentIndex = statusOrder.indexOf(incident.status);
    final targetIndex = statusOrder.indexOf(status);
    
    return currentIndex >= targetIndex;
  }
}