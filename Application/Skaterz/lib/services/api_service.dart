import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = kReleaseMode || kIsWeb
      ? "https://skate-mobile-application-api.onrender.com/api"
      : "http://10.0.2.2:8080/api";

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

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (e) {
      debugPrint("Secure Storage Error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'jwt_token');
      await _storage.deleteAll();
    } catch (e) {
      debugPrint("Secure Storage Logout Error: $e");
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
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

  // --- Caching Helpers ---

  Future<void> _cacheData(String key, dynamic data) async {
    try {
      await _storage.write(key: 'cache_$key', value: jsonEncode(data));
    } catch (e) {
      debugPrint("Caching Error: $key - $e");
    }
  }

  Future<dynamic> getCachedData(String key) async {
    try {
      String? cached = await _storage.read(key: 'cache_$key');
      if (cached != null) return jsonDecode(cached);
    } catch (e) {
      debugPrint("Cache Read Error: $key - $e");
    }
    return null;
  }

  // --- Wrapper für Requests mit Timeout ---
  Future<http.Response> _get(String path) async {
    return await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
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

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = _handleResponse(response);
    if (data != null && data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _get('/users/me');
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('user_me', data);
    }
    return data;
  }

  Future<void> uploadProfileImage(String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/me/image'),
      headers: await _getHeaders(),
      body: jsonEncode({'image': base64Image}),
    ).timeout(const Duration(seconds: 30));
    _handleResponse(response);
  }

  Future<void> updatePrivacy(bool isPublic) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/privacy'),
      headers: await _getHeaders(),
      body: jsonEncode({'is_public': isPublic}),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await _get('/users/profile/$userId');
    return _handleResponse(response);
  }

  // --- Data Services ---

  Future<List<dynamic>> getCategories() async {
    final response = await _get('/categories');
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('categories', data);
    }
    return data;
  }

  Future<List<dynamic>> getTricks({int? categoryId}) async {
    final path = categoryId == null ? '/tricks' : '/tricks?category_id=$categoryId';
    final response = await _get(path);
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('tricks_${categoryId ?? 'all'}', data);
    }
    return data;
  }

  Future<List<dynamic>> getCompletedTricks() async {
    final response = await _get('/completed');
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('completed_tricks', data);
    }
    return data;
  }

  Future<List<dynamic>> getWishlistTricks() async {
    final response = await _get('/wishlist');
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('wishlist_tricks', data);
    }
    return data;
  }

  Future<void> toggleWishlist(int trickId, bool isWishlisted) async {
    final endpoint = isWishlisted ? '/wishlist/remove' : '/wishlist/add';
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode({'trick_id': trickId}),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  Future<void> toggleCompleted(int trickId, bool isCompleted) async {
    final endpoint = isCompleted ? '/completed/remove' : '/completed/add';
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode({'trick_id': trickId}),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }

  Future<List<dynamic>> getCategoryStats({int? userId}) async {
    final path = userId == null ? '/categories/stats' : '/categories/stats?user_id=$userId';
    final response = await _get(path);
    final data = _handleResponse(response);
    if (data != null && userId == null) {
      await _cacheData('category_stats_me', data);
    }
    return data;
  }

  Future<List<dynamic>> getLeaderboard({int? categoryId}) async {
    final path = categoryId == null ? '/users/leaderboard' : '/users/leaderboard?category_id=$categoryId';
    final response = await _get(path);
    return _handleResponse(response);
  }

  // --- Session Goals ---

  Future<List<dynamic>> getSessionGoals() async {
    try {
      final response = await _get('/goals');
      final data = _handleResponse(response);
      if (data != null) {
        await _cacheData('session_goals', data);
      }
      return data ?? [];
    } catch (e) {
      debugPrint("API getSessionGoals Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addSessionGoal(Map<String, dynamic> goalData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/goals'),
      headers: await _getHeaders(),
      body: jsonEncode(goalData),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateSessionGoal(int id, Map<String, dynamic> goalData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/goals/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(goalData),
    ).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<void> deleteSessionGoal(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/goals/$id'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 15));
    _handleResponse(response);
  }
}
