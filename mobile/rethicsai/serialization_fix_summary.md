# Evidence File Serialization Fix

## 🚫 Problem: Exception: Failed to create incident: Invalid argument: Instance of '_$EvidenceFileImpl'

### Root Cause:
The error occurred because the `EvidenceFile` model contained a `Uint8List? fileBytes` field that **cannot be serialized to JSON/Firestore**. When Firestore tried to convert the object to JSON, it failed because `Uint8List` is not a supported Firestore data type.

## ✅ Solution: Separated File Upload Logic from Storage Model

### 1. **Created Separate File Upload Handler**
**New File: `lib/shared/models/file_upload_data.dart`**

```dart
/// Temporary class to hold file data for upload
/// This is NOT serialized to Firestore - only used during upload process
class FileUploadData {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final Uint8List fileBytes;  // ✅ Only exists during upload
  final DateTime uploadedAt;
  final String? description;
  
  // Convert to clean data for storage
  toEvidenceFile({String? fileData, String? filePath}) { ... }
}
```

### 2. **Cleaned Up EvidenceFile Model**
**File: `lib/shared/models/incident_model.dart`**

```dart
// REMOVED the problematic field:
// @JsonKey(includeFromJson: false, includeToJson: false) Uint8List? fileBytes, ❌

const factory EvidenceFile({
  required String id,
  @JsonKey(name: 'file_name') required String fileName,
  @JsonKey(name: 'file_type') required String fileType,
  @JsonKey(name: 'file_size') required int fileSize,
  @JsonKey(name: 'file_data') String? fileData,     // ✅ Serializable download URL
  @JsonKey(name: 'file_path') String? filePath,     // ✅ Serializable path
  @JsonKey(name: 'description') String? description, // ✅ Serializable text
  @JsonKey(name: 'uploaded_at') required DateTime uploadedAt, // ✅ Serializable
}) = _EvidenceFile;
```

### 3. **Updated Incident Service**
**File: `lib/core/services/incident_service.dart`**

```dart
// BEFORE: Tried to serialize fileBytes ❌
static Future<String> createIncident(
  Map<String, dynamic> incidentData, {
  List<EvidenceFile>? evidenceFiles,  // Had fileBytes - caused serialization error
}) async { ... }

// AFTER: Separate upload process ✅
static Future<String> createIncident(
  Map<String, dynamic> incidentData, {
  List<FileUploadData>? fileUploads,  // Only for upload process
}) async {
  // 1. Upload files to Firebase Storage using fileBytes
  List<EvidenceFile> uploadedFiles = [];
  if (fileUploads != null && fileUploads.isNotEmpty) {
    uploadedFiles = await _uploadFilesAndCreateEvidenceFiles(incidentId, fileUploads);
  }
  
  // 2. Create incident with clean EvidenceFile objects (no fileBytes)
  final incident = IncidentModel(..., evidenceFiles: uploadedFiles);
  
  // 3. Save to Firestore - no serialization issues!
  await _incidents.doc(incidentId).set(incident.toJson());
}
```

### 4. **Updated Form Submission**
**File: `lib/features/incidents/presentation/pages/incident_report_page.dart`**

```dart
// BEFORE: Created EvidenceFile with fileBytes ❌
evidenceFiles = _uploadedFiles.map((file) => EvidenceFile(
  fileBytes: file.bytes,  // Caused serialization error
  ...
)).toList();

// AFTER: Created temporary FileUploadData ✅
fileUploads = _uploadedFiles.map((file) => FileUploadData(
  fileBytes: file.bytes ?? Uint8List(0),  // Only for upload
  ...
)).toList();

// Submit with FileUploadData (not EvidenceFile)
final result = await IncidentService.createIncident(
  incidentData,
  fileUploads: fileUploads,  // ✅ No serialization to Firestore
);
```

### 5. **Upload Process Flow**
```
User selects files → PlatformFile with bytes
                   ↓
Create FileUploadData objects with fileBytes
                   ↓
Submit to IncidentService.createIncident()
                   ↓
Upload files to Firebase Storage using fileBytes
                   ↓
Create clean EvidenceFile objects with download URLs
                   ↓
Store EvidenceFile objects in Firestore (no fileBytes)
                   ✅ SUCCESS!
```

## 🔧 Technical Details

### Why the Error Occurred:
1. **Firestore Limitation**: Firestore cannot serialize `Uint8List`/binary data directly
2. **Freezed JSON Conversion**: When `incident.toJson()` was called, it tried to serialize the `fileBytes` field
3. **Invalid Argument**: Firestore rejected the `_$EvidenceFileImpl` instance because it contained non-serializable data

### How the Fix Works:
1. **Separation of Concerns**: Upload logic (with binary data) separate from storage model (serializable only)
2. **Clean Storage**: `EvidenceFile` only contains serializable fields (strings, numbers, dates)
3. **File Upload Process**: Binary data handled during upload, then replaced with download URLs
4. **Firestore Compatible**: All stored data is JSON-serializable

### Benefits:
- ✅ **No Serialization Errors**: EvidenceFile model is fully Firestore-compatible
- ✅ **Clean Architecture**: Clear separation between upload process and data storage
- ✅ **Better Performance**: No binary data stored in Firestore documents
- ✅ **Scalable**: Files stored in Firebase Storage, metadata in Firestore
- ✅ **Error Recovery**: Upload failures don't prevent incident submission

## 🧪 Testing Results

The form now successfully:
1. ✅ Accepts multiple file uploads (images, documents)
2. ✅ Uploads files to Firebase Storage
3. ✅ Creates incident with file metadata
4. ✅ Stores incident in Firestore without serialization errors
5. ✅ Displays cases in tracking page with file attachments
6. ✅ Handles upload failures gracefully

**Error Status**: ✅ **RESOLVED** - Form submits successfully with image attachments