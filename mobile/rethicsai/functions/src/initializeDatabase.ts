import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to initialize the database with users collection
 * This bypasses Firestore security rules since it runs with admin privileges
 */
export const initializeDatabase = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = context.auth.uid;
    const email = context.auth.token.email || '';
    
    console.log(`Initializing database for user: ${uid}, email: ${email}`);

    // Check if users collection already exists
    const usersSnapshot = await db.collection('users').limit(1).get();
    
    if (usersSnapshot.empty) {
      console.log('Users collection is empty, creating initial data...');
      
      // Create the current user as super admin
      const userData = {
        uid: uid,
        email: email,
        firstName: data.firstName || 'Super',
        lastName: data.lastName || 'Admin',
        phoneNumber: data.phoneNumber || null,
        country: data.country || null,
        role: 'super_admin',
        permissions: [
          'system_administration',
          'manage_users',
          'change_user_roles',
          'view_analytics',
          'assign_cases',
          'moderate_content',
          'view_all_incidents',
          'delete_users',
          'backup_data',
          'submit_incident',
          'view_own_incidents',
          'update_own_profile',
          'view_education_content'
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        emailVerified: context.auth.token.email_verified || false,
      };

      // Create user document
      await db.collection('users').doc(uid).set(userData);
      console.log(`Created user document for ${email}`);

      // Create role management document
      const roleData = {
        user_id: uid,
        email: email,
        current_role: 'super_admin',
        previous_role: null,
        assigned_by: 'system',
        assigned_at: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        is_active: true,
        permissions: userData.permissions,
      };

      await db.collection('user_roles').doc(uid).set(roleData);
      console.log(`Created role document for ${email}`);

      // Create role history entry
      const historyData = {
        user_id: uid,
        email: email,
        action: 'role_assigned',
        from_role: null,
        to_role: 'super_admin',
        assigned_by: 'system',
        timestamp: new Date().toISOString(),
        reason: 'Initial super admin setup via Cloud Function',
      };

      await db.collection('role_history').add(historyData);
      console.log(`Created role history entry for ${email}`);

      return {
        success: true,
        message: 'Database initialized successfully',
        user: {
          uid: uid,
          email: email,
          role: 'super_admin'
        }
      };
    } else {
      // Users collection exists, just upgrade current user to super admin
      console.log('Users collection exists, upgrading current user to super admin...');
      
      const userRef = db.collection('users').doc(uid);
      const userDoc = await userRef.get();
      
      const userData: Record<string, any> = {
        uid: uid,
        email: email,
        role: 'super_admin',
        permissions: [
          'system_administration',
          'manage_users',
          'change_user_roles',
          'view_analytics',
          'assign_cases',
          'moderate_content',
          'view_all_incidents',
          'delete_users',
          'backup_data',
          'submit_incident',
          'view_own_incidents',
          'update_own_profile',
          'view_education_content'
        ],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
      };

      if (userDoc.exists) {
        // Update existing user
        await userRef.update(userData);
        console.log(`Updated existing user ${email} to super_admin`);
      } else {
        // Create new user
        userData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        userData.firstName = data.firstName || 'Super';
        userData.lastName = data.lastName || 'Admin';
        userData.phoneNumber = data.phoneNumber || null;
        userData.country = data.country || null;
        userData.emailVerified = context.auth.token.email_verified || false;
        
        await userRef.set(userData);
        console.log(`Created new user ${email} as super_admin`);
      }

      // Update/create role management document
      const roleData = {
        user_id: uid,
        email: email,
        current_role: 'super_admin',
        assigned_by: 'system',
        assigned_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        is_active: true,
        permissions: userData.permissions,
      };

      await db.collection('user_roles').doc(uid).set(roleData, { merge: true });
      console.log(`Updated role document for ${email}`);

      return {
        success: true,
        message: 'User upgraded to super admin successfully',
        user: {
          uid: uid,
          email: email,
          role: 'super_admin'
        }
      };
    }

  } catch (error) {
    console.error('Error initializing database:', error);
    throw new functions.https.HttpsError('internal', 'Failed to initialize database', error);
  }
});

/**
 * Create demo users for testing (super admin only)
 */
export const createDemoUsers = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    // Check if current user is super admin
    const currentUserDoc = await db.collection('users').doc(context.auth.uid).get();
    if (!currentUserDoc.exists || currentUserDoc.data()?.role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can create demo users');
    }

    const demoUsers = [
      {
        uid: 'demo_admin',
        email: 'admin@rethicsai.com',
        firstName: 'Demo',
        lastName: 'Admin',
        role: 'admin',
      },
      {
        uid: 'demo_moderator', 
        email: 'moderator@rethicsai.com',
        firstName: 'Demo',
        lastName: 'Moderator',
        role: 'moderator',
      },
      {
        uid: 'demo_user',
        email: 'user@rethicsai.com', 
        firstName: 'Demo',
        lastName: 'User',
        role: 'user',
      },
    ];

    const rolePermissions = {
      'user': [
        'submit_incident',
        'view_own_incidents',
        'update_own_profile',
        'view_education_content',
      ],
      'moderator': [
        'submit_incident',
        'view_own_incidents',
        'update_own_profile',
        'view_education_content',
        'moderate_content',
        'view_all_incidents',
      ],
      'admin': [
        'submit_incident',
        'view_own_incidents',
        'update_own_profile',
        'view_education_content',
        'moderate_content',
        'view_all_incidents',
        'assign_cases',
        'manage_users',
        'view_analytics',
        'change_user_roles',
      ],
    };

    const batch = db.batch();
    
    for (const user of demoUsers) {
      // Create user document
      const userRef = db.collection('users').doc(user.uid);
      batch.set(userRef, {
        ...user,
        permissions: (rolePermissions as Record<string, string[]>)[user.role] || rolePermissions.user,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        emailVerified: true,
        isDemoUser: true,
      });

      // Create role management document
      const roleRef = db.collection('user_roles').doc(user.uid);
      batch.set(roleRef, {
        user_id: user.uid,
        email: user.email,
        current_role: user.role,
        previous_role: null,
        assigned_by: context.auth.uid,
        assigned_at: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        is_active: true,
        permissions: (rolePermissions as Record<string, string[]>)[user.role] || rolePermissions.user,
      });
    }

    await batch.commit();
    console.log(`Created ${demoUsers.length} demo users`);

    return {
      success: true,
      message: `Created ${demoUsers.length} demo users successfully`,
      users: demoUsers.map(u => ({ uid: u.uid, email: u.email, role: u.role }))
    };

  } catch (error) {
    console.error('Error creating demo users:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create demo users', error);
  }
});