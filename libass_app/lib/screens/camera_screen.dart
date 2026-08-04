import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

/// Camera Screen — Take a photo or pick from gallery, get AI outfit rating.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  File? _imageFile;
  OutfitRating? _rating;
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _rating = null;
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _rateOutfit() async {
    if (_imageFile == null) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.rateOutfit(_imageFile!);
      setState(() => _rating = result);
    } catch (e) {
      debugPrint('Rating error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating failed. Please try again.'),
            backgroundColor: LibassTheme.danger,
          ),
        );
      }
    }
    setState(() => _loading = false);
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _rating = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Rate My Outfit',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'AI-powered outfit analysis with actionable tips',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: LibassTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          if (_imageFile == null) ...[
            // ─── Upload Zone ─────────────────
            _buildUploadZone(),
          ] else if (_rating == null) ...[
            // ─── Preview + Rate Button ───────
            _buildPreview(),
          ] else ...[
            // ─── Results ─────────────────────
            _buildResults(),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: LibassTheme.bgSurfaceDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: LibassTheme.accentPrimary.withValues(alpha: 0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: LibassTheme.accentPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 32,
                    color: LibassTheme.accentPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap to Take a Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: LibassTheme.accentPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our AI will analyze your full outfit',
                  style: TextStyle(
                    fontSize: 13,
                    color: LibassTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Or choose from gallery'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.file(
                _imageFile!,
                width: double.infinity,
                height: 350,
                fit: BoxFit.cover,
              ),
              // AI scanning overlay
              if (_loading)
                Container(
                  width: double.infinity,
                  height: 350,
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Stack(
                    children: [
                      // Scanner line
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: LibassTheme.accentSecondary.withValues(alpha: 0.8),
                                blurRadius: 15,
                                spreadRadius: 4,
                              )
                            ],
                            gradient: LinearGradient(
                              colors: [
                                LibassTheme.accentSecondary.withValues(alpha: 0),
                                LibassTheme.accentSecondary,
                                LibassTheme.accentSecondary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(
                              begin: 0,
                              end: 350,
                              duration: 2.seconds,
                              curve: Curves.easeInOut,
                            ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: LibassTheme.accentSecondary,
                              strokeWidth: 3,
                            ).animate().scale(duration: 400.ms),
                            const SizedBox(height: 20),
                            const Text(
                              'Analyzing Style...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _rateOutfit,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(_loading ? 'Analyzing...' : 'Rate My Outfit'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                backgroundColor: LibassTheme.bgSurfaceDim,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResults() {
    final r = _rating!;
    final scoreColor = r.score >= 8
        ? LibassTheme.accentPrimary
        : r.score >= 6
            ? LibassTheme.warning
            : LibassTheme.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      '${r.score}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Rating',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: LibassTheme.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.feedback,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Improvements
        if (r.improvements.isNotEmpty) ...[
          Text(
            'Suggestions to Improve',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: 10),
          ...r.improvements.map((imp) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          LibassTheme.accentSecondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: LibassTheme.accentSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    imp.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    imp.detail,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
        ],

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Rate Another Outfit'),
          ),
        ),
      ],
    );
  }
}
