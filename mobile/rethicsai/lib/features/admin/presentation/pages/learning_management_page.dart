import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../education/presentation/models/education_models.dart';
import '../../../education/data/education_service.dart';
import '../widgets/admin_content_card.dart';
import '../widgets/add_content_dialog.dart';

class LearningManagementPage extends StatefulWidget {
  const LearningManagementPage({super.key});

  @override
  State<LearningManagementPage> createState() => _LearningManagementPageState();
}

class _LearningManagementPageState extends State<LearningManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EducationService _educationService = EducationService();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Learning Material Management',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Manage educational content for African cybersecurity',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _showAddContentDialog,
                            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search learning content...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  color: Colors.grey[100],
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: const [
                      Tab(text: 'Content', icon: Icon(Icons.library_books)),
                      Tab(text: 'Categories', icon: Icon(Icons.category)),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentTab(),
                      _buildCategoriesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return Column(
      children: [
        // Category Filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Filter by category:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<List<EducationCategory>>(
                  stream: _educationService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    return DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      underline: Container(),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All Categories')),
                        ...categories.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.title),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Content List
        Expanded(
          child: StreamBuilder<List<EducationContent>>(
            stream: _selectedCategory == 'all' 
                ? _educationService.getAllContent()
                : _educationService.getContentByCategory(_selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorState('Failed to load content');
              }

              final allContent = snapshot.data ?? [];
              final filteredContent = _searchQuery.isEmpty 
                  ? allContent
                  : allContent.where((content) =>
                      content.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      content.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      content.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
                    ).toList();

              if (filteredContent.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredContent.length,
                itemBuilder: (context, index) {
                  final content = filteredContent[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdminContentCard(
                      content: content,
                      onEdit: () => _editContent(content),
                      onDelete: () => _deleteContent(content),
                      onToggleStatus: () => _toggleContentStatus(content),
                    ).animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.2, end: 0),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return StreamBuilder<List<EducationCategory>>(
      stream: _educationService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Failed to load categories');
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.icon),
                    color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                  ),
                ),
                title: Text(
                  category.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${category.moduleCount} modules'),
                        const SizedBox(width: 12),
                        Text('${category.estimatedTime}'),
                        const SizedBox(width: 12),
                        Text(category.difficulty),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCategory(category);
                    } else if (value == 'delete') {
                      _deleteCategory(category);
                    }
                  },
                ),
              ),
            ).animate(delay: Duration(milliseconds: index * 100))
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Content Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some learning content to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddContentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
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
      default:
        return Icons.category;
    }
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddContentDialog(
        onContentAdded: () {
          setState(() {}); // Refresh the lists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Content added successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        },
      ),
    );
  }

  void _editContent(EducationContent content) {
    showDialog(
      context: context,
      builder: (context) => AddContentDialog(
        content: content,
        onContentAdded: () {
          setState(() {}); // Refresh the lists
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Content updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        },
      ),
    );
  }

  void _deleteContent(EducationContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Content'),
        content: Text('Are you sure you want to delete "${content.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _educationService.deleteContent(content.id);
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Content deleted successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete content: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleContentStatus(EducationContent content) async {
    try {
      await _educationService.toggleContentStatus(content.id, !content.isFeatured);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content status updated'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _editCategory(EducationCategory category) {
    // Implement category editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category editing coming soon!')),
    );
  }

  void _deleteCategory(EducationCategory category) {
    // Implement category deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category deletion coming soon!')),
    );
  }
}