import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/detected_threat_service.dart';

/// Admin view of scams the model detected from user text scans and SMS —
/// data collection & analysis (Thadee roadmap item 4). Filterable by country.
class DetectedThreatsPage extends StatefulWidget {
  const DetectedThreatsPage({super.key});

  @override
  State<DetectedThreatsPage> createState() => _DetectedThreatsPageState();
}

class _DetectedThreatsPageState extends State<DetectedThreatsPage> {
  final DetectedThreatService _service = DetectedThreatService();
  String? _country; // null = all countries

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
        stream: _service.watchRecent(limit: 300),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final all = snapshot.data ?? [];
          if (all.isEmpty) {
            return Center(
              child: Text('No threats detected yet.',
                  style: TextStyle(color: Colors.grey[600])),
            );
          }

          // Distinct countries present in the data (for the filter dropdown).
          final countries = <String>{
            for (final t in all)
              if ((t.country ?? '').isNotEmpty) t.country!
          }.toList()
            ..sort();

          // Reset filter if the selected country is no longer present.
          final activeCountry =
              (_country != null && countries.contains(_country)) ? _country : null;
          final items = activeCountry == null
              ? all
              : all.where((t) => t.country == activeCountry).toList();

          return Column(
            children: [
              _buildFilterBar(countries, activeCountry),
              _buildSummary(items),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('No detections for $activeCountry.',
                            style: TextStyle(color: Colors.grey[600])),
                      )
                    : ListView.separated(
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

  Widget _buildFilterBar(List<String> countries, String? activeCountry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: AppTheme.primaryColor.withOpacity(0.04),
      child: Row(
        children: [
          Icon(Icons.public, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Text('Country:', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: activeCountry,
                  isExpanded: true,
                  hint: const Text('All countries', style: TextStyle(fontSize: 13)),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All countries')),
                    ...countries.map((c) =>
                        DropdownMenuItem<String?>(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _country = v),
                ),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      label: Text('${_readable[e.key] ?? e.key}: ${e.value}',
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
          Row(
            children: [
              Icon(Icons.public, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(t.country ?? 'Unknown',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '· ${t.source} · ${t.threatLevel} · ${DateFormat('MMM dd, yyyy HH:mm').format(t.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
