import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/pages/trick_list_page.dart';
import 'package:skaterz/core/constants.dart';

class TrickCategoryPage extends StatefulWidget {
  const TrickCategoryPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onMenuTap,
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
  final bool isLoggedIn;
  final VoidCallback onMenuTap;
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
  State<TrickCategoryPage> createState() => _TrickCategoryPageState();
}

class _TrickCategoryPageState extends State<TrickCategoryPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cached = await _apiService.getCachedData('categories');
    if (cached != null && cached is List && mounted) {
      setState(() {
        _allCategories = cached;
        _isLoading = false;
      });
    }

    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _allCategories.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = AppColors.getDynamicPrimary(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: null,
      body: _isLoading && _allCategories.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadCategories,
              color: primaryColor,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final columns = screenWidth > 1200 ? 5 : (screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2));
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _allCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCategoryTile(
                          context,
                          widget.localizations.allTricks,
                          Icons.auto_awesome_motion_rounded,
                          null,
                          primaryColor,
                        );
                      }
                      final category = _allCategories[index - 1];
                      
                      return _buildCategoryTile(
                        context,
                        category['name'] ?? widget.localizations.category,
                        _getCategoryIcon(category['name']),
                        category['id'],
                        primaryColor,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  IconData _getCategoryIcon(String? name) {
    final n = name?.toLowerCase() ?? "";
    return Icons.skateboarding_rounded;
  }

  Widget _buildCategoryTile(BuildContext context, String title, IconData icon, int? categoryId, Color color) {
    final theme = Theme.of(context);
    final heroTag = categoryId != null ? 'category_icon_$categoryId' : 'category_icon_all';
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: TrickListPage(
                localizations: widget.localizations,
                categoryId: categoryId,
                categoryName: title,
                isLoggedIn: widget.isLoggedIn,
                userData: widget.userData,
                isDarkMode: widget.isDarkMode,
                onThemeToggle: widget.onThemeToggle,
                onLanguageChange: widget.onLanguageChange,
                onProfileTap: widget.onProfileTap,
                onProgressTap: widget.onProgressTap,
                onLeaderboardTap: widget.onLeaderboardTap,
                onTrickListTap: widget.onTrickListTap,
                onFriendsTap: widget.onFriendsTap,
                onSessionGoalsTap: widget.onSessionGoalsTap,
                onEquipmentTap: widget.onEquipmentTap,
                onSettingsTap: widget.onSettingsTap,
                isMenuExpanded: widget.isMenuExpanded,
                onToggleMenu: widget.onToggleMenu,
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: heroTag,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
