import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';

class TrickListPage extends StatefulWidget {
  const TrickListPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    this.categoryId,
    this.categoryName,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final int? categoryId;
  final String? categoryName;

  @override
  State<TrickListPage> createState() => _TrickListPageState();
}

class _TrickListPageState extends State<TrickListPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _allTricks = [];
  List<dynamic> _filteredTricks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTricks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTricks() async {
    try {
      final tricks = await _apiService.getTricks(categoryId: widget.categoryId);
      if (mounted) {
        setState(() {
          _allTricks = tricks;
          _filteredTricks = tricks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _filterTricks(String query) {
    if (!mounted) return;
    setState(() {
      _filteredTricks = _allTricks
          .where((trick) =>
              trick['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
              (trick['description']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  void _showLoginWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.localizations.loginRequiredWarning),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.categoryName ?? widget.localizations.trickListMenuItem,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          onChanged: _filterTricks,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: Text(widget.localizations.loadingData))
          : _filteredTricks.isEmpty
              ? Center(child: Text(widget.localizations.noTricksYet))
              : ListView.separated(
                  itemCount: _filteredTricks.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withOpacity(0.2),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final trick = _filteredTricks[index];
                    final int trickId = trick['id'];
                    final bool isCompleted = trick['completed'] ?? false;
                    final bool isWishlisted = trick['wishlisted'] ?? false;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const Icon(Icons.skateboarding, color: Color(0xFF004D40)),
                      title: Text(
                        trick['name'] ?? 'Unknown Trick',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: trick['description'] != null ? Text(trick['description']) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompleted)
                            IconButton(
                              icon: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_border,
                                color: isWishlisted ? Colors.red : null,
                              ),
                              onPressed: () async {
                                if (!widget.isLoggedIn) {
                                  _showLoginWarning();
                                  return;
                                }
                                try {
                                  await _apiService.toggleWishlist(trickId, isWishlisted);
                                  _loadTricks();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${e.toString()}')),
                                    );
                                  }
                                }
                              },
                            ),
                          IconButton(
                            icon: Icon(
                              isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                              color: isCompleted ? Colors.green : null,
                            ),
                            onPressed: () async {
                              if (!widget.isLoggedIn) {
                                _showLoginWarning();
                                return;
                              }
                              try {
                                await _apiService.toggleCompleted(trickId, isCompleted);
                                _loadTricks();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: ${e.toString()}')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
