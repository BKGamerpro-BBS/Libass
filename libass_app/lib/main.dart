import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'services/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/outfits_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/nav_bar.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LibassApp());
}

class LibassApp extends StatelessWidget {
  const LibassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIBASS — AI Stylist',
      theme: LibassTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

/// Root shell — handles auth state and shows either AuthScreen or MainShell.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _authenticated = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      // Proactively wake the Render server during splash screen
      await ApiService.wakeUpServer();
      final result = await ApiService.checkSession();
      if (result['authenticated'] == true) {
        _authenticated = true;
      }
    } catch (_) {
      // Server unreachable or no valid session — stay on auth screen
    }
    if (mounted) setState(() => _checkingSession = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                LibassTheme.bgPrimary,
                LibassTheme.accentPrimaryLight.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'LI',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: LibassTheme.accentPrimary,
                        shadows: [
                          Shadow(
                            color: LibassTheme.accentPrimary.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: 'BASS',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: LibassTheme.accentSecondary,
                        shadows: [
                          Shadow(
                            color: LibassTheme.accentSecondary.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI Personal Stylist',
                  style: TextStyle(
                    color: LibassTheme.textSecondary,
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: LibassTheme.accentPrimary,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Connecting...',
                  style: TextStyle(
                    color: LibassTheme.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 80),
                const Text(
                  'v2.0.1',
                  style: TextStyle(
                    color: LibassTheme.borderColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_authenticated) {
      return AuthScreen(
        onAuthenticated: () => setState(() => _authenticated = true),
      );
    }

    return MainShell(
      onLogout: () => setState(() => _authenticated = false),
    );
  }
}

/// Main navigation shell — bottom nav with 5 screens.
class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check for app updates after the main shell loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: (i) => setState(() => _currentIndex = i)),
    const OutfitsScreen(),
    const CameraScreen(),
    const WardrobeScreen(),
    ProfileScreen(onLogout: widget.onLogout),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: LibassNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
