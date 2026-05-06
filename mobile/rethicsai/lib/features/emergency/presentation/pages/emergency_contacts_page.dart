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
  
  // Using Firebase data instead of hardcoded data
  Map<String, List<EmergencyContact>> _emergencyContacts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load all contacts from Firebase
      final allContacts = await EmergencyContactsService.getAllContacts();
      final countries = await EmergencyContactsService.getAvailableCountries();

      // Group contacts by country (maintaining original structure)
      final Map<String, List<EmergencyContact>> groupedContacts = {};
      for (final country in countries) {
        groupedContacts[country] = allContacts
            .where((contact) => contact.country == country)
            .toList();
      }

      setState(() {
        _emergencyContacts = groupedContacts;
        _isLoading = false;
        if (countries.isNotEmpty) {
          _selectedCountry = countries.first;
        }
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Use fallback data if Firebase fails
      _emergencyContacts = _getDefaultContacts();
      _animationController.forward();
    }
  }

  // Fallback data in case Firebase is not available
  Map<String, List<EmergencyContact>> _getDefaultContacts() {
    return {
      'Nigeria': [],
      'Kenya': [],
      'South Africa': [],
      'Ghana': [],
      'Uganda': [],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        title: Text(
          'Emergency Contacts',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadEmergencyContacts,
            icon: const Icon(Icons.refresh, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                  AppTheme.secondaryColor,
                ],
              ),
            ),
          ),
          
          // African pattern overlay
          const AfricanPatternBackground(opacity: 0.1),
          
          // Main content
          SafeArea(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading emergency contacts...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Hero section (original design)
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.emergency_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ).animate().scale(delay: 200.ms, duration: 800.ms),
              
              const SizedBox(height: 16),
              
              Text(
                'Emergency Help',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Get immediate assistance from verified emergency contacts across Africa',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
        
        // Country selector (original design)
        if (_emergencyContacts.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select Country',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountry,
                        dropdownColor: AppTheme.primaryColor,
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        items: _emergencyContacts.keys.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCountry = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(delay: 800.ms),
        
        const SizedBox(height: 24),
        
        // Emergency contacts list (original card design)
        Expanded(
          child: _buildContactsList(),
        ),
      ],
    );
  }

  Widget _buildContactsList() {
    final contacts = _emergencyContacts[_selectedCountry] ?? [];
    
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contact_phone,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No emergency contacts available for $_selectedCountry',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        return _buildContactCard(contacts[index], index);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showContactActions(contact),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Contact type icon (original design)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getTypeGradient(contact.type),
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _getTypeColor(contact.type).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getTypeIcon(contact.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Contact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contact.department.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            contact.department,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(contact.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getTypeColor(contact.type).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getTypeDisplayName(contact.type),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(contact.type),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                contact.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Contact actions (original design)
              Row(
                children: [
                  // Primary phone button
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      color: Colors.green,
                      onTap: () => _makeCall(contact.phone),
                    ),
                  ),
                  
                  if (contact.emergencyNumber != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.emergency,
                        label: 'Emergency',
                        color: Colors.red,
                        onTap: () => _makeCall(contact.emergencyNumber!),
                      ),
                    ),
                  ],
                  
                  const SizedBox(width: 12),
                  _buildIconButton(
                    icon: Icons.more_vert,
                    color: Colors.grey,
                    onTap: () => _showContactActions(contact),
                  ),
                ],
              ),
              
              // Availability indicator (original design)
              if (contact.availability.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        contact.availability,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
     .fadeIn(duration: 600.ms)
     .slideY(begin: 0.3, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _showContactActions(EmergencyContact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getTypeGradient(contact.type),
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getTypeIcon(contact.type),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (contact.department.isNotEmpty)
                        Text(
                          contact.department,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            if (contact.phone.isNotEmpty)
              _buildActionItem(
                icon: Icons.phone,
                title: 'Call ${contact.phone}',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(contact.phone);
                },
              ),
            
            if (contact.emergencyNumber != null)
              _buildActionItem(
                icon: Icons.emergency,
                title: 'Emergency ${contact.emergencyNumber}',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(contact.emergencyNumber!);
                },
              ),
            
            if (contact.email != null)
              _buildActionItem(
                icon: Icons.email,
                title: 'Email ${contact.email}',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _sendEmail(contact.email!);
                },
              ),
            
            if (contact.website != null)
              _buildActionItem(
                icon: Icons.web,
                title: 'Visit Website',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _openWebsite(contact.website!);
                },
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // Helper methods for contact types (maintaining original design system)
  Color _getTypeColor(ContactType type) {
    switch (type) {
      case ContactType.cyberCrime:
        return Colors.red.shade600;
      case ContactType.police:
        return Colors.blue.shade600;
      case ContactType.financial:
        return Colors.green.shade600;
      case ContactType.telecom:
        return Colors.purple.shade600;
      case ContactType.legal:
        return Colors.orange.shade600;
    }
  }

  IconData _getTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.cyberCrime:
        return Icons.security;
      case ContactType.police:
        return Icons.local_police;
      case ContactType.financial:
        return Icons.account_balance;
      case ContactType.telecom:
        return Icons.phone;
      case ContactType.legal:
        return Icons.gavel;
    }
  }

  List<Color> _getTypeGradient(ContactType type) {
    final color = _getTypeColor(type);
    return [color, color.withOpacity(0.7)];
  }

  String _getTypeDisplayName(ContactType type) {
    switch (type) {
      case ContactType.cyberCrime:
        return 'CYBER';
      case ContactType.police:
        return 'POLICE';
      case ContactType.financial:
        return 'FINANCE';
      case ContactType.telecom:
        return 'TELECOM';
      case ContactType.legal:
        return 'LEGAL';
    }
  }

  // Action methods (original functionality)
  Future<void> _makeCall(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$cleanNumber');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: cleanNumber));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number copied: $cleanNumber'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make call'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    try {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: email));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email address copied: $email'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to send email'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openWebsite(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Website URL copied: $url'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open website'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}