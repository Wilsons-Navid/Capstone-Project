import 'dart:typed_data';

/// Temporary class to hold file data for upload
/// This is not serialized to Firestore - only used during upload process
class FileUploadData {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final Uint8List fileBytes;
  final DateTime uploadedAt;
  final String? description;

  const FileUploadData({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileBytes,
    required this.uploadedAt,
    this.description,
  });

  /// Convert to EvidenceFile for storage (without fileBytes)
  toEvidenceFile({
    String? fileData,
    String? filePath,
    String? description,
  }) {
    return {
      'id': id,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileData': fileData,
      'filePath': filePath,
      'description': description ?? this.description,
      'uploadedAt': uploadedAt,
    };
  }
}