import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/constants/app_colors.dart';

/// A signature drawing pad with smooth Bezier curves, a dashed baseline guide,
/// and an undo-last-stroke capability. Exports as a PNG with a white background
/// so the image is legible when embedded in contracts or PDFs.
class SignaturePad extends StatefulWidget {
  final double height;
  final Color penColor;
  final double penWidth;

  const SignaturePad({
    super.key,
    this.height = 200,
    this.penColor = Colors.black,
    this.penWidth = 2.8,
  });

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  final GlobalKey _repaintKey = GlobalKey();

  bool get isEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  /// Remove the last completed stroke (undo).
  void undoLastStroke() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  /// Export the signature as PNG bytes. Always uses a white background so the
  /// image is readable when printed or embedded in a contract PDF.
  Future<Uint8List?> toPngBytes() async {
    if (isEmpty) return null;
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C2A3A) : Colors.white;

    return Stack(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmpty
                  ? (isDark ? AppColors.borderDark : AppColors.border)
                  : AppColors.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: RepaintBoundary(
              key: _repaintKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  setState(() => _currentStroke = [d.localPosition]);
                },
                onPanUpdate: (d) {
                  setState(() => _currentStroke.add(d.localPosition));
                },
                onPanEnd: (_) {
                  setState(() {
                    if (_currentStroke.isNotEmpty) {
                      _strokes.add(List.from(_currentStroke));
                      _currentStroke = [];
                    }
                  });
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SignaturePainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    color: isDark ? Colors.white : widget.penColor,
                    strokeWidth: widget.penWidth,
                    backgroundColor: bgColor,
                    isEmpty: isEmpty,
                  ),
                ),
              ),
            ),
          ),
        ),

        // "Sign here" hint — lives outside RepaintBoundary so it is NOT exported
        if (isEmpty)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Sign here',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;
  final bool isEmpty;

  const _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.isEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Solid background (ensures white export even in dark mode)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    final baselineY = size.height * 0.72;

    // Dashed baseline guide
    final baselinePaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashW = 8.0;
    const double dashGap = 5.0;
    double x = 20.0;
    while (x < size.width - 20) {
      canvas.drawLine(Offset(x, baselineY), Offset(x + dashW, baselineY), baselinePaint);
      x += dashW + dashGap;
    }

    // "×" mark at the start of the baseline when the pad is empty
    if (isEmpty) {
      final xPaint = Paint()
        ..color = color.withValues(alpha: 0.22)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(20, baselineY - 8), Offset(28, baselineY), xPaint);
      canvas.drawLine(Offset(20, baselineY), Offset(28, baselineY - 8), xPaint);
    }

    // Strokes
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawSmoothed(canvas, stroke, paint);
    }
    if (currentStroke.isNotEmpty) {
      _drawSmoothed(canvas, currentStroke, paint);
    }
  }

  /// Renders a stroke using quadratic Bezier curves through midpoints, which
  /// produces smooth, natural-looking handwriting instead of jagged line segments.
  void _drawSmoothed(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        paint.strokeWidth / 2,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        // Control point is the actual sampled point; destination is the midpoint.
        // This gives C1-continuous curves through all samples.
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) => true;
}
