import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

// Base Map Layout

abstract class BaseFloorPainter extends CustomPainter {
  final Offset? selectedLocation;
  final String? selectedRoom;
  final bool showEmergencyPath;

  BaseFloorPainter({
    required this.selectedLocation,
    required this.selectedRoom,
    required this.showEmergencyPath,
  });

  static final Paint mapBgPaint = Paint()..color = const Color(0xFFF2F4F7);
  static final Paint buildingPaint = Paint()..color = const Color(0xFFFBFBF8);
  static final Paint hallwayPaint = Paint()..color = const Color(0xFFE2E2E2);
  static final Paint fillPaint = Paint()..style = PaintingStyle.fill;

  static final Paint strokePaint = Paint()
    ..color = const Color(0xFF212121)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  static final Paint pinPaint = Paint()..color = kGoogleRed;
  static final Paint pinInnerPaint = Paint()..color = Colors.white;

  void drawHatchedBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF2F4F7);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final stripePaint = Paint()
      ..color = const Color(0xFFD3D8DE)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double step = 22.0;
    final double maxDim = size.width + size.height;
    for (double d = -size.height; d < maxDim; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), stripePaint);
    }
  }

  void drawRoom(
    Canvas canvas,
    Rect rect,
    String label, {
    Color fillColor = const Color(0xFFFFFFFF),
    Color textColor = const Color(0xFF202124),
    Color borderColor = const Color(0xFF212121),
    double fontSize = 9.0,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    fillPaint.color = fillColor;
    canvas.drawRect(rect, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRect(rect, borderPaint);

    if (label.isNotEmpty) {
      drawText(
        canvas,
        label,
        rect.center,
        fontSize,
        color: textColor,
        fontWeight: fontWeight,
        maxWidth: math.max(6.0, rect.width - 2.0),
        maxHeight: math.max(6.0, rect.height - 2.0),
      );
    }
  }

  void drawFireExit(Canvas canvas, Rect rect, {String label = 'FIRE\nEXIT'}) {
    fillPaint.color = const Color(0xFFFF8E8E);
    canvas.drawRect(rect, fillPaint);

    final Paint exitBorder = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(rect, exitBorder);

    drawText(
      canvas,
      label,
      rect.center,
      8.0,
      color: const Color(0xFF1A1A1A),
      fontWeight: FontWeight.w900,
      maxWidth: math.max(6.0, rect.width - 2.0),
      maxHeight: math.max(6.0, rect.height - 2.0),
    );
  }

  void drawDoorSwing(
    Canvas canvas,
    Offset hinge,
    double radius,
    double startAngle,
    double sweepAngle, {
    Color strokeColor = const Color(0xFF757575),
  }) {
    final arcPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawArc(
      Rect.fromCircle(center: hinge, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
    final leafEnd = Offset(
      hinge.dx + radius * math.cos(startAngle + sweepAngle),
      hinge.dy + radius * math.sin(startAngle + sweepAngle),
    );
    canvas.drawLine(hinge, leafEnd, Paint()..color = const Color(0xFF333333)..strokeWidth = 1.3);
  }

  void drawStartBadge(
    Canvas canvas,
    Offset position,
    String label, {
    Color color = const Color(0xFF0F9D58),
  }) {
    final outerGlow = Paint()
      ..color = color.withValues(alpha: 0.26)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 14, outerGlow);

    final fillBadge = Paint()..color = color;
    canvas.drawCircle(position, 8, fillBadge);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(position, 8, borderPaint);

    canvas.drawCircle(position, 3.0, Paint()..color = Colors.white);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final badgeOffset = Offset(position.dx, position.dy - 17);
    final textBg = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: badgeOffset,
        width: tp.width + 10,
        height: tp.height + 6,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(textBg, Paint()..color = color.withValues(alpha: 0.94));
    canvas.drawRRect(textBg, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.9);
    tp.paint(canvas, Offset(badgeOffset.dx - tp.width / 2, badgeOffset.dy - tp.height / 2));
  }

  void drawPin(Canvas canvas, Offset position) {
    // 1. Subtle drop-shadow / ripple on the floor at the tip of the pin
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(position.dx, position.dy + 1.5), width: 14, height: 6),
      shadowPaint,
    );

    // 2. Location pin icon (Icons.location_on)
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on.codePoint),
        style: TextStyle(
          fontSize: 34,
          fontFamily: Icons.location_on.fontFamily,
          package: Icons.location_on.fontPackage,
          color: kGoogleRed,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height + 4),
    );
  }

  void drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize, {
    Color color = const Color(0xFF202124),
    FontWeight fontWeight = FontWeight.bold,
    double? maxWidth,
    double? maxHeight,
  }) {
    double currentFontSize = fontSize;
    TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: currentFontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    // Layout without maxWidth so words are NEVER split across syllables (e.g. 'LABORATORY' stays a single unbroken word)
    painter.layout();

    // Auto-downscale font size cleanly if the unbroken text width/height exceeds room boundaries
    if ((maxWidth != null && painter.width > maxWidth) ||
        (maxHeight != null && painter.height > maxHeight)) {
      final double scaleW = maxWidth != null ? (maxWidth / painter.width) : 1.0;
      final double scaleH = maxHeight != null ? (maxHeight / painter.height) : 1.0;
      final double scale = math.min(scaleW, scaleH);
      currentFontSize = math.max(5.0, currentFontSize * scale * 0.95);

      painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: currentFontSize,
            fontWeight: fontWeight,
            color: color,
            height: 1.05,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      painter.layout();
    }

    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant BaseFloorPainter oldDelegate) {
    return oldDelegate.selectedLocation != selectedLocation ||
        oldDelegate.selectedRoom != selectedRoom ||
        oldDelegate.showEmergencyPath != showEmergencyPath;
  }
}

