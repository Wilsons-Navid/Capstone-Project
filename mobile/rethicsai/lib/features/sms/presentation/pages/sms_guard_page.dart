import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/sms_scanner_service.dart';

/// SMS Protection — scans the inbox and live-classifies incoming messages with
/// the project's scam model. Android-only.
class SmsGuardPage extends StatefulWidget {
  const SmsGuardPage({super.key});

  @override
  State<SmsGuardPage> createState() => _SmsGuardPageState();
}

class _SmsGuardPageState extends State<SmsGuardPage> {
  final SmsScannerService _service = SmsScannerService();
  final List<SmsScanItem> _items = [];

  bool _granted = false;
  bool _loading = false;
  bool _liveOn = false;

  static const _readable = {
    'advance_fee_fraud': 'Advance-fee fraud',
    'mobile_money_fraud': 'Mobile-money fraud',
    'phishing': 'Phishing',
    'not_a_scam': 'Not a scam',
  };

  Future<void> _grant() async {
    final ok = await _service.requestPermission();
    if (mounted) setState(() => _granted = ok);
  }

  Future<void> _scanInbox() async {
    if (!_granted) {
      await _grant();
      if (!_granted) return;
    }
    setState(() => _loading = true);
    try {
      final results = await _service.scanInbox(limit: 30);
      if (mounted) {
        setState(() {
          _items
            ..clear()
            ..addAll(results);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLive(bool value) async {
    if (value && !_granted) {
      await _grant();
      if (!_granted) return;
    }
    if (value) {
      _service.startListening((item) {
        if (!mounted) return;
        setState(() => _items.insert(0, item));
        if (item.isScam) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red[700],
              content: Text(
                'Suspicious SMS from ${item.address}: '
                '${_readable[item.verdict!.category] ?? item.verdict!.category}',
              ),
            ),
          );
        }
      });
    }
    setState(() => _liveOn = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('SMS Protection')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'SMS protection is available on Android only.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SMS Protection')),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      _loading ? 'Scanning…' : 'No messages scanned yet.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildItem(_items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sms_failed, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Scan your messages for scams with the AI model.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _scanInbox,
                  icon: const Icon(Icons.inbox, size: 18),
                  label: Text(_loading ? 'Scanning…' : 'Scan inbox'),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Switch(value: _liveOn, onChanged: _toggleLive),
                  const Text('Live', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(SmsScanItem item) {
    final scam = item.isScam;
    final accent = item.verdict == null
        ? Colors.grey
        : (scam ? Colors.red[700]! : Colors.green[700]!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scam ? Colors.red.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.address,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(item.date),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.verdict == null
                  ? 'Not analyzed'
                  : '${_readable[item.verdict!.category] ?? item.verdict!.category} '
                      '(${(item.verdict!.confidence * 100).round()}%)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
