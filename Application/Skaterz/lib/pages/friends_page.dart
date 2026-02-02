import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/pages/public_profile_page.dart';
import 'package:skaterz/core/constants.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({
    super.key,
    required this.localizations,
    required this.onMenuTap,
  });

  final AppLocalizations localizations;
  final VoidCallback onMenuTap;

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
    _loadFriends();
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
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.getDynamicGradient(context)),
        ),
        title: Text(widget.localizations.friends.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: !isDesktop ? IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: widget.onMenuTap,
        ) : null,
      ),
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
                              Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
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
                      final bool isUrl = avatarData != null && avatarData.startsWith('http');
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            backgroundImage: avatarData != null && avatarData.isNotEmpty
                                ? (isUrl ? NetworkImage(avatarData) : MemoryImage(base64Decode(avatarData)) as ImageProvider)
                                : null,
                            child: (avatarData == null || avatarData.isEmpty) 
                                ? const Icon(Icons.person_rounded, color: Colors.grey) 
                                : null,
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
