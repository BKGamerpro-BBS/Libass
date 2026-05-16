import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

/// Wardrobe Screen — Grid of clothing items with upload, edit, and delete.
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<WardrobeItem> _items = [];
  bool _loading = true;
  final _picker = ImagePicker();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedSeason = 'all';
  bool _sortByAlpha = false;

  @override
  void initState() {
    super.initState();
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    setState(() => _loading = true);
    try {
      _items = await ApiService.getWardrobe();
    } catch (e) {
      debugPrint('Wardrobe error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _uploadItem() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      _processUpload(File(picked.path));
    } catch (e) {
      debugPrint('Upload error: $e');
    }
  }

  Future<void> _uploadMultipleItems() async {
    try {
      final pickedList = await _picker.pickMultiImage(
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (pickedList.isEmpty) return;

      int count = 0;
      for (var picked in pickedList) {
        count++;
        await _processUpload(
          File(picked.path),
          isBatch: true,
          batchStatus: '($count/${pickedList.length})',
        );
      }
      _loadWardrobe();
    } catch (e) {
      debugPrint('Batch upload error: $e');
    }
  }

  Future<void> _processUpload(File file,
      {bool isBatch = false, String batchStatus = ''}) async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: LibassTheme.accentPrimary),
              const SizedBox(height: 20),
              Text(isBatch
                  ? 'Uploading items $batchStatus'
                  : 'Analyzing clothing item...'),
            ],
          ),
        ),
      );
    }

    try {
      final item = await ApiService.addWardrobeItem(file);
      if (mounted) {
        Navigator.pop(context); // close loading
        if (!isBatch) {
          _showEditDialog(item);
        }
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload failed. Connection error?'),
            backgroundColor: LibassTheme.danger,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _processUpload(file, isBatch: isBatch, batchStatus: batchStatus),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(WardrobeItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: LibassTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteWardrobeItem(item.id);
        _loadWardrobe();
      } catch (e) {
        debugPrint('Delete error: $e');
      }
    }
  }

  void _showEditDialog(WardrobeItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    String category = item.category;
    String fit = item.fit;
    String season = item.season;
    String specificType = item.specificType;
    String color = item.color;
    String pattern = item.pattern;
    String occasion = item.occasion;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: LibassTheme.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LibassTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '✏️ Edit Item Details',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'AI detected these — correct anything that looks wrong',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),

                // Preview image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: LibassTheme.bgSurfaceDim,
                    child: Image.network(
                      ApiService.imageUrl(item.imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),

                // Category
                _dropdownField(
                  'Category',
                  category,
                  ['top', 'bottom', 'dress', 'shoes', 'accessories', 'outerwear'],
                  (v) => setSheetState(() => category = v!),
                ),
                const SizedBox(height: 12),

                // Season
                _dropdownField(
                  'Season',
                  season,
                  ['summer', 'winter', 'spring', 'rainy', 'all'],
                  (v) => setSheetState(() => season = v!),
                ),
                const SizedBox(height: 12),

                // Fit
                _dropdownField(
                  'Fit',
                  fit,
                  ['slim', 'regular', 'loose', 'flowy', 'baggy'],
                  (v) => setSheetState(() => fit = v!),
                ),
                const SizedBox(height: 12),

                // Occasion
                _dropdownField(
                  'Occasion',
                  occasion,
                  ['casual', 'formal', 'work', 'party', 'gym', 'date'],
                  (v) => setSheetState(() => occasion = v!),
                ),
                const SizedBox(height: 12),

                // Color
                TextField(
                  controller: TextEditingController(text: color),
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                  onChanged: (v) => color = v,
                ),
                const SizedBox(height: 12),

                // Pattern
                _dropdownField(
                  'Pattern',
                  pattern,
                  ['solid', 'striped', 'checkered', 'floral', 'polka dot', 'graphic', 'denim'],
                  (v) => setSheetState(() => pattern = v!),
                ),
                const SizedBox(height: 12),

                // Specific Type
                TextField(
                  controller:
                      TextEditingController(text: specificType),
                  decoration: const InputDecoration(
                    labelText: 'Specific Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  onChanged: (v) => specificType = v,
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ApiService.updateWardrobeItem(item.id, {
                          'name': nameCtrl.text,
                          'category': category,
                          'season': season,
                          'fit': fit,
                          'specific_type': specificType,
                          'color': color,
                          'pattern': pattern,
                          'occasion': occasion,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadWardrobe();
                      } catch (e) {
                        debugPrint('Update error: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LibassTheme.accentPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('✅ Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          items: options
              .map(
                (o) {
                  String prefix = '';
                  if (label == 'Season') prefix = '${_seasonEmoji(o)} ';
                  if (label == 'Category') {
                    if (o == 'top') prefix = '👕 ';
                    if (o == 'bottom') prefix = '👖 ';
                    if (o == 'dress') prefix = '👗 ';
                    if (o == 'shoes') prefix = '👟 ';
                    if (o == 'accessories') prefix = '💍 ';
                    if (o == 'outerwear') prefix = '🧥 ';
                  }
                  
                  return DropdownMenuItem(
                    value: o,
                    child: Text(
                      prefix + o[0].toUpperCase() + o.substring(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                },
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _seasonEmoji(String season) {
    const map = {
      'summer': '☀️',
      'winter': '❄️',
      'spring': '🌸',
      'rainy': '🌧️',
      'all': '🔄',
    };
    return map[season.toLowerCase()] ?? '🔄';
  }

  List<WardrobeItem> get _filteredItems {
    final list = _items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.specificType.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      final matchesSeason =
          _selectedSeason == 'all' || item.season == _selectedSeason;
      return matchesSearch && matchesCategory && matchesSeason;
    }).toList();
    
    if (_sortByAlpha) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header + Upload
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Wardrobe',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${_items.length} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _uploadItem,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LibassTheme.accentPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _uploadMultipleItems,
                icon: const Icon(Icons.auto_awesome_motion_rounded,
                    size: 18, color: LibassTheme.accentSecondary),
                label: const Text('Batch', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      LibassTheme.accentSecondary.withValues(alpha: 0.05),
                  side: BorderSide(
                      color: LibassTheme.accentSecondary.withValues(alpha: 0.3)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: LibassTheme.bgSurfaceDim,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _sortByAlpha
                              ? Icons.sort_by_alpha_rounded
                              : Icons.access_time_rounded,
                          size: 18,
                          color: _sortByAlpha
                              ? LibassTheme.accentPrimary
                              : LibassTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _sortByAlpha = !_sortByAlpha),
                        tooltip: _sortByAlpha ? 'Sort by Name' : 'Sort by Recent',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['all', 'top', 'bottom', 'dress', 'shoes', 'accessories', 'outerwear'].map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          '${cat[0].toUpperCase()}${cat.substring(1)} (${cat == 'all' ? _items.length : _items.where((i) => i.category == cat).length})',
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : LibassTheme.textPrimary,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        onSelected: (s) => setState(() => _selectedCategory = cat),
                        selectedColor: LibassTheme.accentPrimary,
                        backgroundColor: LibassTheme.bgSurfaceDim,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['all', 'summer', 'winter', 'spring', 'rainy'].map((season) {
                    final selected = _selectedSeason == season;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          season[0].toUpperCase() + season.substring(1),
                          style: TextStyle(
                            color: selected ? Colors.white : LibassTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        selected: selected,
                        onSelected: (s) => setState(() => _selectedSeason = season),
                        selectedColor: LibassTheme.accentSecondary,
                        backgroundColor: LibassTheme.bgSurfaceDim.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: LibassTheme.accentPrimary),
                )
              : _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _searchQuery.isEmpty ? '👕' : '🔍',
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Your wardrobe is empty!\nTap "Add Item" to upload clothing photos.'
                                  : 'No items found matching "$_searchQuery"',
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
                      onRefresh: _loadWardrobe,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (_, i) => _WardrobeCard(
                          item: _filteredItems[i],
                          seasonEmoji: _seasonEmoji(_filteredItems[i].season),
                          onTap: () => _showEditDialog(_filteredItems[i]),
                          onDelete: () => _deleteItem(_filteredItems[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _WardrobeCard extends StatelessWidget {
  final WardrobeItem item;
  final String seasonEmoji;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WardrobeCard({
    required this.item,
    required this.seasonEmoji,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: LibassTheme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: LibassTheme.bgSurfaceDim,
                        child: Image.network(
                          ApiService.imageUrl(item.imagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 36,
                              color: LibassTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            seasonEmoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                  child: Text(
                    '${item.category} • ${item.specificType} • ${item.fit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: LibassTheme.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LibassTheme.accentPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$seasonEmoji ${item.season[0].toUpperCase()}${item.season.substring(1)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: LibassTheme.accentPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Delete button
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: LibassTheme.danger.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
