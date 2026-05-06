# Incident Submission & Tracking Debug Flow

## ✅ Fixed Issues

### 1. **User Email Capture**
- **Before**: Hardcoded `'contact_details': 'user@example.com'`
- **After**: Uses `FirebaseAuth.instance.currentUser.email`
- **Location**: `lib/features/incidents/presentation/pages/incident_report_page.dart:495`

### 2. **User Profile Integration**
- **Added**: Dynamic loading of user profile data
- **Fields**: `reporter_name`, `reporter_phone`, `reporter_country`
- **Location**: `lib/features/incidents/presentation/pages/incident_report_page.dart:62-77`

### 3. **Firestore Field Mapping**
- **Updated**: IncidentModel with additional reporter fields
- **Location**: `lib/shared/models/incident_model.dart:32-34`
- **Fields Added**:
  ```dart
  @JsonKey(name: 'reporter_name') String? reporterName,
  @JsonKey(name: 'reporter_phone') String? reporterPhone,
  @JsonKey(name: 'reporter_country') String? reporterCountry,
  ```

### 4. **Service Layer Updates**
- **Enhanced**: `IncidentService.createIncident()` method
- **Location**: `lib/core/services/incident_service.dart:39-98`
- **Changes**:
  - Captures actual user email and profile data
  - Explicit `user_id` field mapping
  - Better error handling and fallback queries

### 5. **Case Tracking Improvements**
- **Enhanced**: `getUserIncidents()` method with fallback queries
- **Location**: `lib/core/services/incident_service.dart:220-263`
- **Features**:
  - Handles missing Firestore indexes gracefully
  - Better error parsing and logging
  - Sorts by creation date client-side

## 🔧 Technical Details

### Authentication Flow:
```dart
// 1. Check authentication
_currentUser = FirebaseAuth.instance.currentUser;
if (_currentUser == null) {
  // Redirect to login
}

// 2. Load user profile
_userProfile = await UserService.getUserProfile(_currentUser!.uid);

// 3. Use real data in submission
final userEmail = _currentUser!.email ?? 'no-email@rethicsai.com';
final userName = _userProfile != null 
    ? '${_userProfile!['firstName']} ${_userProfile!['lastName']}'
    : _currentUser!.displayName ?? 'Anonymous User';
```

### Firestore Document Structure:
```json
{
  "id": "auto-generated",
  "user_id": "firebase-auth-uid",
  "case_number": "RET20240122001",
  "contact_details": "user@actual-email.com",
  "reporter_name": "John Doe",
  "reporter_phone": "+234 801 234 5678",
  "reporter_country": "Nigeria",
  "title": "Incident Title",
  "description": "Incident Description",
  "incident_type": "Mobile Money Scam",
  "priority_level": "Medium",
  "status": "Submitted",
  "created_at": "2024-01-22T10:30:00.000Z",
  "updated_at": "2024-01-22T10:30:00.000Z"
}
```

### Query Pattern:
```dart
// Primary query with ordering
_incidents
  .where('user_id', isEqualTo: userId)
  .orderBy('created_at', descending: true)

// Fallback query without ordering
_incidents
  .where('user_id', isEqualTo: userId)
```

## 🧪 Testing Checklist

### Profile Page:
- [ ] Displays current user's name and email
- [ ] Shows real statistics from user's incidents
- [ ] Updates profile data successfully
- [ ] Handles missing profile data gracefully

### Incident Reporting:
- [ ] Captures user's actual email
- [ ] Saves user profile information
- [ ] Creates proper case number (RET format)
- [ ] Redirects to case tracking after submission
- [ ] Shows confirmation with user email

### Case Tracking:
- [ ] Shows only current user's cases
- [ ] Displays real case data from Firestore
- [ ] Handles empty state properly
- [ ] Updates when new cases are submitted
- [ ] Shows proper case details in modal

### Firestore Data:
- [ ] Documents have correct `user_id` field
- [ ] Reporter information is captured
- [ ] Status values are consistent
- [ ] Timestamps are properly formatted

## 🚀 Key Improvements

1. **Real User Data**: No more hardcoded emails or names
2. **Better Error Handling**: Graceful fallbacks for missing data
3. **Improved UX**: Clear confirmation messages with user email
4. **Data Consistency**: Proper field mapping between frontend and Firestore
5. **Authentication Checks**: Proper user validation before operations

The incident submission and tracking system now properly captures and displays real user data, ensuring that users can submit incidents with their actual email addresses and track their own cases effectively.