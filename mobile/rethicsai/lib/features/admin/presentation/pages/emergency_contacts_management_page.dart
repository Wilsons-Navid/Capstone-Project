import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';
import '../../../../core/services/emergency_contacts_service.dart';
import '../widgets/emergency_contact_editor_dialog.dart';

class EmergencyContactsManagementPage extends StatefulWidget {
  const EmergencyContactsManagementPage({super.key});

  @override
  State<EmergencyContactsManagementPage> createState() =>
      _EmergencyContactsManagementPageState();
}

class _EmergencyContactsManagementPageState
    extends State<EmergencyContactsManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  List<EmergencyContact> _contacts = [];
  List<EmergencyContact> _filteredContacts = [];
  List<String> _countries = [];
  String _selectedCountry = 'All';
  ContactType? _selectedType;
  bool _isLoading = true;
  Map<String, int> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // First try to seed default data if needed
      await EmergencyContactsService.seedDefaultData();
      
      // Load all contacts and countries
      final contacts = await EmergencyContactsService.getAllContacts();
      final countries = await EmergencyContactsService.getAvailableCountries();
      
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _countries = ['All', ...countries];
        _isLoading = false;
      });
      
      _calculateStatistics();
    } catch (e) {
      print('Error loading contacts: $e');
      // Try to initialize with default data as fallback
      try {
        await EmergencyContactsService.seedDefaultData();
        final contacts = await EmergencyContactsService.getAllContacts();
        final countries = await EmergencyContactsService.getAvailableCountries();
        
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _countries = ['All', ...countries];
          _isLoading = false;
        });
        
        _calculateStatistics();
        _showSnackBar('Contacts loaded after seeding default data');
      } catch (e2) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load contacts: $e2. Please check Firebase connection.', isError: true);
      }
    }
  }

  void _calculateStatistics() {
    final stats = <String, int>{};
    stats['total'] = _contacts.length;
    stats['countries'] = _contacts.map((c) => c.country).toSet().length;
    
    for (final type in ContactType.values) {
      stats[type.displayName] = _contacts.where((c) => c.type == type).length;
    }
    
    setState(() {
      _statistics = stats;
    });
  }

  void _filterContacts() {
    List<EmergencyContact> filtered = _contacts;
    
    // Filter by country
    if (_selectedCountry != 'All') {
      filtered = filtered.where((c) => c.country == _selectedCountry).toList();
    }
    
    // Filter by type
    if (_selectedType != null) {
      filtered = filtered.where((c) => c.type == _selectedType).toList();
    }
    
    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((contact) =>
          contact.name.toLowerCase().contains(query) ||
          contact.department.toLowerCase().contains(query) ||
          contact.description.toLowerCase().contains(query) ||
          contact.phone.contains(query)).toList();
    }
    
    setState(() {
      _filteredContacts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AfricanPatternBackground(opacity: 0.03),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                if (_statistics.isNotEmpty) _buildStatistics(),
                Expanded(child: _buildContactsList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage emergency contact database',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _testFirebaseConnection,
                    icon: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => _filterContacts(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: _countries.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(
                        country,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value!;
                    });
                    _filterContacts();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<ContactType?>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<ContactType?>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...ContactType.values.map((type) {
                      return DropdownMenuItem<ContactType>(
                        value: type,
                        child: Text(
                          type.displayName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _filterContacts();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          // Use Wrap instead of horizontal scroll to show all items
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildCompactStatItem('Total', _statistics['total'].toString(), Icons.contacts, AppTheme.primaryColor),
              _buildCompactStatItem('Countries', _statistics['countries'].toString(), Icons.public, Colors.blue),
              _buildCompactStatItem('Cybercrime', _statistics['Cybercrime'].toString(), Icons.security, Colors.red),
              _buildCompactStatItem('Police', _statistics['Police'].toString(), Icons.local_police, Colors.blue),
              _buildCompactStatItem('Financial', _statistics['Financial'].toString(), Icons.account_balance, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: color
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, 
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_phone, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or add a new contact',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showContactDetails(contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: contact.typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: contact.typeColor.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      contact.typeIcon,
                      color: contact.typeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.department,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          color: AppTheme.primaryColor,
                          onPressed: () => _showEditContactDialog(contact),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          color: Colors.red,
                          onPressed: () => _showDeleteConfirmation(contact),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: Text(
                      contact.phone,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.public, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      contact.country,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: contact.typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  contact.typeDisplayName,
                  style: TextStyle(
                    color: contact.typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => EmergencyContactEditorDialog(
        countries: _countries.where((c) => c != 'All').toList(),
        onSave: _saveContact,
      ),
    );
  }

  void _showEditContactDialog(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => EmergencyContactEditorDialog(
        contact: contact,
        countries: _countries.where((c) => c != 'All').toList(),
        onSave: _saveContact,
      ),
    );
  }

  Future<void> _saveContact(EmergencyContact contact, bool isNew) async {
    try {
      if (isNew) {
        await EmergencyContactsService.createContact(contact);
      } else {
        await EmergencyContactsService.updateContact(contact.id, contact);
      }
      
      _showSnackBar('Contact ${isNew ? 'created' : 'updated'} successfully');
      _loadData();
    } catch (e) {
      _showSnackBar('Failed to ${isNew ? 'create' : 'update'} contact: $e', isError: true);
    }
  }

  void _showDeleteConfirmation(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Contact'),
        content: Text(
          'Are you sure you want to delete "${contact.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContact(contact);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    try {
      await EmergencyContactsService.deleteContact(contact.id);
      _showSnackBar('Contact deleted successfully');
      _loadData();
    } catch (e) {
      _showSnackBar('Failed to delete contact: $e', isError: true);
    }
  }

  void _showContactDetails(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(contact.typeIcon, color: contact.typeColor),
            const SizedBox(width: 12),
            Expanded(child: Text(contact.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Department', contact.department),
              _buildDetailRow('Phone', contact.phone),
              if (contact.emergencyNumber != null)
                _buildDetailRow('Emergency Number', contact.emergencyNumber!),
              if (contact.email != null)
                _buildDetailRow('Email', contact.email!),
              if (contact.website != null)
                _buildDetailRow('Website', contact.website!),
              if (contact.address != null)
                _buildDetailRow('Address', contact.address!),
              _buildDetailRow('Description', contact.description),
              _buildDetailRow('Availability', contact.availability),
              _buildDetailRow('Languages', contact.languages.join(', ')),
              _buildDetailRow('Country', contact.country),
              _buildDetailRow('Priority', contact.priority.toString()),
              _buildDetailRow('Type', contact.typeDisplayName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditContactDialog(contact);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testFirebaseConnection() async {
    try {
      _showSnackBar('Testing Firebase connection...', isError: false);
      
      // Test basic Firestore connection
      final testDoc = await FirebaseFirestore.instance
          .collection('emergency_contacts')
          .limit(1)
          .get();
      
      _showSnackBar('Firebase connection successful! Found ${testDoc.docs.length} documents');
      
      // Now try seeding
      await EmergencyContactsService.seedDefaultData();
      _showSnackBar('Seeding completed successfully');
      
      // Try loading again
      await _loadData();
      
    } catch (e) {
      _showSnackBar('Firebase test failed: $e', isError: true);
      print('Firebase test error: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}