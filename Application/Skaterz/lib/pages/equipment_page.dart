import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/login_required_view.dart';
import 'package:intl/intl.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onMenuTap,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onMenuTap;

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _equipment = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadEquipment();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadEquipment() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getEquipment();
      if (mounted) {
        setState(() {
          _equipment = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.error}: $e')),
        );
      }
    }
  }

  void _showAddEditSheet({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditEquipmentSheet(
        localizations: widget.localizations,
        item: item,
        onSave: (data) async {
          Navigator.pop(context);
          try {
            if (item == null) {
              await _apiService.addEquipment(data);
            } else {
              await _apiService.updateEquipment(item['id'], data);
            }
            _loadEquipment();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.localizations.error}: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.deleteEquipment),
        content: Text(widget.localizations.deleteEquipmentConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(widget.localizations.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.localizations.undo, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteEquipment(id);
        _loadEquipment();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.localizations.error}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.equipmentMenuItem,
        icon: Icons.handyman_outlined,
        onMenuTap: widget.onMenuTap,
      );
    }

    final activeItems = _equipment.where((e) => e['isActive'] == true || e['active'] == true).toList();
    final inactiveItems = _equipment.where((e) => e['isActive'] == false && e['active'] == false).toList();

    double totalCost = 0;
    for (var item in activeItems) {
      totalCost += (item['price'] ?? 0).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        title: Text(widget.localizations.equipmentMenuItem, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: !isDesktop ? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuTap,
        ) : null,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'equipment_fab_main',
        onPressed: () => _showAddEditSheet(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEquipment,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCurrentSetupSummary(activeItems, totalCost),
                  const SizedBox(height: 24),
                  
                  if (activeItems.isNotEmpty) ...[
                    _buildSectionHeader(widget.localizations.activeSetup),
                    ...activeItems.map((e) => _EquipmentCard(
                      item: e, 
                      localizations: widget.localizations,
                      onEdit: () => _showAddEditSheet(item: e),
                      onDelete: () => _deleteItem(e['id']),
                    )),
                  ],
                  
                  if (inactiveItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(widget.localizations.inactiveSetup),
                    ...inactiveItems.map((e) => _EquipmentCard(
                      item: e, 
                      localizations: widget.localizations,
                      onEdit: () => _showAddEditSheet(item: e),
                      onDelete: () => _deleteItem(e['id']),
                    )),
                  ],
                  
                  if (_equipment.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Icon(Icons.handyman_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(widget.localizations.noData, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentSetupSummary(List<dynamic> activeItems, double totalCost) {
    final deck = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'DECK', orElse: () => {});
    final trucks = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'TRUCKS', orElse: () => {});
    final wheels = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'WHEELS', orElse: () => {});

    final bool hasAnyActive = activeItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.localizations.activeSetup,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (totalCost > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${totalCost.toStringAsFixed(2)} €',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                )
              else
                const Icon(Icons.bolt, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSetupIcon(Icons.layers, deck['brand'] ?? (hasAnyActive ? '?' : '-'), widget.localizations.typeDeck),
              _buildSetupIcon(Icons.settings_input_component, trucks['brand'] ?? (hasAnyActive ? '?' : '-'), widget.localizations.typeTrucks),
              _buildSetupIcon(Icons.circle_outlined, wheels['brand'] ?? (hasAnyActive ? '?' : '-'), widget.localizations.typeWheels),
            ],
          ),
          if (!hasAnyActive) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No active setup configured',
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupIcon(IconData icon, String label, String category) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(category, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2, fontSize: 13),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.item, required this.localizations, required this.onEdit, required this.onDelete});
  final Map<String, dynamic> item;
  final AppLocalizations localizations;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'DECK': return Icons.layers;
      case 'TRUCKS': return Icons.settings_input_component;
      case 'WHEELS': return Icons.circle_outlined;
      case 'BEARINGS': return Icons.blur_circular;
      case 'GRIP': return Icons.texture;
      case 'HARDWARE': return Icons.build;
      default: return Icons.handyman;
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupDateStr = item['setupDate'] ?? item['setup_date'];
    int daysInUse = 0;
    if (setupDateStr != null) {
      try {
        final date = DateTime.parse(setupDateStr.toString());
        daysInUse = DateTime.now().difference(date).inDays;
      } catch (_) {}
    }

    final bool isActive = item['isActive'] == true || item['active'] == true;
    final double? price = item['price'] != null ? (item['price'] as num).toDouble() : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.1), 
            shape: BoxShape.circle
          ),
          child: Icon(_getTypeIcon(item['type'] ?? ''), color: isActive ? AppColors.primary : Colors.grey),
        ),
        title: Row(
          children: [
            Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
            if (price != null && price > 0)
              Text(
                '${price.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey[600]
                ),
              ),
            const SizedBox(width: 8),
            if (isActive && daysInUse > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLifecycleColor(daysInUse, item['type'] ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$daysInUse d',
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: _getLifecycleColor(daysInUse, item['type'] ?? '')
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item['brand'] ?? ''} ${item['model'] ?? ''} ${item['size'] ?? ''}'.trim()),
            if (item['notes'] != null && item['notes'].toString().isNotEmpty)
              Text(
                item['notes'], 
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Color _getLifecycleColor(int days, String type) {
    int limit = 90; // Default 3 months
    if (type.toUpperCase() == 'DECK') limit = 45; // Decks wear faster
    if (type.toUpperCase() == 'WHEELS') limit = 180; // Wheels last longer
    
    if (days < limit * 0.5) return Colors.green;
    if (days < limit) return Colors.orange;
    return Colors.red;
  }
}

class _AddEditEquipmentSheet extends StatefulWidget {
  const _AddEditEquipmentSheet({required this.localizations, this.item, required this.onSave});
  final AppLocalizations localizations;
  final Map<String, dynamic>? item;
  final Function(Map<String, dynamic>) onSave;

  @override
  State<_AddEditEquipmentSheet> createState() => _AddEditEquipmentSheetState();
}

class _AddEditEquipmentSheetState extends State<_AddEditEquipmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _sizeController;
  late TextEditingController _notesController;
  late TextEditingController _priceController;
  late DateTime _setupDate;
  late bool _isActive;

  final List<String> _commonBrands = [
    'Independent', 'Thunder', 'Venture', 'Independent', 'Santa Cruz', 'Baker', 'Element', 
    'Spitfire', 'Bones', 'Ricta', 'Girl', 'Chocolate', 'Real', 'Anti-Hero', 'Krooked',
    'Creature', 'Palace', 'Polar', 'Primitive', 'Flip', 'Enjoi', 'Almost', 'Blind',
    'Deathwish', 'Zero', 'Tensor', 'Ace', 'Royal', 'Krux', 'Powell Peralta', 'Bronson'
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _type = item?['type'] ?? 'DECK';
    _nameController = TextEditingController(text: item?['name'] ?? '');
    _brandController = TextEditingController(text: item?['brand'] ?? '');
    _modelController = TextEditingController(text: item?['model'] ?? '');
    _sizeController = TextEditingController(text: item?['size'] ?? '');
    _notesController = TextEditingController(text: item?['notes'] ?? '');
    _priceController = TextEditingController(text: item?['price']?.toString() ?? '');
    _isActive = item?['isActive'] ?? item?['active'] ?? true;
    
    final dateStr = item?['setupDate'] ?? item?['setup_date'];
    _setupDate = dateStr != null ? DateTime.parse(dateStr.toString()) : DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _sizeController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(
                widget.item == null ? widget.localizations.addEquipment : widget.localizations.editEquipment,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: widget.localizations.equipmentType),
                items: ['DECK', 'TRUCKS', 'WHEELS', 'BEARINGS', 'GRIP', 'HARDWARE'].map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: widget.localizations.name,
                  hintText: 'e.g. Daily Setup',
                ),
                validator: (v) => v!.isEmpty ? widget.localizations.enterCredentials : null,
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return _commonBrands.where((brand) => brand.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) => _brandController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Link internal controller with autocomplete
                  if (controller.text.isEmpty && _brandController.text.isNotEmpty) {
                    controller.text = _brandController.text;
                  }
                  controller.addListener(() => _brandController.text = controller.text);
                  
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(labelText: widget.localizations.equipmentBrand),
                    onFieldSubmitted: (v) => onFieldSubmitted(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _modelController, decoration: InputDecoration(labelText: widget.localizations.equipmentModel))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _sizeController, decoration: InputDecoration(labelText: widget.localizations.equipmentSize))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(widget.localizations.setupDate),
                      subtitle: Text(DateFormat.yMMMMd().format(_setupDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _setupDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _setupDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: widget.localizations.price,
                        suffixText: '€',
                        prefixIcon: const Icon(Icons.euro),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _notesController, decoration: InputDecoration(labelText: widget.localizations.equipmentNotes), maxLines: 2),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(widget.localizations.active),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave({
                        'type': _type,
                        'name': _nameController.text,
                        'brand': _brandController.text,
                        'model': _modelController.text,
                        'size': _sizeController.text,
                        'notes': _notesController.text,
                        'isActive': _isActive,
                        'price': double.tryParse(_priceController.text) ?? 0.0,
                        'setupDate': _setupDate.toIso8601String().split('T')[0],
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.localizations.saveAndContinue, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
