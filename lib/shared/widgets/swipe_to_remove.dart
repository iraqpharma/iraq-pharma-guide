import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-style swipe row: a short drag parks the card open and reveals a Delete
/// button; keep dragging past the threshold and it deletes straight away.
/// Written by hand rather than pulling in a package — it is one gesture and
/// one animation, and the app is about to ship.
class SwipeToRemove extends StatefulWidget {
  final Widget child;
  final VoidCallback onRemove;
  final String label;

  const SwipeToRemove({
    super.key,
    required this.child,
    required this.onRemove,
    required this.label,
  });

  @override
  State<SwipeToRemove> createState() => _SwipeToRemoveState();
}

class _SwipeToRemoveState extends State<SwipeToRemove>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 92;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// How far the card is pulled aside, in pixels.
  double _offset = 0;
  bool _removing = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final from = _offset;
    _anim.reset();
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    void listener() {
      setState(() => _offset = from + (target - from) * curve.value);
    }

    curve.addListener(listener);
    _anim.forward().whenComplete(() => curve.removeListener(listener));
  }

  Future<void> _remove() async {
    if (_removing) return;
    setState(() => _removing = true);
    HapticFeedback.mediumImpact();
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fullThreshold = MediaQuery.of(context).size.width * 0.45;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      child: _removing
          ? const SizedBox.shrink()
          : GestureDetector(
              onHorizontalDragUpdate: (d) {
                // Drag direction that "opens" the row depends on text
                // direction: towards the start edge in both cases.
                final delta = rtl ? d.delta.dx : -d.delta.dx;
                setState(() =>
                    _offset = (_offset + delta).clamp(0.0, fullThreshold + 60));
              },
              onHorizontalDragEnd: (_) {
                if (_offset >= fullThreshold) {
                  _remove();
                } else if (_offset > _actionWidth * 0.5) {
                  _animateTo(_actionWidth);
                } else {
                  _animateTo(0);
                }
              },
              child: Stack(
                children: [
                  // Delete affordance sitting under the card.
                  Positioned.fill(
                    child: Align(
                      alignment: rtl
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: _offset.clamp(0.0, double.infinity),
                          color: const Color(0xFFD32F2F),
                          alignment: Alignment.center,
                          child: _offset < 40
                              ? null
                              : FittedBox(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.delete_outline_rounded,
                                            color: Colors.white, size: 22),
                                        const SizedBox(height: 3),
                                        Text(
                                          widget.label,
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Tapping the revealed button deletes; tapping elsewhere
                  // while open just closes the row.
                  if (_offset > 0)
                    Positioned.fill(
                      child: Align(
                        alignment: rtl
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _remove,
                          child: SizedBox(width: _offset, height: double.infinity),
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(rtl ? _offset : -_offset, 0),
                    child: GestureDetector(
                      onTap: _offset > 0 ? () => _animateTo(0) : null,
                      child: AbsorbPointer(
                        absorbing: _offset > 0,
                        child: widget.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
