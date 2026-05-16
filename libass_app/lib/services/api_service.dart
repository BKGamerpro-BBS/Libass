import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// LIBASS API Client — talks to the Flask backend.
///
/// For development, set [baseUrl] to your computer's local network IP
/// (e.g. http://192.168.1.100:5000). For production, point to your server.
class ApiService {
  // Change this to your Flask backend URL.
  // - Android emulator: http://10.0.2.2:5000 (maps to host localhost)
  // - Physical device: use your computer's LAN IP, e.g. http://192.168.1.100:5000
  // - iOS simulator: http://localhost:5000
  static String baseUrl = Platform.isAndroid
      ? 'http://192.168.1.15:5000'
      : 'http://localhost:5000';

  // Session cookie for auth
  static String? _sessionCookie;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  static Future<void> updateBaseUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', url);
  }

  static void _saveCookie(http.Response res) async {
    final raw = res.headers['set-cookie'];
    if (raw != null) {
      _sessionCookie = raw.split(';').first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_cookie', _sessionCookie!);
    }
  }

  static Future<bool> ping() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/libaas/profile'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200 || res.statusCode == 401; // 401 means auth required, so server is up
    } catch (_) {
      return false;
    }
  }

  /// Check if a given URL is a valid Libass server
  static Future<bool> testConnection(String url) async {
    try {
      final res = await http
          .get(Uri.parse('$url/api/libaas/profile'))
          .timeout(const Duration(seconds: 5));
      // Any response from this endpoint means the server is likely our backend
      return res.statusCode == 200 || res.statusCode == 401;
    } catch (_) {
      return false;
    }
  }

  // ─── AUTH ─────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
      String email, String password, String gender) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/libaas/auth/register'),
      headers: _headers,
      body: jsonEncode(
          {'email': email, 'password': password, 'gender': gender}),
    ).timeout(const Duration(seconds: 5));
    _saveCookie(res);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/libaas/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 5));
    _saveCookie(res);
    return jsonDecode(res.body);
  }

  static Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/api/libaas/auth/logout'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
  }

  static Future<Map<String, dynamic>> checkSession() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/auth/session'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));
    _saveCookie(res);
    return jsonDecode(res.body);
  }

  // ─── PROFILE ──────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/profile'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> saveProfile(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/libaas/profile'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 5));
    return jsonDecode(res.body);
  }

  // ─── WARDROBE ─────────────────────────────────────
  static Future<List<WardrobeItem>> getWardrobe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/wardrobe'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));
    final list = jsonDecode(res.body) as List;
    return list.map((i) => WardrobeItem.fromJson(i)).toList();
  }

  static Future<WardrobeItem> addWardrobeItem(File imageFile) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/libaas/wardrobe'),
    );
    if (_sessionCookie != null) {
      req.headers['Cookie'] = _sessionCookie!;
    }
    req.files.add(await http.MultipartFile.fromPath('images', imageFile.path));
    final streamedRes = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamedRes);
    _saveCookie(res);
    if (res.statusCode >= 400) {
      throw Exception('Upload failed (${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data is List) return WardrobeItem.fromJson(data.first);
    return WardrobeItem.fromJson(data);
  }

  static Future<WardrobeItem> updateWardrobeItem(
      String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/libaas/wardrobe/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 5));
    return WardrobeItem.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteWardrobeItem(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/api/libaas/wardrobe/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 5));
  }

  // ─── SUGGESTIONS ──────────────────────────────────
  static Future<List<OutfitSuggestion>> getSuggestions({
    String weather = 'summer',
    String occasion = 'casual',
    String persona = 'casual',
  }) async {
    final res = await http.get(
      Uri.parse(
          '$baseUrl/api/libaas/suggestions?weather=$weather&occasion=$occasion&persona=$persona'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    final list = jsonDecode(res.body) as List;
    return list.map((i) => OutfitSuggestion.fromJson(i)).toList();
  }

  // ─── WEATHER ──────────────────────────────────────
  static Future<WeatherData> getWeather(double lat, double lon) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/weather?lat=$lat&lon=$lon'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));
    return WeatherData.fromJson(jsonDecode(res.body));
  }

  // ─── RATING ───────────────────────────────────────
  static Future<OutfitRating> rateOutfit(File imageFile) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/libaas/rate_outfit'),
    );
    if (_sessionCookie != null) {
      req.headers['Cookie'] = _sessionCookie!;
    }
    req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamedRes = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamedRes);
    _saveCookie(res);
    return OutfitRating.fromJson(jsonDecode(res.body));
  }

  // ─── FEEDBACK ─────────────────────────────────────
  static Future<void> saveFeedback(List<String> itemIds, int isLiked) async {
    await http.post(
      Uri.parse('$baseUrl/api/libaas/feedback'),
      headers: _headers,
      body: jsonEncode({'item_ids': itemIds, 'is_liked': isLiked}),
    ).timeout(const Duration(seconds: 5));
  }

  /// Full image URL from relative server path
  static String imageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Normalize path and base
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    
    return '$cleanBase$cleanPath';
  }
}
