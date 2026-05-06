# Firestore Index Setup

## Required Index for User Activities Query

The application requires a composite index for the `user_activities` collection to support queries with multiple order conditions.

### Index Details:
- **Collection**: `user_activities`
- **Fields**:
  1. `userId` (Ascending)
  2. `timestamp` (Descending)
  3. `__name__` (Descending)

### How to Create:

1. **Automatic Creation** (Recommended):
   - Run the app and trigger the query that needs the index
   - Click on the Firebase console URL provided in the error message:
     ```
     https://console.firebase.google.com/v1/r/project/rethics-d47fa/firestore/indexes?create_composite=...
     ```

2. **Manual Creation**:
   - Go to [Firebase Console](https://console.firebase.google.com/project/rethics-d47fa/firestore/indexes)
   - Navigate to Firestore → Indexes
   - Click "Create Index"
   - Select collection: `user_activities`
   - Add fields in this order:
     - `userId`: Ascending
     - `timestamp`: Descending
     - `__name__`: Descending

### Query Pattern:
This index supports queries like:
```javascript
db.collection('user_activities')
  .where('userId', '==', 'USER_ID')
  .orderBy('timestamp', 'desc')
  .orderBy('__name__', 'desc')
  .limit(10)
```

### Development Note:
This is a normal development workflow. Firestore automatically detects the need for composite indexes when running complex queries and provides the creation URL in error messages.

The application will work perfectly once this index is created. The index typically takes a few minutes to build depending on the amount of data.