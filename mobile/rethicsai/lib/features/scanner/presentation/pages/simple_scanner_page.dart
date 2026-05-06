import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/threat_scanner_service.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../shared/models/activity_model.dart';

class SimpleScannerPage extends StatefulWidget {
  const SimpleScannerPage({super.key});

  @override
  State<SimpleScannerPage> createState() => _SimpleScannerPageState();
}

class _SimpleScannerPageState extends State<SimpleScannerPage> with SingleTickerProviderStateMixin {
  final ThreatScannerService _scannerService = ThreatScannerService();
  final TextEditingController _inputController = TextEditingController();
  late TabController _tabController;
  
  ScanResult? _lastScanResult;
  bool _isScanning = false;
  int _selectedTabIndex = 0;

  final List<ScanTypeData> _scanTypes = [
    ScanTypeData(
      type: ScanType.url,
      title: 'URL Scanner',
      subtitle: 'Check if a website is safe',
      icon: Icons.link,
      hintText: 'Enter URL (e.g., https://example.com)',
    ),
    ScanTypeData(
      type: ScanType.email,
      title: 'Email Scanner',
      subtitle: 'Analyze email addresses for threats',
      icon: Icons.email,
      hintText: 'Enter email address to scan (e.g., suspicious@example.com)',
    ),
    ScanTypeData(
      type: ScanType.phone,
      title: 'Phone Scanner',
      subtitle: 'Check phone number legitimacy',
      icon: Icons.phone,
      hintText: 'Enter phone number (e.g., +1234567890)',
    ),
    ScanTypeData(
      type: ScanType.text,
      title: 'Text Scanner',
      subtitle: 'Coming soon - Text analysis feature',
      icon: Icons.text_fields,
      hintText: 'Text scanning feature coming soon...',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _scanTypes.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
        _inputController.clear();
        _lastScanResult = null;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'scanner.threat_scanner'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _scanTypes.map((scanType) => Tab(
            icon: Icon(scanType.icon, size: 20),
            text: scanType.title.split(' ').first,
          )).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _scanTypes.map((scanType) => 
                _buildScannerContent(scanType)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent(ScanTypeData scanType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      scanType.icon,
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
                          scanType.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          scanType.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Input Section
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter ${scanType.title.split(' ').first} to Scan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _inputController,
                    maxLines: scanType.type == ScanType.email || scanType.type == ScanType.text ? 5 : 1,
                    decoration: InputDecoration(
                      hintText: scanType.hintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isScanning ? null : () => _performScan(scanType.type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isScanning
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('scanner.scanning'.tr()),
                            ],
                          )
                        : Text('scanner.scan_now'.tr()),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Results Section
          if (_lastScanResult != null) _buildResultsCard(_lastScanResult!),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ScanResult result) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getThreatLevelColor(result.threatLevel),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'scanner.threat_level'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getThreatLevelColor(result.threatLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getThreatLevelString(result.threatLevel),
                    style: TextStyle(
                      color: _getThreatLevelColor(result.threatLevel),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Result
            Text(
              result.result,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            // Recommendations
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommendations:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...result.recommendations.map((rec) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _performScan(ScanType type) async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter something to scan')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _lastScanResult = null;
    });

    try {
      ScanResult result;
      switch (type) {
        case ScanType.url:
          result = await _scannerService.scanUrl(input);
          break;
        case ScanType.email:
          // Validate email address format first
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
          if (!emailRegex.hasMatch(input)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid email address'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() {
              _isScanning = false;
            });
            return;
          }
          result = await _scannerService.scanEmailAddress(input);
          break;
        case ScanType.phone:
          result = await _scannerService.scanPhoneNumber(input);
          break;
        case ScanType.text:
          // Text scanning feature coming soon
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text scanning feature coming soon!'),
              backgroundColor: Colors.blue,
            ),
          );
          setState(() {
            _isScanning = false;
          });
          return;
        case ScanType.file:
          result = await _scannerService.scanFileHash(input);
          break;
      }

      // Record activity
      await ActivityService.recordSecurityScanActivity(
        threatsFound: result.threatLevel != ThreatLevel.safe ? 1 : 0,
        scanType: type.name,
      );

      setState(() {
        _lastScanResult = result;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Color _getThreatLevelColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.safe:
        return Colors.green;
      case ThreatLevel.low:
        return Colors.yellow;
      case ThreatLevel.medium:
        return Colors.orange;
      case ThreatLevel.high:
        return Colors.red;
      case ThreatLevel.critical:
        return Colors.red.shade900;
      case ThreatLevel.unknown:
        return Colors.grey;
    }
  }

  String _getThreatLevelString(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.safe:
        return 'Safe';
      case ThreatLevel.low:
        return 'Low Risk';
      case ThreatLevel.medium:
        return 'Medium Risk';
      case ThreatLevel.high:
        return 'High Risk';
      case ThreatLevel.critical:
        return 'Critical';
      case ThreatLevel.unknown:
        return 'Unknown';
    }
  }
}

class ScanTypeData {
  final ScanType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final String hintText;

  const ScanTypeData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.hintText,
  });
}