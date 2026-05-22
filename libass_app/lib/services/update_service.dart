import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import 'api_service.dart';

/// Checks the backend for the latest app version and shows an update dialog.
class UpdateService {
  /// The current version of this app — must match pubspec.yaml version.
  static const String currentVersion = '2.0.0';

  /// Checks the backend for updates and shows a dialog if one is available.
  /// Call this from your main shell after authentication.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/api/libaas/version'))
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      final latestVersion = data['latest_version'] as String? ?? currentVersion;
      final minVersion = data['min_version'] as String? ?? '0.0.0';
      final downloadUrl = data['download_url'] as String? ?? '';
      final changelog = data['changelog'] as String? ?? '';

      if (!context.mounted) return;

      final comparison = _compareVersions(currentVersion, latestVersion);
      if (comparison >= 0) return; // Already on latest or newer

      final isForced = _compareVersions(currentVersion, minVersion) < 0;

      showDialog(
        context: context,
        barrierDismissible: !isForced,
        builder: (ctx) => _UpdateDialog(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          changelog: changelog,
          isForced: isForced,
        ),
      );
    } catch (_) {
      // Silently fail — don't block the app if the check fails
    }
  }

  /// Compare two semver strings. Returns:
  ///  -1 if a < b, 0 if a == b, 1 if a > b
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av < bv) return -1;
      if (av > bv) return 1;
    }
    return 0;
  }
}

class _UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String changelog;
  final bool isForced;

  const _UpdateDialog({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
    required this.isForced,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: LibassTheme.bgSurface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: LibassTheme.accentPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: LibassTheme.accentPrimary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isForced ? 'Update Required' : 'Update Available',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LibassTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Version info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LibassTheme.bgSurfaceDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LibassTheme.borderSubtle),
              ),
              child: Text(
                'v$currentVersion  →  v$latestVersion',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LibassTheme.accentPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Changelog
            if (changelog.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LibassTheme.bgPrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LibassTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What's New:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LibassTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      changelog,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LibassTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDownload(downloadUrl),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LibassTheme.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // Later button (only if not forced)
            if (!isForced) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: LibassTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
