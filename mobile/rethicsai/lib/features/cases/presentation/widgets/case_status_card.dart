import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../shared/models/incident_model.dart';

class CaseStatusCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const CaseStatusCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _getStatusGradient(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.caseNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          incident.title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.category,
                          'Type',
                          incident.incidentType,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.priority_high,
                          'Priority',
                          incident.priorityLevel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          'Reported',
                          DateFormat('MMM dd, yyyy').format(incident.createdAt),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.location_on,
                          'Location',
                          incident.locationOccurred ?? 'Not specified',
                        ),
                      ),
                    ],
                  ),
                  if (incident.assignedOfficer != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Assigned to: ${incident.assignedOfficer}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Progress indicator
                  const SizedBox(height: 16),
                  _buildProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().shimmer(
      duration: const Duration(seconds: 2),
      delay: const Duration(milliseconds: 500),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Submitted', 'Under Review', 'Investigating', 'Resolved'];
    final currentStep = _getCurrentStep();
    final isCompleted = currentStep >= 3;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${((currentStep + 1) / steps.length * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? const Color(0xFF4CAF50) : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 16,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentStep;
            final isLast = index == steps.length - 1;
            final stepColor = isCompleted && index == currentStep 
                ? const Color(0xFF4CAF50) 
                : (isActive ? AppTheme.primaryColor : Colors.grey[300]!);
            
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: stepColor,
                      shape: BoxShape.circle,
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: stepColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: isActive
                        ? Icon(
                            isCompleted && index == currentStep 
                                ? Icons.check_circle 
                                : Icons.check,
                            color: Colors.white,
                            size: isCompleted && index == currentStep ? 16 : 12,
                          )
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? stepColor.withOpacity(0.5)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              steps[currentStep],
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? const Color(0xFF4CAF50) : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  LinearGradient _getStatusGradient() {
    switch (incident.status.toLowerCase()) {
      case 'submitted':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        );
      case 'under_review':
      case 'investigating':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
        );
      case 'resolved':
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        );
      case 'closed':
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
        );
      default:
        return AppTheme.primaryGradient;
    }
  }

  IconData _getStatusIcon() {
    switch (incident.status.toLowerCase()) {
      case 'submitted':
        return Icons.upload;
      case 'under_review':
        return Icons.visibility;
      case 'investigating':
        return Icons.search;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.lock;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    switch (incident.status.toLowerCase()) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'investigating':
        return 'Investigating';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return incident.status.toUpperCase();
    }
  }

  int _getCurrentStep() {
    switch (incident.status.toLowerCase()) {
      case 'submitted':
        return 0;
      case 'under_review':
      case 'under review':
        return 1;
      case 'investigating':
      case 'in progress':
        return 2;
      case 'resolved':
      case 'closed':
        return 3;
      default:
        return 0;
    }
  }
}