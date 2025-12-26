import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.localizations,
    required this.onLogout,
    required this.onUserDataChanged,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogout;
  final VoidCallback onUserDataChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _userData;
  List<dynamic> _wishlistTricks = [];
  List<dynamic> _recentlyCompleted = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _apiService.getCurrentUser();
      final wishlist = await _apiService.getWishlistTricks();
      final completed = await _apiService.getCompletedTricks();
      
      List<dynamic> recent = List.from(completed);
      recent.sort((a, b) {
        if (a['created_at'] == null || b['created_at'] == null) return 0;
        return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']));
      });
      
      if (mounted) {
        setState(() {
          _userData = user;
          _wishlistTricks = wishlist;
          _recentlyCompleted = recent.take(3).toList();
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        final String base64Image = base64Encode(bytes);

        setState(() => _isLoading = true);
        await _apiService.uploadProfileImage(base64Image);
        await _loadData(); 
        widget.onUserDataChanged();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.localizations.profilePictureUpdated), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.failedToUpload}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLargeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  const Base64Decoder().convert(base64String),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final String? base64String = _userData?['profile_image'] ?? _userData?['profileImage'];
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showLargeImage(base64String),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: (base64String != null && base64String.isNotEmpty)
                ? MemoryImage(const Base64Decoder().convert(base64String)) 
                : null,
            child: (base64String == null || base64String.isEmpty)
                ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: const Color(0xFF004D40),
            radius: 18,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              onPressed: _isLoading ? null : _pickImage,
            ),
          ),
        ),
      ],
    );
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
          widget.localizations.profileMenuItem,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: Text(widget.localizations.loadingData))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatar()),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _userData?['name'] ?? 'User',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(_userData?['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                          Text('@${_userData?['username'] ?? ''}', 
                              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFF004D40)),
                        const SizedBox(width: 8),
                        Text(
                          widget.localizations.recentlyCompleted,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                        ),
                      ],
                    ),
                    const Divider(),
                    _recentlyCompleted.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.localizations.noTricksYet),
                          )
                        : Column(
                            children: _recentlyCompleted.map((trick) => ListTile(
                                visualDensity: VisualDensity.compact,
                              leading: const Icon(Icons.check_circle, color: Color(0xFF004D40)),
                              title: Text(trick['name'] ?? ''),
                              subtitle: trick['type'] != null ? Text(trick['type']) : null,
                            )).toList(),
                          ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.localizations.wishlist} (${_wishlistTricks.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                    const Divider(),
                    _wishlistTricks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(widget.localizations.wishlistEmpty),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _wishlistTricks.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final trick = _wishlistTricks[index];
                              return ListTile(
                                leading: const Icon(Icons.skateboarding, color: Color(0xFF004D40)),
                                title: Text(trick['name'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.favorite, color: Colors.red),
                                  onPressed: () async {
                                    await _apiService.toggleWishlist(trick['id'], true);
                                    await _loadData();
                                    widget.onUserDataChanged();
                                  },
                                ),
                              );
                            },
                          ),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.localizations.logoutButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
    );
  }
}
