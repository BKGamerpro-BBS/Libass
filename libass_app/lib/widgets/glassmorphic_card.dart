import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// A glassmorphic card with frosted glass effect.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 10,
    this.opacity = 0.08,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.all(
              color: LibassTheme.borderSubtle.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
