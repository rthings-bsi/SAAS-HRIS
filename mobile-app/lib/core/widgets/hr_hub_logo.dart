import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HrHubLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final bool isSquircleCard;

  const HrHubLogo({
    super.key,
    this.size = 40.0,
    this.showText = false,
    this.subtitle,
    this.isSquircleCard = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget mark;

    if (isSquircleCard) {
      mark = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.corporateNavy,
          borderRadius: BorderRadius.circular(size * 0.33),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18094595),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: size * 0.62,
          height: size * 0.70,
          child: CustomPaint(
            painter: _SpindoLogoGeometryPainter(
              leftColor: Colors.white,
              rightColor: Colors.white,
            ),
          ),
        ),
      );
    } else {
      mark = SizedBox(
        width: size,
        height: size * 1.12,
        child: CustomPaint(
          painter: _SpindoLogoGeometryPainter(
            leftColor: AppColors.spindoOrange,
            rightColor: AppColors.corporateNavy,
          ),
        ),
      );
    }

    if (!showText) {
      return mark;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 12),
        const Text(
          'HR HUB',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.corporateNavyDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Precise PT SPINDO Logo geometry matching web-admin SVG:
/// ```xml
/// <svg viewBox="0 0 32 36" fill="none">
///   <circle cx="8" cy="7" r="3.5" />
///   <rect x="4.5" y="14" width="7" height="18" rx="3.5" />
///   <rect x="17.5" y="7" width="7" height="25" rx="3.5" />
/// </svg>
/// ```
class _SpindoLogoGeometryPainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;

  _SpindoLogoGeometryPainter({
    required this.leftColor,
    required this.rightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 32.0;
    final scaleY = size.height / 36.0;

    final paintLeft = Paint()
      ..color = leftColor
      ..style = PaintingStyle.fill;

    final paintRight = Paint()
      ..color = rightColor
      ..style = PaintingStyle.fill;

    // 1. Left circle dot: cx: 8, cy: 7, r: 3.5
    canvas.drawCircle(
      Offset(8 * scaleX, 7 * scaleY),
      3.5 * scaleX,
      paintLeft,
    );

    // 2. Left pillar rect: x: 4.5, y: 14, w: 7, h: 18, rx: 3.5
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        4.5 * scaleX,
        14 * scaleY,
        7.0 * scaleX,
        18.0 * scaleY,
      ),
      Radius.circular(3.5 * scaleX),
    );
    canvas.drawRRect(leftRect, paintLeft);

    // 3. Right taller pillar rect: x: 17.5, y: 7, w: 7, h: 25, rx: 3.5
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        17.5 * scaleX,
        7 * scaleY,
        7.0 * scaleX,
        25.0 * scaleY,
      ),
      Radius.circular(3.5 * scaleX),
    );
    canvas.drawRRect(rightRect, paintRight);
  }

  @override
  bool shouldRepaint(covariant _SpindoLogoGeometryPainter oldDelegate) {
    return oldDelegate.leftColor != leftColor ||
        oldDelegate.rightColor != rightColor;
  }
}
