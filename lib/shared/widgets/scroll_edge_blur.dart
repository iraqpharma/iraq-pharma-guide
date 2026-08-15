import 'dart:ui';
import 'package:flutter/material.dart';

/// A short progressive blur pinned under a fixed header — Apple's scroll edge
/// effect. Content sliding beneath the header softens instead of being cut by
/// a hard line, and it fades in with the first few pixels of scroll.
///
/// Built as a stack of thin bands with decreasing blur rather than one blurred
/// layer behind a gradient mask: a ShaderMask puts the BackdropFilter inside a
/// new compositing layer, where it has no parent backdrop to sample — which is
/// why the earlier version rendered nothing at all.
class ScrollEdgeBlur extends StatelessWidget {
  /// Current scroll offset in pixels.
  final double offset;

  /// Distance from the top of the stack (usually the header height).
  final double top;

  /// Total height of the softened strip.
  final double height;

  /// Number of bands. More bands = smoother ramp, slightly more cost.
  final int bands;

  const ScrollEdgeBlur({
    super.key,
    required this.offset,
    required this.top,
    this.height = 34,
    this.bands = 5,
  });

  @override
  Widget build(BuildContext context) {
    // Fully ramped in after 40px of scroll.
    final t = (offset / 40).clamp(0.0, 1.0);
    if (t <= 0.01) return const SizedBox.shrink();

    final bandHeight = height / bands;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: Column(
          children: List.generate(bands, (i) {
            // Strongest at the top band, fading to nothing at the bottom.
            final strength = (bands - i) / bands;
            return ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 9 * strength * t,
                  sigmaY: 9 * strength * t,
                ),
                child: SizedBox(height: bandHeight, width: double.infinity),
              ),
            );
          }),
        ),
      ),
    );
  }
}
