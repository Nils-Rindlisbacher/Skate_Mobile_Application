import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';

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
  // Stores trickId -> Set of selected stances
  final Map<int, Set<String>> _selectedStances = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = "";

  final List<String> _stances = ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'];

  @override
  void initState() {
    super.initState();
    _loadTricks();
  }

  Future<void> _loadTricks() async {
    try {
      final tricks = await _apiService.getTricks(size: 1000);
      
      tricks.sort((a, b) {
        int catComp = (a['category_id'] ?? 0).compareTo(b['category_id'] ?? 0);
        if (catComp != 0) return catComp;
        return (a['id'] ?? 0).compareTo(b['id'] ?? 0);
      });
      
      if (mounted) {
        setState(() {
          _allTricks = tricks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.errorLoadingTricks}: $e')),
        );
      }
    }
  }

  List<String> _getAvailableStances(String trickName) {
    final name = trickName.toLowerCase();

    if (name == 'rock to fakie' || 
        name == 'rock n roll' || 
        name == 'blunt to fakie') {
      return ['REGULAR'];
    }
    return _stances;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final List<Future> saveTasks = [];
      
      _selectedStances.forEach((trickId, stances) {
        for (String stance in stances) {
          saveTasks.add(_apiService.toggleCompleted(trickId, false, stance));
        }
      });

      // Execute all toggles. Depending on server capacity, maybe chunk these or use a bulk endpoint if available.
      // For now, simple Future.wait.
      await Future.wait(saveTasks);
      
      if (mounted) {
        widget.onComplete();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.errorSaving}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleStance(int trickId, String stance) {
    setState(() {
      if (!_selectedStances.containsKey(trickId)) {
        _selectedStances[trickId] = {stance};
      } else {
        if (_selectedStances[trickId]!.contains(stance)) {
          _selectedStances[trickId]!.remove(stance);
          if (_selectedStances[trickId]!.isEmpty) {
            _selectedStances.remove(trickId);
          }
        } else {
          _selectedStances[trickId]!.add(stance);
        }
      }
    });
  }

  String _formatStance(String stance) {
    switch (stance.toUpperCase()) {
      case 'REGULAR': return widget.localizations.regular;
      case 'NOLLIE': return widget.localizations.nollie;
      case 'SWITCH': return widget.localizations.switchStance;
      case 'FAKIE': return widget.localizations.fakie;
      default: return stance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    final filteredTricks = _allTricks.where((trick) =>
      trick['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: null,
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
                        style: TextStyle(
                          fontSize: 16, 
                          color: subtitleColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: widget.localizations.searchTricks,
                          hintStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.search, color: subtitleColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTricks.length,
                    itemBuilder: (context, index) {
                      final trick = filteredTricks[index];
                      final int id = trick['id'];
                      final String categoryName = trick['type'] ?? widget.localizations.allTricks;
                      final selectedStances = _selectedStances[id] ?? {};
                      final availableStances = _getAvailableStances(trick['name'] ?? '');

                      bool showCategoryHeader = false;
                      if (index == 0 || filteredTricks[index - 1]['type'] != categoryName) {
                        showCategoryHeader = true;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showCategoryHeader)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary.withOpacity(0.8),
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trick['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: availableStances.map((stance) {
                                    final isSelected = selectedStances.contains(stance);
                                    return ChoiceChip(
                                      label: Text(
                                        _formatStance(stance),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected ? Colors.white : textColor,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      backgroundColor: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
                                      showCheckmark: false,
                                      onSelected: (_) => _toggleStance(id, stance),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: isDarkMode ? Colors.white12 : Colors.black12),
                        ],
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
                        backgroundColor: AppColors.primary,
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
