import 'dart:ui';
import 'package:flutter/material.dart';

/// A short gradient blur pinned under a fixed header — Apple calls this the
/// scroll edge effect. Content sliding beneath the header softens instead of
/// being cut by a hard line. It fades in with the first few pixels of scroll
/// so a page sitting at the top looks untouched.
///
/// Draw it as the last child of a Stack, above the scroll view and below the
/// header, so the header itself is never blurred.
class ScrollEdgeBlur extends StatelessWidget {
  /// Current scroll offset in pixels.
  final double offset;

  /// Distance from the top of the stack (the header height).
  final double top;

  /// How tall the softened strip is.
  final double height;

  const ScrollEdgeBlur({
    super.key,
    required this.offset,
    required this.top,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    // Fully faded in after 40px of scroll.
    final t = (offset / 40).clamp(0.0, 1.0);
    if (t == 0) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: ClipRect(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.transparent],
              stops: [0.35, 1.0],
            ).createShader(rect),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
