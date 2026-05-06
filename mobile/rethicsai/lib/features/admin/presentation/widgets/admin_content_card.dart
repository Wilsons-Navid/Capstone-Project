import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../education/presentation/models/education_models.dart';

class AdminContentCard extends StatelessWidget {
  final EducationContent content;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const AdminContentCard({
    super.key,
    required this.content,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Header with thumbnail and basic info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getContentTypeColor().withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: content.videoUrl != null ? _buildVideoThumbnail() : _buildDefaultThumbnail(),
                ),
                
                const SizedBox(width: 12),
                
                // Content info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              content.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (content.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        content.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Metadata
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: _getContentTypeIcon(),
                            label: content.type,
                            color: _getContentTypeColor(),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.timer_outlined,
                            label: '${content.duration} min',
                            color: Colors.grey[600]!,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.signal_cellular_alt,
                            label: content.difficulty,
                            color: _getDifficultyColor(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Tags
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: content.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle Featured Status
                    IconButton(
                      onPressed: onToggleStatus,
                      icon: Icon(
                        content.isFeatured ? Icons.star : Icons.star_outline,
                        color: content.isFeatured ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      tooltip: content.isFeatured ? 'Remove from featured' : 'Add to featured',
                    ),
                    
                    // Edit
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      tooltip: 'Edit content',
                    ),
                    
                    // Delete
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'Delete content',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    final videoId = YoutubePlayer.convertUrlToId(content.videoUrl!);
    if (videoId == null) return _buildDefaultThumbnail();

    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Image.network(
            thumbnailUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getContentTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            content.thumbnail,
            style: const TextStyle(fontSize: 20),
          ),
          Icon(
            _getContentTypeIcon(),
            color: _getContentTypeColor(),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getContentTypeColor() {
    switch (content.type.toLowerCase()) {
      case 'video':
        return Colors.red;
      case 'article':
        return Colors.blue;
      case 'interactive':
        return Colors.green;
      case 'quiz':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getContentTypeIcon() {
    switch (content.type.toLowerCase()) {
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

  Color _getDifficultyColor() {
    switch (content.difficulty.toLowerCase()) {
      case 'beginner':
      case 'essential':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}