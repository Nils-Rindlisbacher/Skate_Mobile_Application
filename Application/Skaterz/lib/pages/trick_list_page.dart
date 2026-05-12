import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/side_menu.dart';
import 'package:skaterz/widgets/custom_app_bar.dart';

enum TrickFilter { all, completed, wishlist }

class TrickListPage extends StatefulWidget {
  const TrickListPage({
    super.key,
    required this.localizations,
    this.categoryId,
    required this.categoryName,
    required this.isLoggedIn,
    this.userData,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.onProfileTap,
    required this.onProgressTap,
    required this.onLeaderboardTap,
    required this.onTrickListTap,
    required this.onFriendsTap,
    required this.onSessionGoalsTap,
    required this.onEquipmentTap,
    required this.onSettingsTap,
    this.isMenuExpanded = false,
    this.onToggleMenu,
  });

  final AppLocalizations localizations;
  final int? categoryId;
  final String categoryName;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final Function(String) onLanguageChange;
  final VoidCallback onProfileTap;
  final VoidCallback onProgressTap;
  final VoidCallback onLeaderboardTap;
  final VoidCallback onTrickListTap;
  final VoidCallback onFriendsTap;
  final VoidCallback onSessionGoalsTap;
  final VoidCallback onEquipmentTap;
  final VoidCallback onSettingsTap;
  final bool isMenuExpanded;
  final VoidCallback? onToggleMenu;

  @override
  State<TrickListPage> createState() => _TrickListPageState();
}

