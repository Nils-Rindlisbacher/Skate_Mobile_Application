import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Production URL points to a subdomain, local URLs for development
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
      // Clear cache on logout
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
      throw Exception('Request failed with status: ${response.statusCode}');
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
    );
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
    );

    final data = _handleResponse(response);
    if (data != null && data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _getHeaders(),
    );
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
    );
    _handleResponse(response);
  }

  Future<void> updatePrivacy(bool isPublic) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/privacy'),
      headers: await _getHeaders(),
      body: jsonEncode({'is_public': isPublic}),
    );
    _handleResponse(response);
  }

  Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile/$userId'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // --- Data Services ---

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _getHeaders(),
    );
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('categories', data);
    }
    return data;
  }

  Future<List<dynamic>> getTricks({int? categoryId}) async {
    final url = categoryId == null
        ? '$baseUrl/tricks'
        : '$baseUrl/tricks?category_id=$categoryId';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('tricks_${categoryId ?? 'all'}', data);
    }
    return data;
  }

  Future<List<dynamic>> getCompletedTricks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/completed'),
      headers: await _getHeaders(),
    );
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('completed_tricks', data);
    }
    return data;
  }

  Future<List<dynamic>> getWishlistTricks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wishlist'),
      headers: await _getHeaders(),
    );
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('wishlist_tricks', data);
    }
    return data;
  }

  Future<void> toggleWishlist(int trickId, bool isWishlisted) async {
    final endpoint = isWishlisted ? 'wishlist/remove' : 'wishlist/add';
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode({'trick_id': trickId}),
    );
    _handleResponse(response);
  }

  Future<void> toggleCompleted(int trickId, bool isCompleted) async {
    final endpoint = isCompleted ? 'completed/remove' : 'completed/add';
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode({'trick_id': trickId}),
    );
    _handleResponse(response);
  }

  Future<List<dynamic>> getCategoryStats({int? userId}) async {
    final url = userId == null 
        ? '$baseUrl/categories/stats'
        : '$baseUrl/categories/stats?user_id=$userId';
        
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    final data = _handleResponse(response);
    if (data != null && userId == null) {
      await _cacheData('category_stats_me', data);
    }
    return data;
  }

  Future<List<dynamic>> getLeaderboard({int? categoryId}) async {
    final url = categoryId == null
        ? '$baseUrl/users/leaderboard'
        : '$baseUrl/users/leaderboard?category_id=$categoryId';
        
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  // --- Session Goals ---

  Future<List<dynamic>> getSessionGoals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/goals'),
      headers: await _getHeaders(),
    );
    final data = _handleResponse(response);
    if (data != null) {
      await _cacheData('session_goals', data);
    }
    return data;
  }

  Future<Map<String, dynamic>> addSessionGoal(Map<String, dynamic> goalData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/goals'),
      headers: await _getHeaders(),
      body: jsonEncode(goalData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateSessionGoal(int id, Map<String, dynamic> goalData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/goals/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(goalData),
    );
    return _handleResponse(response);
  }

  Future<void> deleteSessionGoal(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/goals/$id'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
  }
}
