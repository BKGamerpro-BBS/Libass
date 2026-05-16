import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

/// Outfits Screen — AI-powered outfit suggestions with weather filtering.
class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  List<OutfitSuggestion> _suggestions = [];
  bool _loading = true;
  bool _error = false;
  String _selectedWeather = 'summer';
  String _selectedOccasion = 'casual';

  static const _occasions = [
    'casual',
    'formal',
    'date_night',
    'work',
    'party',
    'athletic',
  ];

  static const _weatherOptions = ['summer', 'winter', 'spring', 'rainy'];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final suggs = await ApiService.getSuggestions(
        weather: _selectedWeather,
        occasion: _selectedOccasion,
      );
      _suggestions = suggs;
    } catch (e) {
      debugPrint('Suggestions error: $e');
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendFeedback(OutfitSuggestion s, int liked) async {
    final ids = s.items.map((i) => i.id).toList();
    try {
      await ApiService.saveFeedback(ids, liked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(liked == 1 ? '❤️ Loved it!' : '👎 Noted!'),
          backgroundColor:
              liked == 1 ? LibassTheme.accentPrimary : LibassTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadSuggestions();
    } catch (e) {
      debugPrint('Feedback error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Filters ─────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Outfit Suggestions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: _loadSuggestions,
                    icon: const Icon(Icons.autorenew_rounded,
                        color: LibassTheme.accentPrimary),
                    tooltip: 'Regenerate',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Weather chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weatherOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final w = _weatherOptions[i];
                    final selected = w == _selectedWeather;
                    final emojis = {
                      'summer': '☀️',
                      'winter': '❄️',
                      'spring': '🌸',
                      'rainy': '🌧️',
                    };
                    return ChoiceChip(
                      label: Text(
                        '${emojis[w]} ${w[0].toUpperCase()}${w.substring(1)}',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : LibassTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      selected: selected,
                      selectedColor: LibassTheme.accentPrimary,
                      backgroundColor: LibassTheme.bgSurfaceDim,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) {
                        _selectedWeather = w;
                        _loadSuggestions();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Occasion dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: LibassTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOccasion,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more_rounded),
                    style: const TextStyle(
                      color: LibassTheme.textPrimary,
                      fontSize: 14,
                    ),
                    items: _occasions.map((o) {
                      return DropdownMenuItem(
                        value: o,
                        child: Text(
                          o.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      _selectedOccasion = v!;
                      _loadSuggestions();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Suggestions List ────────────────
        Expanded(
          child: _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: LibassTheme.accentPrimary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Searching for perfect combinations...',
                        style: TextStyle(
                          color: LibassTheme.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              : _error
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off_rounded,
                                size: 48,
                                color: LibassTheme.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Could not connect to server.\nCheck your connection and try again.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: LibassTheme.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadSuggestions,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _suggestions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🧐', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'No outfits found for this combination.\nTry uploading more items!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: LibassTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: LibassTheme.accentPrimary,
                      onRefresh: _loadSuggestions,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) =>
                            _SuggestionCard(
                              suggestion: _suggestions[i],
                              onLike: () =>
                                  _sendFeedback(_suggestions[i], 1),
                              onDislike: () =>
                                  _sendFeedback(_suggestions[i], 0),
                            ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final OutfitSuggestion suggestion;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _SuggestionCard({
    required this.suggestion,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score + occasion row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _scoreColor(suggestion.score).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⭐ ${suggestion.score}/10',
                    style: TextStyle(
                      color: _scoreColor(suggestion.score),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    suggestion.isLiked = !suggestion.isLiked;
                    onLike();
                  },
                  icon: Icon(
                      suggestion.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 22),
                  color: LibassTheme.accentSecondary,
                  tooltip: 'Love it',
                ),
                IconButton(
                  onPressed: onDislike,
                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 20),
                  color: LibassTheme.textSecondary,
                  tooltip: 'Not my style',
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing your style...')),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 20),
                  color: LibassTheme.accentPrimary,
                  tooltip: 'Share Outfit',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Item images
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestion.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final item = suggestion.items[i];
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 90,
                          height: 90,
                          color: LibassTheme.bgSurfaceDim,
                          child: Image.network(
                            ApiService.imageUrl(item.imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 90,
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              suggestion.reasoning,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 8) return LibassTheme.accentPrimary;
    if (score >= 6) return LibassTheme.warning;
    return LibassTheme.danger;
  }
}
