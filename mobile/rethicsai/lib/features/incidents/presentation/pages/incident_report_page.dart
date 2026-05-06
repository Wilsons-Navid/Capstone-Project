import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/models/incident_model.dart';
import '../../../../shared/models/file_upload_data.dart';
import '../../../../shared/models/activity_model.dart';

class IncidentReportPage extends StatefulWidget {
  const IncidentReportPage({super.key});

  @override
  State<IncidentReportPage> createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _suspectController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _locationController = TextEditingController();
  
  String _selectedIncidentType = 'Mobile Money Scam';
  String _selectedPriority = 'Medium';
  String _selectedCurrency = 'NGN';
  DateTime _selectedDate = DateTime.now();
  List<PlatformFile> _uploadedFiles = [];
  bool _isSubmitting = false;
  
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _locationServicesEnabled = false;
  bool _isLoadingLocation = false;
  String? _currentLocationString;
  Map<String, double>? _currentCoordinates;

  final List<String> _incidentTypes = [
    'Mobile Money Scam',
    'Email Phishing',
    'Fake Loan App',
    'Social Media Fraud',
    'Identity Theft',
    'Online Shopping Scam',
    'Romance Scam',
    'Investment Fraud',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        _formatAmountOnBlur();
      }
    });
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      try {
        _userProfile = await UserService.getUserProfile(_currentUser!.uid);
        // Infer default currency based on user country (fallback to NGN)
        final country = _userProfile?['country']?.toString() ?? 'Nigeria';
        _selectedCurrency = _inferCurrencyFromCountry(country);
        
        // Check if location services are enabled in user's privacy settings
        final privacy = _userProfile?['privacy'] as Map<String, dynamic>? ?? {};
        _locationServicesEnabled = privacy['locationServices'] ?? false;
        
        // If location services are enabled, automatically get current location
        if (_locationServicesEnabled) {
          _getCurrentLocation();
        }
        
        setState(() {}); // Update UI with user data
      } catch (e) {
        print('Failed to load user profile: $e');
      }
    }
  }
  
  Future<void> _getCurrentLocation() async {
    if (!_locationServicesEnabled) return;
    
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      // Get both address string and coordinates
      String? locationString = await LocationService.getCurrentLocationAddress();
      Map<String, double>? coordinates = await LocationService.getCurrentCoordinates();
      
      if (locationString != null) {
        _currentLocationString = locationString;
        _currentCoordinates = coordinates;
        // Auto-fill the location field
        _locationController.text = locationString;
      }
    } catch (e) {
      print('Failed to get current location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _suspectController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: const AfricanPatternBackground(opacity: 0.03),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),
                
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 24),
                          _buildIncidentTypeSelector(),
                          const SizedBox(height: 20),
                          _buildBasicInfoSection(),
                          const SizedBox(height: 20),
                          _buildDetailsSection(),
                          const SizedBox(height: 20),
                          _buildEvidenceSection(),
                          const SizedBox(height: 20),
                          _buildPrioritySection(),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Icon(Icons.report_problem, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Incident',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Help us fight cybercrime in Africa',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondaryColor.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ðŸ›¡ï¸ Your Security Matters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Every report helps protect our African community from cyber threats. Your information is secure and will be handled by trained professionals.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildIncidentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type of Incident *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedIncidentType,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _incidentTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) => setState(() => _selectedIncidentType = value!),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms);
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: _buildInputDecoration('Incident Title *', Icons.title),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Currency (moved amount to next line below)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      decoration: _buildInputDecoration('incidents.currency'.tr(), Icons.payments),
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      iconEnabledColor: AppTheme.secondaryColor,
                      dropdownColor: Colors.white,
                      items: _currencyOptions
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCurrency = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Amount Lost (full width on next line)
        TextFormField(
          controller: _amountController,
          focusNode: _amountFocusNode,
          decoration: _buildInputDecoration('incidents.amount_lost'.tr(), Icons.money).copyWith(
            hintText: '0.00',
            suffixText: _selectedCurrency,
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          validator: _validateAmount,
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms);
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'incidents.incident_details'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: _buildInputDecoration('${'incidents.description'.tr()} *', Icons.description),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
          maxLines: 4,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildLocationField(),
        const SizedBox(height: 16),
          TextFormField(
            controller: _suspectController,
            decoration: _buildInputDecoration('${'incidents.suspect_info'.tr()} (optional)', Icons.person),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
            maxLines: 2,
          ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 500.ms);
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${'incidents.location'.tr()} *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            if (_locationServicesEnabled && !_isLoadingLocation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Text(
                  'Auto-detected',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: _buildInputDecoration(
                  _locationServicesEnabled 
                    ? 'Auto-detected location (tap refresh to update)'
                    : 'Location where it occurred', 
                  Icons.location_on
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
                validator: (value) => value?.isEmpty == true ? 'Please specify location' : null,
              ),
            ),
            const SizedBox(width: 8),
            if (_locationServicesEnabled)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.white),
                  tooltip: 'Refresh location',
                ),
              ),
          ],
        ),
        if (_locationServicesEnabled && _currentLocationString != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Current location automatically detected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (!_locationServicesEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Enable location services in your profile settings for automatic detection',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 450.ms);
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidence Files',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload, size: 40, color: AppTheme.primaryColor),
                const SizedBox(height: 8),
                const Text('Tap to upload screenshots, emails, or documents'),
                const SizedBox(height: 4),
                Text(
                  'Max size: 10MB per file â€¢ Formats: JPG, PNG, PDF, DOC',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (_uploadedFiles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Column(
                    children: _uploadedFiles.map((file) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(file.extension ?? ''),
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatFileSize(file.size),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _uploadedFiles.remove(file);
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms);
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _priorities.map((priority) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPriority = priority),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedPriority == priority 
                        ? AppTheme.primaryColor 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedPriority == priority 
                          ? AppTheme.primaryColor 
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    priority,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedPriority == priority 
                          ? Colors.white 
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 700.ms);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 800.ms).scale(delay: 800.ms);
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppTheme.onSurfaceVariant,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        backgroundColor: Colors.white,
      ),
      floatingLabelStyle: TextStyle(
        color: AppTheme.secondaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        backgroundColor: Colors.white,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon, color: AppTheme.secondaryColor, size: 22),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.errorColor, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String? _validateAmount(String? value) {
    final text = (value ?? '').replaceAll(',', '').trim();
    if (text.isEmpty) return null; // optional field
    final reg = RegExp(r'^(\d+)(\.\d{1,2})?$');
    if (!reg.hasMatch(text)) {
      return 'Enter a valid amount (max 2 decimals)';
    }
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  void _formatAmountOnBlur() {
    final raw = _amountController.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return;
    final value = double.tryParse(raw);
    if (value == null) return;
    try {
      final localeCode = context.locale.languageCode;
      final formatter = NumberFormat('#,##0.##', localeCode);
      _amountController.text = formatter.format(value);
    } catch (_) {
      _amountController.text = value.toStringAsFixed(2);
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        withData: true, // Important: Load file data
      );
      
      if (result != null) {
        // Filter out files that are too large (> 10MB)
        final validFiles = result.files.where((file) {
          if (file.size > 10 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('errors.file_too_large'.tr(args: [file.name])),
                backgroundColor: Colors.orange,
              ),
            );
            return false;
          }
          return true;
        }).toList();
        
        setState(() {
          _uploadedFiles = validFiles;
        });
        
        if (validFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('common.files_selected_success'.tr(args: [validFiles.length.toString()])),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      }
    } catch (e) {
      print('File picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('errors.file_pick_failed'.tr(args: [e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if user is authenticated
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit a report'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      // Get user email and details
      final userEmail = _currentUser!.email ?? 'no-email@rethicsai.com';
      final userName = _userProfile != null 
          ? '${_userProfile!['firstName'] ?? ''} ${_userProfile!['lastName'] ?? ''}'
          : _currentUser!.displayName ?? 'Anonymous User';
      
      print('Submitting incident for user: $userEmail ($userName)');
      
      // Create incident data for service
      final incidentData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'incident_type': _selectedIncidentType,
        'priority_level': _selectedPriority,
        'date_occurred': _selectedDate.toIso8601String(),
        'location_occurred': _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : 'common.location_not_specified'.tr(),
        'location_latitude': _currentCoordinates?['latitude'],
        'location_longitude': _currentCoordinates?['longitude'],
        'suspect_information': _suspectController.text.trim().isEmpty 
            ? null 
            : _suspectController.text.trim(),
        'financial_loss': _amountController.text.replaceAll(',', '').trim().isEmpty 
            ? null 
            : double.tryParse(_amountController.text.replaceAll(',', '').trim()),
        'financial_loss_currency': _selectedCurrency,
        'contact_preference': 'email',
        'contact_details': userEmail,
        'reporter_name': userName.trim(),
        'reporter_phone': _userProfile?['phoneNumber'],
        'reporter_country': _userProfile?['country'] ?? 'Nigeria',
      };

      List<FileUploadData>? fileUploads;
      if (_uploadedFiles.isNotEmpty) {
        print('Processing ${_uploadedFiles.length} evidence files');
        
        fileUploads = _uploadedFiles.map((file) {
          if (file.bytes == null) {
            print('Warning: File ${file.name} has no data');
          }
          
          return FileUploadData(
            id: '${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}',
            fileName: file.name,
            fileType: file.extension ?? file.name.split('.').last,
            fileSize: file.size,
            fileBytes: file.bytes ?? Uint8List(0), // Use actual file bytes or empty
            uploadedAt: DateTime.now(),
          );
        }).toList();
        
        print('Created ${fileUploads.length} file upload objects');
      }

      // Submit to Firestore
      print('IncidentReportPage: Submitting incident to Firestore');
      print('File uploads: ${fileUploads?.length ?? 0}');
      
      final result = await IncidentService.createIncident(
        incidentData,
        fileUploads: fileUploads,
      );
      print('IncidentReportPage: Incident submitted with ID: $result');
      
      // Record activity for incident submission
      await ActivityService.recordIncidentActivity(
        incidentId: result,
        title: 'Incident Report Submitted',
        description: '$_selectedIncidentType case submitted - ID: $result',
        type: ActivityType.incidentReported,
        status: ActivityStatus.success,
      );
      
      // Verify the incident was saved
      final exists = await IncidentService.verifyIncidentExists(result);
      print('IncidentReportPage: Incident verification result: $exists');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exists 
              ? 'âœ… Report submitted successfully!\nðŸ“„ Case ID: $result\nðŸ“§ Confirmation sent to: ${_currentUser!.email}\nðŸ“Š You can track this case in "My Cases"' 
              : 'âš ï¸ Report submitted but verification failed. Case ID: $result'),
            backgroundColor: exists ? AppTheme.accentColor : Colors.orange,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Navigate to case tracking page to show the new case
        Navigator.pushReplacementNamed(context, '/case-tracking');
      }
    } catch (e) {
      print('Error submitting incident: $e');
      
      if (mounted) {
        String errorMessage = 'Failed to submit report';
        
        // Provide more specific error messages
        if (e.toString().contains('storage')) {
          errorMessage = 'File upload failed. Please try with smaller files or check your connection.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please check your account permissions.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$errorMessage\n\nError details: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                  label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                // Remove uploaded files and let user try again
                setState(() {
                  _uploadedFiles.clear();
                });
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Currency support
  static const List<String> _currencyOptions = [
    'NGN','KES','ZAR','TZS','UGX','GHS','MAD','EGP','XOF','XAF','USD'
  ];

  String _inferCurrencyFromCountry(String country) {
    final c = country.toLowerCase();
    if (c.contains('nigeria')) return 'NGN';
    if (c.contains('kenya')) return 'KES';
    if (c.contains('south africa')) return 'ZAR';
    if (c.contains('tanzania')) return 'TZS';
    if (c.contains('uganda')) return 'UGX';
    if (c.contains('ghana')) return 'GHS';
    if (c.contains('morocco')) return 'MAD';
    if (c.contains('egypt')) return 'EGP';
    if (c.contains('senegal') || c.contains('cote d') || c.contains('cÃ´te d')) return 'XOF';
    if (c.contains('cameroon') || c.contains('gabon') || c.contains('congo')) return 'XAF';
    return 'USD';
  }
}
