import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const bool useProduction = true; 

  final String baseUrl = (kReleaseMode || useProduction)
      ? "https://skate-mobile-application-api.onrender.com/api"
      : (kIsWeb ? "http://127.0.0.1:8080/api" : "http://10.0.2.2:8080/api");

  final _storage = const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'SkaterzAuth',
      publicKey: 'SkaterzKey',
    ),
  );
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  VoidCallback? onUnauthorized;
  
  String? _cachedToken;
  bool _tokenLoaded = false;

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _tokenLoaded = true;
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    if (_tokenLoaded) return _cachedToken;
    try {
      _cachedToken = await _storage.read(key: 'jwt_token');
      _tokenLoaded = true;
      return _cachedToken;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      _cachedToken = null;
      _tokenLoaded = true;
      await _storage.delete(key: 'jwt_token');
      await _storage.deleteAll();
      _memoryCache.clear();
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      logout();
      if (onUnauthorized != null) onUnauthorized!();
      throw Exception('Unauthorized');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Server Error (${response.statusCode}): ${response.body}');
    }
  }

  // --- Theme Management ---
  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: 'theme_mode', value: mode);
    _memoryCache['theme_mode'] = mode;
  }

  // --- Caching Helpers ---
  final Map<String, dynamic> _memoryCache = {};

  Future<void> _cacheData(String key, dynamic data) async {
    try {
      _memoryCache[key] = data;
      await _storage.write(key: 'cache_$key', value: jsonEncode(data));
    } catch (e) {
      debugPrint("Caching Error: $key - $e");
    }
  }

  Future<void> clearCache(String key) async {
    _memoryCache.remove(key);
    await _storage.delete(key: 'cache_$key');
  }

  Future<dynamic> getCachedData(String key) async {
    if (_memoryCache.containsKey(key)) return _memoryCache[key];
    try {
      String? cached = await _storage.read(key: 'cache_$key');
      if (cached != null) {
        final data = jsonDecode(cached);
        _memoryCache[key] = data;
        return data;
      }
    } catch (_) {}
    return null;
  }

  Future<void> warmUp() async {
    try {
      // ignore: unawaited_futures
      Future.wait([
        http.get(Uri.parse('$baseUrl/categories')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('$baseUrl/tricks/count')).timeout(const Duration(seconds: 5)),
      ]).then((_) => null).catchError((_) => null);
    } catch (_) {}
  }

  Future<http.Response> _get(String path, {Duration timeout = const Duration(seconds: 15)}) async {
    // Add a cache-busting timestamp to the URL for web
    final Uri uri = Uri.parse('$baseUrl$path');
    final Map<String, String> queryParams = Map.from(uri.queryParameters);
    queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
    
    final finalUri = uri.replace(queryParameters: queryParams);

    return await http.get(
      finalUri,
      headers: await _getHeaders(),
    ).timeout(timeout);
  }

  // --- Auth Services ---
  Future<void> register(String username, String password, String email, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'name': name,
      }),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = _handleResponse(response);
    if (data != null && data is Map && data['token'] != null) {
      await saveToken(data['token']);
      return Map<String, dynamic>.from(data);
    }
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _get('/users/me');
      final data = _handleResponse(response);
      if (data != null && data is Map) {
        final map = Map<String, dynamic>.from(data);
        await _cacheData('user_me', map);
        return map;
      }
      return null;
    } catch (e) {
      final cached = await getCachedData('user_me');
      if (cached != null && cached is Map) return Map<String, dynamic>.from(cached);
      rethrow;
    }
  }

  Future<void> uploadProfileImage(String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/me/image'),
      headers: await _getHeaders(),
      body: jsonEncode({'image': base64Image}),
    ).timeout(const Duration(seconds: 30));
    _handleResponse(response);
    await clearCache('user_me');
  }

  Future<void> updatePrivacy(bool isPublic) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/privacy'),
      headers: await _getHeaders(),
      body: jsonEncode({'is_public': isPublic}),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
    await clearCache('user_me');
  }

  Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final response = await _get('/users/profile/$userId');
    final data = _handleResponse(response);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // --- Data Services ---
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _get('/categories');
      final data = _handleResponse(response);
      if (data != null && data is List) {
        await _cacheData('categories', data);
        return data;
      }
      return [];
    } catch (e) {
      final cached = await getCachedData('categories');
      if (cached != null && cached is List) return cached;
      rethrow;
    }
  }

  Future<List<dynamic>> getTricks({int? categoryId, String? search, int page = 0, int size = 20, int? userId}) async {
    String path = '/tricks?page=$page&size=$size';
    if (categoryId != null) path += '&category_id=$categoryId';
    if (search != null && search.isNotEmpty) path += '&search=${Uri.encodeComponent(search)}';
    if (userId != null) path += '&user_id=$userId';
    
    try {
      final response = await _get(path, timeout: const Duration(seconds: 20));
      final data = _handleResponse(response);
      if (data != null && data is List) {
        return data;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getTrickCount() async {
    try {
      final response = await _get('/tricks/count');
      final data = _handleResponse(response);
      final count = (data as num).toInt();
      _cacheData('trick_count', count);
      return count;
    } catch (e) {
      final cached = await getCachedData('trick_count');
      if (cached != null) return (cached as num).toInt();
      return 233; 
    }
  }

  Future<List<dynamic>> getCompletedTricks({int? userId}) async {
    final path = userId == null ? '/completed' : '/completed?user_id=$userId';
    try {
      final response = await _get(path);
      final data = _handleResponse(response);
      if (data != null && data is List) {
        if (userId == null) await _cacheData('completed_tricks', data);
        return data;
      }
      return [];
    } catch (e) {
      if (userId == null) {
        final cached = await getCachedData('completed_tricks');
        if (cached != null && cached is List) return cached;
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getWishlistTricks() async {
    try {
      final response = await _get('/wishlist');
      final data = _handleResponse(response);
      if (data != null && data is List) {
        await _cacheData('wishlist_tricks', data);
        return data;
      }
      return [];
    } catch (e) {
      final cached = await getCachedData('wishlist_tricks');
      if (cached != null && cached is List) return cached;
      rethrow;
    }
  }

  Future<void> toggleWishlist(int trickId, bool isWishlisted, String stance) async {
    final endpoint = isWishlisted ? '/wishlist/remove' : '/wishlist/add';
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'trick_id': trickId,
        'stance': stance,
      }),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
    await clearCache('wishlist_tricks');
  }

  Future<void> toggleCompleted(int trickId, bool isCompleted, String stance) async {
    final endpoint = isCompleted ? '/completed/remove' : '/completed/add';
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'trick_id': trickId,
        'stance': stance,
      }),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
    await clearCache('completed_tricks');
    await clearCache('category_stats_me');
  }

  Future<List<dynamic>> getCategoryStats({int? userId}) async {
    final path = userId == null ? '/categories/stats' : '/categories/stats?user_id=$userId';
    try {
      final response = await _get(path);
      final data = _handleResponse(response);
      if (data != null && data is List) {
        if (userId == null) await _cacheData('category_stats_me', data);
        return data;
      }
      return [];
    } catch (e) {
      if (userId == null) {
        final cached = await getCachedData('category_stats_me');
        if (cached != null && cached is List) return cached;
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getCategoryStatsFiltered({int? userId, String? search}) async {
    String path = userId == null ? '/categories/stats' : '/categories/stats?user_id=$userId';
    if (search != null && search.isNotEmpty) {
      path += (path.contains('?') ? '&' : '?') + 'search=${Uri.encodeComponent(search)}';
    }
    
    try {
      final response = await _get(path);
      final data = _handleResponse(response);
      return (data != null && data is List) ? data : [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getLeaderboard({int? categoryId, String? stance}) async {
    final queryParams = <String>[];
    if (categoryId != null) queryParams.add('category_id=$categoryId');
    if (stance != null && stance != 'ALL') queryParams.add('stance=$stance');
    final String path = '/users/leaderboard${queryParams.isNotEmpty ? '?${queryParams.join('&')}' : ''}';
    
    final response = await _get(path);
    final data = _handleResponse(response);
    return (data != null && data is List) ? data : [];
  }

  // --- Session Goals ---
  Future<List<dynamic>> getSessionGoals() async {
    try {
      final response = await _get('/goals');
      final data = _handleResponse(response);
      if (data != null && data is List) {
        await _cacheData('session_goals', data);
        return data;
      }
      return [];
    } catch (e) {
      final cached = await getCachedData('session_goals');
      if (cached != null && cached is List) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> addSessionGoal(Map<String, dynamic> goalData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/goals'),
      headers: await _getHeaders(),
      body: jsonEncode(goalData),
    ).timeout(const Duration(seconds: 15));
    final data = _handleResponse(response);
    await clearCache('session_goals');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<Map<String, dynamic>?> updateSessionGoal(int id, Map<String, dynamic> goalData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/goals/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(goalData),
    ).timeout(const Duration(seconds: 15));
    final data = _handleResponse(response);
    await clearCache('session_goals');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> deleteSessionGoal(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/goals/$id'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
    await clearCache('session_goals');
  }

  // --- Skating Sessions ---
  Future<List<dynamic>> getSkatingSessions({int? userId}) async {
    final path = userId == null ? '/sessions' : '/sessions?user_id=$userId';
    try {
      final response = await _get(path);
      final data = _handleResponse(response);
      if (data != null && data is List) {
        if (userId == null) await _cacheData('skating_sessions', data);
        return data;
      }
      return [];
    } catch (e) {
      if (userId == null) {
        final cached = await getCachedData('skating_sessions');
        if (cached != null && cached is List) return cached;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> logSkatingSession(String mood, {DateTime? date}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'mood': mood,
        'sessionDate': (date ?? DateTime.now()).toIso8601String().split('T')[0],
      }),
    ).timeout(const Duration(seconds: 15));
    final data = _handleResponse(response);
    await clearCache('skating_sessions');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> deleteSkatingSession(String date) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sessions/$date'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
    await clearCache('skating_sessions');
  }

  // --- Equipment Services ---
  Future<List<dynamic>> getEquipment() async {
    try {
      final response = await _get('/equipment');
      final data = _handleResponse(response);
      if (data != null && data is List) {
        await _cacheData('equipment_list', data);
        return data;
      }
      return [];
    } catch (e) {
      final cached = await getCachedData('equipment_list');
      if (cached != null && cached is List) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> addEquipment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/equipment'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    final result = _handleResponse(response);
    await clearCache('equipment_list');
    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  Future<Map<String, dynamic>?> updateEquipment(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/equipment/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    final result = _handleResponse(response);
    await clearCache('equipment_list');
    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  Future<void> deleteEquipment(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/equipment/$id'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
    await clearCache('equipment_list');
  }
}
