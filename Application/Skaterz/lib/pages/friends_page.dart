import 'dart:convert';
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

class _FriendsPageState extends State<FriendsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadFriends();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _apiService.getFriends();
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.error}: $e')),
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
        featureName: widget.localizations.friends,
        icon: Icons.people_outline_rounded, onMenuTap: () {  },
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFriends,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _friends.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(widget.localizations.noUsersFound, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      final String? avatarData = friend['profile_image'] ?? friend['profileImage'];
                      final bool hasCustomImage = avatarData != null && avatarData.isNotEmpty;
                      final bool isUrl = hasCustomImage && avatarData.startsWith('http');
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            backgroundImage: hasCustomImage
                                ? (isUrl ? NetworkImage(avatarData) : MemoryImage(base64Decode(avatarData)) as ImageProvider)
                                : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider,
                          ),
                          title: Text(friend['name'] ?? friend['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('@${friend['username']}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PublicProfilePage(
                                  localizations: widget.localizations,
                                  userId: friend['id'],
                                  username: friend['username'],
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
                                ),
                              ),
                            ).then((_) => _loadFriends());
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
