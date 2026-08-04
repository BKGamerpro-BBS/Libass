import 'dart:async';
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
  static String baseUrl = 'https://libass-backend.onrender.com';

  // Session cookie for auth
  static String? _sessionCookie;

  /// Whether the server has been confirmed awake this session
  static bool _serverAwake = false;

  /// Timer for keeping production server awake
  static Timer? _keepAliveTimer;

  /// Production-appropriate timeouts for Render free-tier cold starts
  static const Duration _authTimeout = Duration(seconds: 60);
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _longTimeout = Duration(seconds: 45);
  static const Duration _uploadTimeout = Duration(seconds: 90);
  static const Duration _pingTimeout = Duration(seconds: 10);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
    // Restore saved base URL (in case user changed it during dev)
    final savedUrl = prefs.getString('base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      baseUrl = savedUrl;
    }
  }

  static const String defaultUrl = 'https://libass-backend.onrender.com';

  /// Helper to check if a URL points to a local IP / localhost
  static bool isLocalUrl(String url) {
    return url.contains('localhost') ||
        url.contains('127.0.0.1') ||
        url.contains('10.0.2.2') ||
        url.contains('192.168.') ||
        url.contains('172.');
  }

  /// Wakes up the Render server or checks server connectivity.
  /// If configured to a local IP that is unreachable (e.g. on Mobile Data),
  /// automatically falls back to the production Render URL.
  static Future<bool> wakeUpServer() async {
    if (_serverAwake) return true;

    // If configured to a local IP, attempt a quick 3-second ping
    if (isLocalUrl(baseUrl)) {
      try {
        final res = await http
            .get(Uri.parse(baseUrl))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          _serverAwake = true;
          return true;
        }
      } catch (_) {
        // Local IP unreachable (e.g. user switched to Mobile Data or left home Wi-Fi)
        // Auto-fallback to production Render backend
        baseUrl = defaultUrl;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('base_url', defaultUrl);
      }
    }

    try {
      // Use the root health-check endpoint — lightweight, no auth needed
      final res = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        _serverAwake = true;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Starts a periodic keep-alive ping loop that runs every 5 minutes.
  /// This prevents the remote Render server from sleeping while the app is active.
  static void startKeepAliveLoop() {
    _keepAliveTimer?.cancel();

    // Check if the current URL is local. If it is, skip pinging.
    if (isLocalUrl(baseUrl)) return;

    // Ping every 5 minutes (Render's timeout is 15 minutes)
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final res = await http.get(Uri.parse(baseUrl)).timeout(_pingTimeout);
        if (res.statusCode == 200) {
          _serverAwake = true;
        }
      } catch (_) {
        // Fail silently during keep-alive pings
      }
    });
  }

  /// Cancels the keep-alive ping loop.
  static void stopKeepAliveLoop() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  static Future<void> updateBaseUrl(String url) async {
    url = url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', url);
    
    // Restart keep-alive loop with the new URL configuration
    startKeepAliveLoop();
  }

  /// Check if a given URL is a valid Libass server
  static Future<bool> testConnection(String url) async {
    url = url.trim();
    if (url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    try {
      final res = await http
          .get(Uri.parse('$url/api/libaas/profile'))
          .timeout(_authTimeout);
      // Any response from this endpoint means the server is likely our backend
      return res.statusCode == 200 || res.statusCode == 401;
    } catch (_) {
      return false;
    }
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
          .timeout(_pingTimeout);
      final ok = res.statusCode == 200 || res.statusCode == 401;
      if (ok) _serverAwake = true;
      return ok;
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
    ).timeout(_authTimeout);
    _saveCookie(res);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/libaas/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(_authTimeout);
    _saveCookie(res);
    return jsonDecode(res.body);
  }

  static Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/api/libaas/auth/logout'),
      headers: _headers,
    ).timeout(_defaultTimeout);
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
  }

  static Future<Map<String, dynamic>> checkSession() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/auth/session'),
      headers: _headers,
    ).timeout(_authTimeout);
    _saveCookie(res);
    _serverAwake = true;
    return jsonDecode(res.body);
  }

  // ─── PROFILE ──────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/profile'),
      headers: _headers,
    ).timeout(_defaultTimeout);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> saveProfile(
      Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/libaas/profile'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_defaultTimeout);
    return jsonDecode(res.body);
  }

  // ─── WARDROBE ─────────────────────────────────────
  static Future<List<WardrobeItem>> getWardrobe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/wardrobe'),
      headers: _headers,
    ).timeout(_defaultTimeout);
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
    final streamedRes = await req.send().timeout(_uploadTimeout);
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
    ).timeout(_defaultTimeout);
    return WardrobeItem.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteWardrobeItem(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/api/libaas/wardrobe/$id'),
      headers: _headers,
    ).timeout(_defaultTimeout);
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
    ).timeout(_longTimeout);
    final list = jsonDecode(res.body) as List;
    return list.map((i) => OutfitSuggestion.fromJson(i)).toList();
  }

  // ─── WEATHER ──────────────────────────────────────
  static Future<WeatherData> getWeather(double lat, double lon) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/libaas/weather?lat=$lat&lon=$lon'),
      headers: _headers,
    ).timeout(_defaultTimeout);
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
    final streamedRes = await req.send().timeout(_uploadTimeout);
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
    ).timeout(_defaultTimeout);
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
