# 🚀 Firebase Role Access Control - Setup Guide

## Quick Start - How to Access the Role Management System

### 🎯 **Step 1: Access the Database Setup Page**

The easiest way to get started is through the built-in setup utility:

**Method 1: Direct URL Navigation (Recommended)**
1. Run your Flutter app: `flutter run`
2. Navigate to: `/setup`
3. Or in your app, go to any page and manually navigate to the setup route

**Method 2: Programmatic Navigation**
```dart
Navigator.pushNamed(context, '/setup');
// Or using the router constant
Navigator.pushNamed(context, AppRouter.databaseSetup);
```

### 🔧 **Step 2: Initialize the Database**

Once on the setup page:

1. **Check Status** - The page will show your current database status
2. **Initialize Database** - Click "Initialize Database" to create collections
3. **Create Super Admin** - Fill in your details and click "Create Super Admin Account"

### 🔑 **Step 3: Access Role Management**

After creating your super admin account:

1. **Navigate to Admin Dashboard**: `/admin`
2. **Click on "User Management"** 
3. **Start managing user roles!**

---

## 📋 **Detailed Setup Process**

### **Prerequisites**
- ✅ Firebase project configured
- ✅ Firestore Database enabled
- ✅ Firebase Authentication enabled
- ✅ User logged into the app

### **What the Setup Does**

1. **Creates Required Collections:**
   - `users` - Main user profiles with roles
   - `user_roles` - Detailed role management with permissions
   - `role_history` - Audit trail of all role changes

2. **Sets Up Your Super Admin Account:**
   - Converts your current user to super_admin role
   - Grants all system permissions
   - Creates proper role management documents

3. **Optional Demo Data:**
   - Creates test users with different roles
   - Useful for testing the role management system

---

## 🎮 **Using the Role Management System**

### **For Super Admins**
- **Full Access** to all features
- **Bulk Operations**: Select multiple users and change roles
- **User Management**: Create, modify, deactivate users
- **System Administration**: Access to all admin features

### **For Admins**
- **Manage Users and Moderators** (cannot modify other admins)
- **View Analytics** and reports
- **Assign Cases** to officers
- **Access Role History**

### **Role Hierarchy**
1. **Super Admin** - Full system control
2. **Admin** - User management and analytics
3. **Moderator** - Content moderation and incident viewing
4. **User** - Basic incident reporting

---

## 🔒 **Security Features**

### **Firestore Security Rules**
- ✅ Permission-based access control
- ✅ Role hierarchy enforcement
- ✅ Protected admin operations
- ✅ Complete audit logging

### **UI Security**
- ✅ Dynamic menus based on user permissions
- ✅ Role-based navigation
- ✅ Action validation before execution

---

## 🛠️ **Manual Setup (Alternative)**

If you prefer to set up manually or need to create users programmatically:

### **1. Create First Super Admin via Firebase Console**

```javascript
// In Firestore Console, create document in 'users' collection
{
  "uid": "your-user-id",
  "email": "your-email@domain.com",
  "firstName": "Your",
  "lastName": "Name", 
  "role": "super_admin",
  "permissions": [
    "system_administration",
    "manage_users", 
    "change_user_roles",
    "view_analytics",
    "assign_cases",
    "moderate_content",
    "view_all_incidents",
    "delete_users",
    "backup_data",
    "submit_incident",
    "view_own_incidents", 
    "update_own_profile",
    "view_education_content"
  ],
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z",
  "isActive": true,
  "emailVerified": true
}
```

### **2. Create Role Management Document**

```javascript
// In Firestore Console, create document in 'user_roles' collection
{
  "user_id": "your-user-id",
  "email": "your-email@domain.com",
  "current_role": "super_admin",
  "previous_role": null,
  "assigned_by": "system",
  "assigned_at": "2024-01-01T00:00:00.000Z",
  "created_at": "2024-01-01T00:00:00.000Z", 
  "updated_at": "2024-01-01T00:00:00.000Z",
  "is_active": true,
  "permissions": [/* same as above */]
}
```

---

## 🧪 **Testing the System**

### **Quick Test Flow**
1. **Login** with your account
2. **Navigate to** `/setup`
3. **Initialize database** and create super admin
4. **Go to** `/admin` → User Management
5. **Test role changes** and bulk operations

### **Demo Users** 
The setup can create demo users for testing:
- `superadmin@rethicsai.com` (Super Admin)
- `admin@rethicsai.com` (Admin) 
- `moderator@rethicsai.com` (Moderator)
- `user@rethicsai.com` (User)

---

## 🎯 **Access Routes**

### **Main Routes**
- `/setup` - Database initialization
- `/admin` - Admin dashboard  
- `/admin/users` - User management
- `/profile` - User profile (shows current role)

### **Navigation Flow**
```
App Start → Login → Dashboard → Admin Panel → User Management
     ↓           ↓        ↓           ↓             ↓
   /login    /dashboard  /admin  /admin/users  [Role Management UI]
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

**1. "No users collection found"**
- Solution: Use the `/setup` page to initialize the database

**2. "Permission denied" when accessing admin features**  
- Solution: Ensure your user has admin or super_admin role in Firestore

**3. "Cannot access User Management"**
- Solution: Check that you have `manage_users` permission in your role

**4. "Bulk operations not visible"**
- Solution: Only super_admins can see bulk operations

### **Debug Steps**
1. Check Firebase Console → Firestore → `users` collection
2. Verify your user document has the correct `role` field
3. Check `user_roles` collection for detailed permissions
4. Use the setup page to view database status

---

## 📱 **UI Features**

### **User Management Page**
- **Color-coded roles** (each role has a distinct color)
- **Advanced filtering** (by role, active status)
- **Bulk operations** (super admin only)
- **Role history viewer** (complete audit trail)
- **Search functionality** (by name, email, role)
- **Quick actions menu** (edit, activate/deactivate, view history)

### **Role Selection Dialog**  
- **Visual hierarchy** with role descriptions
- **Permission preview** for each role
- **Validation** (only shows assignable roles)
- **Reason tracking** for audit purposes

---

## 🎉 **You're Ready!**

Once setup is complete:
1. ✅ Database collections created
2. ✅ Super admin account ready
3. ✅ Security rules active
4. ✅ Role management UI accessible

Navigate to `/admin/users` and start managing your user roles!

---

## 📞 **Need Help?**

If you encounter any issues:
1. Check the setup page at `/setup` for database status
2. Verify Firebase Console shows the collections
3. Ensure proper authentication and permissions
4. Use demo users to test functionality

The role management system is now fully operational! 🚀