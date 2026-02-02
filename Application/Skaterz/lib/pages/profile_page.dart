import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/models/skating_session.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/skate_heatmap.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.localizations,
    required this.onLogout,
    required this.onUserDataChanged,
    required this.isLoggedIn,
    required this.onMenuTap,
    this.isActive = true,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogout;
  final VoidCallback onUserDataChanged;
  final bool isLoggedIn;
  final VoidCallback onMenuTap;
  final bool isActive;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _userData;
  List<dynamic> _wishlistTricks = [];
  List<dynamic> _recentlyCompleted = [];
  List<dynamic> _allCompleted = [];
  List<SkatingSession> _sessions = [];
  List<dynamic> _mediaItems = [];
  
  int _totalBaseTricks = 0;
  int _currentStreak = 0;
  int _friendCount = 0;
  bool _alreadySkatedToday = false;
  bool _isLoading = true;
  bool _isWishlistExpanded = false;
  bool _isUploadingImage = false;

  final Map<String, Color> stanceColors = {
    'REGULAR': const Color(0xFFF57C00), 
    'NOLLIE': const Color(0xFFEF6C00),  
    'SWITCH': const Color(0xFFFF9800),  
    'FAKIE': const Color(0xFFFFB74D),   
  };

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadInitialData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoggedIn && widget.isLoggedIn) {
      _loadInitialData();
    } else if (widget.isLoggedIn && widget.isActive && !oldWidget.isActive) {
      _loadData(); 
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final cacheResults = await Future.wait([
        _apiService.getCachedData('user_me'),
        _apiService.getCachedData('wishlist_tricks'),
        _apiService.getCachedData('completed_tricks'),
        _apiService.getCachedData('skating_sessions'),
        _apiService.getCachedData('cache_total_tricks_count'),
      ]);

      if (mounted) {
        setState(() {
          if (cacheResults[0] != null) {
            _userData = cacheResults[0] as Map<String, dynamic>;
            _friendCount = (_userData?['friendCount'] ?? _userData?['friend_count'] ?? 0) as int;
          }
          _wishlistTricks = (cacheResults[1] as List?) ?? [];
          if (cacheResults[2] != null) {
            _allCompleted = cacheResults[2] as List;
            _recentlyCompleted = _processCompletedTricks(_allCompleted);
          }
          if (cacheResults[3] != null) {
            _sessions = (cacheResults[3] as List).map((s) => SkatingSession.fromJson(s)).toList();
            _calculateSessionStats();
          }
          final cachedCount = cacheResults[4];
          if (cachedCount != null) {
            _totalBaseTricks = int.tryParse(cachedCount.toString()) ?? 0;
          }
          if (_userData != null || _sessions.isNotEmpty) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Cache Error: $e");
    }
    _loadData();
  }

  void _calculateSessionStats() {
    if (_sessions.isEmpty) {
      _currentStreak = 0; _alreadySkatedToday = false; return;
    }
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    _alreadySkatedToday = _sessions.any((s) => s.sessionDate.year == now.year && s.sessionDate.month == now.month && s.sessionDate.day == now.day);
    final sortedSessions = _sessions.map((s) => s.sessionDate).toList()..sort((a, b) => b.compareTo(a));
    DateTime lastSessionDate = DateTime(sortedSessions[0].year, sortedSessions[0].month, sortedSessions[0].day);
    int daysSinceLastSession = todayDate.difference(lastSessionDate).inDays;
    if (daysSinceLastSession > 1) {
      _currentStreak = 0;
    } else {
      int streak = 0;
      DateTime checkDate = daysSinceLastSession == 0 ? todayDate : lastSessionDate;
      final sessionDays = sortedSessions.map((d) => DateTime(d.year, d.month, d.day)).toSet();
      while (sessionDays.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      _currentStreak = streak;
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      final List<Future<dynamic>> requests = [
        _apiService.getCurrentUser(),
        _apiService.getCompletedTricks(),
        _apiService.getSkatingSessions(),
        _apiService.getTrickCount(),
        _apiService.getWishlistTricks(),
        _apiService.getMyMedia(),
      ];
      final results = await Future.wait(requests);
      if (mounted) {
        setState(() {
          _userData = results[0] as Map<String, dynamic>?;
          if (_userData != null) _friendCount = (_userData?['friendCount'] ?? _userData?['friend_count'] ?? 0) as int;
          _allCompleted = (results[1] as List?) ?? [];
          _recentlyCompleted = _processCompletedTricks(_allCompleted);
          final sessionsData = results[2] as List?;
          if (sessionsData != null) {
            _sessions = sessionsData.map((s) => SkatingSession.fromJson(s)).toList();
            _calculateSessionStats();
          }
          _totalBaseTricks = results[3] as int? ?? 0;
          _wishlistTricks = (results[4] as List?) ?? [];
          _mediaItems = results[5] as List<dynamic>;
          _isLoading = false;
        });
        const storage = FlutterSecureStorage();
        await storage.write(key: 'cache_total_tricks_count', value: _totalBaseTricks.toString());
      }
    } catch (e) {
      debugPrint("API Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteSession(DateTime date) async {
    setState(() => _alreadySkatedToday = false);
    try {
      await _apiService.deleteSkatingSession(date.toIso8601String().split('T')[0]);
      await _loadData();
    } catch (e) {
      if (mounted) {
        _calculateSessionStats();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.localizations.error}: $e')));
      }
    }
  }

  List<dynamic> _processCompletedTricks(List<dynamic> tricks) {
    List<dynamic> sorted = List.from(tricks);
    sorted.sort((a, b) {
      final dateA = a['created_at'] ?? a['createdAt'];
      final dateB = b['created_at'] ?? b['createdAt'];
      if (dateA == null || dateB == null) return 0;
      return DateTime.parse(dateB.toString()).compareTo(DateTime.parse(dateA.toString()));
    });
    return sorted.take(3).toList();
  }

  String _formatStance(String stance) {
    switch (stance.toUpperCase()) {
      case 'REGULAR': return widget.localizations.regular;
      case 'NOLLIE': return widget.localizations.nollie;
      case 'SWITCH': return widget.localizations.switchStance;
      case 'FAKIE': return widget.localizations.fakie;
      default: return stance;
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.localizations.profilePictureUpdated.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(Icons.image_rounded, 'Gallery', _pickFromGallery),
                _sourceButton(Icons.gif_box_rounded, 'Giphy', _pickFromGiphy),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      if (image == null) return;
      setState(() => _isUploadingImage = true);
      final bytes = await image.readAsBytes();
      await _apiService.uploadProfileImage(base64Encode(bytes));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.profilePictureUpdated)));
        _loadData(forceRefresh: true);
        widget.onUserDataChanged();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.localizations.error}: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickFromGiphy() async {
    try {
      final giphyGif = await GiphyGet.getGif(
        context: context,
        apiKey: 'l86itSDv66Z6vIDZFr6vPyitshnyMT6Z', 
        tabColor: AppColors.primary,
        debounceTimeInMilliseconds: 350,
      );

      if (giphyGif == null || giphyGif.images?.original?.url == null) return;

      setState(() => _isUploadingImage = true);
      await _apiService.uploadProfileImage(giphyGif.images!.original!.url!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.profilePictureUpdated)));
        _loadData(forceRefresh: true);
        widget.onUserDataChanged();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.localizations.error}: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _addMediaItem() async {
    final XFile? file = await _picker.pickMedia();
    if (file == null) return;

    final trickController = TextEditingController();
    final noteController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Private Gallery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: trickController, decoration: const InputDecoration(labelText: 'Trick Name', hintText: 'e.g. Kickflip')),
            const SizedBox(height: 12),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Note / Location', hintText: 'e.g. Berlin Skatepark')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.localizations.cancel)),
          ElevatedButton(
            onPressed: () async {
              final bytes = await file.readAsBytes();
              final base64Media = base64Encode(bytes);
              
              await _apiService.addMedia({
                'path': base64Media,
                'trickName': trickController.text,
                'note': noteController.text,
                'isVideo': file.name.toLowerCase().endsWith('.mp4') || file.name.toLowerCase().endsWith('.mov'),
              });
              
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.localizations.profileMenuItem.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: !isDesktop ? IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap) : null,
        actions: [
          if (_currentStreak > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.getDynamicPrimary(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(Icons.local_fire_department_rounded, color: AppColors.getDynamicPrimary(context), size: 18),
                const SizedBox(width: 4),
                Text('$_currentStreak', style: TextStyle(color: AppColors.getDynamicPrimary(context), fontWeight: FontWeight.w900)),
              ]),
            ),
        ],
      ),
      floatingActionButton: (_isLoading && _sessions.isEmpty) || _alreadySkatedToday 
          ? null 
          : FloatingActionButton.extended(
              heroTag: 'profile_fab',
              onPressed: () => _showMoodPicker(),
              icon: const Icon(Icons.skateboarding_rounded, color: Colors.white),
              label: Text(widget.localizations.skatedToday.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              backgroundColor: AppColors.getDynamicPrimary(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
      body: _isLoading && _userData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeroHeader(context),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionContainer(
                            child: SkateHeatmap(
                              sessions: _sessions,
                              onDeleteSession: _handleDeleteSession,
                              onSessionUpdated: _loadData,
                              localizations: widget.localizations,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildMediaGallery(),
                          const SizedBox(height: 24),

                          _buildRecentlyCompletedSection(),
                          const SizedBox(height: 24),
                          _buildStanceMasteryGrid(),
                          const SizedBox(height: 40),
                          Center(
                            child: TextButton.icon(
                              onPressed: widget.onLogout,
                              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                              label: Text(widget.localizations.logoutButton.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMediaGallery() {
    return _buildSectionContainer(
      title: 'Private Media Gallery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mediaItems.isEmpty)
            const Text('No private photos or videos yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaItems.length,
                itemBuilder: (context, index) {
                  final item = _mediaItems[index];
                  final bool isUrl = item['path'].startsWith('http');
                  
                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      image: item['isVideo'] ? null : DecorationImage(
                        image: isUrl ? NetworkImage(item['path']) : MemoryImage(base64Decode(item['path'])) as ImageProvider,
                        fit: BoxFit.cover
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (item['isVideo']) const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 40)),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['trickName'] ?? 'Session', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (item['note'] != null) Text(item['note'], style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 8), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _addMediaItem,
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: const Text('Add Media', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Expanded(
                child: Text(
                  'Content Sharing will come soon!',
                  style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.getDynamicPrimary(context).withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 20),
          Text(_userData?['name'] ?? widget.localizations.guest, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text('@${_userData?['username'] ?? ''}', style: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppColors.getDynamicPrimary(context).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('$_friendCount ${widget.localizations.friends.toUpperCase()}', style: TextStyle(color: AppColors.getDynamicPrimary(context), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child, String? title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primaryOld.withValues(alpha: 0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildRecentlyCompletedSection() {
    return _buildSectionContainer(
      title: widget.localizations.recentlyCompleted,
      child: _recentlyCompleted.isEmpty
          ? Text(widget.localizations.noTricksYet, style: const TextStyle(color: Colors.grey))
          : Column(
              children: _recentlyCompleted.map((trick) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: stanceColors[trick['stance']]?.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: stanceColors[trick['stance']], size: 18),
                ),
                title: Text(trick['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_formatStance(trick['stance'] ?? 'REGULAR'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
    );
  }

  Widget _buildStanceMasteryGrid() {
    Map<String, int> counts = {'REGULAR': 0, 'NOLLIE': 0, 'SWITCH': 0, 'FAKIE': 0};
    for (var item in _allCompleted) {
      counts[(item['stance'] ?? 'REGULAR').toString().toUpperCase()] = (counts[(item['stance'] ?? 'REGULAR').toString().toUpperCase()] ?? 0) + 1;
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.65),
      itemCount: 4,
      itemBuilder: (context, index) {
        final stance = stanceColors.keys.elementAt(index);
        final count = counts[stance] ?? 0;
        final color = stanceColors[stance]!;
        final double progress = _totalBaseTricks > 0 ? count / _totalBaseTricks : 0;

        return Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stance.substring(0, 3).toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 45, height: 45, child: CircularProgressIndicator(value: progress, strokeWidth: 4, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color), strokeCap: StrokeCap.round)),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('$count/$_totalBaseTricks', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    final String? avatarData = _userData?['profile_image'] ?? _userData?['profileImage'];
    final bool isUrl = avatarData != null && avatarData.startsWith('http');

    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(gradient: AppColors.getDynamicGradient(context), shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 60, backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 56, backgroundColor: Colors.grey[100],
                backgroundImage: avatarData != null && avatarData.isNotEmpty
                    ? (isUrl ? NetworkImage(avatarData) : MemoryImage(const Base64Decoder().convert(avatarData)) as ImageProvider)
                    : null,
                child: (avatarData == null || avatarData.isEmpty) 
                    ? (_isUploadingImage ? const CircularProgressIndicator() : const Icon(Icons.person_rounded, size: 50, color: Colors.grey)) 
                    : (_isUploadingImage ? const CircularProgressIndicator() : null),
              ),
            ),
          ),
          Positioned(
            bottom: 5, right: 5,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _showImageSourcePicker,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: _isUploadingImage ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.localizations.sessionMood.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _moodIcon('GREAT', '🔥', AppColors.primary, widget.localizations.moodGreat),
                _moodIcon('OK', '🛹', Colors.blueGrey, widget.localizations.moodOk),
                _moodIcon('BAD', '🤕', Colors.orange, widget.localizations.moodBad),
                _moodIcon('INJURED', '🚑', Colors.redAccent, widget.localizations.moodInjured),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _moodIcon(String mood, String emoji, Color color, String label) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        setState(() => _alreadySkatedToday = true);
        try { await _apiService.logSkatingSession(mood); _loadData(); } catch (e) { _calculateSessionStats(); }
      },
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
