import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-flavoured tab bar: a floating translucent capsule with a frosted
/// backdrop, black glyphs, and a soft grey pill that slides behind whichever
/// tab is active. Used only on iOS — Android keeps the original bar.
class IosGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<IosNavItem> items;

  const IosGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final glyph = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad > 0 ? bottomPad : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              // Low enough that the page genuinely reads through the blur.
              // The Scaffold must set extendBody:true or there is nothing
              // behind this to blur and it renders as a solid slab.
              color: (isDark ? Colors.black : Colors.white)
                  .withOpacity(isDark ? 0.34 : 0.40),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.07),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final slot = c.maxWidth / items.length;
                // The row is laid out visually; in RTL the first item sits on
                // the right, so mirror the indicator to match.
                final rtl = Directionality.of(context) == TextDirection.rtl;
                final logical =
                    rtl ? (items.length - 1 - selectedIndex) : selectedIndex;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: logical * slot + 6,
                      top: 6,
                      width: slot - 12,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(isDark ? 0.14 : 0.07),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(items.length, (i) {
                        final item = items[i];
                        final active = i == selectedIndex;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onTap(i);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  scale: active ? 1.06 : 1.0,
                                  child: Icon(
                                    active ? item.activeIcon : item.icon,
                                    size: 23,
                                    color: glyph
                                        .withOpacity(active ? 0.92 : 0.45),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 9.5,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: glyph
                                        .withOpacity(active ? 0.92 : 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class IosNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const IosNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
