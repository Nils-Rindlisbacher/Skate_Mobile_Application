import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/pages/public_profile_page.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/login_required_view.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
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
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
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

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<dynamic> _friends = [];
  List<dynamic> _pendingRequests = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.isLoggedIn) {
      _loadData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getFriends(),
        _apiService.getPendingRequests(),
      ]);
      if (mounted) {
        setState(() {
          _friends = results[0];
          _pendingRequests = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.localizations.error}: $e')));
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        return;
      }

      setState(() => _isSearching = true);
      try {
        final results = await _apiService.searchUsers(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
          });
        }
      } catch (e) {
        debugPrint("Search error: $e");
      }
    });
  }

  Future<void> _handleAccept(int requestId) async {
    try {
      await _apiService.acceptFriendRequest(requestId);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.friendshipAccepted)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleDecline(int requestId) async {
    try {
      await _apiService.declineFriendRequest(requestId);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.friends,
        icon: Icons.people_outline_rounded,
        onMenuTap: () {},
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.localizations.searchFriends,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchController.clear(); _onSearchChanged(""); })
                  : null,
                filled: true,
                fillColor: colorScheme.onSurface.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
            tabs: [
              Tab(text: widget.localizations.friends.toUpperCase()),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.localizations.pendingRequests.toUpperCase()),
                    if (_pendingRequests.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${_pendingRequests.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isSearching ? _buildSearchResults() : _buildFriendsList(),
                _buildRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_friends.isEmpty) return _buildEmptyState(Icons.people_outline_rounded, widget.localizations.noUsersFound);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) => _buildUserCard(_friends[index], isFriend: true),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) return _buildEmptyState(Icons.search_off_rounded, widget.localizations.noUsersFound);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final bool isFriend = _friends.any((f) => f['id'] == user['id']);
        return _buildUserCard(user, isFriend: isFriend);
      },
    );
  }

  Widget _buildRequestsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_pendingRequests.isEmpty) return _buildEmptyState(Icons.mark_email_unread_outlined, widget.localizations.noPendingRequests);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) => _buildRequestCard(_pendingRequests[index]),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool isFriend = false}) {
    final String? avatarData = user['profile_image'] ?? user['profileImage'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.withOpacity(0.1),
          backgroundImage: avatarData != null ? MemoryImage(base64Decode(avatarData)) : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider,
        ),
        title: Text(user['name'] ?? user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('@${user['username']}'),
        trailing: isFriend ? Icon(Icons.check_circle_rounded, color: AppColors.primary) : const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PublicProfilePage(
          localizations: widget.localizations,
          userId: user['id'],
          username: user['username'],
          isLoggedIn: widget.isLoggedIn,
          currentUserData: widget.userData,
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
        ))).then((_) => _loadData()),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final sender = request['sender'];
    final String? avatarData = sender['profile_image'] ?? sender['profileImage'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: avatarData != null ? MemoryImage(base64Decode(avatarData)) : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider),
        title: Text(sender['name'] ?? sender['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.localizations.wantsToBeYourFriend),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _handleAccept(request['id'])),
            IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: () => _handleDecline(request['id'])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 80, color: Colors.grey.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: Colors.grey)),
    ]));
  }
}
