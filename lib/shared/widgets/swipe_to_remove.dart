import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// iOS-style swipe row. A short drag parks the row open and reveals a Delete
/// button; dragging past the threshold triggers the same delete action. Both
/// paths go through [onRemove], which is expected to ask for confirmation.
///
/// The action button is the LAST child of the Stack on purpose: when it sat
/// underneath the card, the card's own gesture detector swallowed the tap and
/// the button did nothing.
class SwipeToRemove extends StatefulWidget {
  final Widget child;

  /// Should perform its own confirmation. Returns true when the row was
  /// actually removed, so the widget knows whether to collapse or spring back.
  final Future<bool> Function() onRemove;
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
  static const double _actionWidth = 96;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  double _offset = 0;
  bool _busy = false;

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
      if (!mounted) return;
      setState(() => _offset = from + (target - from) * curve.value);
    }

    curve.addListener(listener);
    _anim.forward().whenComplete(() => curve.removeListener(listener));
  }

  Future<void> _requestRemove() async {
    if (_busy) return;
    _busy = true;
    HapticFeedback.mediumImpact();
    final removed = await widget.onRemove();
    if (!mounted) return;
    _busy = false;
    // Cancelled at the confirmation dialog → slide the row back.
    if (!removed) _animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fullThreshold = MediaQuery.of(context).size.width * 0.42;
    final alignment = rtl ? Alignment.centerLeft : Alignment.centerRight;

    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        final delta = rtl ? d.delta.dx : -d.delta.dx;
        setState(() =>
            _offset = (_offset + delta).clamp(0.0, fullThreshold + 40));
      },
      onHorizontalDragEnd: (_) {
        if (_offset >= fullThreshold) {
          _animateTo(_actionWidth);
          _requestRemove();
        } else if (_offset > _actionWidth * 0.45) {
          _animateTo(_actionWidth);
        } else {
          _animateTo(0);
        }
      },
      child: Stack(
        children: [
          // The card, slid aside.
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

          // The delete button, drawn on top so it always receives the tap.
          if (_offset > 4)
            Positioned.fill(
              child: Align(
                alignment: alignment,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _requestRemove,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: _offset,
                      color: const Color(0xFFD32F2F),
                      alignment: Alignment.center,
                      child: _offset < 46
                          ? null
                          : FittedBox(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
            ),
        ],
      ),
    );
  }
}
