import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';

enum TrickFilter { all, completed, wishlist }

class TrickListPage extends StatefulWidget {
  const TrickListPage({
    super.key,
    required this.localizations,
    this.categoryId,
    required this.categoryName,
    required this.isLoggedIn,
  });

  final AppLocalizations localizations;
  final int? categoryId;
  final String categoryName;
  final bool isLoggedIn;

  @override
  State<TrickListPage> createState() => _TrickListPageState();
}

class _TrickListPageState extends State<TrickListPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _tricks = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String _selectedStance = 'ALL';
  String _searchQuery = "";
  TrickFilter _currentFilter = TrickFilter.all;
  
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;

  final Map<String, Color> stanceColors = {
    'REGULAR': const Color(0xFF4FC3F7), 
    'NOLLIE': const Color(0xFFFF8A65),  
    'SWITCH': const Color(0xFF9575CD),  
    'FAKIE': const Color(0xFF4DB6AC),   
  };

  @override
  void initState() {
    super.initState();
    _loadInitialTricks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (_hasMore && !_isFetchingMore && !_isLoading) {
        _loadMoreTricks();
      }
    }
  }

  String _formatStance(String stance) {
    if (stance.isEmpty) return "";
    if (stance == 'ALL') return widget.localizations.allTricks;
    return stance[0].toUpperCase() + stance.substring(1).toLowerCase();
  }

  List<String> _getAvailableStances(String trickName) {
    final name = trickName.toLowerCase();
    if (name == 'ollie' || 
        name == 'nollie' || 
        name == 'rock to fakie' || 
        name == 'rock n roll' || 
        name == 'blunt to fakie') {
      return ['REGULAR'];
    }
    return ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'];
  }

  Future<void> _loadInitialTricks() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _tricks = [];
      _hasMore = true;
    });

    try {
      final tricks = await _apiService.getTricks(
        categoryId: widget.categoryId,
        page: 0,
        size: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _tricks = tricks;
          _isLoading = false;
          _hasMore = tricks.length == _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadMoreTricks() async {
    if (_isFetchingMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newTricks = await _apiService.getTricks(
        categoryId: widget.categoryId,
        page: nextPage,
        size: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _tricks.addAll(newTricks);
          _isFetchingMore = false;
          _hasMore = newTricks.length == _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }

  bool _isTrickCompleted(Map<String, dynamic> trick, String stance) {
    if (trick['stances'] == null) return false;
    if (stance == 'ALL') {
       final Map<String, dynamic> stances = trick['stances'];
       return stances.values.any((s) => s['completed'] == true);
    }
    return trick['stances'][stance]?['completed'] ?? false;
  }

  bool _isTrickWishlisted(Map<String, dynamic> trick, String stance) {
    if (trick['stances'] == null) return false;
    if (stance == 'ALL') {
       final Map<String, dynamic> stances = trick['stances'];
       return stances.values.any((s) => s['wishlisted'] == true);
    }
    return trick['stances'][stance]?['wishlisted'] ?? false;
  }

  Future<void> _handleToggleWishlist(int trickId, bool currentStatus, String stance, void Function(void Function()) setModalState) async {
    final trickIndex = _tricks.indexWhere((t) => t['id'] == trickId);
    if (trickIndex != -1) {
      setState(() {
        _tricks[trickIndex]['stances'][stance]['wishlisted'] = !currentStatus;
      });
      setModalState(() {});
    }

    try {
      await _apiService.toggleWishlist(trickId, currentStatus, stance);
    } catch (e) {
      if (trickIndex != -1) {
        setState(() {
          _tricks[trickIndex]['stances'][stance]['wishlisted'] = currentStatus;
        });
        setModalState(() {});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleToggleCompleted(int trickId, bool currentStatus, String stance, void Function(void Function()) setModalState) async {
    final trickIndex = _tricks.indexWhere((t) => t['id'] == trickId);
    if (trickIndex != -1) {
      setState(() {
        _tricks[trickIndex]['stances'][stance]['completed'] = !currentStatus;
      });
      setModalState(() {});
    }

    try {
      await _apiService.toggleCompleted(trickId, currentStatus, stance);
    } catch (e) {
      if (trickIndex != -1) {
        setState(() {
          _tricks[trickIndex]['stances'][stance]['completed'] = currentStatus;
        });
        setModalState(() {});
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showTrickDetails(Map<String, dynamic> trick, int index) {
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.loginRequiredWarning)));
      return;
    }

    String innerSelectedStance = _selectedStance == 'ALL' ? 'REGULAR' : _selectedStance;
    final availableStances = _getAvailableStances(trick['name'] ?? '');
    
    if (!availableStances.contains(innerSelectedStance)) {
      innerSelectedStance = 'REGULAR';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final currentTrickData = _tricks.firstWhere((t) => t['id'] == trick['id'], orElse: () => trick);
              final bool isCompleted = _isTrickCompleted(currentTrickData, innerSelectedStance);
              final bool isWishlisted = _isTrickWishlisted(currentTrickData, innerSelectedStance);
              final Color currentStanceColor = stanceColors[innerSelectedStance] ?? AppColors.primary;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentTrickData['name'] ?? 'Trick', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(backgroundColor: Colors.grey.withValues(alpha: 0.1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('${widget.localizations.stances} *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: availableStances.map((stance) {
                      final isSelected = innerSelectedStance == stance;
                      final bool stanceDone = _isTrickCompleted(currentTrickData, stance);
                      final Color sColor = stanceColors[stance] ?? AppColors.primary;
                      
                      return ChoiceChip(
                        label: Text(_formatStance(stance)),
                        selected: isSelected,
                        showCheckmark: false, 
                        selectedColor: sColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? sColor : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        avatar: stanceDone ? Icon(Icons.check, size: 16, color: sColor) : null,
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            setModalState(() => innerSelectedStance = stance);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isCompleted ? null : () => _handleToggleWishlist(currentTrickData['id'], isWishlisted, innerSelectedStance, (fn) {
                            if (context.mounted) {
                               setModalState(fn);
                            }
                          }),
                          icon: Icon(isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                          label: Text(widget.localizations.wishlist),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isCompleted ? Colors.grey : Colors.red,
                            side: BorderSide(
                              color: isCompleted ? Colors.grey.withValues(alpha: 0.2) : Colors.red, 
                              width: 1.5
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleToggleCompleted(currentTrickData['id'], isCompleted, innerSelectedStance, (fn) {
                            if (context.mounted) {
                               setModalState(fn);
                            }
                          }),
                          icon: Icon(isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded),
                          label: Text(isCompleted ? widget.localizations.undo : widget.localizations.complete), 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted ? Colors.grey[300] : currentStanceColor,
                            foregroundColor: isCompleted ? Colors.black87 : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStanceIndicators(Map<String, dynamic> trick) {
    final availableStances = _getAvailableStances(trick['name'] ?? '');
    final allPossibleStances = ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: allPossibleStances.map((stance) {
        if (!availableStances.contains(stance)) return const SizedBox.shrink();

        final bool isDone = _isTrickCompleted(trick, stance);
        final bool isWishlisted = _isTrickWishlisted(trick, stance);
        
        if (_currentFilter == TrickFilter.wishlist) {
            return Container(
              margin: const EdgeInsets.only(left: 4),
              child: Icon(
                isDone ? Icons.favorite : (isWishlisted ? Icons.favorite : Icons.favorite_border),
                color: isDone ? Colors.green : (isWishlisted ? stanceColors[stance] : Colors.grey.withValues(alpha: 0.2)),
                size: 14,
              ),
            );
        }

        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? stanceColors[stance] : Colors.grey.withValues(alpha: 0.2),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTricks = _tricks.where((trick) {
      final name = trick['name']?.toString().toLowerCase() ?? "";
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      if (_currentFilter == TrickFilter.completed) {
        matchesFilter = _isTrickCompleted(trick, _selectedStance);
      } else if (_currentFilter == TrickFilter.wishlist) {
        matchesFilter = _isTrickWishlisted(trick, _selectedStance);
      }
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        title: Text(widget.categoryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.localizations.searchTricks,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                            _loadInitialTricks();
                          },
                        )
                      : null,
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    // For searching, we might want to do server-side search eventually, 
                    // but for now we just filter the loaded list.
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(TrickFilter.all, widget.localizations.allTricks),
                            const SizedBox(width: 8),
                            _buildFilterChip(TrickFilter.completed, widget.localizations.completed),
                            const SizedBox(width: 8),
                            _buildFilterChip(TrickFilter.wishlist, widget.localizations.wishlist),
                          ],
                        ),
                      ),
                    ),
                    if (_currentFilter != TrickFilter.all) ...[
                      const SizedBox(width: 8),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStance,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedStance = newValue);
                              }
                            },
                            items: ['ALL', 'REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(_formatStance(value)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _tricks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadInitialTricks,
                    child: filteredTricks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              const Text("No tricks found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredTricks.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredTricks.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            
                            final trick = filteredTricks[index];

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                              ),
                              child: ListTile(
                                onTap: () => _showTrickDetails(trick, index),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                title: Text(
                                  trick['name'] ?? 'Trick',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildStanceIndicators(trick), 
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TrickFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _currentFilter = filter;
          if (filter == TrickFilter.all) {
            _selectedStance = 'ALL';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
