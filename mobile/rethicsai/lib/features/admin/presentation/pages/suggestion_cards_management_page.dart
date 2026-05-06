import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../shared/widgets/african_pattern_background.dart';
import '../../../../shared/widgets/premium_components.dart';
import '../../../../shared/models/suggestion_card_model.dart';
import '../../../../core/services/suggestion_cards_admin_service.dart';
import '../widgets/suggestion_card_editor_dialog.dart';

class SuggestionCardsManagementPage extends StatefulWidget {
  const SuggestionCardsManagementPage({super.key});

  @override
  State<SuggestionCardsManagementPage> createState() =>
      _SuggestionCardsManagementPageState();
}

class _SuggestionCardsManagementPageState
    extends State<SuggestionCardsManagementPage> {
  final SuggestionCardsAdminService _adminService =
      SuggestionCardsAdminService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, int> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _adminService.initializeDefaultCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final stats = await _adminService.getCardsStatistics();
    if (mounted) {
      setState(() {
        _statistics = stats;
      });
    }
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
                      // Header row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
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
                                  'Wilson AI Cards',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Manage suggestion cards for users',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _showAddCardDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Search bar
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search cards...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Statistics
                if (_statistics.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(20),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total',
                            _statistics['total'].toString(),
                            Icons.widgets,
                            AppTheme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Active',
                            _statistics['active'].toString(),
                            Icons.visibility,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Inactive',
                            _statistics['inactive'].toString(),
                            Icons.visibility_off,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Categories',
                            _statistics['categories'].toString(),
                            Icons.category,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Cards list
                Expanded(
                  child: _buildCardsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCardsList() {
    return StreamBuilder<List<SuggestionCardModel>>(
      stream: _searchQuery.isEmpty
          ? _adminService.getSuggestionCardsStream()
          : _adminService.searchCards(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading cards',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final cards = snapshot.data ?? [];

        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.widgets, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No cards found' : 'No cards match your search',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                if (_searchQuery.isEmpty)
                  ElevatedButton.icon(
                    onPressed: _showAddCardDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: cards.length,
          onReorder: (oldIndex, newIndex) => _reorderCards(cards, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildCardItem(card, index);
          },
        );
      },
    );
  }

  Widget _buildCardItem(SuggestionCardModel card, int index) {
    return Card(
      key: ValueKey(card.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: card.gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            card.iconData,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                card.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!card.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              card.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Category: ${card.category}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                card.isActive ? Icons.visibility : Icons.visibility_off,
                color: card.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleCardStatus(card),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => _showEditCardDialog(card),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(card),
            ),
          ],
        ),
        onTap: () => _showCardDetails(card),
      ),
    );
  }

  Future<void> _reorderCards(List<SuggestionCardModel> cards, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    
    final item = cards.removeAt(oldIndex);
    cards.insert(newIndex, item);
    
    final cardIds = cards.map((card) => card.id).toList();
    await _adminService.reorderCards(cardIds, 'current_admin_user'); // Replace with actual user ID
    
    _loadStatistics();
  }

  Future<void> _toggleCardStatus(SuggestionCardModel card) async {
    final success = await _adminService.toggleCardStatus(
      card.id,
      !card.isActive,
      'current_admin_user', // Replace with actual user ID
    );
    
    if (success) {
      _showSnackBar('Card ${card.isActive ? 'deactivated' : 'activated'} successfully');
      _loadStatistics();
    } else {
      _showSnackBar('Failed to update card status', isError: true);
    }
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) => SuggestionCardEditorDialog(
        onSave: _saveCard,
      ),
    );
  }

  void _showEditCardDialog(SuggestionCardModel card) {
    showDialog(
      context: context,
      builder: (context) => SuggestionCardEditorDialog(
        card: card,
        onSave: _saveCard,
      ),
    );
  }

  Future<void> _saveCard(SuggestionCardModel card, bool isNew) async {
    final success = isNew
        ? await _adminService.createSuggestionCard(card)
        : await _adminService.updateSuggestionCard(card);
    
    if (success) {
      _showSnackBar('Card ${isNew ? 'created' : 'updated'} successfully');
      _loadStatistics();
    } else {
      _showSnackBar('Failed to ${isNew ? 'create' : 'update'} card', isError: true);
    }
  }

  void _showDeleteConfirmation(SuggestionCardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Card'),
        content: Text(
          'Are you sure you want to delete "${card.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCard(card);
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

  Future<void> _deleteCard(SuggestionCardModel card) async {
    final success = await _adminService.deleteSuggestionCard(card.id);
    
    if (success) {
      _showSnackBar('Card deleted successfully');
      _loadStatistics();
    } else {
      _showSnackBar('Failed to delete card', isError: true);
    }
  }

  void _showCardDetails(SuggestionCardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: card.gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                card.iconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                card.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Subtitle', card.subtitle),
              _buildDetailRow('Question', card.text),
              _buildDetailRow('Category', card.category),
              _buildDetailRow('Sort Order', card.sortOrder.toString()),
              _buildDetailRow('Status', card.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', _formatDate(card.createdAt)),
              _buildDetailRow('Updated', _formatDate(card.updatedAt)),
              if (card.createdBy != null)
                _buildDetailRow('Created By', card.createdBy!),
              if (card.updatedBy != null)
                _buildDetailRow('Updated By', card.updatedBy!),
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
              _showEditCardDialog(card);
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

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}