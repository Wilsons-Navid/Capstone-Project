import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../education/presentation/models/education_models.dart';
import '../../../education/data/education_service.dart';

class AddContentDialog extends StatefulWidget {
  final EducationContent? content; // For editing
  final VoidCallback? onContentAdded;

  const AddContentDialog({
    super.key,
    this.content,
    this.onContentAdded,
  });

  @override
  State<AddContentDialog> createState() => _AddContentDialogState();
}

class _AddContentDialogState extends State<AddContentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _educationService = EducationService();
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _thumbnailController;
  late TextEditingController _durationController;
  late TextEditingController _videoUrlController;
  late TextEditingController _tagsController;
  late TextEditingController _articleContentController;
  
  String _selectedType = 'Interactive';
  String _selectedDifficulty = 'Beginner';
  String _selectedCategory = '';
  bool _isFeatured = false;
  bool _isLoading = false;

  final List<String> _contentTypes = ['Video', 'Article', 'Interactive', 'Quiz'];
  final List<String> _difficulties = ['Beginner', 'Essential', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingContent();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _thumbnailController = TextEditingController();
    _durationController = TextEditingController();
    _videoUrlController = TextEditingController();
    _tagsController = TextEditingController();
    _articleContentController = TextEditingController();
  }

  void _loadExistingContent() {
    if (widget.content != null) {
      final content = widget.content!;
      _titleController.text = content.title;
      _descriptionController.text = content.description;
      _thumbnailController.text = content.thumbnail;
      _durationController.text = content.duration.toString();
      _videoUrlController.text = content.videoUrl ?? '';
      _tagsController.text = content.tags.join(', ');
      _articleContentController.text = content.articleContent ?? '';
      _selectedType = content.type;
      _selectedDifficulty = content.difficulty;
      _selectedCategory = content.categoryId;
      _isFeatured = content.isFeatured;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _thumbnailController.dispose();
    _durationController.dispose();
    _videoUrlController.dispose();
    _tagsController.dispose();
    _articleContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.95,
          minHeight: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.content == null ? Icons.add_circle : Icons.edit,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.content == null ? 'Add Learning Content' : 'Edit Learning Content',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _buildSectionTitle('Basic Information'),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title',
                        hint: 'Enter content title',
                        required: true,
                      ),
                      
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Brief description of the content',
                        required: true,
                        maxLines: 3,
                      ),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _thumbnailController,
                              label: 'Thumbnail (Emoji)',
                              hint: '🔒',
                              required: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _durationController,
                              label: 'Duration (minutes)',
                              hint: '15',
                              required: true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      
                      // Content Settings
                      const SizedBox(height: 20),
                      _buildSectionTitle('Content Settings'),
                      
                      // Category Dropdown
                      StreamBuilder<List<EducationCategory>>(
                        stream: _educationService.getCategories(),
                        builder: (context, snapshot) {
                          final categories = snapshot.data ?? [];
                          if (_selectedCategory.isEmpty && categories.isNotEmpty) {
                            _selectedCategory = categories.first.id;
                          }
                          
                          return _buildDropdown(
                            label: 'Category',
                            value: _selectedCategory.isEmpty ? null : _selectedCategory,
                            items: categories.map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.title),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedCategory = value as String),
                          );
                        },
                      ),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Content Type',
                              value: _selectedType,
                              items: _contentTypes.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedType = value!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Difficulty',
                              value: _selectedDifficulty,
                              items: _difficulties.map((diff) => DropdownMenuItem(
                                value: diff,
                                child: Text(diff),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedDifficulty = value!),
                            ),
                          ),
                        ],
                      ),
                      
                      // Video URL (if video type)
                      if (_selectedType == 'Video') ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _videoUrlController,
                          label: 'YouTube Video URL',
                          hint: 'https://www.youtube.com/watch?v=...',
                          required: _selectedType == 'Video',
                        ),
                      ],
                      
                      // Article Content (if article/interactive type)
                      if (_selectedType == 'Article' || _selectedType == 'Interactive') ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _articleContentController,
                          label: 'Article Content (Markdown)',
                          hint: '# Title\n\nContent here...',
                          maxLines: 8,
                          required: _selectedType == 'Article' || _selectedType == 'Interactive',
                        ),
                      ],
                      
                      // Tags
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _tagsController,
                        label: 'Tags',
                        hint: 'Mobile Money, Scams, Africa (comma separated)',
                      ),
                      
                      // Featured toggle
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Switch(
                            value: _isFeatured,
                            onChanged: (value) => setState(() => _isFeatured = value),
                            activeColor: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('Featured Content'),
                          const Spacer(),
                          if (_isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveContent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.content == null ? 'Add Content' : 'Update Content'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primaryColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (value) => value?.isEmpty ?? true ? 'This field is required' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primaryColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  void _saveContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final contentData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'thumbnail': _thumbnailController.text,
        'duration': int.parse(_durationController.text),
        'difficulty': _selectedDifficulty,
        'type': _selectedType,
        'category_id': _selectedCategory,
        'tags': tags,
        'is_featured': _isFeatured,
      };

      // Add type-specific content
      if (_selectedType == 'Video' && _videoUrlController.text.isNotEmpty) {
        // Validate YouTube URL
        final videoId = YoutubePlayer.convertUrlToId(_videoUrlController.text);
        if (videoId == null) {
          throw 'Invalid YouTube URL';
        }
        contentData['video_url'] = _videoUrlController.text;
      }

      if ((_selectedType == 'Article' || _selectedType == 'Interactive') && 
          _articleContentController.text.isNotEmpty) {
        contentData['article_content'] = _articleContentController.text;
      }

      if (widget.content == null) {
        // Add new content
        contentData['id'] = 'content_${DateTime.now().millisecondsSinceEpoch}';
        await _educationService.addContent(contentData);
      } else {
        // Update existing content
        await _educationService.updateContent(widget.content!.id, contentData);
      }

      Navigator.pop(context);
      widget.onContentAdded?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}