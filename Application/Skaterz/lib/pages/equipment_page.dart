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
    if (mounted) setState(() => _isLoading = true);
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
          
          // Optimistic UI update
          setState(() {
            if (item == null) {
              _equipment.add(Map<String, dynamic>.from(data)..['id'] = -1); // Temporary ID
            } else {
              final index = _equipment.indexWhere((e) => e['id'] == item['id']);
              if (index != -1) _equipment[index] = data;
            }
          });

          try {
            if (item == null) {
              final newItem = await _apiService.addEquipment(data);
              setState(() {
                final index = _equipment.indexWhere((e) => e['id'] == -1);
                if (index != -1) _equipment[index] = newItem!;
              });
            } else {
              await _apiService.updateEquipment(item['id'], data);
            }
          } catch (e) {
            // Revert on error
            _loadEquipment(); 
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
            child: Text(widget.localizations.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final originalItem = _equipment.firstWhere((e) => e['id'] == id);
      final index = _equipment.indexOf(originalItem);

      // Optimistic UI update
      setState(() {
        _equipment.removeWhere((e) => e['id'] == id);
      });

      try {
        await _apiService.deleteEquipment(id);
      } catch (e) {
        // Revert on error
        setState(() {
          _equipment.insert(index, originalItem);
        });
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.equipmentMenuItem,
        icon: Icons.handyman_outlined,
        onMenuTap: widget.onMenuTap,
      );
    }

    _equipment.sort((a, b) => (a['isActive'] == true) ? -1 : 1);
    final activeItems = _equipment.where((e) => e['isActive'] == true || e['active'] == true).toList();
    final inactiveItems = _equipment.where((e) => e['isActive'] != true && e['active'] != true).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.getDynamicGradient(context)),
        ),
        title: Text(widget.localizations.equipmentMenuItem.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: !isDesktop ? IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: widget.onMenuTap,
        ) : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'equipment_fab_main',
        onPressed: () => _showAddEditSheet(),
        backgroundColor: AppColors.getDynamicPrimary(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(widget.localizations.addEquipment.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEquipment,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: _buildCurrentSetupSummary(activeItems))),
                  if (activeItems.isNotEmpty)
                    SliverList(delegate: SliverChildBuilderDelegate((context, index) => _EquipmentCard(item: activeItems[index], localizations: widget.localizations, onEdit: () => _showAddEditSheet(item: activeItems[index]), onDelete: () => _deleteItem(activeItems[index]['id'])), childCount: activeItems.length)),
                  if (inactiveItems.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _buildSectionHeader(widget.localizations.inactiveSetup)),
                    SliverList(delegate: SliverChildBuilderDelegate((context, index) => _EquipmentCard(item: inactiveItems[index], localizations: widget.localizations, onEdit: () => _showAddEditSheet(item: inactiveItems[index]), onDelete: () => _deleteItem(inactiveItems[index]['id'])), childCount: inactiveItems.length)),
                  ],
                  if (_equipment.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.handyman_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(widget.localizations.noData, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentSetupSummary(List<dynamic> activeItems) {
    final deck = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'DECK', orElse: () => {});
    final trucks = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'TRUCKS', orElse: () => {});
    final wheels = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'WHEELS', orElse: () => {});
    final hasAnyActive = activeItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.getDynamicGradient(context),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.getDynamicPrimary(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.localizations.activeSetup.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSetupIcon(Icons.layers_rounded, deck['brand'] ?? (hasAnyActive ? '?' : '-'), widget.localizations.typeDeck),
              _buildSetupIcon(Icons.settings_input_component_rounded, trucks['brand'] ?? (hasAnyActive ? '?' : '-'), widget.localizations.typeTrucks),
              _buildSetupIcon(Icons.album_rounded, wheels['brand'] ?? (hasAnyActive ? '?' : '-'), widget.localizations.typeWheels),
            ],
          ),
          if (!hasAnyActive) const Center(child: Text('No active setup', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSetupIcon(IconData icon, String label, String category) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text(category.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5, fontSize: 12)),
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
      case 'DECK': return Icons.layers_rounded;
      case 'TRUCKS': return Icons.settings_input_component_rounded;
      case 'WHEELS': return Icons.album_rounded;
      case 'BEARINGS': return Icons.motion_photos_on_rounded;
      case 'GRIP': return Icons.texture_rounded;
      case 'HARDWARE': return Icons.build_rounded;
      default: return Icons.handyman_rounded;
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: (isActive ? AppColors.getDynamicPrimary(context) : Colors.grey).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_getTypeIcon(item['type'] ?? ''), color: isActive ? AppColors.getDynamicPrimary(context) : Colors.grey, size: 20),
        ),
        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item['brand'] ?? ''} ${item['model'] ?? ''}'.trim()),
        trailing: daysInUse > 0 ? Text('$daysInUse d', style: TextStyle(color: _getLifecycleColor(daysInUse, item['type'] ?? ''), fontWeight: FontWeight.bold, fontSize: 12)) : null,
      ),
    );
  }

  Color _getLifecycleColor(int days, String type) {
    int limit = 90;
    if (type.toUpperCase() == 'DECK') limit = 45; 
    if (type.toUpperCase() == 'WHEELS') limit = 180;
    if (days < limit * 0.5) return AppColors.success;
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
    'Summer Supply', 'Baker', 'Element', 'Independent', 'Santa Cruz', 'Venture', 'Thunder',
    'Spitfire', 'Bones', 'Ricta', 'Girl', 'Chocolate', 'Real', 'Anti-Hero', 'Krooked',
    'Creature', 'Palace', 'Polar', 'Primitive', 'Flip', 'Enjoi', 'Almost', 'Blind',
    'Deathwish', 'Zero', 'Tensor', 'Ace', 'Royal', 'Krux', 'Powell Peralta', 'Bronson'
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _type = item?['type'] ?? 'DECK';
    _nameController = TextEditingController(text: item?['brand'] ?? ''); // Use Brand as default name
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 12),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(widget.item == null ? widget.localizations.addEquipment : widget.localizations.editEquipment, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: widget.localizations.equipmentType),
                items: ['DECK', 'TRUCKS', 'WHEELS', 'BEARINGS', 'GRIP', 'HARDWARE'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return _commonBrands.where((brand) => brand.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  setState(() {
                    _brandController.text = selection;
                    _nameController.text = selection; // Auto-fill name with brand
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: widget.localizations.equipmentBrand,
                      hintText: 'e.g. Summer Supply',
                    ),
                    onChanged: (v) {
                      _brandController.text = v;
                      _nameController.text = v;
                    },
                    validator: (v) => v!.isEmpty ? widget.localizations.enterCredentials : null,
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
                        final picked = await showDatePicker(context: context, initialDate: _setupDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                        if (picked != null) setState(() => _setupDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: widget.localizations.price, suffixText: '€'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _notesController, decoration: InputDecoration(labelText: widget.localizations.equipmentNotes), maxLines: 2),
              const SizedBox(height: 16),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(widget.localizations.active), value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: AppColors.primary),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave({
                      'type': _type, 'name': _nameController.text, 'brand': _brandController.text, 'model': _modelController.text, 'size': _sizeController.text, 
                      'notes': _notesController.text, 'isActive': _isActive, 'price': double.tryParse(_priceController.text) ?? 0.0, 'setupDate': _setupDate.toIso8601String().split('T')[0],
                    });
                  }
                }, child: Text(widget.localizations.saveAndContinue.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
