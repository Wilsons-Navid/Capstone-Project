# 🔥 Firebase Security Rules - Emergency Update

## The Problem
Your app shows: `[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.`

This means your Firebase Firestore security rules are blocking the app from accessing the database.

## 🚨 **IMMEDIATE FIX - Firebase Console**

### **Step 1: Go to Firebase Console**
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your `rethics-d47fa` project
3. Click **"Firestore Database"** in the left menu
4. Click the **"Rules"** tab

### **Step 2: Temporary Rules (FOR TESTING ONLY)**
Replace your current rules with this **TEMPORARY** rule for testing:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // TEMPORARY: Allow all operations for testing
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### **Step 3: Publish Rules**
1. Click **"Publish"** button
2. Wait for rules to deploy (usually 1-2 minutes)
3. Try the app again

---

## 🛡️ **PROPER SECURITY RULES (After Testing)**

Once the users collection is created, replace with proper secure rules:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Helper function to check if user is super admin
    function isSuperAdmin() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // Helper function to check if user has admin privileges
    function hasAdminPrivileges() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin');
    }
    
    // Helper function to check if user has specific permission
    function hasPermission(permission) {
      return request.auth != null && 
             exists(/databases/$(database)/documents/user_roles/$(request.auth.uid)) &&
             permission in get(/databases/$(database)/documents/user_roles/$(request.auth.uid)).data.permissions;
    }
    
    // Users can read and write their own user documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Admins can read all user documents
      allow read: if hasAdminPrivileges();
      // Only super admins can write to other users' documents
      allow write: if isSuperAdmin();
      
      // Chat sessions - users can read/write their own chat history
      match /chatSessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        match /messages/{messageId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
    
    // Public threat intelligence data (read-only for authenticated users)
    match /threat_intelligence/{threatId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Suspicious content analysis results
    match /content_analysis/{analysisId} {
      allow read, write: if request.auth != null;
    }
    
    // Admin-only collections
    match /admin/{document=**} {
      allow read, write: if request.auth != null && 
                            exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Main incidents collection (authenticated users can create/read, admins can modify)
    match /incidents/{incidentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       (resource.data.userId == request.auth.uid || 
                        isAdmin());
      allow delete: if request.auth != null && isAdmin();
    }
    
    // Cases collection (for case tracking)
    match /cases/{caseId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       (resource.data.userId == request.auth.uid || 
                        isAdmin());
      allow delete: if request.auth != null && isAdmin();
    }
    
    // Global incidents (public reports for admin review)
    match /global_incidents/{incidentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && isAdmin();
      allow delete: if request.auth != null && isAdmin();
    }
    
    // Education content (read-only for authenticated users)
    match /education_content/{contentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Cyber insights (read-only, updated by Cloud Functions)
    match /cyber_insights/{insightId} {
      allow read: if request.auth != null;
      // Only Cloud Functions can write insights
      allow write: if false;
    }
    
    // Role management collections
    match /user_roles/{userId} {
      // Users can read their own role info
      allow read: if request.auth != null && request.auth.uid == userId;
      // Admins can read all role documents
      allow read: if hasPermission('manage_users') || hasPermission('view_analytics');
      // Only users with change_user_roles permission can write
      allow write: if hasPermission('change_user_roles');
    }
    
    match /role_history/{historyId} {
      // Only users with manage_users permission can read role history
      allow read: if hasPermission('manage_users') || hasPermission('view_analytics');
      // Only users with change_user_roles permission can write role history
      allow write: if hasPermission('change_user_roles');
    }
    
    // Bulk operations audit log (super admin only)
    match /bulk_operations/{operationId} {
      allow read, write: if isSuperAdmin();
    }
  }
}
```

---

## 🔄 **QUICK TEST STEPS**

1. **Update rules to temporary version above**
2. **Wait 2 minutes for rules to deploy**
3. **Open your app on phone**
4. **Try the "Setup Database" button again**
5. **It should work now!**

---

## ⚠️ **IMPORTANT SECURITY NOTE**

The temporary rules (`allow read, write: if request.auth != null;`) give access to ALL authenticated users. This is ONLY for initial setup. Replace with proper rules after creating your admin account!

---

## 🔍 **Alternative: Manual Collection Creation**

If you prefer not to change rules, you can manually create the users collection in Firebase Console:

### **Step 1: Create Users Collection**
1. Go to Firestore Database → Data tab
2. Click "Start collection"
3. Collection ID: `users`
4. Document ID: Use your Firebase Auth UID
5. Add these fields:
   ```
   uid: "your-user-id"
   email: "your@email.com"
   firstName: "Your"
   lastName: "Name"
   role: "super_admin"
   permissions: ["system_administration", "manage_users", "change_user_roles", ...]
   createdAt: (current timestamp)
   isActive: true
   ```

### **Step 2: Create Role Management Collections**
Create `user_roles` and `role_history` collections similarly.

---

## 🎯 **Next Steps After Fix**

1. ✅ Update Firebase rules (temporary or permanent)
2. ✅ Test app setup again
3. ✅ Create your super admin account
4. ✅ Replace with secure rules
5. ✅ Start managing user roles!

The permission error will be fixed once you update the Firebase security rules! 🚀