
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/pages/trick_list_page.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/custom_app_bar.dart';

class TrickCategoryPage extends StatefulWidget {
  const TrickCategoryPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onMenuTap,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onMenuTap;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: null,
      body: _isLoading && _allCategories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final columns = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _allCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCategoryTile(
                          context,
                          widget.localizations.allTricks,
                          Icons.apps_rounded,
                          null,
                          AppColors.getDynamicPrimary(context),
                        );
                      }
                      final category = _allCategories[index - 1];
                      
                      return _buildCategoryTile(
                        context,
                        category['name'] ?? widget.localizations.category,
                        Icons.skateboarding_rounded,
                        category['id'],
                        AppColors.getDynamicPrimary(context),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String title, IconData icon, int? categoryId, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrickListPage(
              localizations: widget.localizations,
              categoryId: categoryId,
              categoryName: title,
              isLoggedIn: widget.isLoggedIn,
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withOpacity(0.15), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
