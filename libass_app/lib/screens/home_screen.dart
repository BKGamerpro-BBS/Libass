import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/glassmorphic_card.dart';

/// Home Screen — Weather widget + daily outfit suggestion + quick actions.
class HomeScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _weather;
  String _currentWeather = 'summer';
  OutfitSuggestion? _dailySuggestion;
  bool _loadingWeather = true;
  bool _loadingSuggestion = true;
  String _lastWeatherUpdate = 'Never';
  String _city = '';
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      if (mounted) setState(() => _profile = data);
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _loadWeather({bool manual = false}) async {
    if (manual) {
      final now = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refreshing weather data... (${now.hour}:${now.minute.toString().padLeft(2, '0')})'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _loadingWeather = true;
    if (mounted) setState(() {});

    try {
      // Default coords (NYC) — overridden if GPS available
      double lat = 40.71;
      double lon = -74.01;

      // Attempt real location first
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (locErr) {
        debugPrint('Location error (using defaults): $locErr');
      }

      // Single weather API call with best available coordinates
      final weather = await ApiService.getWeather(lat, lon);

      final cond = weather.condition.toLowerCase();
      const weatherMap = {
        'clear': 'summer',
        'sunny': 'summer',
        'snowy': 'winter',
        'cloudy': 'spring',
        'rainy': 'rainy',
        'thunderstorm': 'rainy',
        'storm': 'rainy',
        'mist': 'spring',
        'fog': 'spring',
      };
      _currentWeather = weatherMap[cond] ?? 'summer';
      _weather = weather;
      _city = weather.city ?? '';
      _loadingWeather = false;

      final now = DateTime.now();
      _lastWeatherUpdate = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      if (mounted) setState(() {});
      _loadSuggestion();
    } catch (e) {
      debugPrint('Weather error: $e');
      _weather = WeatherData(
        temperatureF: 72,
        temperatureC: 22,
        condition: 'Clear',
      );
      _loadingWeather = false;
      _lastWeatherUpdate = 'Offline';
      if (mounted) setState(() {});
      _loadSuggestion();
    }
  }

  Future<void> _loadSuggestion() async {
    try {
      final suggestions =
          await ApiService.getSuggestions(weather: _currentWeather);
      if (suggestions.isNotEmpty) {
        _dailySuggestion = suggestions.first;
      }
    } catch (e) {
      debugPrint('Suggestion error: $e');
    }
    _loadingSuggestion = false;
    if (mounted) setState(() {});
  }

  String _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '☀️';
      case 'partly cloudy':
        return '⛅';
      case 'overcast':
        return '☁️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      case 'thunderstorm':
      case 'storm':
        return '⛈️';
      case 'drizzle':
        return '🌦️';
      default:
        return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ──────────────────────────
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_greeting${(_profile != null && _profile!['name'] != null && _profile!['name'].toString().trim().isNotEmpty) ? ", ${_profile!['name']}" : ""}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LibassTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Personal AI Stylist',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LibassTheme.textSecondary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 32),
          _buildQuickActions()
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 32),

          // ─── Weather Context ───────────────────
          _buildWeatherCard(),

          const SizedBox(height: 24),

          // ─── Daily Pick ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Pick",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History coming soon!')),
                  );
                },
                icon: const Icon(Icons.history_rounded,
                    color: LibassTheme.accentPrimary),
                tooltip: 'History',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDailyPick(),

          const SizedBox(height: 24),

          // ─── Quick Actions ───────────────────
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),

          const SizedBox(height: 100), // bottom nav spacing
        ],
      ),
    );
  }


  Widget _buildWeatherCard() {
    if (_loadingWeather) {
      return Card(
        child: Container(
          height: 120,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: LibassTheme.accentPrimary,
          ),
        ),
      );
    }

    final w = _weather!;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9CFC4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: GlassmorphicCard(
        borderRadius: BorderRadius.circular(20),
        blur: 15,
        opacity: 0.15,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        w.condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _weatherIcon(w.condition),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${w.temperatureC}°C / ${w.temperatureF}°F',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                      ),
                    ),
                  ),
                  if (w.highC != null && w.lowC != null)
                    Text(
                      'H: ${w.highC}° L: ${w.lowC}°',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _WeatherDetail(icon: Icons.water_drop_outlined, label: '65%'),
                      const SizedBox(width: 16),
                      _WeatherDetail(icon: Icons.air_rounded, label: '12 km/h'),
                    ],
                  ),
                  if (_city.isNotEmpty)
                    Text(
                      _city,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [const Shadow(blurRadius: 8, color: Colors.black45)],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated at: $_lastWeatherUpdate',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                'Styling for $_currentWeather',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _loadWeather(manual: true),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Refresh Weather',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPick() {
    if (_loadingSuggestion) {
      return const Card(
        child: SizedBox(
          height: 160,
          child: Center(
            child: CircularProgressIndicator(
              color: LibassTheme.accentPrimary,
            ),
          ),
        ),
      );
    }

    if (_dailySuggestion == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                '👕',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),
              Text(
                'Add items to your wardrobe to get AI suggestions!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LibassTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final s = _dailySuggestion!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LibassTheme.accentPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⭐ ${s.score}/10',
                    style: const TextStyle(
                      color: LibassTheme.accentPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LibassTheme.accentSecondaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.occasion,
                    style: const TextStyle(
                      color: LibassTheme.accentSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to favorites!')),
                    );
                  },
                  icon: const Icon(Icons.favorite_border_rounded, size: 20),
                  color: LibassTheme.danger,
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing functionality coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  color: LibassTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: s.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final item = s.items[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 100,
                      color: LibassTheme.bgSurfaceDim,
                      child: Image.network(
                        ApiService.imageUrl(item.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded, size: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.reasoning,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => widget.onNavigate?.call(1),
                child: const Text('View all suggestions →'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 5) return 'Good Late Night';
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.add_a_photo_rounded,
            label: 'Rate\nOutfit',
            badge: 'NEW',
            color: LibassTheme.accentSecondary,
            onTap: () => widget.onNavigate?.call(2), // Camera tab
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.auto_awesome_rounded,
            label: 'Get\nStyled',
            color: LibassTheme.accentPrimary,
            onTap: () => widget.onNavigate?.call(1), // Outfits tab
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.upload_rounded,
            label: 'Add\nClothes',
            color: LibassTheme.warning,
            onTap: () => widget.onNavigate?.call(3), // Wardrobe tab
          ),
        ),
      ],
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WeatherDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? LibassTheme.accentPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: effectiveColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LibassTheme.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
