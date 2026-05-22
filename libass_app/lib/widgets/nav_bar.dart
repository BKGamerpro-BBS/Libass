import 'package:flutter/material.dart';
import '../theme.dart';

/// LIBASS animated bottom navigation bar.
/// Active tab pops up into a green circle, inactive tabs sit in the bar.
class LibassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LibassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.checkroom_rounded, label: 'Outfits'),
    _NavItem(icon: Icons.camera_alt_rounded, label: 'Camera'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Wardrobe'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: LibassTheme.bgSurface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final isActive = i == currentIndex;
          return _NavButton(
            item: _items[i],
            isActive: isActive,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 64,
        transform: Matrix4.translationValues(
          0,
          isActive ? -16 : 0,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? 52 : 40,
              height: isActive ? 52 : 40,
              decoration: BoxDecoration(
                color:
                    isActive ? LibassTheme.accentPrimary : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:
                              LibassTheme.accentPrimary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [],
              ),
              child: Icon(
                item.icon,
                size: isActive ? 28 : 22,
                color: isActive
                    ? Colors.white
                    : LibassTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? LibassTheme.accentPrimary
                    : LibassTheme.textSecondary,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
