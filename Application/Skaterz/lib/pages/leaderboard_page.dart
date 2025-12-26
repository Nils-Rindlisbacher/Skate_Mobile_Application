import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/widgets/login_required_view.dart';
import 'package:skaterz/pages/public_profile_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onNavigateToProfile,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onNavigateToProfile;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _leaderboard = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final cacheKey = 'leaderboard_${_selectedCategoryId ?? 'all'}';
    
    // 1. Load from Cache
    final cachedLeaderboard = await _apiService.getCachedData(cacheKey);
    final cachedCategories = await _apiService.getCachedData('categories');
    
    if (mounted && (cachedLeaderboard != null || cachedCategories != null)) {
      setState(() {
        if (cachedLeaderboard != null) _leaderboard = cachedLeaderboard;
        if (cachedCategories != null) _categories = cachedCategories;
        _isLoading = false;
      });
    }

    // 2. Load from API in parallel
    try {
      final results = await Future.wait([
        _apiService.getLeaderboard(categoryId: _selectedCategoryId),
        _apiService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _leaderboard = results[0];
          _categories = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _leaderboard.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.leaderboardMenuItem,
        icon: Icons.emoji_events_outlined,
      );
    }

    // Filter users with 0 tricks
    final filteredLeaderboard = _leaderboard.where((entry) {
      final int count = entry['completedCount'] ?? 0;
      return count > 0;
    }).toList();

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
          widget.localizations.leaderboardMenuItem,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<int?>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: widget.localizations.trickListMenuItem,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(widget.localizations.all),
                  ),
                  ..._categories.map((cat) {
                    return DropdownMenuItem<int?>(
                      value: cat['id'],
                      child: Text(cat['name']),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _isLoading = true;
                  });
                  _loadData();
                },
              ),
            ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading && _leaderboard.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeaderboard.isEmpty
                      ? ListView(children: [Center(child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Text(widget.localizations.noUsersFound),
                        ))])
                      : ListView.builder(
                          itemCount: filteredLeaderboard.length,
                          itemBuilder: (context, index) {
                            final entry = filteredLeaderboard[index];
                            final int rank = index + 1;
                            final int completedCount = entry['completedCount'] ?? 0;
                            final String name = entry['name'] ?? 'User';
                            final String? base64Image = entry['profile_image'];
                            
                            final dynamic rawId = entry['id'];
                            final int? userId = rawId != null 
                                ? (rawId is int ? rawId : int.tryParse(rawId.toString()))
                                : null;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: InkWell(
                                onTap: userId == null ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PublicProfilePage(
                                        localizations: widget.localizations,
                                        userId: userId,
                                        username: entry['username'] ?? 'User',
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          '#$rank',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getRankColor(rank),
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundImage: (base64Image != null && base64Image.isNotEmpty)
                                            ? MemoryImage(const Base64Decoder().convert(base64Image))
                                            : null,
                                        child: (base64Image == null || base64Image.isEmpty) 
                                            ? const Icon(Icons.person) 
                                            : null,
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('@${entry['username'] ?? ''}'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF004D40).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$completedCount ${widget.localizations.tricks}',
                                      style: const TextStyle(
                                        color: Color(0xFF004D40),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber[700]!;
    if (rank == 2) return Colors.grey[600]!;
    if (rank == 3) return Colors.brown[600]!;
    return Colors.black54;
  }
}
