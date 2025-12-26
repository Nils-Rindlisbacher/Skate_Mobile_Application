import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';

class InitialTrickSelectionPage extends StatefulWidget {
  const InitialTrickSelectionPage({
    super.key,
    required this.localizations,
    required this.onComplete,
  });

  final AppLocalizations localizations;
  final VoidCallback onComplete;

  @override
  State<InitialTrickSelectionPage> createState() => _InitialTrickSelectionPageState();
}

class _InitialTrickSelectionPageState extends State<InitialTrickSelectionPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allTricks = [];
  final Set<int> _selectedTrickIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadTricks();
  }

  Future<void> _loadTricks() async {
    try {
      final tricks = await _apiService.getTricks();
      // Alphabetical sorting
      tricks.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
      
      setState(() {
        _allTricks = tricks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tricks: $e')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      for (int trickId in _selectedTrickIds) {
        await _apiService.toggleCompleted(trickId, false);
      }
      
      if (mounted) {
        widget.onComplete();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTricks = _allTricks.where((trick) =>
      trick['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002211), Color(0xFF004D40), Color(0xFF00FF88)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(
          widget.localizations.selectInitialTricksTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        widget.localizations.selectInitialTricksSubtitle,
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: widget.localizations.searchTricks,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredTricks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final trick = filteredTricks[index];
                      final int id = trick['id'];
                      final bool isSelected = _selectedTrickIds.contains(id);

                      return CheckboxListTile(
                        title: Text(trick['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(trick['description'] ?? ''),
                        secondary: const Icon(Icons.skateboarding, color: Color(0xFF004D40)),
                        value: isSelected,
                        activeColor: const Color(0xFF004D40),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedTrickIds.add(id);
                            } else {
                              _selectedTrickIds.remove(id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(widget.localizations.saveAndContinue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
