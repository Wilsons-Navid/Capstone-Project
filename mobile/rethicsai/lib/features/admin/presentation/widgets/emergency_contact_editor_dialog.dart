import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/services/emergency_contacts_service.dart';

class EmergencyContactEditorDialog extends StatefulWidget {
  final EmergencyContact? contact;
  final List<String> countries;
  final Function(EmergencyContact contact, bool isNew) onSave;

  const EmergencyContactEditorDialog({
    super.key,
    this.contact,
    required this.countries,
    required this.onSave,
  });

  @override
  State<EmergencyContactEditorDialog> createState() => _EmergencyContactEditorDialogState();
}

class _EmergencyContactEditorDialogState extends State<EmergencyContactEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyNumberController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _availabilityController;
  late TextEditingController _priorityController;
  
  ContactType _selectedType = ContactType.cyberCrime;
  String _selectedCountry = '';
  List<String> _selectedLanguages = [];

  // Lets the admin register a brand-new country instead of only picking an
  // existing one. A country is represented by the contacts that carry it.
  static const String _kAddNewCountry = '__add_new_country__';
  bool _addingNewCountry = false;
  late TextEditingController _newCountryController;
  
  final List<String> _availableLanguages = [
    'English', 'Swahili', 'Hausa', 'Yoruba', 'Igbo', 'Afrikaans', 
    'Zulu', 'Xhosa', 'French', 'Arabic', 'Amharic', 'Portuguese'
  ];

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    
    final contact = widget.contact;
    _nameController = TextEditingController(text: contact?.name ?? '');
    _departmentController = TextEditingController(text: contact?.department ?? '');
    _phoneController = TextEditingController(text: contact?.phone ?? '');
    _emergencyNumberController = TextEditingController(text: contact?.emergencyNumber ?? '');
    _emailController = TextEditingController(text: contact?.email ?? '');
    _websiteController = TextEditingController(text: contact?.website ?? '');
    _addressController = TextEditingController(text: contact?.address ?? '');
    _descriptionController = TextEditingController(text: contact?.description ?? '');
    _availabilityController = TextEditingController(text: contact?.availability ?? '24/7');
    _priorityController = TextEditingController(text: contact?.priority.toString() ?? '5');
    
    _selectedType = contact?.type ?? ContactType.cyberCrime;
    _selectedCountry = contact?.country ?? (widget.countries.isNotEmpty ? widget.countries.first : '');
    _newCountryController = TextEditingController();
    // If editing a contact whose country isn't in the known list, treat it as new.
    if (_selectedCountry.isNotEmpty && !widget.countries.contains(_selectedCountry)) {
      _addingNewCountry = true;
      _newCountryController.text = _selectedCountry;
    }
    _selectedLanguages = List<String>.from(contact?.languages ?? ['English']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _emergencyNumberController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _availabilityController.dispose();
    _priorityController.dispose();
    _newCountryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.95,
          minHeight: 300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Contact' : 'Add New Contact',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: 8),
                      
                      _buildTextFormField(
                        controller: _nameController,
                        label: 'Organization Name *',
                        hint: 'e.g., Nigeria Police Force Cybercrime Unit',
                        validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      _buildTextFormField(
                        controller: _departmentController,
                        label: 'Department *',
                        hint: 'e.g., NPF-SCID Cybercrime Division',
                        validator: (value) => value?.isEmpty == true ? 'Department is required' : null,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<ContactType>(
                              value: _selectedType,
                              decoration: InputDecoration(
                                labelText: 'Type *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                              ),
                              items: ContactType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getTypeIcon(type), size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          type.displayName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _addingNewCountry
                                  ? _kAddNewCountry
                                  : (_selectedCountry.isEmpty ? null : _selectedCountry),
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Country *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                              ),
                              items: [
                                ...widget.countries.map((country) {
                                  return DropdownMenuItem(
                                    value: country,
                                    child: Text(
                                      country,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }),
                                const DropdownMenuItem(
                                  value: _kAddNewCountry,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 14, color: AppTheme.primaryColor),
                                      SizedBox(width: 4),
                                      Text('Add new country',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  if (value == _kAddNewCountry) {
                                    _addingNewCountry = true;
                                  } else {
                                    _addingNewCountry = false;
                                    _selectedCountry = value ?? '';
                                  }
                                });
                              },
                              validator: (value) => value == null ? 'Country is required' : null,
                            ),
                          ),
                        ],
                      ),

                      // New-country name field (shown when "Add new country" is picked).
                      if (_addingNewCountry) ...[
                        const SizedBox(height: 8),
                        _buildTextFormField(
                          controller: _newCountryController,
                          label: 'New country name *',
                          hint: 'e.g., Zambia',
                          validator: (value) => _addingNewCountry &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Country name is required'
                              : null,
                        ),
                      ],

                      const SizedBox(height: 10),
                      
                      // Contact Information
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextFormField(
                              controller: _phoneController,
                              label: 'Phone Number *',
                              hint: '+234-1-4931260',
                              validator: (value) => value?.isEmpty == true ? 'Phone is required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildTextFormField(
                              controller: _emergencyNumberController,
                              label: 'Emergency Number',
                              hint: '199',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'cybercrime@npf.gov.ng',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _websiteController,
                              label: 'Website',
                              hint: 'https://www.npf.gov.ng',
                              keyboardType: TextInputType.url,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      _buildTextFormField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'Louis Edet House, Area 11, Garki, Abuja',
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Additional Information
                      _buildSectionTitle('Additional Information'),
                      const SizedBox(height: 8),
                      
                      _buildTextFormField(
                        controller: _descriptionController,
                        label: 'Description *',
                        hint: 'Brief description of services provided',
                        maxLines: 3,
                        validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextFormField(
                              controller: _availabilityController,
                              label: 'Availability *',
                              hint: '24/7, Mon-Fri 8AM-6PM, etc.',
                              validator: (value) => value?.isEmpty == true ? 'Availability is required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: _buildTextFormField(
                              controller: _priorityController,
                              label: 'Priority (1-10) *',
                              hint: '1-10',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^(10|[1-9])$')),
                              ],
                              validator: (value) {
                                if (value?.isEmpty == true) return 'Priority is required';
                                final priority = int.tryParse(value!);
                                if (priority == null || priority < 1 || priority > 10) {
                                  return 'Priority must be between 1 and 10';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Languages
                      Text(
                        'Supported Languages *',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _availableLanguages.map((language) {
                            final isSelected = _selectedLanguages.contains(language);
                            return FilterChip(
                              label: Text(
                                language,
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedLanguages.add(language);
                                  } else {
                                    _selectedLanguages.remove(language);
                                  }
                                });
                              },
                              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      if (_selectedLanguages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Please select at least one language',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_isEditing ? 'Update Contact' : 'Create Contact'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
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

  void _saveContact() {
    if (!_formKey.currentState!.validate()) return;

    // Resolve the country: a freshly typed one when adding, else the picked one.
    final country = _addingNewCountry
        ? _newCountryController.text.trim()
        : _selectedCountry;
    if (country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose or enter a country'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one language'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final contact = EmergencyContact(
      id: _isEditing ? widget.contact!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      name: _nameController.text.trim(),
      department: _departmentController.text.trim(),
      phone: _phoneController.text.trim(),
      emergencyNumber: _emergencyNumberController.text.trim().isEmpty 
          ? null 
          : _emergencyNumberController.text.trim(),
      email: _emailController.text.trim().isEmpty 
          ? null 
          : _emailController.text.trim(),
      website: _websiteController.text.trim().isEmpty 
          ? null 
          : _websiteController.text.trim(),
      address: _addressController.text.trim().isEmpty 
          ? null 
          : _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      availability: _availabilityController.text.trim(),
      languages: _selectedLanguages,
      country: country,
      priority: int.parse(_priorityController.text.trim()),
      createdAt: _isEditing ? widget.contact!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    widget.onSave(contact, !_isEditing);
    Navigator.pop(context);
  }
}