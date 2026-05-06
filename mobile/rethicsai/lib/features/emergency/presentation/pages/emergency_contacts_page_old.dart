import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../core/services/emergency_contacts_service.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedCountry = 'Nigeria';
  List<EmergencyContact> _allContacts = [];
  List<EmergencyContact> _filteredContacts = [];
  List<String> _availableCountries = [];
  bool _isLoading = true;
    'Nigeria': [
      EmergencyContact(
        type: ContactType.cyberCrime,
        name: 'Nigeria Police Force Cybercrime Unit',
        department: 'NPF-SCID Cybercrime Division',
        phone: '+234-1-4931260',
        email: 'cybercrime@npf.gov.ng',
        website: 'https://www.npf.gov.ng',
        address: 'Louis Edet House, Area 11, Garki, Abuja',
        description: 'Primary cybercrime reporting unit for Nigeria',
        availability: '24/7 Emergency Hotline',
        languages: ['English', 'Hausa', 'Yoruba', 'Igbo'],
      ),
      EmergencyContact(
        type: ContactType.cyberCrime,
        name: 'Economic and Financial Crimes Commission',
        department: 'EFCC Cybercrime Division',
        phone: '+234-9-9044751',
        email: 'info@efcc.gov.ng',
        website: 'https://www.efcc.gov.ng',
        address: 'Plot 802/803 Ralph Shodeinde Street, Central Business District, Abuja',
        description: 'Financial crimes and advanced fee fraud',
        availability: 'Mon-Fri 8AM-6PM',
        languages: ['English'],
      ),
      EmergencyContact(
        type: ContactType.police,
        name: 'Nigeria Police Emergency',
        department: 'Emergency Response Unit',
        phone: '199',
        emergencyNumber: '199',
        email: 'emergency@npf.gov.ng',
        description: 'General police emergency services',
        availability: '24/7',
        languages: ['English', 'Local languages'],
      ),
    ],
    'Kenya': [
      EmergencyContact(
        type: ContactType.cyberCrime,
        name: 'Kenya Police Cybercrime Unit',
        department: 'Directorate of Criminal Investigations',
        phone: '+254-20-2240000',
        email: 'cybercrime@dci.go.ke',
        website: 'https://www.dci.go.ke',
        address: 'Kiambu Road, Nairobi',
        description: 'Kenya\'s primary cybercrime investigation unit',
        availability: '24/7 Hotline',
        languages: ['English', 'Swahili'],
      ),
      EmergencyContact(
        type: ContactType.cyberCrime,
        name: 'Communications Authority of Kenya',
        department: 'Consumer Affairs',
        phone: '+254-20-4242000',
        email: 'info@ca.go.ke',
        website: 'https://www.ca.go.ke',
        address: 'Waiyaki Way, Nairobi',
        description: 'Telecommunications and online fraud reporting',
        availability: 'Mon-Fri 8AM-5PM',
        languages: ['English', 'Swahili'],
      ),
      EmergencyContact(
        type: ContactType.police,
        name: 'Kenya Police Emergency',
        department: 'Emergency Services',
        phone: '999',
        emergencyNumber: '999',
        description: 'General emergency services',
        availability: '24/7',
        languages: ['English', 'Swahili'],
      ),
    ],
    'South Africa': [
      EmergencyContact(
        type: ContactType.cyberCrime,
        name: 'Hawks Cybercrime Unit',
        department: 'Directorate for Priority Crime Investigation',
        phone: '+27-12-393-3000',
        email: 'cybercrime@saps.gov.za',
        website: 'https://www.saps.gov.za',
        address: '231 Pretorius Street, Pretoria',
        description: 'Elite cybercrime investigation unit',
        availability: '24/7 Hotline',
        languages: ['English', 'Afrikaans', 'Zulu', 'Xhosa'],
      ),
      EmergencyContact(
        type: ContactType.cyberCrime,
        name: 'South African Banking Risk Information Centre',
        department: 'SABRIC Cybercrime Division',
        phone: '+27-11-645-6700',
        email: 'info@sabric.co.za',
        website: 'https://www.sabric.co.za',
        address: 'Rosebank, Johannesburg',
        description: 'Banking and financial cybercrime',
        availability: 'Mon-Fri 8AM-5PM',
        languages: ['English', 'Afrikaans'],
      ),
      EmergencyContact(
        type: ContactType.police,
        name: 'South African Police Emergency',
        department: 'Emergency Services',
        phone: '10111',
        emergencyNumber: '10111',
        description: 'General police emergency',
        availability: '24/7',
        languages: ['English', 'Afrikaans', 'Local languages'],
      ),
    ],
    'Ghana': [
      EmergencyContact(
        type: ContactType.cyberCrime,
        name: 'Ghana Police Cybercrime Unit',
        department: 'Criminal Investigation Department',
        phone: '+233-30-2773906',
        email: 'cybercrime@ghanapolice.gov.gh',
        website: 'https://www.ghanapolice.gov.gh',
        address: 'National Police Headquarters, Accra',
        description: 'National cybercrime investigation unit',
        availability: '24/7',
        languages: ['English'],
      ),
      EmergencyContact(
        type: ContactType.police,
        name: 'Ghana Police Emergency',
        department: 'Emergency Response',
        phone: '191',
        emergencyNumber: '191',
        description: 'General police emergency',
        availability: '24/7',
        languages: ['English'],
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // African pattern background
          const AfricanPatternBackground(opacity: 0.03),
          
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                // Custom app bar
                _buildCustomAppBar()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, end: 0),
                
                // Country selector
                _buildCountrySelector()
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.3, end: 0),
                
                // Emergency notice
                _buildEmergencyNotice()
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                
                // Contacts list
                Expanded(
                  child: _buildContactsList()
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.errorColor,
            AppTheme.errorColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Emergency icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.emergency,
              color: Colors.white,
              size: 24,
            ),
          )
              .animate()
              .scale(delay: 300.ms, duration: 600.ms)
              .then()
              .shimmer(duration: 2000.ms),
          
          const SizedBox(width: 16),
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'emergency.emergency_contacts'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'emergency.immediate_help'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          isExpanded: true,
          hint: const Text('Select Country'),
          items: _emergencyContacts.keys.map((country) {
            return DropdownMenuItem(
              value: country,
              child: Row(
                children: [
                  Text(_getCountryFlag(country), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(country, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCountry = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[50]!,
            Colors.orange[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.errorColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In Case of Emergency',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'If you are in immediate danger, call local emergency services first, then report the cybercrime.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    final contacts = _emergencyContacts[_selectedCountry] ?? [];
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactCard(contact, index)
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 600.ms)
            .slideX(begin: 0.3, end: 0);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and type
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: contact.type == ContactType.cyberCrime
                      ? AppTheme.primaryGradient
                      : AppTheme.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  contact.type == ContactType.cyberCrime
                      ? Icons.security
                      : Icons.local_police,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (contact.department != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.department!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Quick call button
              if (contact.emergencyNumber != null)
                ElevatedButton.icon(
                  onPressed: () => _makeCall(contact.emergencyNumber!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: Text(contact.emergencyNumber!),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            contact.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contact details
          _buildContactDetail(Icons.phone, 'Phone', contact.phone),
          if (contact.email != null)
            _buildContactDetail(Icons.email, 'Email', contact.email!),
          if (contact.address != null)
            _buildContactDetail(Icons.location_on, 'Address', contact.address!),
          _buildContactDetail(Icons.access_time, 'Hours', contact.availability),
          if (contact.languages.isNotEmpty)
            _buildContactDetail(Icons.language, 'Languages', contact.languages.join(', ')),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(contact.phone),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              
              if (contact.email != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendEmail(contact.email!),
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      side: BorderSide(color: AppTheme.secondaryColor),
                    ),
                  ),
                ),
              ],
              
              if (contact.website != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWebsite(contact.website!),
                    icon: const Icon(Icons.web),
                    label: const Text('Website'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                      side: BorderSide(color: AppTheme.accentColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _getCountryFlag(String country) {
    switch (country) {
      case 'Nigeria':
        return '🇳🇬';
      case 'Kenya':
        return '🇰🇪';
      case 'South Africa':
        return '🇿🇦';
      case 'Ghana':
        return '🇬🇭';
      default:
        return '🌍';
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        HapticFeedback.mediumImpact();
      } else {
        _showCallDialog(phoneNumber);
      }
    } catch (e) {
      _showCallDialog(phoneNumber);
    }
  }

  Future<void> _sendEmail(String email) async {
    try {
      final uri = Uri.parse('mailto:$email?subject=Cybercrime Report - Rethicssec');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showEmailDialog(email);
      }
    } catch (e) {
      _showEmailDialog(email);
    }
  }

  Future<void> _openWebsite(String website) async {
    try {
      final uri = Uri.parse(website);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showWebsiteDialog(website);
      }
    } catch (e) {
      _showWebsiteDialog(website);
    }
  }

  void _showCallDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Call $phoneNumber'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phoneNumber));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Phone number copied: $phoneNumber')),
                      );
                    },
                    child: const Text('Copy Number'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEmailDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: $email'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: email));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email copied: $email')),
                );
              },
              child: const Text('Copy Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showWebsiteDialog(String website) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visit Website'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Website: $website'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: website));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Website URL copied: $website')),
                );
              },
              child: const Text('Copy URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

enum ContactType { cyberCrime, police, government }

class EmergencyContact {
  final ContactType type;
  final String name;
  final String? department;
  final String phone;
  final String? emergencyNumber;
  final String? email;
  final String? website;
  final String? address;
  final String description;
  final String availability;
  final List<String> languages;

  const EmergencyContact({
    required this.type,
    required this.name,
    this.department,
    required this.phone,
    this.emergencyNumber,
    this.email,
    this.website,
    this.address,
    required this.description,
    required this.availability,
    this.languages = const [],
  });
}