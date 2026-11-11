import 'dart:math' as math;

import 'package:flutter/material.dart';

class IosGlassIconPalette {
  final Color topColor;
  final Color bottomColor;
  final Color shadowColor;
  final Color cutoutColor;

  const IosGlassIconPalette({
    required this.topColor,
    required this.bottomColor,
    required this.shadowColor,
    required this.cutoutColor,
  });
}

IosGlassIconPalette iosGlassPaletteForMenu(String menuId) {
  switch (menuId) {
    case 'overtime':
      return const IosGlassIconPalette(
        topColor: Color(0xFF3B82F6),
        bottomColor: Color(0xFF1E3A8A),
        shadowColor: Color(0xFF1D4ED8),
        cutoutColor: Color(0xFF1E3A8A),
      );
    case 'leave':
      return const IosGlassIconPalette(
        topColor: Color(0xFF10B981),
        bottomColor: Color(0xFF065F46),
        shadowColor: Color(0xFF059669),
        cutoutColor: Color(0xFF065F46),
      );
    case 'payroll':
      return const IosGlassIconPalette(
        topColor: Color(0xFF14B8A6),
        bottomColor: Color(0xFF115E59),
        shadowColor: Color(0xFF0D9488),
        cutoutColor: Color(0xFF115E59),
      );
    case 'attendance_camera':
      return const IosGlassIconPalette(
        topColor: Color(0xFF0284C7),
        bottomColor: Color(0xFF075985),
        shadowColor: Color(0xFF0284C7),
        cutoutColor: Color(0xFF075985),
      );
    case 'on_duty':
      return const IosGlassIconPalette(
        topColor: Color(0xFFEA580C),
        bottomColor: Color(0xFF9A3412),
        shadowColor: Color(0xFFEA580C),
        cutoutColor: Color(0xFF9A3412),
      );
    case 'profile':
      return const IosGlassIconPalette(
        topColor: Color(0xFF475569),
        bottomColor: Color(0xFF0F172A),
        shadowColor: Color(0xFF1E293B),
        cutoutColor: Color(0xFF1E293B),
      );
    case 'attendance_history':
      return const IosGlassIconPalette(
        topColor: Color(0xFF6366F1),
        bottomColor: Color(0xFF312E81),
        shadowColor: Color(0xFF4338CA),
        cutoutColor: Color(0xFF312E81),
      );
    case 'shift_schedule':
      return const IosGlassIconPalette(
        topColor: Color(0xFF06B6D4),
        bottomColor: Color(0xFF155E75),
        shadowColor: Color(0xFF0891B2),
        cutoutColor: Color(0xFF155E75),
      );
    case 'company_policy':
      return const IosGlassIconPalette(
        topColor: Color(0xFF1D4ED8),
        bottomColor: Color(0xFF0F172A),
        shadowColor: Color(0xFF1E3A8A),
        cutoutColor: Color(0xFF0F172A),
      );
    default:
      return const IosGlassIconPalette(
        topColor: Color(0xFF2563EB),
        bottomColor: Color(0xFF1E3A8A),
        shadowColor: Color(0xFF1D4ED8),
        cutoutColor: Color(0xFF1E3A8A),
      );
  }
}

/// True Apple-style continuous superellipse (`|x|^n + |y|^n = 1`, n = 4.2).
class IosSquircleBorder extends OutlinedBorder {
  const IosSquircleBorder({super.side});

