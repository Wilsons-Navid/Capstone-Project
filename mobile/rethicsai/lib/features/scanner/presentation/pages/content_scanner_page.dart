import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/suspicious_content_service.dart';
import '../../../../core/services/wilson_ai_service.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../widgets/content_analysis_result_card.dart';
import '../widgets/threat_level_indicator.dart';

class ContentScannerPage extends StatefulWidget {
  const ContentScannerPage({super.key});

  @override
  State<ContentScannerPage> createState() => _ContentScannerPageState();
}

class _ContentScannerPageState extends State<ContentScannerPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final SuspiciousContentService _contentService = SuspiciousContentService();
  final PageController _pageController = PageController();
  
  late AnimationController _animationController;
  ContentAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  String _selectedContentType = 'text';
  int _currentPageIndex = 0;

  final List<String> _contentTypes = [
    'text',
    'email',
    'sms',
    'social_media',
    'url',
    'message',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
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
                _buildAppBar()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, end: 0),
                
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    children: [
                      _buildScannerPage(),
                      _buildResultsPage(),
                      _buildHistoryPage(),
                    ],
                  ),
                ),
                
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.security_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Content Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Analyze suspicious content',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Type Selection
          Text(
            'Content Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _contentTypes.length,
              itemBuilder: (context, index) {
                final type = _contentTypes[index];
                final isSelected = type == _selectedContentType;
                return Container(
                  margin: EdgeInsets.only(right: index == _contentTypes.length - 1 ? 0 : 12),
                  child: FilterChip(
                    label: Text(type.replaceAll('_', ' ').toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedContentType = type;
                      });
                    },
                    backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideX(begin: -0.3, end: 0),
          
          const SizedBox(height: 24),
          
          // Content Input
          Text(
            'Content to Analyze',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: _getHintText(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Paste from clipboard',
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 24),
          
          // Analyze Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'ANALYZE CONTENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 24),
          
          // Quick Tips
          if (!_isAnalyzing) _buildQuickTips(),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    if (_analysisResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Analysis Results Yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze content to see results here',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Threat Level Indicator
          ThreatLevelIndicator(threatLevel: _analysisResult!.threatLevelEnum)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          
          const SizedBox(height: 20),
          
          // Analysis Result Card
          ContentAnalysisResultCard(result: _analysisResult!)
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildHistoryPage() {
    return FutureBuilder<List<ContentAnalysisResult>>(
      future: _contentService.getUserAnalysisHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading history: ${snapshot.error}'),
          );
        }
        
        final history = snapshot.data ?? [];
        
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Analysis History',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final result = history[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ContentAnalysisResultCard(
                result: result,
                isCompact: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Tips',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('📧', 'Always verify sender before clicking links'),
          _buildTip('💰', 'Be skeptical of "too good to be true" offers'),
          _buildTip('🔒', 'Never share passwords or personal info via messages'),
          _buildTip('📱', 'Double-check URLs before entering sensitive data'),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(0, Icons.scanner, 'Scanner'),
            _buildNavItem(1, Icons.analytics, 'Results'),
            _buildNavItem(2, Icons.history, 'History'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == _currentPageIndex;
    return Expanded(
      child: InkWell(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      setState(() {
        _contentController.text = clipboardData!.text!;
      });
    }
  }

  String _getHintText() {
    switch (_selectedContentType) {
      case 'text':
        return 'Text scanning coming soon...';
      case 'email':
        return 'Enter email address to scan (e.g., suspicious@example.com)';
      case 'sms':
        return 'Paste SMS content here...';
      case 'social_media':
        return 'Paste social media content here...';
      case 'url':
        return 'Enter URL to scan (e.g., https://suspicious-site.com)';
      case 'message':
        return 'Paste message content here...';
      default:
        return 'Paste suspicious content here...';
    }
  }

  Future<void> _analyzeContent() async {
    // Check if text scanning is selected
    if (_selectedContentType == 'text') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text scanning feature coming soon!'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter content to analyze'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate email address format if email type is selected
    if (_selectedContentType == 'email') {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(_contentController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final result = await _contentService.analyzeContent(
        content: _contentController.text.trim(),
        contentType: _selectedContentType,
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'manual_input',
        },
      );

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      // Navigate to results page
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Show result snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis complete - Threat Level: ${result.threatLevel}'),
          backgroundColor: _getThreatColor(result.threatLevelEnum),
        ),
      );

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getThreatColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.low:
        return Colors.green;
      case ThreatLevel.medium:
        return Colors.orange;
      case ThreatLevel.high:
        return Colors.red;
      case ThreatLevel.critical:
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }
}