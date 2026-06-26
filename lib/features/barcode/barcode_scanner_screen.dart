import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late final AnimationController _scanAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _scanPos = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _scanAnim, curve: Curves.easeInOut));

  bool _detected = false;

  @override
  void dispose() {
    _scanAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final code = capture.barcodes
        .where((b) => b.rawValue != null && b.rawValue!.isNotEmpty)
        .map((b) => b.rawValue!)
        .firstOrNull;
    if (code == null) return;
    _detected = true;
    _ctrl.stop();
    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.68;
    // Vertical center offset — shift slightly upward for better UX
    const verticalOffset = -50.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Camera feed ───────────────────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // ── 2. Dark overlay with transparent scan window ─────────────────
          _ScanOverlay(boxSize: boxSize, verticalOffset: verticalOffset),

          // ── 3. Corner brackets ───────────────────────────────────────────
          Center(
            child: Transform.translate(
              offset: Offset(0, verticalOffset),
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: CustomPaint(painter: _CornerPainter()),
              ),
            ),
          ),

          // ── 4. Animated scan line ────────────────────────────────────────
          AnimatedBuilder(
            animation: _scanPos,
            builder: (_, __) {
              final boxTop =
                  (size.height / 2) + verticalOffset - (boxSize / 2);
              final y = boxTop + _scanPos.value * (boxSize - 4);
              final margin = (size.width - boxSize) / 2 + 16;
              return Positioned(
                top: y,
                left: margin,
                right: margin,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withOpacity(0.9),
                        AppColors.accent.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── 5. Top bar ───────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(ctrl: _ctrl),
          ),

          // ── 6. Bottom hint ───────────────────────────────────────────────
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'وجّه الكاميرا نحو باركود البكج',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Dark overlay with a transparent rectangular cutout
// ═════════════════════════════════════════════════════════════════════════════

class _ScanOverlay extends StatelessWidget {
  final double boxSize;
  final double verticalOffset;
  const _ScanOverlay({required this.boxSize, required this.verticalOffset});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(boxSize: boxSize, verticalOffset: verticalOffset),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double boxSize;
  final double verticalOffset;
  const _OverlayPainter(
      {required this.boxSize, required this.verticalOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + verticalOffset);
    final rect = Rect.fromCenter(
        center: center, width: boxSize, height: boxSize);
    final rrect =
        RRect.fromRectAndRadius(rect, const Radius.circular(20));

    final paint = Paint()..color = Colors.black.withOpacity(0.58);

    // Draw overlay in four rectangles around the cutout
    // Top
    canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, rect.top), paint);
    // Bottom
    canvas.drawRect(
        Rect.fromLTRB(0, rect.bottom, size.width, size.height), paint);
    // Left
    canvas.drawRect(
        Rect.fromLTRB(0, rect.top, rect.left, rect.bottom), paint);
    // Right
    canvas.drawRect(
        Rect.fromLTRB(rect.right, rect.top, size.width, rect.bottom),
        paint);

    // Slightly lighter tint inside to guide the eye (optional subtle effect)
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withOpacity(0.03),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// Corner brackets painter
// ═════════════════════════════════════════════════════════════════════════════

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const r = 20.0;
    const len = 30.0;
    const pi = 3.14159265;

    // Top-left
    _drawCorner(canvas, paint,
        arcRect: Rect.fromLTWH(0, 0, r * 2, r * 2),
        arcStart: pi,
        arcSweep: -pi / 2,
        h1: Offset(r, 0),
        h2: Offset(r + len, 0),
        v1: Offset(0, r),
        v2: Offset(0, r + len));

    // Top-right
    _drawCorner(canvas, paint,
        arcRect: Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        arcStart: 0,
        arcSweep: -pi / 2,
        h1: Offset(size.width - r - len, 0),
        h2: Offset(size.width - r, 0),
        v1: Offset(size.width, r),
        v2: Offset(size.width, r + len));

    // Bottom-left
    _drawCorner(canvas, paint,
        arcRect: Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        arcStart: pi / 2,
        arcSweep: pi / 2,
        h1: Offset(r, size.height),
        h2: Offset(r + len, size.height),
        v1: Offset(0, size.height - r - len),
        v2: Offset(0, size.height - r));

    // Bottom-right
    _drawCorner(canvas, paint,
        arcRect: Rect.fromLTWH(
            size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        arcStart: 0,
        arcSweep: pi / 2,
        h1: Offset(size.width - r - len, size.height),
        h2: Offset(size.width - r, size.height),
        v1: Offset(size.width, size.height - r - len),
        v2: Offset(size.width, size.height - r));
  }

  void _drawCorner(
    Canvas canvas,
    Paint paint, {
    required Rect arcRect,
    required double arcStart,
    required double arcSweep,
    required Offset h1,
    required Offset h2,
    required Offset v1,
    required Offset v2,
  }) {
    canvas.drawArc(arcRect, arcStart, arcSweep, false, paint);
    canvas.drawLine(h1, h2, paint);
    canvas.drawLine(v1, v2, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// Top app bar (back + title + torch toggle)
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final MobileScannerController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, MediaQuery.of(context).padding.top + 4, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.78),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Title (centered)
          const Spacer(),
          Text(
            'مسح الباركود',
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          // Torch toggle
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: ctrl,
            builder: (_, state, __) {
              final isOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: isOn ? 'إطفاء الفلاش' : 'تشغيل الفلاش',
                icon: Icon(
                  isOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: isOn ? Colors.amber : Colors.white,
                  size: 24,
                ),
                onPressed: ctrl.toggleTorch,
              );
            },
          ),
        ],
      ),
    );
  }
}