class _TrickListPageState extends State<TrickListPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _searchDebounce;

  List<dynamic> _tricks = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  late bool _isMenuExpanded;
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
    _isMenuExpanded = widget.isMenuExpanded;
    _loadInitialTricks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
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
    switch (stance.toUpperCase()) {
      case 'ALL': return widget.localizations.allTricks;
      case 'REGULAR': return widget.localizations.regular;
      case 'NOLLIE': return widget.localizations.nollie;
      case 'SWITCH': return widget.localizations.switchStance;
      case 'FAKIE': return widget.localizations.fakie;
      default: return stance;
    }
  }

  List<String> _getAvailableStances(String trickName) {
    final name = trickName.toLowerCase();
    if (name == 'rock to fakie' || name == 'rock n roll' || name == 'blunt to fakie') {
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
        search: _searchQuery,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.localizations.error}: $e')));
      }
    }
  }

  Future<void> _loadMoreTricks() async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final newTricks = await _apiService.getTricks(
        categoryId: widget.categoryId,
        search: _searchQuery,
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
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = query);
        _loadInitialTricks();
      }
    });
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
      setState(() => _tricks[trickIndex]['stances'][stance]['wishlisted'] = !currentStatus);
      setModalState(() {});
    }
    try {
      await _apiService.toggleWishlist(trickId, currentStatus, stance);
    } catch (e) {
      if (trickIndex != -1) {
        setState(() => _tricks[trickIndex]['stances'][stance]['wishlisted'] = currentStatus);
        setModalState(() {});
      }
    }
  }

  Future<void> _handleToggleCompleted(int trickId, bool currentStatus, String stance, void Function(void Function()) setModalState) async {
    final trickIndex = _tricks.indexWhere((t) => t['id'] == trickId);
    if (trickIndex != -1) {
      setState(() => _tricks[trickIndex]['stances'][stance]['completed'] = !currentStatus);
      setModalState(() {});
    }
    try {
      await _apiService.toggleCompleted(trickId, currentStatus, stance);
    } catch (e) {
      if (trickIndex != -1) {
        setState(() => _tricks[trickIndex]['stances'][stance]['completed'] = currentStatus);
        setModalState(() {});
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
    if (!availableStances.contains(innerSelectedStance)) innerSelectedStance = 'REGULAR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final primaryColor = AppColors.getDynamicPrimary(context);

        return Container(
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24, left: 24, right: 24, top: 12),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final currentTrickData = _tricks.firstWhere((t) => t['id'] == trick['id'], orElse: () => trick);
              final bool isCompleted = _isTrickCompleted(currentTrickData, innerSelectedStance);
              final bool isWishlisted = _isTrickWishlisted(currentTrickData, innerSelectedStance);
              final Color currentStanceColor = stanceColors[innerSelectedStance] ?? primaryColor;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(currentTrickData['name'] ?? widget.localizations.tricks, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: -0.5))),
                      IconButton(icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withOpacity(0.5)), onPressed: () => Navigator.pop(context), style: IconButton.styleFrom(backgroundColor: colorScheme.onSurface.withOpacity(0.05))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(widget.localizations.stances.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: availableStances.map((stance) {
                      final isSelected = innerSelectedStance == stance;
                      final bool stanceDone = _isTrickCompleted(currentTrickData, stance);
                      final Color sColor = stanceColors[stance] ?? primaryColor;
                      return ChoiceChip(
                        label: Text(_formatStance(stance)),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: sColor.withOpacity(0.15),
                        backgroundColor: colorScheme.onSurface.withOpacity(0.05),
                        labelStyle: TextStyle(color: isSelected ? sColor : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 13),
                        avatar: stanceDone ? Icon(Icons.check_circle_rounded, size: 16, color: sColor) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? sColor.withOpacity(0.3) : Colors.transparent)),
                        onSelected: (selected) { if (selected) { HapticFeedback.selectionClick(); setModalState(() => innerSelectedStance = stance); } },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isCompleted ? null : () => _handleToggleWishlist(currentTrickData['id'], isWishlisted, innerSelectedStance, (fn) => setModalState(fn)),
                          icon: Icon(isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20),
                          label: Text(widget.localizations.wishlist.toUpperCase()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isCompleted ? colorScheme.onSurface.withOpacity(0.2) : Colors.redAccent,
                            side: BorderSide(color: isCompleted ? colorScheme.onSurface.withOpacity(0.1) : Colors.redAccent.withOpacity(0.5), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleToggleCompleted(currentTrickData['id'], isCompleted, innerSelectedStance, (fn) => setModalState(fn)),
                          icon: Icon(isCompleted ? Icons.history_rounded : Icons.check_circle_rounded, size: 20),
                          label: Text((isCompleted ? widget.localizations.undo : widget.localizations.complete).toUpperCase()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted ? colorScheme.onSurface.withOpacity(0.1) : currentStanceColor,
                            foregroundColor: isCompleted ? colorScheme.onSurface : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: allPossibleStances.map((stance) {
        if (!availableStances.contains(stance)) return const SizedBox.shrink();
        final bool isDone = _isTrickCompleted(trick, stance);
        final bool isWishlisted = _isTrickWishlisted(trick, stance);
        if (_currentFilter == TrickFilter.wishlist) {
            return Container(margin: const EdgeInsets.only(left: 6), child: Icon(isDone ? Icons.favorite : (isWishlisted ? Icons.favorite : Icons.favorite_border), color: isDone ? Colors.green : (isWishlisted ? stanceColors[stance] : colorScheme.onSurface.withOpacity(0.1)), size: 14));
        }
        return Container(margin: const EdgeInsets.only(left: 6), width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isDone ? stanceColors[stance] : colorScheme.onSurface.withOpacity(0.1)));
      }).toList(),
    );
  }

  void _toggleMenu() {
    setState(() => _isMenuExpanded = !_isMenuExpanded);
    widget.onToggleMenu?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = AppColors.getDynamicPrimary(context);

    final filteredTricks = _tricks.where((trick) {
      if (_currentFilter == TrickFilter.completed) return _isTrickCompleted(trick, _selectedStance);
      if (_currentFilter == TrickFilter.wishlist) return _isTrickWishlisted(trick, _selectedStance);
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final sideMenu = SideMenu(
          localizations: widget.localizations, isLoggedIn: widget.isLoggedIn, userData: widget.userData, isExpanded: _isMenuExpanded, isDesktop: isDesktop, onToggleMenu: _toggleMenu, onLanguageChange: widget.onLanguageChange, onProfileTap: widget.onProfileTap, onTrickListTap: widget.onTrickListTap, onProgressTap: widget.onProgressTap, onLeaderboardTap: widget.onLeaderboardTap, onFriendsTap: widget.onFriendsTap, onSessionGoalsTap: widget.onSessionGoalsTap, onEquipmentTap: widget.onEquipmentTap, onSettingsTap: widget.onSettingsTap, isDarkMode: widget.isDarkMode, onThemeToggle: widget.onThemeToggle,
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorScheme.surface,
          appBar: CustomAppBar(title: widget.categoryName, isDarkMode: widget.isDarkMode, onMenuTap: isDesktop ? _toggleMenu : () => _scaffoldKey.currentState?.openDrawer(), showMenuButton: true, isExpanded: _isMenuExpanded, isDesktop: isDesktop),
          drawer: isDesktop ? null : sideMenu,
          body: Row(
            children: [
              if (isDesktop) AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut, width: _isMenuExpanded ? 280 : 72, child: sideMenu),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                            cursorColor: primaryColor,
                            decoration: InputDecoration(
                              hintText: widget.localizations.searchTricks,
                              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                              prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                              suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear_rounded, color: colorScheme.onSurface.withOpacity(0.4)), onPressed: () { _searchController.clear(); _onSearchChanged(""); }) : null,
                              filled: true, fillColor: colorScheme.onSurface.withOpacity(0.04),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                                _buildFilterChip(TrickFilter.all, widget.localizations.allTricks),
                                const SizedBox(width: 10),
                                _buildFilterChip(TrickFilter.completed, widget.localizations.completed),
                                const SizedBox(width: 10),
                                _buildFilterChip(TrickFilter.wishlist, widget.localizations.wishlist),
                              ]))),
                              if (_currentFilter != TrickFilter.all) ...[
                                const SizedBox(width: 12),
                                Container(
                                  height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.onSurface.withOpacity(0.05))),
                                  child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                                    value: _selectedStance,
                                    icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: 0.5),
                                    dropdownColor: theme.cardColor,
                                    onChanged: (String? newValue) { if (newValue != null) setState(() => _selectedStance = newValue); },
                                    items: ['ALL', 'REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'].map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(_formatStance(value).toUpperCase()))).toList(),
                                  )),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading && _tricks.isEmpty
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : RefreshIndicator(
                              onRefresh: _loadInitialTricks,
                              color: primaryColor,
                              child: filteredTricks.isEmpty
                                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.1)), const SizedBox(height: 16), Text(widget.localizations.noTricksFound, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w600))]))
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filteredTricks.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == filteredTricks.length) return Padding(padding: const EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3)));
                                      final trick = filteredTricks[index];
                                      return Card(
                                        elevation: 0, margin: const EdgeInsets.only(bottom: 12),
                                        color: theme.cardColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.onSurface.withOpacity(0.04))),
                                        child: ListTile(
                                          onTap: () => _showTrickDetails(trick, index),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          title: Text(trick['name'] ?? widget.localizations.tricks, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
                                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [_buildStanceIndicators(trick), const SizedBox(width: 12), Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withOpacity(0.2))]),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(TrickFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = AppColors.getDynamicPrimary(context);
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() { _currentFilter = filter; if (filter == TrickFilter.all) _selectedStance = 'ALL'; }); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? primaryColor : colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? primaryColor : Colors.transparent)),
        child: Text(label.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
      ),
    );
  }
}
