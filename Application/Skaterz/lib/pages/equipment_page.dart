import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/login_required_view.dart';

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
                        padding: const EdgeInsets.only(top: 100),
                        child: Column(
                          children: [
                            Icon(Icons.handyman_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(widget.localizations.noData, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onEdit,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_getTypeIcon(item['type'] ?? ''), color: AppColors.primary),
        ),
        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item['brand'] ?? ''} ${item['model'] ?? ''}'.trim()),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
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
  late bool _isActive;

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
    _isActive = item?['isActive'] ?? item?['active'] ?? true;
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
                decoration: InputDecoration(labelText: widget.localizations.name),
                validator: (v) => v!.isEmpty ? widget.localizations.enterCredentials : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _brandController, decoration: InputDecoration(labelText: widget.localizations.equipmentBrand))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _modelController, decoration: InputDecoration(labelText: widget.localizations.equipmentModel))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _sizeController, decoration: InputDecoration(labelText: widget.localizations.equipmentSize)),
              const SizedBox(height: 16),
              TextFormField(controller: _notesController, decoration: InputDecoration(labelText: widget.localizations.equipmentNotes), maxLines: 2),
              const SizedBox(height: 16),
              SwitchListTile(
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
                        'setupDate': widget.item?['setupDate'] ?? DateTime.now().toIso8601String().split('T')[0],
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
