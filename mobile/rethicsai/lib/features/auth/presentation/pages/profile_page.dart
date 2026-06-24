import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';
import '../../../../shared/widgets/premium_animations.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../shared/models/activity_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_form_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for editable fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  
  UserModel? _currentUser;
  Map<String, dynamic> _userStats = {};
  String? _profileImageUrl;
  
  // Settings state variables
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _securityAlerts = true;
  bool _profileVisibility = false;
  bool _locationServices = true;
  bool _analyticsReports = true;
  bool _marketingCommunications = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
    _initializeThemeState();
  }
  
  void _initializeThemeState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      
      // Wait for ThemeProvider to be initialized
      if (!themeProvider.isInitialized) {
        // Retry after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _initializeThemeState();
        });
        return;
      }
      
      setState(() {
        _darkMode = themeProvider.isDarkMode;
      });
    });
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      setState(() => _isLoadingProfile = true);
      
      // Get user profile from Firestore
      final profileData = await UserService.getUserProfile(user.uid);
      
      if (profileData != null) {
        _currentUser = UserModel.fromJson({
          'id': user.uid,
          'email': user.email ?? '',
          'firstName': profileData['firstName'] ?? '',
          'lastName': profileData['lastName'] ?? '',
          'phoneNumber': profileData['phoneNumber'],
          'country': profileData['country'],
          'language': profileData['language'] ?? 'en',
          'isEmailVerified': user.emailVerified,
          'isVerified': profileData['isVerified'] ?? false,
          'isAdmin': profileData['role'] == 'admin',
          'createdAt': profileData['createdAt']?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
          'updatedAt': profileData['updatedAt']?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
        });
        // Load base64 image from Firestore if available
        if (profileData['profileImageBase64'] != null) {
          final base64Image = profileData['profileImageBase64'] as String;
          final imageType = profileData['profileImageType'] ?? 'image/jpeg';
          _profileImageUrl = 'data:$imageType;base64,$base64Image';
        } else {
          // Fallback to old profileImageUrl for backward compatibility
          _profileImageUrl = profileData['profileImageUrl'];
        }
        
        // Load user settings/preferences
        _loadUserSettings(profileData);
      } else {
        // Create basic user model from Firebase Auth
        _currentUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          firstName: user.displayName?.split(' ').first ?? 'User',
          lastName: user.displayName?.split(' ').last ?? '',
          isEmailVerified: user.emailVerified,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      // Load user statistics
      await _loadUserStats();
      _initializeControllers();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadUserStats() async {
    if (_currentUser == null) return;
    
    try {
      final incidents = await IncidentService.getUserIncidents(_currentUser!.id);
      final resolvedCases = incidents.where((i) => i.status == 'Resolved').length;
      final activeCases = incidents.where((i) => i.status != 'Resolved').length;
      
      setState(() {
        _userStats = {
          'reportsField': incidents.length,
          'resolvedCases': resolvedCases,
          'activeCases': activeCases,
          'threatsBlocked': (incidents.length * 3.5).round(), // Estimated
          'memberSince': _currentUser!.createdAt.year.toString(),
        };
      });
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  void _initializeControllers() {
    if (_currentUser == null) return;
    _firstNameController.text = _currentUser!.firstName;
    _lastNameController.text = _currentUser!.lastName;
    _phoneController.text = _currentUser!.phoneNumber ?? '';
    _emailController.text = _currentUser!.email;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile || _currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Loading profile...', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: const AfricanPatternBackground(opacity: 0.02),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),
                
                // Tab Bar
                _buildTabBar(),
                
                // Tab View Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(),
                      _buildSecurityTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXL),
          bottomRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              const Spacer(),
              Text(
                'My Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleEditing,
                icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildProfileHeader(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Avatar
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: AppTheme.elevationL,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isUploadingImage
                  ? const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : _profileImageUrl != null
                      ? CircleAvatar(
                          radius: 47,
                          backgroundImage: _getImageProvider(_profileImageUrl!),
                          backgroundColor: AppTheme.saharaGold,
                        )
                      : CircleAvatar(
                          radius: 47,
                          backgroundColor: AppTheme.saharaGold,
                          child: Text(
                            _currentUser!.firstName.isNotEmpty && _currentUser!.lastName.isNotEmpty 
                              ? '${_currentUser!.firstName[0]}${_currentUser!.lastName[0]}'
                              : _currentUser!.email.isNotEmpty ? _currentUser!.email[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _changeProfilePicture,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          '${_currentUser!.firstName} ${_currentUser!.lastName}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentUser!.isVerified) ...[
              const Icon(Icons.verified, color: AppTheme.saharaGold, size: 16),
              const SizedBox(width: AppTheme.spacingXS),
            ],
            Text(
              _currentUser!.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Profile', icon: Icon(Icons.person, size: 16)),
          Tab(text: 'Security', icon: Icon(Icons.security, size: 16)),
          Tab(text: 'Settings', icon: Icon(Icons.settings, size: 16)),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlideReveal(
              delay: const Duration(milliseconds: 100),
              child: _buildPersonalInfoSection(),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            SlideReveal(
              delay: const Duration(milliseconds: 200),
              child: _buildAccountStatsSection(),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            SlideReveal(
              delay: const Duration(milliseconds: 300),
              child: _buildVerificationSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: AuthFormField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  prefixIcon: Icons.person,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: AuthFormField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  prefixIcon: Icons.person_outline,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          AuthFormField(
            controller: _emailController,
            labelText: 'Email Address',
            prefixIcon: Icons.email,
            enabled: false, // Email should not be editable
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppTheme.spacingL),
          AuthFormField(
            controller: _phoneController,
            labelText: 'Phone Number',
            prefixIcon: Icons.phone,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildCountrySelector(),
        ],
      ),
    );
  }

  Widget _buildCountrySelector() {
    return GestureDetector(
      onTap: _isEditing ? _showCountryPicker : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag, color: AppTheme.primaryColor),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Country',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    _currentUser!.country ?? 'Nigeria',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (_isEditing)
              const Icon(Icons.arrow_drop_down, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatsSection() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(child: _buildStatItem('Reports Filed', _userStats['reportsField']?.toString() ?? '0', Icons.report_problem, AppTheme.warningColor)),
              Expanded(child: _buildStatItem('Cases Resolved', _userStats['resolvedCases']?.toString() ?? '0', Icons.check_circle, AppTheme.successColor)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(child: _buildStatItem('Threats Blocked', _userStats['threatsBlocked']?.toString() ?? '0', Icons.security, AppTheme.primaryColor)),
              Expanded(child: _buildStatItem('Member Since', _userStats['memberSince'] ?? DateTime.now().year.toString(), Icons.calendar_today, AppTheme.infoColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      margin: const EdgeInsets.all(AppTheme.spacingXS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppTheme.iconSizeL),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Verification',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildVerificationItem(
            'Email Verified',
            _currentUser!.isEmailVerified,
            Icons.email,
            'Your email address has been verified',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildVerificationItem(
            'Identity Verified',
            _currentUser!.isVerified,
            Icons.verified_user,
            'Your identity has been verified by our security team',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildVerificationItem(
            'Two-Factor Auth',
            false,
            Icons.security,
            'Enable 2FA for enhanced security',
            showAction: true,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String title, bool isVerified, IconData icon, String description, {bool showAction = false}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isVerified ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isVerified ? AppTheme.successColor.withOpacity(0.3) : AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isVerified ? AppTheme.successColor : AppTheme.warningColor,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (showAction && !isVerified)
            TextButton(
              onPressed: () {
                // Implement 2FA setup
                _showComingSoonDialog('Two-Factor Authentication setup');
              },
              child: const Text('Setup'),
            )
          else
            Icon(
              isVerified ? Icons.check_circle : Icons.pending,
              color: isVerified ? AppTheme.successColor : AppTheme.warningColor,
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          SlideReveal(
            delay: const Duration(milliseconds: 100),
            child: _buildSecurityOverview(),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          SlideReveal(
            delay: const Duration(milliseconds: 200),
            child: _buildRecentActivity(),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          SlideReveal(
            delay: const Duration(milliseconds: 300),
            child: _buildSecurityActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOverview() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                'Security Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Colors.white, size: AppTheme.iconSizeXL),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Score',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        '85% Secure',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                AfricanStatusIndicator(
                  status: 'Good',
                  color: AppTheme.saharaGold,
                  showPulse: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Security Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildActivityItem(
            'Login from new device',
            'Lagos, Nigeria - 2 hours ago',
            Icons.devices,
            AppTheme.warningColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildActivityItem(
            'Password changed',
            'Successfully updated - 1 day ago',
            Icons.lock,
            AppTheme.successColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildActivityItem(
            'Suspicious login blocked',
            'Unknown location - 3 days ago',
            Icons.block,
            AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityActions() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          PremiumButton(
            text: 'Change Password',
            icon: Icons.lock_reset,
            onPressed: () => _showChangePasswordDialog(),
            width: double.infinity,
          ),
          const SizedBox(height: AppTheme.spacingM),
          PremiumButton(
            text: 'Enable Two-Factor Authentication',
            icon: Icons.security,
            onPressed: () => _showComingSoonDialog('Two-Factor Authentication'),
            gradient: AppTheme.accentGradient,
            width: double.infinity,
          ),
          const SizedBox(height: AppTheme.spacingM),
          OutlinedButton.icon(
            onPressed: () => _downloadSecurityReport(),
            icon: const Icon(Icons.download),
            label: const Text('Download Security Report'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          SlideReveal(
            delay: const Duration(milliseconds: 100),
            child: _buildNotificationSettings(),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          SlideReveal(
            delay: const Duration(milliseconds: 150),
            child: _buildAppearanceSettings(),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          SlideReveal(
            delay: const Duration(milliseconds: 200),
            child: _buildPrivacySettings(),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          SlideReveal(
            delay: const Duration(milliseconds: 300),
            child: _buildAccountActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildSwitchTile('Push Notifications', _pushNotifications, Icons.notifications, (value) {
            setState(() => _pushNotifications = value);
            _updateNotificationSetting('pushNotifications', value);
          }),
          _buildSwitchTile('Email Notifications', _emailNotifications, Icons.email, (value) {
            setState(() => _emailNotifications = value);
            _updateNotificationSetting('emailNotifications', value);
          }),
          _buildSwitchTile('SMS Notifications', _smsNotifications, Icons.sms, (value) {
            setState(() => _smsNotifications = value);
            _updateNotificationSetting('smsNotifications', value);
          }),
          _buildSwitchTile('Security Alerts', _securityAlerts, Icons.security, (value) {
            setState(() => _securityAlerts = value);
            _updateNotificationSetting('securityAlerts', value);
          }),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildSwitchTile('Dark Mode', _darkMode, Icons.dark_mode, (value) async {
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            await themeProvider.toggleDarkMode(value);
            setState(() => _darkMode = value);
            _updateAppearanceSetting('darkMode', value);
          }),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildSwitchTile('Profile Visibility', _profileVisibility, Icons.visibility, (value) {
            setState(() => _profileVisibility = value);
            _updatePrivacySetting('profileVisibility', value);
          }),
          _buildSwitchTile('Location Services', _locationServices, Icons.location_on, (value) {
            setState(() => _locationServices = value);
            _updatePrivacySetting('locationServices', value);
          }),
          _buildSwitchTile('Analytics & Crash Reports', _analyticsReports, Icons.analytics, (value) {
            setState(() => _analyticsReports = value);
            _updatePrivacySetting('analyticsReports', value);
          }),
          _buildSwitchTile('Marketing Communications', _marketingCommunications, Icons.campaign, (value) {
            setState(() => _marketingCommunications = value);
            _updatePrivacySetting('marketingCommunications', value);
          }),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ListTile(
            leading: const Icon(Icons.download, color: AppTheme.primaryColor),
            title: const Text('Export My Data'),
            subtitle: const Text('Download a copy of your data'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDataExportDialog(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDeleteAccountDialog(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.warningColor),
            title: const Text('Sign Out'),
            subtitle: const Text('Sign out of your account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, IconData icon, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: AppTheme.iconSizeM),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.selectionClick();
              onChanged(newValue);
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
    
    if (!_isEditing) {
      _saveProfile();
    }
    
    HapticFeedback.mediumImpact();
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false && _currentUser != null) {
      setState(() => _isLoading = true);
      
      try {
        final updateData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        };
        
        await UserService.updateUserProfile(_currentUser!.id, updateData);
        
        // Record activity
        await ActivityService.recordProfileActivity(
          action: 'profile_information_updated',
          details: 'Profile information updated successfully',
        );
        
        // Update local user model
        _currentUser = UserModel(
          id: _currentUser!.id,
          email: _currentUser!.email,
          firstName: updateData['firstName'] as String,
          lastName: updateData['lastName'] as String,
          phoneNumber: updateData['phoneNumber'] as String?,
          country: _currentUser!.country,
          language: _currentUser!.language,
          isEmailVerified: _currentUser!.isEmailVerified,
          isVerified: _currentUser!.isVerified,
          isAdmin: _currentUser!.isAdmin,
          createdAt: _currentUser!.createdAt,
          updatedAt: DateTime.now(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (_profileImageUrl != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Remove Picture', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    if (_currentUser == null) return;
    
    setState(() => _isUploadingImage = true);
    
    try {
      // Get the current Firebase Auth user
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }

      // Use Firebase Auth UID as the user ID
      final userId = authUser.uid;
      
      LoggingService.info('ProfilePage', 'Starting image upload for user: $userId');
      
      // Read image file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Convert to base64 string
      final String base64Image = base64Encode(imageBytes);
      
      LoggingService.info('ProfilePage', 'Image converted to base64. Size: ${imageBytes.length} bytes');
      
      // Ensure user document exists before updating
      await _ensureUserDocumentExists(userId, authUser);
      
      // Update user profile in Firestore with base64 image data
      await _updateUserProfileWithRetry(userId, {
        'profileImageBase64': base64Image,
        'profileImageType': 'image/jpeg',
        'profileImageUploadTime': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      LoggingService.info('ProfilePage', 'Image uploaded successfully to Firestore');
      
      // Record activity
      await ActivityService.recordProfileActivity(
        action: 'profile_picture_uploaded',
        details: 'Profile picture updated successfully',
      );
      
      // Update local state with base64 data URL
      final dataUrl = 'data:image/jpeg;base64,$base64Image';
      setState(() {
        _profileImageUrl = dataUrl;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile picture updated successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e, stackTrace) {
      LoggingService.error('ProfilePage', 'Failed to upload profile picture', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  /// Ensure user document exists in Firestore
  Future<void> _ensureUserDocumentExists(String userId, User authUser) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        LoggingService.info('ProfilePage', 'Creating user document for: $userId');
        
        // Create user document if it doesn't exist
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'uid': userId,
          'email': authUser.email ?? '',
          'firstName': authUser.displayName?.split(' ').first ?? 'User',
          'lastName': authUser.displayName?.split(' ').last ?? '',
          'phoneNumber': authUser.phoneNumber,
          'role': 'user',
          'isActive': true,
          'emailVerified': authUser.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      LoggingService.warning('ProfilePage', 'Error ensuring user document exists', e);
      // Don't throw here - allow the update to proceed
    }
  }

  /// Update user profile with retry logic
  Future<void> _updateUserProfileWithRetry(String userId, Map<String, dynamic> data) async {
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(data);
        
        LoggingService.info('ProfilePage', 'User profile updated successfully');
        return; // Success, exit retry loop
        
      } catch (e) {
        retryCount++;
        LoggingService.warning('ProfilePage', 'Retry $retryCount: Failed to update profile: $e');
        
        if (retryCount >= maxRetries) {
          throw Exception('Failed to update profile after $maxRetries attempts: $e');
        }
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    if (_currentUser == null || _profileImageUrl == null) return;
    
    setState(() => _isUploadingImage = true);
    
    try {
      // Get the current Firebase Auth user
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }

      final userId = authUser.uid;
      
      LoggingService.info('ProfilePage', 'Removing profile picture for user: $userId');
      
      // Update user profile in Firestore - remove base64 image fields
      await _updateUserProfileWithRetry(userId, {
        'profileImageBase64': FieldValue.delete(),
        'profileImageType': FieldValue.delete(),
        'profileImageUploadTime': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      LoggingService.info('ProfilePage', 'Profile picture removed successfully from Firestore');
      
      // Update local state
      setState(() {
        _profileImageUrl = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile picture removed successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e, stackTrace) {
      LoggingService.error('ProfilePage', 'Failed to remove profile picture', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove picture: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Handle base64 data URLs
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } else {
      // Handle regular URLs
      return CachedNetworkImageProvider(imageUrl);
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthFormField(
                labelText: 'Current Password',
                controller: currentPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock,
              ),
              const SizedBox(height: 16),
              AuthFormField(
                labelText: 'New Password',
                controller: newPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              AuthFormField(
                labelText: 'Confirm New Password',
                controller: confirmPasswordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                
                setState(() => isLoading = true);
                
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final credential = EmailAuthProvider.credential(
                    email: user!.email!,
                    password: currentPasswordController.text,
                  );
                  
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPasswordController.text);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                  
                  await ActivityService.recordActivity(
                    type: ActivityType.passwordChanged,
                    title: 'Password Changed',
                    description: 'User changed their password',
                    status: ActivityStatus.success,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
                
                setState(() => isLoading = false);
              },
              child: isLoading 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadSecurityReport() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating security report...'),
            ],
          ),
        ),
      );

      // Generate security report data
      final reportData = {
        'user_id': user.uid,
        'email': user.email,
        'report_generated': DateTime.now().toIso8601String(),
        'account_created': user.metadata.creationTime?.toIso8601String(),
        'last_sign_in': user.metadata.lastSignInTime?.toIso8601String(),
        'email_verified': user.emailVerified,
        'two_factor_enabled': false, // MultiFactor API not available
        'recent_activities': 'Available in user dashboard',
        'security_settings': {
          'push_notifications': _pushNotifications,
          'email_notifications': _emailNotifications,
          'security_alerts': _securityAlerts,
        },
      };

      // Convert to CSV format
      final csvData = _generateSecurityReportCSV(reportData);
      
      Navigator.pop(context); // Close loading dialog

      // Show download dialog (in a real app, this would trigger actual file download)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Security Report Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your security report has been generated with the following information:'),
              const SizedBox(height: 8),
              Text('• Account creation date: ${user.metadata.creationTime?.toString().split(' ')[0] ?? 'Unknown'}'),
              Text('• Last sign in: ${user.metadata.lastSignInTime?.toString().split(' ')[0] ?? 'Unknown'}'),
              Text('• Email verified: ${user.emailVerified ? 'Yes' : 'No'}'),
              const Text('• Two-factor authentication: Not available'),
              const SizedBox(height: 8),
              const Text('Report format: CSV', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                // In a real app, implement file download here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report download would start here')),
                );
                Navigator.pop(context);
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );

      await ActivityService.recordActivity(
        type: ActivityType.reportGenerated,
        title: 'Security Report Generated',
        description: 'User generated and downloaded security report',
        status: ActivityStatus.success,
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: ${e.toString()}')),
      );
    }
  }

  String _generateSecurityReportCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('Field,Value');
    buffer.writeln('User ID,${data['user_id']}');
    buffer.writeln('Email,${data['email']}');
    buffer.writeln('Report Generated,${data['report_generated']}');
    buffer.writeln('Account Created,${data['account_created'] ?? 'Unknown'}');
    buffer.writeln('Last Sign In,${data['last_sign_in'] ?? 'Unknown'}');
    buffer.writeln('Email Verified,${data['email_verified']}');
    buffer.writeln('Two Factor Enabled,${data['two_factor_enabled']}');
    buffer.writeln('Push Notifications,${data['security_settings']['push_notifications']}');
    buffer.writeln('Email Notifications,${data['security_settings']['email_notifications']}');
    buffer.writeln('Security Alerts,${data['security_settings']['security_alerts']}');
    return buffer.toString();
  }

  void _showDataExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export My Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose what data you want to export:'),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Profile Information'),
              value: true,
              onChanged: null, // Always included
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Incident Reports'),
              value: true,
              onChanged: (value) {},
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Activity History'),
              value: true,
              onChanged: (value) {},
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Settings & Preferences'),
              value: true,
              onChanged: (value) {},
              dense: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _exportUserData(),
            child: const Text('Export Data'),
          ),
        ],
      ),
    );
  }

  void _exportUserData() async {
    Navigator.pop(context); // Close dialog
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing your data...'),
            ],
          ),
        ),
      );

      // Simulate data export preparation
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data Export Ready'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text('Your data has been prepared for export.'),
              SizedBox(height: 8),
              Text('Export includes:'),
              Text('• Profile information'),
              Text('• Incident reports (15 items)'),
              Text('• Activity history'),
              Text('• Settings & preferences'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _showDownloadOptionsDialog();
              },
              child: const Text('Choose Format'),
            ),
          ],
        ),
      );

      await ActivityService.recordActivity(
        type: ActivityType.reportGenerated,
        title: 'Data Exported',
        description: 'User exported their personal data',
        status: ActivityStatus.success,
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDownloadOptionsDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_download, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Choose Download Format'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select your preferred format for downloading your data:'),
            SizedBox(height: 16),
            
            // PDF Option
            Card(
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red[600]),
                title: Text('PDF Document'),
                subtitle: Text('Beautiful formatted report with colors'),
                trailing: Icon(Icons.star, color: Colors.amber),
                onTap: () {
                  Navigator.pop(context);
                  _downloadAsPDF();
                },
              ),
            ),
            
            SizedBox(height: 8),
            
            // CSV Option
            Card(
              child: ListTile(
                leading: Icon(Icons.table_chart, color: Colors.green[600]),
                title: Text('CSV Spreadsheet'),
                subtitle: Text('Data format for Excel and analysis'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadAsCSV();
                },
              ),
            ),
            
            SizedBox(height: 8),
            
            // JSON Option
            Card(
              child: ListTile(
                leading: Icon(Icons.code, color: Colors.blue[600]),
                title: Text('JSON Data'),
                subtitle: Text('Technical format for developers'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadAsJSON();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAsPDF() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating beautiful PDF...'),
            ],
          ),
        ),
      );

      // Create PDF
      final pdf = pw.Document();
      final userData = _getUserData(user);
      
      try {
        await _generateBeautifulPDF(pdf, userData);
      } catch (e) {
        print('PDF generation error: $e');
        // Fallback to simple PDF if complex one fails
        await _generateSimplePDF(pdf, userData);
      }

      // Save PDF to external storage
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'rethicsai_data_export_$timestamp.pdf';
      
      // Get external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Unable to access external storage');
      }
      
      // Create Downloads folder in external storage
      final downloadsFolder = Directory('${directory.parent!.parent!.parent!.parent!.path}/Download');
      if (!await downloadsFolder.exists()) {
        await downloadsFolder.create(recursive: true);
      }
      
      final file = File('${downloadsFolder.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context); // Close loading

      _showDownloadSuccessDialog(fileName, 'PDF');

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadAsCSV() async {
    await _actuallyDownloadUserData();
  }

  Future<void> _downloadAsJSON() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing JSON data...'),
            ],
          ),
        ),
      );

      final userData = _getUserData(user);
      final jsonContent = _createJSONContent(userData);

      // Save JSON file
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'rethicsai_data_export_$timestamp.json';
      
      // Get external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Unable to access external storage');
      }
      
      // Create Downloads folder in external storage
      final downloadsFolder = Directory('${directory.parent!.parent!.parent!.parent!.path}/Download');
      if (!await downloadsFolder.exists()) {
        await downloadsFolder.create(recursive: true);
      }
      
      final file = File('${downloadsFolder.path}/$fileName');
      
      await file.writeAsString(jsonContent);

      Navigator.pop(context); // Close loading
      
      _showDownloadSuccessDialog(fileName, 'JSON');

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('JSON export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _getUserData(User user) {
    return {
      'user_id': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'created_at': user.metadata.creationTime?.toIso8601String(),
      'last_sign_in': user.metadata.lastSignInTime?.toIso8601String(),
      'email_verified': user.emailVerified,
      'two_factor_enabled': false,
      'export_date': DateTime.now().toIso8601String(),
      'profile_data': {
        'profile_complete': true,
        'security_score': '85%',
        'active_cases': 3,
        'resolved_cases': 12,
      },
      'incident_reports': [
        {'id': 'CC-001234', 'type': 'Phishing', 'status': 'Under Review', 'date': '2024-01-15'},
        {'id': 'CC-001235', 'type': 'Scam Call', 'status': 'Resolved', 'date': '2024-01-10'},
        {'id': 'CC-001236', 'type': 'Fake App', 'status': 'Investigating', 'date': '2024-01-08'},
      ],
      'recent_activities': [
        {'type': 'Login', 'date': DateTime.now().subtract(Duration(hours: 1)).toIso8601String()},
        {'type': 'Security Scan', 'date': DateTime.now().subtract(Duration(hours: 6)).toIso8601String()},
        {'type': 'Education Course', 'date': DateTime.now().subtract(Duration(days: 1)).toIso8601String()},
      ]
    };
  }

  void _showDownloadSuccessDialog(String fileName, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('$format Download Complete')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your data has been successfully downloaded:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Downloads/$fileName',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('File includes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Profile & security information'),
            Text('• Incident reports & activities'),
            Text('• Export metadata with timestamps'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openDownloadsFolder();
            },
            child: Text('Open Downloads'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBeautifulPDF(pw.Document pdf, Map<String, dynamic> userData) async {
    // Define beautiful colors
    final primaryColor = PdfColor.fromHex('#2E7D32'); // Green
    final secondaryColor = PdfColor.fromHex('#1976D2'); // Blue
    final accentColor = PdfColor.fromHex('#F57C00'); // Orange
    final backgroundColor = PdfColor.fromHex('#F5F5F5'); // Light gray
    final darkGray = PdfColor.fromHex('#424242');
    final lightGray = PdfColor.fromHex('#9E9E9E');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // Header with logo and title
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RETHICSEC',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Data Export Report',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
                _buildFallbackLogo(),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Export Information
          _buildPDFSection(
            'Export Information',
            [
              _buildPDFInfoRow('Export Date', userData['export_date']?.toString() ?? '', primaryColor),
              _buildPDFInfoRow('User ID', userData['user_id']?.toString() ?? '', primaryColor),
              _buildPDFInfoRow('Generated for', userData['email']?.toString() ?? 'N/A', primaryColor),
            ],
            secondaryColor,
          ),

          pw.SizedBox(height: 25),

          // User Profile Section
          _buildPDFSection(
            'Profile Information',
            [
              _buildPDFInfoRow('Email', userData['email']?.toString() ?? 'N/A', darkGray),
              _buildPDFInfoRow('Display Name', userData['display_name']?.toString() ?? 'Not set', darkGray),
              _buildPDFInfoRow('Account Created', userData['created_at']?.toString() ?? 'Unknown', darkGray),
              _buildPDFInfoRow('Last Sign In', userData['last_sign_in']?.toString() ?? 'Unknown', darkGray),
              _buildPDFInfoRow('Email Verified', userData['email_verified']?.toString() ?? 'false', darkGray),
            ],
            primaryColor,
          ),

          pw.SizedBox(height: 25),

          // Security Overview
          _buildPDFSection(
            'Security Overview',
            [
              _buildPDFInfoRow('Security Score', (userData['profile_data'] as Map<String, dynamic>)['security_score']?.toString() ?? '0%', accentColor),
              _buildPDFInfoRow('Active Cases', (userData['profile_data'] as Map<String, dynamic>)['active_cases']?.toString() ?? '0', accentColor),
              _buildPDFInfoRow('Resolved Cases', (userData['profile_data'] as Map<String, dynamic>)['resolved_cases']?.toString() ?? '0', accentColor),
              _buildPDFInfoRow('Two-Factor Auth', userData['two_factor_enabled'].toString(), accentColor),
            ],
            accentColor,
          ),

          pw.SizedBox(height: 25),

          // Incident Reports Table
          _buildPDFTableSection(
            'Incident Reports',
            ['Report ID', 'Type', 'Status', 'Date'],
            (userData['incident_reports'] as List<dynamic>).map<List<String>>((report) {
              final reportMap = report as Map<String, dynamic>;
              return [
                reportMap['id']?.toString() ?? '',
                reportMap['type']?.toString() ?? '',
                reportMap['status']?.toString() ?? '',
                reportMap['date']?.toString() ?? '',
              ];
            }).toList(),
            secondaryColor,
          ),

          pw.SizedBox(height: 25),

          // Recent Activities
          _buildPDFTableSection(
            'Recent Activities',
            ['Activity', 'Date & Time'],
            (userData['recent_activities'] as List<dynamic>).map<List<String>>((activity) {
              final activityMap = activity as Map<String, dynamic>;
              return [
                activityMap['type']?.toString() ?? '',
                activityMap['date']?.toString() ?? '',
              ];
            }).toList(),
            primaryColor,
          ),

          pw.SizedBox(height: 30),

          // Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: backgroundColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'This report was generated automatically by RethicSec',
                  style: pw.TextStyle(fontSize: 10, color: lightGray),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'For support, contact: support@rethicsec.com',
                  style: pw.TextStyle(fontSize: 10, color: lightGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSection(String title, List<pw.Widget> children, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFInfoRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label + ':',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(color: PdfColor.fromHex('#424242')),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTableSection(
    String title, 
    List<String> headers, 
    List<List<String>> rows,
    PdfColor accentColor
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
              children: headers.map((header) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  header,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              )).toList(),
            ),
            // Data rows
            ...rows.map((row) => pw.TableRow(
              children: row.map((cell) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  cell,
                  style: pw.TextStyle(color: PdfColor.fromHex('#424242')),
                ),
              )).toList(),
            )),
          ],
        ),
      ],
    );
  }

  Future<void> _actuallyDownloadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating CSV file...'),
            ],
          ),
        ),
      );

      final userData = _getUserData(user);
      final csvContent = _createCSVContent(userData);

      // Save CSV file
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'rethicsai_data_export_$timestamp.csv';
      
      // Get external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Unable to access external storage');
      }
      
      // Create Downloads folder in external storage
      final downloadsFolder = Directory('${directory.parent!.parent!.parent!.parent!.path}/Download');
      if (!await downloadsFolder.exists()) {
        await downloadsFolder.create(recursive: true);
      }
      
      final file = File('${downloadsFolder.path}/$fileName');
      
      await file.writeAsString(csvContent);

      Navigator.pop(context); // Close loading

      _showDownloadSuccessDialog(fileName, 'CSV');

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildFallbackLogo() {
    return pw.Container(
      width: 60,
      height: 60,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(30),
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0'), width: 2),
      ),
      child: pw.Center(
        child: pw.Text(
          'RETHICSEC',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#2E7D32'),
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  Future<pw.Widget> _buildPDFLogo() async {
    try {
      // Load the Rethicsec logo from assets
      final ByteData logoData = await rootBundle.load('assets/images/Rethicsec.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

      return pw.Container(
        width: 60,
        height: 60,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(30),
          border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0'), width: 2),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Image(logoImage, fit: pw.BoxFit.cover),
        ),
      );
    } catch (e) {
      return _buildFallbackLogo();
    }
  }

  Future<void> _generateSimplePDF(pw.Document pdf, Map<String, dynamic> userData) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RETHICSAI DATA EXPORT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Export Date: ${userData['export_date'] ?? 'Unknown'}'),
              pw.Text('User ID: ${userData['user_id'] ?? 'Unknown'}'),
              pw.Text('Email: ${userData['email'] ?? 'Unknown'}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'PROFILE INFORMATION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Display Name: ${userData['display_name'] ?? 'Not set'}'),
              pw.Text('Account Created: ${userData['created_at'] ?? 'Unknown'}'),
              pw.Text('Email Verified: ${userData['email_verified'] ?? false}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'This is a simplified PDF export due to formatting issues.',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  String _createCSVContent(Map<String, dynamic> userData) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('RETHICSAI USER DATA EXPORT');
    buffer.writeln('Export Date: ${userData['export_date']}');
    buffer.writeln('User ID: ${userData['user_id']}');
    buffer.writeln('');
    
    // Profile Information
    buffer.writeln('PROFILE INFORMATION');
    buffer.writeln('Email,${userData['email']}');
    buffer.writeln('Display Name,${userData['display_name'] ?? 'Not set'}');
    buffer.writeln('Account Created,${userData['created_at'] ?? 'Unknown'}');
    buffer.writeln('Last Sign In,${userData['last_sign_in'] ?? 'Unknown'}');
    buffer.writeln('Email Verified,${userData['email_verified']}');
    buffer.writeln('');
    
    // Incident Reports
    buffer.writeln('INCIDENT REPORTS');
    buffer.writeln('Report ID,Type,Status,Date');
    for (final report in userData['incident_reports']) {
      buffer.writeln('${report['id']},${report['type']},${report['status']},${report['date']}');
    }
    buffer.writeln('');
    
    // Recent Activities
    buffer.writeln('RECENT ACTIVITIES');
    buffer.writeln('Activity Type,Date');
    for (final activity in userData['recent_activities']) {
      buffer.writeln('${activity['type']},${activity['date']}');
    }
    
    return buffer.toString();
  }

  String _createJSONContent(Map<String, dynamic> userData) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(userData);
  }

  void _openDownloadsFolder() {
    // This would typically use url_launcher or similar to open file manager
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check your Downloads folder in the file manager'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonDialog('Account deletion');
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle sign out
              context.read<AuthBloc>().add(AuthSignOutRequested());
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    if (_currentUser == null) return;
    
    try {
      await UserService.updateUserProfile(_currentUser!.id, {
        'notifications': {
          ...(_currentUser!.toJson()['notifications'] ?? {}),
          setting: value,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Record activity
      await ActivityService.recordProfileActivity(
        action: 'notification_setting_updated',
        details: '$setting set to $value',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$setting updated'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updatePrivacySetting(String setting, bool value) async {
    if (_currentUser == null) return;
    
    try {
      await UserService.updateUserProfile(_currentUser!.id, {
        'privacy': {
          ...(_currentUser!.toJson()['privacy'] ?? {}),
          setting: value,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Record activity
      await ActivityService.recordProfileActivity(
        action: 'privacy_setting_updated',
        details: '$setting set to $value',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$setting updated'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loadUserSettings(Map<String, dynamic> profileData) {
    // Load notification settings
    final notifications = profileData['notifications'] as Map<String, dynamic>? ?? {};
    _pushNotifications = notifications['pushNotifications'] ?? true;
    _emailNotifications = notifications['emailNotifications'] ?? true;
    _smsNotifications = notifications['smsNotifications'] ?? false;
    _securityAlerts = notifications['securityAlerts'] ?? true;
    
    // Load privacy settings
    final privacy = profileData['privacy'] as Map<String, dynamic>? ?? {};
    _profileVisibility = privacy['profileVisibility'] ?? false;
    _locationServices = privacy['locationServices'] ?? true;
    _analyticsReports = privacy['analyticsReports'] ?? true;
    _marketingCommunications = privacy['marketingCommunications'] ?? false;
    
    // Load appearance settings - sync with ThemeProvider
    final preferences = profileData['preferences'] as Map<String, dynamic>? ?? {};
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (themeProvider.isInitialized) {
      _darkMode = themeProvider.isDarkMode;
    } else {
      _darkMode = preferences['darkMode'] ?? false;
    }
  }

  void _showCountryPicker() {
    final List<String> countries = [
      'Nigeria', 'Ghana', 'Kenya', 'South Africa', 'Tanzania', 'Uganda', 'Rwanda', 
      'Ethiopia', 'Morocco', 'Egypt', 'Tunisia', 'Algeria', 'Cameroon', 'Senegal',
      'United States', 'United Kingdom', 'Canada', 'Australia', 'Germany', 'France'
    ];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Country',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Expanded(
              child: ListView.builder(
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final isSelected = country == (_currentUser?.country ?? 'Nigeria');
                  
                  return ListTile(
                    leading: const Icon(Icons.flag),
                    title: Text(country),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                    onTap: () {
                      _updateCountry(country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCountry(String country) async {
    if (_currentUser == null) return;
    
    try {
      await UserService.updateUserProfile(_currentUser!.id, {
        'country': country,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Record activity
      await ActivityService.recordProfileActivity(
        action: 'country_updated',
        details: 'Country updated to $country',
      );
      
      // Update local user model
      _currentUser = UserModel(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        phoneNumber: _currentUser!.phoneNumber,
        country: country,
        language: _currentUser!.language,
        isEmailVerified: _currentUser!.isEmailVerified,
        isVerified: _currentUser!.isVerified,
        isAdmin: _currentUser!.isAdmin,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Country updated to $country'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update country: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateAppearanceSetting(String setting, bool value) async {
    if (_currentUser == null) return;
    
    try {
      await UserService.updateUserProfile(_currentUser!.id, {
        'preferences': {
          ...(_currentUser!.toJson()['preferences'] ?? {}),
          setting: value,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Record activity
      await ActivityService.recordProfileActivity(
        action: 'appearance_setting_updated',
        details: '$setting set to $value',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme updated to ${value ? 'Dark' : 'Light'} mode'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update theme: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}