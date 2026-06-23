import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/threat_scanner_service.dart';
import '../../../../core/services/scam_model_service.dart';
import '../../../../core/services/activity_service.dart';
import '../widgets/ai_model_verdict_card.dart';
import '../widgets/scam_action_bar.dart';
import '../widgets/country_report_card.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  final ThreatScannerService _scannerService = ThreatScannerService();
  final TextEditingController _inputController = TextEditingController();
  late TabController _tabController;
  
  ScanResult? _lastScanResult;
  bool _isScanning = false;
  String? _lastError;

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
    // Pre-warm the scam-model Space when the scanner opens, so the first scan
    // returns a model verdict instead of timing out into heuristics.
    unawaited(ScamModelService().warmUp());
    _tabController = TabController(length: _scanTypes.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _inputController.clear();
          _lastScanResult = null;
          _lastError = null;
        });
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
          
          // Results Section — skeleton while scanning, error state on failure,
          // otherwise the verdict card.
          if (_isScanning)
            _buildResultSkeleton()
          else if (_lastError != null)
            _buildErrorState(scanType.type)
          else if (_lastScanResult != null)
            _buildResultsCard(_lastScanResult!),
        ],
      ),
    );
  }

  /// Shimmer skeleton shown while a scan is in flight (MASTER §5: never a blank gap).
  Widget _buildResultSkeleton() {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  bar(22, 22),
                  const SizedBox(width: 8),
                  bar(120, 14),
                  const Spacer(),
                  bar(70, 22),
                ],
              ),
              const SizedBox(height: 20),
              bar(double.infinity, 12),
              const SizedBox(height: 8),
              bar(double.infinity, 12),
              const SizedBox(height: 8),
              bar(220, 12),
              const SizedBox(height: 20),
              bar(double.infinity, 56),
            ],
          ),
        ),
      ),
    );
  }

  /// Inline error state with a retry action (MASTER §5) — no raw exception text.
  Widget _buildErrorState(ScanType type) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 40, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            Text(
              'scanner.scan_failed_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _lastError ?? 'scanner.scan_failed_body'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _performScan(type),
              icon: const Icon(Icons.refresh),
              label: Text('scanner.retry'.tr()),
            ),
          ],
        ),
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
            // Header — verdict conveyed by icon + colour + text (not colour alone).
            Builder(builder: (context) {
              final color = _getThreatLevelColor(result.threatLevel);
              final label = _getThreatLevelString(result.threatLevel);
              return Semantics(
                label: '${'scanner.threat_level'.tr()}: $label',
                child: Row(
                  children: [
                    Icon(_getThreatLevelIcon(result.threatLevel),
                        color: color, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'scanner.threat_level'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 16),
            
            // Result
            Text(
              result.result,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // AI model verdict (the project's e5 + ensemble classifier)
            AiModelVerdictCard(
              aiModel: result.details?['ai_model'] as Map<String, dynamic>?,
            ),

            // Action layer — tappable call / message / email + report
            ScamActionBar(
              content: result.input,
              isThreat: result.threatLevel != ThreatLevel.safe,
            ),

            // Country-aware "report to authorities"
            CountryReportCard(
              content: result.input,
              category: (result.details?['ai_model']
                  as Map<String, dynamic>?)?['category'] as String?,
              isThreat: result.threatLevel != ThreatLevel.safe,
            ),

            // Recommendations
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'scanner.recommendations'.tr(),
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
      _lastError = null;
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
          // Text scanning runs the full pipeline (DB + heuristics + the e5/ensemble AI model).
          result = await _scannerService.scanTextContent(input);
          break;
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
      // Surface a friendly inline error state (no raw exception text to the user).
      if (mounted) {
        setState(() => _lastError = 'scanner.scan_failed_body'.tr());
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Verdict colors come from AA-safe semantic tokens (see design-system/MASTER.md §6),
  // never raw Colors.* — Colors.yellow in particular is near-invisible on white.
  Color _getThreatLevelColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.safe:
        return AppTheme.verdictSafe;
      case ThreatLevel.low:
      case ThreatLevel.medium:
        return AppTheme.amberText; // caution
      case ThreatLevel.high:
      case ThreatLevel.critical:
        return AppTheme.verdictDanger;
      case ThreatLevel.unknown:
        return AppTheme.onSurfaceVariant;
    }
  }

  // Verdict must not rely on colour alone (MASTER §6) — pair it with an icon.
  IconData _getThreatLevelIcon(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.safe:
        return Icons.verified_user;
      case ThreatLevel.low:
        return Icons.info_outline;
      case ThreatLevel.medium:
        return Icons.warning_amber_rounded;
      case ThreatLevel.high:
        return Icons.gpp_bad;
      case ThreatLevel.critical:
        return Icons.dangerous;
      case ThreatLevel.unknown:
        return Icons.help_outline;
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