import 'package:flutter/material.dart';

class HrHubLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;

  const HrHubLogo({
    super.key,
    this.size = 40.0,
    this.showText = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HrHubLogoPainter(),
      ),
    );

    if (!showText) {
      return logoWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(height: 10),
        const Text(
          'HR Hub',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF0F172A),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}

class _HrHubLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 56.0;

    // Left gradient (light orange to orange)
    final paintLeft = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Right gradient (orange to deep burnt orange)
    final paintRight = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Translucent ribbon connector
    final paintRibbon = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xD9FED7AA),
          Color(0x59FFEDD5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 1. Left Dot (cx: 18, cy: 11, r: 4)
    final dotCenter = Offset(18 * scale, 11 * scale);
    canvas.drawCircle(dotCenter, 4 * scale, paintLeft);

    // 2. Left Capsule (x: 14, y: 19, w: 8, h: 23, rx: 4)
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(14 * scale, 19 * scale, 8 * scale, 23 * scale),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(leftRect, paintLeft);

    // 3. Translucent Ribbon Connector
    final ribbonPath = Path()
      ..moveTo(22 * scale, 26 * scale)
      ..cubicTo(26 * scale, 22 * scale, 28 * scale, 18 * scale, 34 * scale, 14 * scale)
      ..cubicTo(33 * scale, 22 * scale, 28 * scale, 30 * scale, 22 * scale, 34 * scale)
      ..close();
    canvas.drawPath(ribbonPath, paintRibbon);

    // 4. Right Taller Capsule (x: 33, y: 9, w: 9, h: 35, rx: 4.5)
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(33 * scale, 9 * scale, 9 * scale, 35 * scale),
      Radius.circular(4.5 * scale),
    );
    canvas.drawRRect(rightRect, paintRight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
