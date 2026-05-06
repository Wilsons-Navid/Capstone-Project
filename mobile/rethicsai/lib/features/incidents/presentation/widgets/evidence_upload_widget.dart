import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/models/incident_model.dart';

class EvidenceUploadWidget extends StatefulWidget {
  final List<EvidenceFile> evidenceFiles;
  final Function(List<EvidenceFile>) onFilesChanged;

  const EvidenceUploadWidget({
    super.key,
    required this.evidenceFiles,
    required this.onFilesChanged,
  });

  @override
  State<EvidenceUploadWidget> createState() => _EvidenceUploadWidgetState();
}

class _EvidenceUploadWidgetState extends State<EvidenceUploadWidget> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upload area
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload evidence',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Screenshots, documents, videos, etc.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Uploaded files list
        if (widget.evidenceFiles.isNotEmpty) ...[
          Text(
            'Uploaded Evidence (${widget.evidenceFiles.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.evidenceFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _buildFileItem(file, index);
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildFileItem(EvidenceFile file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(file.fileName),
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(file.fileSize),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(index),
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.errorColor,
              size: 20,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.3, end: 0);
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFiles() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = <EvidenceFile>[];
        
        for (final platformFile in result.files) {
          if (platformFile.bytes != null) {
            final base64Data = base64Encode(platformFile.bytes!);
            final evidenceFile = EvidenceFile(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: platformFile.name,
              fileType: platformFile.extension ?? 'unknown',
              fileSize: platformFile.size,
              fileData: base64Data,
              uploadedAt: DateTime.now(),
            );
            newFiles.add(evidenceFile);
          }
        }

        if (newFiles.isNotEmpty) {
          final updatedFiles = [...widget.evidenceFiles, ...newFiles];
          widget.onFilesChanged(updatedFiles);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload files: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeFile(int index) {
    final updatedFiles = List<EvidenceFile>.from(widget.evidenceFiles);
    updatedFiles.removeAt(index);
    widget.onFilesChanged(updatedFiles);
  }
}