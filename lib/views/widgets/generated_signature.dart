import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Auto-generated electronic signature widget.
///
/// Renders the signer's name in a script/calligraphy font alongside the
/// official Aqari certification stamp. The widget exposes [toPngBytes] so the
/// rendered image can be captured and uploaded as the user's signature PNG.
class GeneratedSignatureWidget extends StatefulWidget {
  final String firstName;
  final String lastName;
  final DateTime signedAt;

  GeneratedSignatureWidget({
    super.key,
    required this.firstName,
    required this.lastName,
    DateTime? signedAt,
  }) : signedAt = signedAt ?? DateTime.now();

  @override
  State<GeneratedSignatureWidget> createState() =>
      GeneratedSignatureWidgetState();
}

class GeneratedSignatureWidgetState extends State<GeneratedSignatureWidget> {
  final _repaintKey = GlobalKey();

  static bool _isArabic(String text) =>
      RegExp(r'[؀-ۿ]').hasMatch(text);

  /// Capture the rendered signature as PNG bytes (white background, 3× resolution).
  Future<Uint8List?> toPngBytes() async {
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.firstName} ${widget.lastName}'.trim();
    final isAr = _isArabic(fullName);
    final display = fullName.isEmpty ? '—' : fullName;

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Name side ──────────────────────────────────────────
            Expanded(
              child: Directionality(
                textDirection:
                    isAr ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: isAr
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      display,
                      style: isAr
                          ? GoogleFonts.amiri(
                              fontSize: 34,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            )
                          : GoogleFonts.dancingScript(
                              fontSize: 42,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 1.5,
                      color: AppColors.primary.withValues(alpha: 0.22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Signed electronically via Aqari · عقاري',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Official stamp ─────────────────────────────────────
            SizedBox(
              width: 112,
              height: 112,
              child: CustomPaint(
                painter: _AqariStampPainter(signedAt: widget.signedAt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Aqari Certification Stamp ───────────────────────────────────────────────

class _AqariStampPainter extends CustomPainter {
  final DateTime signedAt;

  const _AqariStampPainter({required this.signedAt});

  static const Color _ink = AppColors.primary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3.0;

    // ── Background fill ────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _ink.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );

    // ── Outer ring ────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── Inner ring ────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── "AQARI" arc text at the top ───────────────────────────────
    _drawTopArc(canvas, center, radius - 14);

    // ── House icon ────────────────────────────────────────────────
    _drawHouseIcon(canvas, Offset(center.dx, center.dy - 8), radius * 0.30);

    // ── Date ──────────────────────────────────────────────────────
    final dateStr =
        '${signedAt.day.toString().padLeft(2, '0')}'
        '.${signedAt.month.toString().padLeft(2, '0')}'
        '.${signedAt.year}';
    _drawCentered(
      canvas,
      dateStr,
      Offset(center.dx, center.dy + 14),
      const TextStyle(
        fontSize: 8,
        color: _ink,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );

    // ── Separator ─────────────────────────────────────────────────
    canvas.drawLine(
      Offset(center.dx - 20, center.dy + 24),
      Offset(center.dx + 20, center.dy + 24),
      Paint()
        ..color = _ink.withValues(alpha: 0.30)
        ..strokeWidth = 0.8,
    );

    // ── "عقاري" at the bottom ─────────────────────────────────────
    _drawCentered(
      canvas,
      'عقاري',
      Offset(center.dx, center.dy + 33),
      const TextStyle(
        fontSize: 9,
        color: _ink,
        fontWeight: FontWeight.bold,
      ),
      rtl: true,
    );
  }

  /// Renders each letter of "AQARI" along the top arc, individually rotated.
  void _drawTopArc(Canvas canvas, Offset center, double radius) {
    const text = 'AQARI';
    const n = text.length; // 5
    const totalSpan = math.pi * 0.70; // ~126° spread
    const step = totalSpan / (n - 1);
    // Centre the arc at the top (angle = -π/2)
    const baseAngle = -math.pi / 2 - totalSpan / 2;

    for (int i = 0; i < n; i++) {
      final angle = baseAngle + i * step;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      canvas.save();
      canvas.translate(x, y);
      // Rotate the glyph so it reads naturally along the curve
      canvas.rotate(angle + math.pi / 2);

      final tp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: const TextStyle(
            fontSize: 10,
            color: _ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
  }

  void _drawCentered(
    Canvas canvas,
    String text,
    Offset pos,
    TextStyle style, {
    bool rtl = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawHouseIcon(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      // Roof triangle
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx - size, center.dy - size * 0.10)
      ..lineTo(center.dx + size, center.dy - size * 0.10)
      ..close()
      // Walls
      ..moveTo(center.dx - size * 0.68, center.dy - size * 0.10)
      ..lineTo(center.dx - size * 0.68, center.dy + size * 0.90)
      ..lineTo(center.dx + size * 0.68, center.dy + size * 0.90)
      ..lineTo(center.dx + size * 0.68, center.dy - size * 0.10)
      // Door
      ..moveTo(center.dx - size * 0.22, center.dy + size * 0.90)
      ..lineTo(center.dx - size * 0.22, center.dy + size * 0.38)
      ..lineTo(center.dx + size * 0.22, center.dy + size * 0.38)
      ..lineTo(center.dx + size * 0.22, center.dy + size * 0.90);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AqariStampPainter old) => old.signedAt != signedAt;
}