  static Path buildSquirclePath(Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final rx = rect.width / 2.0;
    final ry = rect.height / 2.0;
    const double exp = 2.0 / 4.2;
    const int steps = 64;

    final path = Path();
    for (int i = 0; i < steps; i++) {
      final theta = (2.0 * math.pi * i) / steps;
      final cosT = math.cos(theta);
      final sinT = math.sin(theta);
      final x = cx + rx * cosT.sign * math.pow(cosT.abs(), exp).toDouble();
      final y = cy + ry * sinT.sign * math.pow(sinT.abs(), exp).toDouble();
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return buildSquirclePath(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return buildSquirclePath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    final paint = side.toPaint();
    canvas.drawPath(buildSquirclePath(rect.deflate(side.width / 2.0)), paint);
  }

  @override
  ShapeBorder scale(double t) => IosSquircleBorder(side: side.scale(t));

  @override
  IosSquircleBorder copyWith({BorderSide? side}) =>
      IosSquircleBorder(side: side ?? this.side);
}

class IosGlassMenuIcon extends StatelessWidget {
  final String menuId;
  final double size;
  final bool showShadow;

  const IosGlassMenuIcon({
    super.key,
    required this.menuId,
    this.size = 52.0,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = iosGlassPaletteForMenu(menuId);
    final glyphSize = size * 0.56;

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: const IosSquircleBorder(),
        shadows: showShadow
            ? [
                BoxShadow(
                  color: palette.shadowColor.withValues(alpha: 0.24),
                  blurRadius: size * 0.24,
                  offset: Offset(0, size * 0.10),
                ),
                BoxShadow(
                  color: const Color(0x0D0F172A),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _IosLiquidGlassTilePainter(
          menuId: menuId,
          palette: palette,
          glyphSize: glyphSize,
        ),
      ),
    );
  }
}

class _IosLiquidGlassTilePainter extends CustomPainter {
  final String menuId;
  final IosGlassIconPalette palette;
  final double glyphSize;

  const _IosLiquidGlassTilePainter({
    required this.menuId,
    required this.palette,
    required this.glyphSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final squirclePath = IosSquircleBorder.buildSquirclePath(rect);

    // 1. Saturated jewel-tone iOS 2026 liquid substrate
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.topColor, palette.bottomColor],
      ).createShader(rect);
    canvas.drawPath(squirclePath, bgPaint);

    // 2. Optical light refraction inside clipped squircle
    canvas.save();
    canvas.clipPath(squirclePath);

    final topBloomPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.70, -0.85),
        radius: 0.90,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, topBloomPaint);

    // Whisper-soft curved glass edge highlight near top rim
    final innerGlossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34],
      ).createShader(rect);
    canvas.drawRect(rect, innerGlossPaint);

    final bottomBouncePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.65, 0.80),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bottomBouncePaint);

    // 3. Layered vector glyph centered in the squircle
    final glyphOffset = Offset(
      (size.width - glyphSize) / 2.0,
      (size.height - glyphSize) / 2.0,
    );
    canvas.save();
    canvas.translate(glyphOffset.dx, glyphOffset.dy);
    _paintMenuGlyph(canvas, glyphSize);
    canvas.restore();

    canvas.restore();

    // 4. iOS 2026 specular glass bezel rim stroke
    final rimRect = rect.deflate(0.65);
    final rimPath = IosSquircleBorder.buildSquirclePath(rimRect);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.78),
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.36),
        ],
        stops: const [0.0, 0.36, 0.68, 1.0],
      ).createShader(rect);
    canvas.drawPath(rimPath, rimPaint);
  }

  void _paintMenuGlyph(Canvas canvas, double s) {
    final frostedFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final frostedStrongFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.46)
      ..style = PaintingStyle.fill;
    final frostedStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.04)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final solidWhiteFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.98)
      ..style = PaintingStyle.fill;
    final softWhiteFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.74)
      ..style = PaintingStyle.fill;
    final whiteStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.98)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.088
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (menuId) {
      case 'overtime':
        final center = Offset(s * 0.49, s * 0.51);
        final discRadius = s * 0.31;
        canvas.drawCircle(center, discRadius, frostedFill);

        final arcRect = Rect.fromCircle(center: center, radius: s * 0.36);
        const startAngle = math.pi * 0.16;
        const sweepAngle = math.pi * 1.66;
        canvas.drawArc(arcRect, startAngle, sweepAngle, false, whiteStroke);

        // Directional clockwise arrowhead at top-right, balanced across arc curvature
        const endAngle = startAngle + sweepAngle;
        final tip = Offset(
          center.dx + arcRect.width * 0.5 * math.cos(endAngle),
          center.dy + arcRect.height * 0.5 * math.sin(endAngle),
        );
        const tangentAngle = endAngle + math.pi / 2;
        const backAxis = tangentAngle + math.pi - 0.22;
        final arrowLen = s * 0.135;
        final wing1 = Offset(
          tip.dx + arrowLen * math.cos(backAxis - 0.66),
          tip.dy + arrowLen * math.sin(backAxis - 0.66),
        );
        final wing2 = Offset(
          tip.dx + arrowLen * math.cos(backAxis + 0.66),
          tip.dy + arrowLen * math.sin(backAxis + 0.66),
        );
        canvas.drawLine(wing1, tip, whiteStroke);
        canvas.drawLine(wing2, tip, whiteStroke);

        // Crisp clock hands
        canvas.drawLine(
          center,
          Offset(center.dx, center.dy - s * 0.18),
          whiteStroke,
        );
        canvas.drawLine(
          center,
          Offset(center.dx + s * 0.15, center.dy + s * 0.05),
          whiteStroke,
        );
        break;

      case 'leave':
        final bodyRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.13, s * 0.22, s * 0.87, s * 0.88),
          Radius.circular(s * 0.16),
        );
        canvas.drawRRect(bodyRect, frostedFill);
        canvas.drawRRect(bodyRect, frostedStroke);

        final headerRect = RRect.fromRectAndCorners(
          Rect.fromLTRB(s * 0.13, s * 0.22, s * 0.87, s * 0.42),
          topLeft: Radius.circular(s * 0.16),
          topRight: Radius.circular(s * 0.16),
          bottomLeft: Radius.circular(s * 0.04),
          bottomRight: Radius.circular(s * 0.04),
        );
        canvas.drawRRect(headerRect, solidWhiteFill);

        // Binding pins
        for (final xPos in [s * 0.34, s * 0.66]) {
          final pinRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(xPos, s * 0.19),
              width: s * 0.09,
              height: s * 0.16,
            ),
            Radius.circular(s * 0.045),
          );
          canvas.drawRRect(pinRect, solidWhiteFill);
        }

        // Bold approval checkmark centered in lower glass pocket
        final checkPath = Path()
          ..moveTo(s * 0.33, s * 0.64)
          ..lineTo(s * 0.45, s * 0.76)
          ..lineTo(s * 0.68, s * 0.53);
        canvas.drawPath(
          checkPath,
          whiteStroke..strokeWidth = s * 0.095,
        );
        break;

      case 'payroll':
        // Frosted slip with smooth scalloped bottom edge
        final slipPath = Path()
          ..moveTo(s * 0.16, s * 0.24)
          ..quadraticBezierTo(s * 0.16, s * 0.12, s * 0.28, s * 0.12)
          ..lineTo(s * 0.64, s * 0.12)
          ..quadraticBezierTo(s * 0.76, s * 0.12, s * 0.76, s * 0.24)
          ..lineTo(s * 0.76, s * 0.84)
          ..quadraticBezierTo(s * 0.66, s * 0.75, s * 0.56, s * 0.84)
          ..quadraticBezierTo(s * 0.46, s * 0.93, s * 0.36, s * 0.84)
          ..quadraticBezierTo(s * 0.26, s * 0.75, s * 0.16, s * 0.84)
          ..close();
        canvas.drawPath(slipPath, frostedFill);
        canvas.drawPath(slipPath, frostedStroke);

        // Two crisp payslip line bars
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.27, s * 0.28, s * 0.36, s * 0.085),
            Radius.circular(s * 0.042),
          ),
          solidWhiteFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.27, s * 0.44, s * 0.24, s * 0.08),
            Radius.circular(s * 0.04),
          ),
          softWhiteFill,
        );

        // Floating coin seal badge in lower-right foreground
        final coinCenter = Offset(s * 0.68, s * 0.67);
        final coinRadius = s * 0.21;
        canvas.drawCircle(coinCenter, coinRadius, solidWhiteFill);
        final coinRingPaint = Paint()
          ..color = palette.cutoutColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.055;
        canvas.drawCircle(coinCenter, s * 0.115, coinRingPaint);
        canvas.drawCircle(
          coinCenter,
          s * 0.045,
          Paint()..color = palette.cutoutColor,
        );
        break;

      case 'attendance_camera':
        // Sleek iOS camera silhouette with rounded viewfinder bump
        final camPath = Path()
          ..moveTo(s * 0.24, s * 0.25)
          ..lineTo(s * 0.31, s * 0.25)
          ..quadraticBezierTo(s * 0.35, s * 0.15, s * 0.41, s * 0.15)
          ..lineTo(s * 0.59, s * 0.15)
          ..quadraticBezierTo(s * 0.65, s * 0.15, s * 0.69, s * 0.25)
          ..lineTo(s * 0.76, s * 0.25)
          ..quadraticBezierTo(s * 0.90, s * 0.25, s * 0.90, s * 0.39)
          ..lineTo(s * 0.90, s * 0.71)
          ..quadraticBezierTo(s * 0.90, s * 0.85, s * 0.76, s * 0.85)
          ..lineTo(s * 0.24, s * 0.85)
          ..quadraticBezierTo(s * 0.10, s * 0.85, s * 0.10, s * 0.71)
          ..lineTo(s * 0.10, s * 0.39)
          ..quadraticBezierTo(s * 0.10, s * 0.25, s * 0.24, s * 0.25)
          ..close();
        canvas.drawPath(camPath, frostedStrongFill);
        canvas.drawPath(camPath, frostedStroke);

        final lensCenter = Offset(s * 0.50, s * 0.56);
        canvas.drawCircle(
          lensCenter,
          s * 0.185,
          whiteStroke..strokeWidth = s * 0.082,
        );
        canvas.drawCircle(lensCenter, s * 0.075, solidWhiteFill);
        canvas.drawCircle(Offset(s * 0.74, s * 0.39), s * 0.042, solidWhiteFill);
        break;

      case 'on_duty':
        // Executive handle
        final handleRect = Rect.fromLTRB(s * 0.36, s * 0.14, s * 0.64, s * 0.34);
        final handlePath = Path()
          ..moveTo(handleRect.left, s * 0.28)
          ..lineTo(handleRect.left, s * 0.21)
          ..quadraticBezierTo(handleRect.left, s * 0.14, s * 0.43, s * 0.14)
          ..lineTo(s * 0.57, s * 0.14)
          ..quadraticBezierTo(handleRect.right, s * 0.14, handleRect.right, s * 0.21)
          ..lineTo(handleRect.right, s * 0.28);
        canvas.drawPath(
          handlePath,
          whiteStroke..strokeWidth = s * 0.082,
        );

        // Frosted briefcase body
        final caseRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.12, s * 0.27, s * 0.88, s * 0.85),
          Radius.circular(s * 0.16),
        );
        canvas.drawRRect(caseRect, frostedFill);
        canvas.drawRRect(caseRect, frostedStroke);

        // Opaque top flap with subtle gentle curve
        final flapPath = Path()
          ..moveTo(s * 0.28, s * 0.27)
          ..lineTo(s * 0.72, s * 0.27)
          ..quadraticBezierTo(s * 0.88, s * 0.27, s * 0.88, s * 0.43)
          ..lineTo(s * 0.88, s * 0.49)
          ..quadraticBezierTo(s * 0.50, s * 0.60, s * 0.12, s * 0.49)
          ..lineTo(s * 0.12, s * 0.43)
          ..quadraticBezierTo(s * 0.12, s * 0.27, s * 0.28, s * 0.27)
          ..close();
        canvas.drawPath(flapPath, solidWhiteFill);

        // Crisp center lock clasp
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(s * 0.50, s * 0.55),
              width: s * 0.14,
              height: s * 0.12,
            ),
            Radius.circular(s * 0.045),
          ),
          solidWhiteFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(s * 0.50, s * 0.55),
              width: s * 0.06,
              height: s * 0.055,
            ),
            Radius.circular(s * 0.025),
          ),
          Paint()..color = palette.cutoutColor,
        );
        break;

      case 'profile':
        final cardRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.10, s * 0.19, s * 0.90, s * 0.81),
          Radius.circular(s * 0.15),
        );
        canvas.drawRRect(cardRect, frostedFill);
        canvas.drawRRect(cardRect, frostedStroke);

        // Left user head & rounded shoulders bust
        canvas.drawCircle(Offset(s * 0.33, s * 0.41), s * 0.095, solidWhiteFill);
        final bustPath = Path()
          ..moveTo(s * 0.20, s * 0.67)
          ..quadraticBezierTo(s * 0.20, s * 0.54, s * 0.33, s * 0.54)
          ..quadraticBezierTo(s * 0.46, s * 0.54, s * 0.46, s * 0.67)
          ..quadraticBezierTo(s * 0.46, s * 0.70, s * 0.42, s * 0.70)
          ..lineTo(s * 0.24, s * 0.70)
          ..quadraticBezierTo(s * 0.20, s * 0.70, s * 0.20, s * 0.67)
          ..close();
        canvas.drawPath(bustPath, solidWhiteFill);

        // Right metadata lines
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.54, s * 0.36, s * 0.25, s * 0.08),
            Radius.circular(s * 0.04),
          ),
          solidWhiteFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.54, s * 0.49, s * 0.20, s * 0.068),
            Radius.circular(s * 0.034),
          ),
          softWhiteFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.54, s * 0.61, s * 0.15, s * 0.068),
            Radius.circular(s * 0.034),
          ),
          softWhiteFill,
        );
        break;

      case 'attendance_history':
        final center = Offset(s * 0.51, s * 0.51);
        canvas.drawCircle(center, s * 0.31, frostedFill);

        final arcRect = Rect.fromCircle(center: center, radius: s * 0.36);
        const startAngle = -math.pi * 0.82;
        const sweepAngle = math.pi * 1.66;
        canvas.drawArc(arcRect, startAngle, sweepAngle, false, whiteStroke);

        // Counter-clockwise rewind arrowhead at top-left, balanced across arc curvature
        final tip = Offset(
          center.dx + arcRect.width * 0.5 * math.cos(startAngle),
          center.dy + arcRect.height * 0.5 * math.sin(startAngle),
        );
        const tangentAngle = startAngle - math.pi / 2;
        const backAxis = tangentAngle + math.pi + 0.22;
        final arrowLen = s * 0.135;
        final wing1 = Offset(
          tip.dx + arrowLen * math.cos(backAxis - 0.66),
          tip.dy + arrowLen * math.sin(backAxis - 0.66),
        );
        final wing2 = Offset(
          tip.dx + arrowLen * math.cos(backAxis + 0.66),
          tip.dy + arrowLen * math.sin(backAxis + 0.66),
        );
        canvas.drawLine(wing1, tip, whiteStroke);
        canvas.drawLine(wing2, tip, whiteStroke);

        canvas.drawLine(
          center,
          Offset(center.dx, center.dy - s * 0.18),
          whiteStroke,
        );
        canvas.drawLine(
          center,
          Offset(center.dx + s * 0.14, center.dy + s * 0.06),
          whiteStroke,
        );
        break;

      case 'shift_schedule':
        final bodyRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(s * 0.13, s * 0.22, s * 0.87, s * 0.88),
          Radius.circular(s * 0.16),
        );
        canvas.drawRRect(bodyRect, frostedFill);
        canvas.drawRRect(bodyRect, frostedStroke);

        final headerRect = RRect.fromRectAndCorners(
          Rect.fromLTRB(s * 0.13, s * 0.22, s * 0.87, s * 0.41),
          topLeft: Radius.circular(s * 0.16),
          topRight: Radius.circular(s * 0.16),
          bottomLeft: Radius.circular(s * 0.04),
          bottomRight: Radius.circular(s * 0.04),
        );
        canvas.drawRRect(headerRect, solidWhiteFill);

        for (final xPos in [s * 0.34, s * 0.66]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(xPos, s * 0.19),
                width: s * 0.09,
                height: s * 0.16,
              ),
              Radius.circular(s * 0.045),
            ),
            solidWhiteFill,
          );
        }

        // Shift slot dot matrix
        final xs = [s * 0.31, s * 0.50, s * 0.69];
        final ys = [s * 0.55, s * 0.72];
        for (int r = 0; r < ys.length; r++) {
          for (int c = 0; c < xs.length; c++) {
            final isHighlighted = r == 0 && c == 1;
            canvas.drawCircle(
              Offset(xs[c], ys[r]),
              isHighlighted ? s * 0.065 : s * 0.05,
              isHighlighted ? solidWhiteFill : softWhiteFill,
            );
          }
        }
        break;

      case 'company_policy':
        // Left solid page + right frosted page forming an open book
        final leftPage = Path()
          ..moveTo(s * 0.50, s * 0.26)
          ..quadraticBezierTo(s * 0.34, s * 0.18, s * 0.13, s * 0.23)
          ..lineTo(s * 0.13, s * 0.78)
          ..quadraticBezierTo(s * 0.34, s * 0.73, s * 0.50, s * 0.81)
          ..close();
        canvas.drawPath(leftPage, solidWhiteFill);

        final rightPage = Path()
          ..moveTo(s * 0.50, s * 0.26)
          ..quadraticBezierTo(s * 0.66, s * 0.18, s * 0.87, s * 0.23)
          ..lineTo(s * 0.87, s * 0.78)
          ..quadraticBezierTo(s * 0.66, s * 0.73, s * 0.50, s * 0.81)
          ..close();
        canvas.drawPath(rightPage, frostedStrongFill);
        canvas.drawPath(rightPage, frostedStroke);

        // Two crisp lines on right page
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.58, s * 0.38, s * 0.20, s * 0.07),
            Radius.circular(s * 0.035),
          ),
          solidWhiteFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.58, s * 0.53, s * 0.16, s * 0.07),
            Radius.circular(s * 0.035),
          ),
          solidWhiteFill,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _IosLiquidGlassTilePainter oldDelegate) {
    return oldDelegate.menuId != menuId ||
        oldDelegate.palette != palette ||
        oldDelegate.glyphSize != glyphSize;
  }
}
