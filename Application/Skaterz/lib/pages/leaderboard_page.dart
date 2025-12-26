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
  Future<List<dynamic>>? _leaderboardFuture;
  Future<List<dynamic>>? _categoriesFuture;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadInitialData();
    }
  }

  @override
  void didUpdateWidget(LeaderboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn && !oldWidget.isLoggedIn) {
      setState(() {
        _loadInitialData();
      });
    }
  }

  void _loadInitialData() {
    _leaderboardFuture = _apiService.getLeaderboard();
    _categoriesFuture = _apiService.getCategories();
  }

  void _refreshLeaderboard() {
    setState(() {
      _leaderboardFuture = _apiService.getLeaderboard(categoryId: _selectedCategoryId);
    });
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
          FutureBuilder<List<dynamic>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final categories = snapshot.data!;
                return Padding(
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
                      ...categories.map((cat) {
                        return DropdownMenuItem<int?>(
                          value: cat['id'],
                          child: Text(cat['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                      _refreshLeaderboard();
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (_leaderboardFuture == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Filter users with 0 tricks
                final leaderboard = (snapshot.data ?? []).where((entry) {
                  final int count = entry['completedCount'] ?? 0;
                  return count > 0;
                }).toList();

                if (leaderboard.isEmpty) {
                  return Center(child: Text(widget.localizations.noUsersFound));
                }

                return ListView.builder(
                  itemCount: leaderboard.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboard[index];
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
                );
              },
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
