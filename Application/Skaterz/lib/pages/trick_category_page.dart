import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/pages/trick_list_page.dart';

class TrickCategoryPage extends StatefulWidget {
  const TrickCategoryPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;

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
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _allCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
          widget.localizations.trickListMenuItem,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _allCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryTile(
                    context,
                    widget.localizations.all,
                    Icons.apps,
                    null,
                  );
                }
                final category = _allCategories[index - 1];
                return _buildCategoryTile(
                  context,
                  category['name'] ?? 'Category',
                  Icons.skateboarding,
                  category['id'],
                );
              },
            ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String title, IconData icon, int? categoryId) {
    return InkWell(
      onTap: () {
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
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: const Color(0xFF004D40)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
