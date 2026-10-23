import 'package:flutter/material.dart';
import '../map/base_map_painter.dart';
import '../map/ground_floor.dart';
import '../map/second_floor.dart';
import 'models/distress_signal.dart';

class AdminHeatMapPainter extends BaseFloorPainter {
  final int floor;
  final List<HeatPoint> heatPoints;
  final List<DistressSignal> distressSignals;
  final double pulseValue;
  final DistressSignal? selectedSignal;
  final Offset? pinnedLocation;
  final String? pinnedRoom;
  final bool showHeatMap;
  final bool showBeacons;

  AdminHeatMapPainter({
    required this.floor,
    required this.heatPoints,
    required this.distressSignals,
    required this.pulseValue,
    this.selectedSignal,
    this.pinnedLocation,
    this.pinnedRoom,
    this.showHeatMap = true,
    this.showBeacons = true,
  }) : super(
          selectedLocation: pinnedLocation ?? selectedSignal?.position,
          selectedRoom: pinnedRoom ?? selectedSignal?.roomName,
          showEmergencyPath: false,
        );

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Render Base Floor Room Labels & Dropped Pin from Ground / Second floor
    final effectiveLocation = pinnedLocation ?? selectedSignal?.position;
    final effectiveRoom = pinnedRoom ?? selectedSignal?.roomName;

    if (floor == 0) {
      GroundFloorPainter(
        selectedLocation: effectiveLocation,
        selectedRoom: effectiveRoom,
        showEmergencyPath: false,
      ).paint(canvas, size);
    } else {
      SecondFloorPainter(
        selectedLocation: effectiveLocation,
        selectedRoom: effectiveRoom,
        showEmergencyPath: false,
      ).paint(canvas, size);
    }

    // 2. Render Heat Map Density Gradient Layer
    if (showHeatMap) {
      _drawHeatMapLayer(canvas, size);
    }

    // 3. Render Live Emergency Distress Signal Beacons
    if (showBeacons) {
      _drawLiveDistressBeacons(canvas, size);
    }
  }

  void _drawHeatMapLayer(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    for (final hp in heatPoints) {
      final center = Offset(hp.normX * w, hp.normY * h);
      final radius = hp.radius;

      final gradient = RadialGradient(
        colors: [
          const Color(0xFFE50914).withValues(alpha: 0.65 * hp.intensity),
          const Color(0xFFFF5722).withValues(alpha: 0.45 * hp.intensity),
          const Color(0xFFFFC107).withValues(alpha: 0.22 * hp.intensity),
          const Color(0x00FFC107),
        ],
        stops: const [0.0, 0.38, 0.72, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawLiveDistressBeacons(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final signalsOnFloor = distressSignals.where((s) => s.floor == floor).toList();

    for (final sig in signalsOnFloor) {
      final center = Offset(sig.position.dx * w, sig.position.dy * h);
      final isSelected = selectedSignal?.id == sig.id;
      final isCritical = sig.urgency == DistressUrgency.critical;

      // Concentric pulsating animated waves
      final double wave1Radius = 18.0 + (pulseValue * 36.0);
      final double wave1Alpha = (1.0 - pulseValue).clamp(0.0, 1.0) * (isCritical ? 0.75 : 0.50);

      final wave1Paint = Paint()
        ..color = sig.urgencyColor.withValues(alpha: wave1Alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, wave1Radius, wave1Paint);

      final double secondPhase = (pulseValue + 0.45) % 1.0;
      final double wave2Radius = 14.0 + (secondPhase * 28.0);
      final double wave2Alpha = (1.0 - secondPhase).clamp(0.0, 1.0) * 0.40;

      final wave2Paint = Paint()
        ..color = sig.urgencyColor.withValues(alpha: wave2Alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, wave2Radius, wave2Paint);

      // Core Outer Glow Shadow
      final glowPaint = Paint()
        ..color = sig.urgencyColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, 18.0, glowPaint);

      // Core Solid Beacon
      final corePaint = Paint()
        ..color = sig.urgencyColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 14.0, corePaint);

      // White Border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, 14.0, borderPaint);

      // Center Icon: Exclamation or SOS
      final iconPainter = TextPainter(
        text: TextSpan(
          text: isCritical ? '!' : 'SOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: isCritical ? 14 : 9,
            fontWeight: FontWeight.w900,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(center.dx - (iconPainter.width / 2), center.dy - (iconPainter.height / 2)),
      );

      // Floating Callout Badge above Beacon
      _drawSignalCalloutBadge(canvas, center, sig, isSelected);

      // Selected targeting reticle
      if (isSelected) {
        final reticlePaint = Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(center, 24.0, reticlePaint);

        // Crosshairs
        const double chLen = 8.0;
        canvas.drawLine(Offset(center.dx - 32, center.dy), Offset(center.dx - 24 - chLen, center.dy), reticlePaint);
        canvas.drawLine(Offset(center.dx + 24 + chLen, center.dy), Offset(center.dx + 32, center.dy), reticlePaint);
        canvas.drawLine(Offset(center.dx, center.dy - 32), Offset(center.dx, center.dy - 24 - chLen), reticlePaint);
        canvas.drawLine(Offset(center.dx, center.dy + 24 + chLen), Offset(center.dx, center.dy + 32), reticlePaint);
      }
    }
  }

  void _drawSignalCalloutBadge(Canvas canvas, Offset center, DistressSignal sig, bool isSelected) {
    final String label = '${sig.studentName.split(' ').first}: ${sig.roomName} (${sig.urgencyLabel})';

    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: '🚨 ',
          style: const TextStyle(fontSize: 10),
        ),
        TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSelected ? 11.5 : 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeWidth = textPainter.width + 16.0;
    final badgeHeight = textPainter.height + 8.0;
    final badgeRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - 28.0),
      width: badgeWidth,
      height: badgeHeight,
    );

    final bgPaint = Paint()
      ..color = isSelected
          ? const Color(0xFFB71C1C).withValues(alpha: 0.95)
          : const Color(0xFF1E1E26).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? const Color(0xFFFFD54F) : sig.urgencyColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.2;

    final rrect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(badgeRect.left + 8.0, badgeRect.top + 4.0),
    );
  }

  @override
  bool shouldRepaint(covariant AdminHeatMapPainter oldDelegate) {
    return true; // Always repaint for smooth pulsing animation and live updates
  }
}
