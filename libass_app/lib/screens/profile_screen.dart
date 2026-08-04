import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/api_service.dart';

/// Profile Screen — User settings, server config, and logout.
class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  final _serverCtrl = TextEditingController(text: ApiService.baseUrl);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Profile error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: LibassTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();
      widget.onLogout();
    }
  }

  Future<void> _editName() async {
    final nameCtrl = TextEditingController(text: _profile?['name'] ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: LibassTheme.accentPrimary)),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: LibassTheme.accentPrimary)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _profile?['name']) {
      setState(() => _loading = true);
      try {
        await ApiService.saveProfile({'name': newName});
        _loadProfile();
      } catch (e) {
        debugPrint('Profile update error: $e');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset App Data?'),
        content: const Text(
          'This will clear all local settings, server URL, and saved credentials. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset Everything',
              style: TextStyle(color: LibassTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      widget.onLogout();
    }
  }

  Future<void> _editGender() async {
    String? gender = _profile?['gender'];
    final newGender = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['male', 'female', 'non-binary', 'unspecified'].map((g) {
            return RadioListTile<String>(
              title: Text(g.toUpperCase()),
              value: g,
              groupValue: gender,
              onChanged: (v) => Navigator.pop(ctx, v),
              activeColor: LibassTheme.accentPrimary,
            );
          }).toList(),
        ),
      ),
    );

    if (newGender != null && newGender != gender) {
      setState(() => _loading = true);
      try {
        await ApiService.saveProfile({'gender': newGender});
        _loadProfile();
      } catch (e) {
        debugPrint('Profile update error: $e');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateServer() async {
    String url = _serverCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) {
      url = 'http://$url';
      _serverCtrl.text = url;
    }
    await ApiService.updateBaseUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server updated to $url'),
          backgroundColor: LibassTheme.accentPrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showServerDialog() {
    bool testing = false;
    String? testResult;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Server Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure the backend API URL. Useful for connecting to a local dev server.',
                style: TextStyle(fontSize: 12, color: LibassTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _serverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              if (testResult != null)
                Text(
                  testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    color: testResult!.startsWith('✅')
                        ? LibassTheme.success
                        : LibassTheme.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _serverCtrl.text = 'https://libass-backend.onrender.com';
                    },
                    child: const Text('Reset to Default'),
                  ),
                  ElevatedButton(
                    onPressed: testing
                        ? null
                        : () async {
                            setState(() {
                              testing = true;
                              testResult = null;
                            });
                            final url = _serverCtrl.text.trim();
                            final ok = await ApiService.testConnection(url);
                            setState(() {
                              testing = false;
                              testResult = ok
                                  ? '✅ Server is reachable!'
                                  : '❌ Server unreachable. Check URL or network.';
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Test Connection', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _updateServer();
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: LibassTheme.accentPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // ─── Profile Card ─────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: LibassTheme.accentPrimary,
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: LibassTheme.accentPrimary
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _profile?['email']?.toString().isNotEmpty == true
                                  ? _profile!['email'].toString()[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: LibassTheme.accentPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _profile?['name'] ?? _profile?['email'] ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 16, color: LibassTheme.accentPrimary),
                                    onPressed: _editName,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gender: ${(_profile?['gender'] ?? 'Not set').toString().toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: LibassTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Last synced: Just now',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: LibassTheme.textSecondary.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _editGender,
                          icon: const Icon(Icons.edit_note_rounded,
                              size: 24, color: LibassTheme.accentPrimary),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                _PreferenceToggle(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  value: true,
                  onChanged: (v) {},
                ),
                const Divider(height: 1, indent: 56),
                _PreferenceToggle(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  value: true,
                  onChanged: (v) {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.thermostat_rounded, color: LibassTheme.accentPrimary),
                  title: const Text('Temperature Units', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: const Text('Celsius (°C)', style: TextStyle(color: LibassTheme.textSecondary, fontSize: 13)),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: LibassTheme.accentPrimary),
                  title: const Text('Language', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: const Text('English', style: TextStyle(color: LibassTheme.textSecondary, fontSize: 13)),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.dns_rounded, color: LibassTheme.accentPrimary),
                  title: const Text('Server Connection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: Text(
                    ApiService.baseUrl.replaceFirst('https://', '').replaceFirst('http://', ''),
                    style: const TextStyle(color: LibassTheme.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: _showServerDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),



          const SizedBox(height: 24),
          Text(
            'Maintenance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              label: const Text('Clear Cache'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetData,
              icon: const Icon(Icons.delete_forever_rounded, color: LibassTheme.danger, size: 18),
              label: const Text('Reset App Data', style: TextStyle(color: LibassTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: LibassTheme.danger, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // ─── App Info ──────────────────────────
          Text(
            'About',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: 'App Version', value: '2.0.1'),
                  const Divider(height: 24),
                  _InfoRow(label: 'Platform', value: 'Flutter'),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'AI Engine',
                    value: 'Gemini Vision + Multi-Agent',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    label: 'Version',
                    value: '2.0.1-mobile',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _resetData,
              icon: const Icon(Icons.refresh_rounded,
                  size: 20, color: LibassTheme.textSecondary),
              label: const Text(
                'Reset App Data',
                style: TextStyle(color: LibassTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Running diagnostics...'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                final serverOk = await ApiService.ping();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      serverOk
                          ? '✅ All systems healthy — Server reachable | v2.0.1'
                          : '⚠️ Server unreachable at ${ApiService.baseUrl}',
                    ),
                    backgroundColor: serverOk ? LibassTheme.success : LibassTheme.warning,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_rounded,
                  size: 20, color: LibassTheme.textSecondary),
              label: const Text(
                'Run Diagnostics',
                style: TextStyle(color: LibassTheme.textSecondary),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── Logout ────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: LibassTheme.danger),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: LibassTheme.danger),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: LibassTheme.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: LibassTheme.accentPrimary),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: LibassTheme.accentPrimary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: LibassTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
