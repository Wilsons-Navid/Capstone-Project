import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';
import '../../../../core/services/threat_management_service.dart';

class ThreatManagementPage extends StatefulWidget {
  const ThreatManagementPage({super.key});

  @override
  State<ThreatManagementPage> createState() => _ThreatManagementPageState();
}

class _ThreatManagementPageState extends State<ThreatManagementPage> {
  final ThreatManagementService _threatService = ThreatManagementService();
  final TextEditingController _searchController = TextEditingController();
  
  List<VerifiedThreat> _allThreats = [];
  List<VerifiedThreat> _filteredThreats = [];
  Map<String, int> _statistics = {};
  
  ThreatContentType? _selectedType;
  ThreatRiskLevel? _selectedRiskLevel;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadThreats();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadThreats() async {
    setState(() => _isLoading = true);
    try {
      final threats = await _threatService.getAllThreats();
      setState(() {
        _allThreats = threats;
        _filteredThreats = threats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load threats: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _threatService.getThreatStatistics();
      setState(() => _statistics = stats);
    } catch (e) {
      print('Failed to load statistics: $e');
    }
  }

  void _filterThreats() {
    List<VerifiedThreat> filtered = _allThreats;

    if (_selectedType != null) {
      filtered = filtered.where((threat) => threat.type == _selectedType).toList();
    }

    if (_selectedRiskLevel != null) {
      filtered = filtered.where((threat) => threat.threatLevel == _selectedRiskLevel).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((threat) =>
          threat.value.toLowerCase().contains(query) ||
          threat.description.toLowerCase().contains(query) ||
          threat.category.toLowerCase().contains(query)).toList();
    }

    setState(() => _filteredThreats = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterThreats();
  }

  void _onTypeFilterChanged(ThreatContentType? type) {
    setState(() => _selectedType = type);
    _filterThreats();
  }

  void _onRiskFilterChanged(ThreatRiskLevel? level) {
    setState(() => _selectedRiskLevel = level);
    _filterThreats();
  }

  Future<void> _showAddThreatDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AddThreatDialog(
        onThreatAdded: () {
          _loadThreats();
          _loadStatistics();
        },
      ),
    );
  }

  Future<void> _showEditThreatDialog(VerifiedThreat threat) async {
    await showDialog(
      context: context,
      builder: (context) => EditThreatDialog(
        threat: threat,
        onThreatUpdated: () {
          _loadThreats();
          _loadStatistics();
        },
      ),
    );
  }

  Future<void> _deleteThreat(VerifiedThreat threat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Threat'),
        content: Text('Are you sure you want to delete this threat?\n\n${threat.value}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _threatService.deleteThreat(threat.id);
        _loadThreats();
        _loadStatistics();
        _showSuccessSnackBar('Threat deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete threat: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Expanded(
                            child: Text(
                              'Threat Management',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: _showAddThreatDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Statistics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('Total', _statistics['total']?.toString() ?? '0'),
                          _buildStatCard('Active', _statistics['active']?.toString() ?? '0'),
                          _buildStatCard('High Risk', _statistics['high_risk']?.toString() ?? '0'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Search and Filters
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search threats...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeFilter(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRiskFilter(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Threats List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredThreats.isEmpty
                          ? const Center(
                              child: Text(
                                'No threats found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredThreats.length,
                              itemBuilder: (context, index) {
                                final threat = _filteredThreats[index];
                                return _buildThreatCard(threat);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<ThreatContentType?>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Type',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem<ThreatContentType?>(
          value: null,
          child: Text('All Types'),
        ),
        ...ThreatContentType.values.map((type) => DropdownMenuItem(
          value: type,
          child: Text(type.displayName),
        )),
      ],
      onChanged: _onTypeFilterChanged,
    );
  }

  Widget _buildRiskFilter() {
    return DropdownButtonFormField<ThreatRiskLevel?>(
      value: _selectedRiskLevel,
      decoration: InputDecoration(
        labelText: 'Risk Level',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem<ThreatRiskLevel?>(
          value: null,
          child: Text('All Levels'),
        ),
        ...ThreatRiskLevel.values.map((level) => DropdownMenuItem(
          value: level,
          child: Text(level.displayName),
        )),
      ],
      onChanged: _onRiskFilterChanged,
    );
  }

  Widget _buildThreatCard(VerifiedThreat threat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          threat.value,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(threat.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildTypeChip(threat.type),
                const SizedBox(width: 8),
                _buildRiskChip(threat.threatLevel),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditThreatDialog(threat);
            } else if (value == 'delete') {
              _deleteThreat(threat);
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTypeChip(ThreatContentType type) {
    final colors = {
      ThreatContentType.url: Colors.blue,
      ThreatContentType.email: Colors.green,
      ThreatContentType.phone: Colors.orange,
      ThreatContentType.text: Colors.purple,
    };

    return Chip(
      label: Text(
        type.displayName,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: colors[type],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRiskChip(ThreatRiskLevel level) {
    final colors = {
      ThreatRiskLevel.safe: Colors.green,
      ThreatRiskLevel.low: Colors.yellow[700],
      ThreatRiskLevel.medium: Colors.orange,
      ThreatRiskLevel.high: Colors.red,
      ThreatRiskLevel.critical: Colors.red[900],
    };

    return Chip(
      label: Text(
        level.displayName,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: colors[level],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class AddThreatDialog extends StatefulWidget {
  final VoidCallback onThreatAdded;

  const AddThreatDialog({super.key, required this.onThreatAdded});

  @override
  State<AddThreatDialog> createState() => _AddThreatDialogState();
}

class _AddThreatDialogState extends State<AddThreatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _threatService = ThreatManagementService();
  
  final _valueController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ThreatContentType _selectedType = ThreatContentType.url;
  ThreatRiskLevel _selectedRiskLevel = ThreatRiskLevel.medium;
  List<String> _recommendations = ['Avoid this content', 'Report if encountered'];
  bool _isLoading = false;

  @override
  void dispose() {
    _valueController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addThreat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final threat = VerifiedThreat.create(
        type: _selectedType,
        value: _valueController.text.trim(),
        threatLevel: _selectedRiskLevel,
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        recommendations: _recommendations.where((r) => r.isNotEmpty).toList(),
        addedBy: user?.email ?? 'Unknown',
      );

      await _threatService.addThreat(threat);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onThreatAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Threat added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add threat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Threat'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ThreatContentType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ThreatContentType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Threat Value'),
                validator: (value) => value?.isEmpty == true ? 'Please enter a value' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => value?.isEmpty == true ? 'Please enter a category' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<ThreatRiskLevel>(
                value: _selectedRiskLevel,
                decoration: const InputDecoration(labelText: 'Risk Level'),
                items: ThreatRiskLevel.values.map((level) => DropdownMenuItem(
                  value: level,
                  child: Text(level.displayName),
                )).toList(),
                onChanged: (value) => setState(() => _selectedRiskLevel = value!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Please enter a description' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addThreat,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

class EditThreatDialog extends StatefulWidget {
  final VerifiedThreat threat;
  final VoidCallback onThreatUpdated;

  const EditThreatDialog({
    super.key,
    required this.threat,
    required this.onThreatUpdated,
  });

  @override
  State<EditThreatDialog> createState() => _EditThreatDialogState();
}

class _EditThreatDialogState extends State<EditThreatDialog> {
  final _formKey = GlobalKey<FormState>();
  final _threatService = ThreatManagementService();
  
  late final TextEditingController _valueController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  
  late ThreatContentType _selectedType;
  late ThreatRiskLevel _selectedRiskLevel;
  late List<String> _recommendations;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.threat.value);
    _categoryController = TextEditingController(text: widget.threat.category);
    _descriptionController = TextEditingController(text: widget.threat.description);
    _selectedType = widget.threat.type;
    _selectedRiskLevel = widget.threat.threatLevel;
    _recommendations = List.from(widget.threat.recommendations);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateThreat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedThreat = widget.threat.copyWith(
        type: _selectedType,
        value: _valueController.text.trim(),
        threatLevel: _selectedRiskLevel,
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        recommendations: _recommendations.where((r) => r.isNotEmpty).toList(),
      );

      await _threatService.updateThreat(updatedThreat);
      
      if (mounted) {
        Navigator.pop(context);
        widget.onThreatUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Threat updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update threat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Threat'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ThreatContentType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ThreatContentType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Threat Value'),
                validator: (value) => value?.isEmpty == true ? 'Please enter a value' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => value?.isEmpty == true ? 'Please enter a category' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<ThreatRiskLevel>(
                value: _selectedRiskLevel,
                decoration: const InputDecoration(labelText: 'Risk Level'),
                items: ThreatRiskLevel.values.map((level) => DropdownMenuItem(
                  value: level,
                  child: Text(level.displayName),
                )).toList(),
                onChanged: (value) => setState(() => _selectedRiskLevel = value!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Please enter a description' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateThreat,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}