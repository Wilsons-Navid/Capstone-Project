import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/threat_scanner_service.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../widgets/ai_model_verdict_card.dart';
import '../widgets/scam_action_bar.dart';
import '../widgets/country_report_card.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with TickerProviderStateMixin {
  final ThreatScannerService _scannerService = ThreatScannerService();
  final TextEditingController _inputController = TextEditingController();
  
  late AnimationController _animationController;
  late TabController _tabController;
  
  // Note: _selectedScanType is managed by _tabController.index
  ScanResult? _lastScanResult;
  bool _isScanning = false;

  final List<ScanTypeInfo> _scanTypes = [
    ScanTypeInfo(
      type: ScanType.url,
      title: 'URL Scanner',
      subtitle: 'Check if a website is safe',
      icon: Icons.link,
      hintText: 'Enter URL (e.g., https://example.com)',
      inputType: TextInputType.url,
    ),
    ScanTypeInfo(
      type: ScanType.email,
      title: 'Email Scanner',
      subtitle: 'Analyze email addresses for threats',
      icon: Icons.email,
      hintText: 'Enter email address to scan (e.g., suspicious@example.com)',
      inputType: TextInputType.emailAddress,
    ),
    ScanTypeInfo(
      type: ScanType.phone,
      title: 'Phone Scanner',
      subtitle: 'Check phone number legitimacy',
      icon: Icons.phone,
      hintText: 'Enter phone number (e.g., +1234567890)',
      inputType: TextInputType.phone,
    ),
    ScanTypeInfo(
      type: ScanType.text,
      title: 'Text Scanner',
      subtitle: 'Coming soon - Text analysis feature',
      icon: Icons.text_fields,
      hintText: 'Text scanning feature coming soon...',
      inputType: TextInputType.multiline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _tabController = TabController(length: _scanTypes.length, vsync: this);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
        children: [
          // African pattern background
          const AfricanPatternBackground(opacity: 0.03),
          
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                // Custom app bar
                _buildCustomAppBar()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, end: 0),
                
                // Tab bar
                _buildTabBar()
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.3, end: 0),
                
                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _scanTypes.map((scanType) => 
                      _buildScannerContent(scanType)
                    ).toList(),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Scanner icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.secondaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.security_outlined,
              color: Colors.white,
              size: 24,
            ),
          )
              .animate()
              .scale(delay: 300.ms, duration: 600.ms)
              .then()
              .shimmer(duration: 2000.ms),
          
          const SizedBox(width: 16),
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'scanner.threat_scanner'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Advanced Security Analysis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Info button
          IconButton(
            onPressed: _showScannerInfo,
            icon: const Icon(Icons.info_outline, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: _scanTypes.map((scanType) => Tab(
          icon: Icon(scanType.icon, size: 20),
          text: scanType.title.split(' ').first,
        )).toList(),
      ),
    );
  }

  Widget _buildScannerContent(ScanTypeInfo scanTypeInfo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scan type header
          _buildScanTypeHeader(scanTypeInfo),
          
          const SizedBox(height: 24),
          
          // Input section
          _buildInputSection(scanTypeInfo),
          
          const SizedBox(height: 24),
          
          // Scan button
          _buildScanButton(scanTypeInfo),
          
          const SizedBox(height: 24),
          
          // Results section
          if (_lastScanResult != null && _lastScanResult!.type == scanTypeInfo.type)
            _buildResultsSection(_lastScanResult!)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildScanTypeHeader(ScanTypeInfo scanTypeInfo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              scanTypeInfo.icon,
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
                  scanTypeInfo.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scanTypeInfo.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildInputSection(ScanTypeInfo scanTypeInfo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter ${scanTypeInfo.title.split(' ').first} to Scan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _inputController,
            keyboardType: scanTypeInfo.inputType,
            maxLines: scanTypeInfo.inputType == TextInputType.multiline ? 4 : 1,
            decoration: InputDecoration(
              hintText: scanTypeInfo.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: _inputController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _inputController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
          
          const SizedBox(height: 12),
          
          // Quick paste button for some types
          if (scanTypeInfo.inputType == TextInputType.multiline)
            TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste),
              label: const Text('Paste from Clipboard'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanButton(ScanTypeInfo scanTypeInfo) {
    return ElevatedButton(
      onPressed: _inputController.text.trim().isEmpty || _isScanning
          ? null
          : () => _performScan(scanTypeInfo.type),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
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
                const SizedBox(width: 12),
                Text('scanner.scanning'.tr()),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 20),
                const SizedBox(width: 8),
                Text(
                  'scanner.scan_now'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    )
        .animate()
        .shimmer(delay: 1000.ms, duration: 2000.ms);
  }

  Widget _buildResultsSection(ScanResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.threatLevelColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: result.threatLevelColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with threat level
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: result.threatLevelColor,
                  shape: BoxShape.circle,
                ),
              )
                  .animate()
                  .scale(duration: 600.ms)
                  .then()
                  .shimmer(duration: 1500.ms),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Text(
                  'scanner.threat_level'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: result.threatLevelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: result.threatLevelColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  result.threatLevelString,
                  style: TextStyle(
                    color: result.threatLevelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Result text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.result,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ...result.recommendations.map((recommendation) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Scan details
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Scanned ${DateFormat('MMM dd, HH:mm').format(result.scannedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performScan(ScanType scanType) async {
    if (_inputController.text.trim().isEmpty) return;
    
    setState(() {
      _isScanning = true;
      _lastScanResult = null;
    });

    try {
      ScanResult result;
      final input = _inputController.text.trim();
      
      switch (scanType) {
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
      
      setState(() {
        _lastScanResult = result;
      });
      
      // Provide haptic feedback based on threat level
      switch (result.threatLevel) {
        case ThreatLevel.safe:
          HapticFeedback.lightImpact();
          break;
        case ThreatLevel.low:
        case ThreatLevel.medium:
          HapticFeedback.mediumImpact();
          break;
        case ThreatLevel.high:
        case ThreatLevel.critical:
          HapticFeedback.heavyImpact();
          break;
        default:
          HapticFeedback.selectionClick();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null) {
        _inputController.text = clipboardData!.text!;
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to paste from clipboard')),
      );
    }
  }

  void _showScannerInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Threat Scanner'),
        content: const Text(
          'The Rethicssec Threat Scanner helps you identify potentially dangerous URLs, suspicious emails, questionable phone numbers, and harmful text content. '
          'Our advanced algorithms analyze patterns and compare against known threat databases to keep you safe online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class ScanTypeInfo {
  final ScanType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final String hintText;
  final TextInputType inputType;

  const ScanTypeInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.hintText,
    required this.inputType,
  });
}