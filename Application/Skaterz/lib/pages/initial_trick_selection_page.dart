import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/custom_app_bar.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = AppColors.getDynamicPrimary(context);

    final filteredTricks = _allTricks.where((trick) =>
      trick['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: widget.localizations.selectInitialTricksTitle,
        isDarkMode: isDarkMode,
        onMenuTap: () {}, // Not needed here as it's an initial setup page
        showMenuButton: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
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
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: TextStyle(color: colorScheme.onSurface),
                        cursorColor: primaryColor,
                        decoration: InputDecoration(
                          hintText: widget.localizations.searchTricks,
                          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.5)),
                          filled: true,
                          fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                          ),
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
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              child: Text(
                                categoryName.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trick['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: availableStances.map((stance) {
                                    final isSelected = selectedStances.contains(stance);
                                    return ChoiceChip(
                                      label: Text(
                                        _formatStance(stance),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : colorScheme.onSurface,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: primaryColor,
                                      backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                      showCheckmark: false,
                                      onSelected: (_) => _toggleStance(id, stance),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected ? primaryColor : Colors.transparent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.05)),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSaving 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.localizations.saveAndContinue.toUpperCase(), 
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
