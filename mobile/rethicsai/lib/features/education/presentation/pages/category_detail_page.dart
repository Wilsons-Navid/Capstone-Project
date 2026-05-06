import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../models/education_models.dart';
import '../../data/education_service.dart';
import '../widgets/interactive_content_viewer.dart';
import '../widgets/learning_content_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDetailPage extends StatefulWidget {
  final EducationCategory category;

  const CategoryDetailPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final EducationService _educationService = EducationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: const AfricanPatternBackground(opacity: 0.03),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar with category info
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(int.parse(widget.category.color.replaceFirst('#', '0xFF'))),
                            Color(int.parse(widget.category.color.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getCategoryIcon(widget.category.icon),
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.category.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                widget.category.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCategoryInfo(
                                    Icons.timer_outlined,
                                    widget.category.estimatedTime,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildCategoryInfo(
                                    Icons.signal_cellular_alt,
                                    widget.category.difficulty,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildCategoryInfo(
                                    Icons.menu_book_outlined,
                                    '${widget.category.moduleCount} modules',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Learning Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: StreamBuilder<List<EducationContent>>(
                    stream: _educationService.getContentByCategory(widget.category.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverToBoxAdapter(
                          child: Container(
                            height: 200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: _buildErrorState(),
                        );
                      }

                      final content = snapshot.data ?? [];
                      if (content.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _buildEmptyState(),
                        );
                      }
                      // Load user quiz results to compute per-card quiz pass state
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = content[index];
                              final hasQuiz = (item.quizQuestions?.isNotEmpty ?? false);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: LearningContentCard(
                                  content: item,
                                  onTap: () => _openContent(item),
                                  categoryColor: Color(int.parse(widget.category.color.replaceFirst('#', '0xFF'))),
                                  hasQuiz: hasQuiz,
                                  quizPassed: hasQuiz ? false : null,
                                ),
                              );
                            },
                            childCount: content.length,
                          ),
                        );
                      }

                      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection(EducationService.userProgressCollection).doc(uid).snapshots(),
                        builder: (context, progressSnap) {
                          final progressData = progressSnap.data?.data() ?? {};
                          final Map<String, dynamic> quizResults = Map<String, dynamic>.from(progressData['quiz_results'] ?? {});
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = content[index];
                                final hasQuiz = (item.quizQuestions?.isNotEmpty ?? false);
                                bool? quizPassed;
                                if (hasQuiz) {
                                  final qr = quizResults[item.id] as Map<String, dynamic>?;
                                  quizPassed = qr != null && (qr['passed'] == true) && ((qr['score'] ?? 0) >= 70);
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: LearningContentCard(
                                    content: item,
                                    onTap: () => _openContent(item),
                                    categoryColor: Color(int.parse(widget.category.color.replaceFirst('#', '0xFF'))),
                                    hasQuiz: hasQuiz,
                                    quizPassed: quizPassed,
                                  ),
                                );
                              },
                              childCount: content.length,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Bottom spacing
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Content Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Learning content for this category is being prepared. Check back soon!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Categories'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Failed to Load Content',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'There was an error loading the learning content. Please check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'phone_android':
        return Icons.phone_android;
      case 'message':
        return Icons.message;
      case 'favorite':
        return Icons.favorite;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'business':
        return Icons.business;
      case 'account_balance':
        return Icons.account_balance;
      case 'lock':
        return Icons.lock;
      case 'phishing':
        return Icons.phishing;
      case 'share':
        return Icons.share;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'wifi':
        return Icons.wifi;
      default:
        return Icons.school;
    }
  }

  void _openContent(EducationContent content) async {
    // Open interactive viewer quickly without pre-completing content
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.white,
          body: InteractiveContentViewer(content: content),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

