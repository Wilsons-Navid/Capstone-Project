import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/detected_threat_service.dart';

/// Admin view of scams the model detected from user text scans and SMS —
/// data collection & analysis (Thadee roadmap item 4).
class DetectedThreatsPage extends StatelessWidget {
  DetectedThreatsPage({super.key});

  final DetectedThreatService _service = DetectedThreatService();

  static const _readable = {
    'advance_fee_fraud': 'Advance-fee fraud',
    'mobile_money_fraud': 'Mobile-money fraud',
    'phishing': 'Phishing',
    'not_a_scam': 'Not a scam',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detected Threats')),
      body: StreamBuilder<List<DetectedThreat>>(
        stream: _service.watchRecent(limit: 200),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text('No threats detected yet.',
                  style: TextStyle(color: Colors.grey[600])),
            );
          }
          return Column(
            children: [
              _buildSummary(items),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildItem(items[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(List<DetectedThreat> items) {
    final counts = <String, int>{};
    for (final t in items) {
      counts[t.category] = (counts[t.category] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${items.length} detections',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries
                .map((e) => Chip(
                      label: Text(
                          '${_readable[e.key] ?? e.key}: ${e.value}',
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(DetectedThreat t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                t.source == 'sms' ? Icons.sms : Icons.text_fields,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                _readable[t.category] ?? t.category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${(t.confidence * 100).round()}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(t.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '${t.source} · ${t.threatLevel} · ${DateFormat('MMM dd, yyyy HH:mm').format(t.createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
