import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../../core/themes/app_theme.dart';
import '../models/education_models.dart';
import '../../data/education_service.dart';
import 'youtube_video_player.dart';
import 'mp4_video_player.dart';

class InteractiveContentViewer extends StatefulWidget {
  final EducationContent content;

  const InteractiveContentViewer({
    super.key,
    required this.content,
  });

  @override
  State<InteractiveContentViewer> createState() => _InteractiveContentViewerState();
}

class _InteractiveContentViewerState extends State<InteractiveContentViewer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EducationService _educationService = EducationService();
  int _currentQuizIndex = 0;
  Map<int, int> _selectedAnswers = {};
  bool _quizCompleted = false;
  bool get _hasQuiz => widget.content.quizQuestions != null && widget.content.quizQuestions!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _getTabCount(),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    int count = 1; // Always have overview
    if (widget.content.videoUrl != null || widget.content.mp4Url != null) count++;
    if (widget.content.articleContent != null) count++;
    if (widget.content.quizQuestions != null && widget.content.quizQuestions!.isNotEmpty) count++;
    if (widget.content.resources != null && widget.content.resources!.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with African-inspired design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.baobabBrown,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.content.thumbnail,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.access_time,
                              text: '${widget.content.duration} min',
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.signal_cellular_alt,
                              text: widget.content.difficulty,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: _getTypeIcon(widget.content.type),
                              text: widget.content.type,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Tab bar
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: _buildTabs(),
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabViews(),
            ),
          ),
        ],
      ),
    ).animate()
        .slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'article':
        return Icons.article_outlined;
      case 'interactive':
        return Icons.touch_app_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [
      const Tab(text: 'Overview'),
    ];
    
    if (widget.content.videoUrl != null || widget.content.mp4Url != null) {
      tabs.add(const Tab(text: 'Video'));
    }
    
    if (widget.content.articleContent != null) {
      tabs.add(const Tab(text: 'Article'));
    }
    
    if (widget.content.quizQuestions != null && widget.content.quizQuestions!.isNotEmpty) {
      tabs.add(const Tab(text: 'Quiz'));
    }
    
    if (widget.content.resources != null && widget.content.resources!.isNotEmpty) {
      tabs.add(const Tab(text: 'Resources'));
    }
    
    return tabs;
  }

  List<Widget> _buildTabViews() {
    List<Widget> tabViews = [
      _buildOverviewTab(),
    ];
    
    if (widget.content.videoUrl != null || widget.content.mp4Url != null) {
      tabViews.add(_buildVideoTab());
    }
    
    if (widget.content.articleContent != null) {
      tabViews.add(_buildArticleTab());
    }
    
    if (widget.content.quizQuestions != null && widget.content.quizQuestions!.isNotEmpty) {
      tabViews.add(_buildQuizTab());
    }
    
    if (widget.content.resources != null && widget.content.resources!.isNotEmpty) {
      tabViews.add(_buildResourcesTab());
    }
    
    return tabViews;
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            widget.content.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Tags
          if (widget.content.tags.isNotEmpty) ...[
            const Text(
              'Topics Covered',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.content.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Learning outcomes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.saharaGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.saharaGold.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppTheme.saharaGold),
                    const SizedBox(width: 8),
                    const Text(
                      'What You\'ll Learn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._getLearningOutcomes().map((outcome) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8, right: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.saharaGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          outcome,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (widget.content.videoUrl != null) {
                  _tabController.animateTo(1);
                } else if (widget.content.articleContent != null) {
                  _tabController.animateTo(1);
                } else {
                  await _completeContent();
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Learning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildVideoTab() {
    if (widget.content.videoUrl == null && widget.content.mp4Url == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Video not available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final hasMp4 = widget.content.mp4Url != null && widget.content.mp4Url!.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prefer MP4 (self-hosted) over YouTube to avoid embed restrictions
          if (hasMp4)
            Mp4VideoPlayer(
              url: widget.content.mp4Url!,
              title: widget.content.title,
              description: widget.content.description,
            )
          else
            YoutubeVideoPlayer(
              videoUrl: widget.content.videoUrl!,
              backupUrls: widget.content.backupVideoUrls ?? const [],
              title: widget.content.title,
              description: widget.content.description,
              autoPlay: false,
              showControls: true,
            ),
          
          const SizedBox(height: 20),
          
          // Video Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'About This Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This cybersecurity education video is specifically designed for African audiences, covering real-world threats and practical solutions that protect our communities online.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Video stats
                Row(
                  children: [
                    _buildVideoStat(Icons.timer, '${widget.content.duration} min'),
                    const SizedBox(width: 16),
                    _buildVideoStat(Icons.signal_cellular_alt, widget.content.difficulty),
                    const SizedBox(width: 16),
                    _buildVideoStat(Icons.language, 'English'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Completion button (hidden if quiz exists)
          if (!_hasQuiz)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completeContent(),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Video as Watched'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.saharaGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.quiz_outlined, color: AppTheme.saharaGold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Complete the quiz to finish this module.'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArticleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.saharaGold.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Text(
                widget.content.articleContent ?? 'Article content will be displayed here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16, 
                  height: 1.6, 
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (!_hasQuiz)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completeContent(),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.saharaGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.quiz_outlined, color: AppTheme.saharaGold),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Complete the quiz to finish this module.'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }String _cleanArticleContent(String content) {
    // Deprecated: Markdown renderer now handles formatting safely
    return content.trim();
  }

  Widget _buildQuizTab() {
    final questions = widget.content.quizQuestions!;
    final currentQuestion = questions[_currentQuizIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuizIndex + 1) / questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${_currentQuizIndex + 1} of ${questions.length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          
          // Question
          Text(
            currentQuestion.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          
          // Options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedAnswers[_currentQuizIndex] == index;
                final isCorrect = index == currentQuestion.correctAnswerIndex;
                final showAnswer = _selectedAnswers.containsKey(_currentQuizIndex);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: showAnswer ? null : () {
                      setState(() {
                        _selectedAnswers[_currentQuizIndex] = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: showAnswer
                            ? (isCorrect
                                ? AppTheme.successColor.withOpacity(0.15)
                                : isSelected
                                    ? AppTheme.errorColor.withOpacity(0.15)
                                    : Colors.white)
                            : isSelected
                                ? AppTheme.primaryColor.withOpacity(0.12)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: showAnswer
                              ? (isCorrect
                                  ? AppTheme.successColor
                                  : isSelected
                                      ? AppTheme.errorColor
                                      : Colors.grey[300]!)
                              : isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: showAnswer
                                  ? (isCorrect
                                      ? AppTheme.successColor
                                      : isSelected
                                          ? AppTheme.errorColor
                                          : Colors.grey[300])
                                  : isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey[300],
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentQuestion.options[index],
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (showAnswer && isCorrect)
                            Icon(Icons.check_circle, color: AppTheme.successColor),
                          if (showAnswer && isSelected && !isCorrect)
                            Icon(Icons.cancel, color: AppTheme.errorColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Explanation
          if (_selectedAnswers.containsKey(_currentQuizIndex)) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.saharaGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.saharaGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppTheme.saharaGold, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Explanation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentQuestion.explanation,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Navigation buttons
          Row(
            children: [
              if (_currentQuizIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuizIndex--;
                      });
                    },
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuizIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedAnswers.containsKey(_currentQuizIndex)
                      ? () {
                          if (_currentQuizIndex < questions.length - 1) {
                            setState(() {
                              _currentQuizIndex++;
                            });
                          } else {
                            _completeQuiz();
                          }
                        }
                      : null,
                  child: Text(
                    _currentQuizIndex < questions.length - 1 ? 'Next' : 'Complete Quiz',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    final resources = widget.content.resources!;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final entry = resources.entries.elementAt(index);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.link,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      entry.value,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.launch),
                    onTap: () => _launchUrl(entry.value),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<String> _getLearningOutcomes() {
    // Generate context-appropriate learning outcomes based on content
    switch (widget.content.categoryId) {
      case 'mobile-money-security':
        return [
          'Identify common mobile money scam tactics',
          'Create secure PINs and protect them effectively',
          'Recognize legitimate vs fake mobile money communications',
          'Know what to do if you\'ve been scammed',
        ];
      case 'whatsapp-telegram-safety':
        return [
          'Secure your messaging apps properly',
          'Spot social engineering attempts',
          'Protect your personal information',
          'Report suspicious activities effectively',
        ];
      case 'job-romance-scams':
        return [
          'Identify red flags in online relationships',
          'Protect yourself from romance scammers',
          'Verify job opportunities safely',
          'Know recovery steps if scammed',
        ];
      default:
        return [
          'Understand the cybersecurity landscape in Africa',
          'Apply practical security measures',
          'Recognize and avoid common threats',
          'Build safer digital habits',
        ];
    }
  }

  Future<void> _launchVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _completeContent() async {
    await _educationService.markContentCompleted(
      widget.content.id,
      widget.content.duration,
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Content completed! +${widget.content.duration} minutes learned'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _completeQuiz() {
    final questions = widget.content.quizQuestions!;
    int correctAnswers = 0;
    
    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }
    
    final score = (correctAnswers / questions.length * 100).round();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              score >= 70 ? Icons.celebration : Icons.refresh,
              color: score >= 70 ? AppTheme.successColor : AppTheme.warningColor,
            ),
            const SizedBox(width: 8),
            Text(score >= 70 ? 'Well Done!' : 'Keep Learning!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You scored $score% ($correctAnswers/${questions.length} correct)',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 70 ? AppTheme.successColor : AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 12),
            if (score < 70)
              const Text(
                'Score at least 70% to pass. You can retry the quiz.',
                style: TextStyle(fontSize: 13),
              ),
          ],
        ),
        actions: [
          if (score < 70)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentQuizIndex = 0;
                  _selectedAnswers.clear();
                });
              },
              child: const Text('Retry Quiz'),
            ),
          if (score >= 70)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _educationService.recordQuizResult(widget.content.id, score, true);
                _completeContent(); // Mark content complete after passing quiz
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
              child: const Text('Finish'),
            ),
        ],
      ),
    );
  }
}



