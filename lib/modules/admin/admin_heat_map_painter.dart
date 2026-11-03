import 'package:flutter/material.dart';
import '../map/base_map_painter.dart';
import '../map/campus_map_data.dart';
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
      final Color baseColor = hp.color ?? const Color(0xFFE50914);

      final gradient = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.65 * hp.intensity),
          baseColor.withValues(alpha: 0.38 * hp.intensity),
          baseColor.withValues(alpha: 0.12 * hp.intensity),
          baseColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(center, radius, paint);
    }
  }

  void _drawLiveDistressBeacons(Canvas canvas, Size size) {
    final signalsOnFloor = distressSignals.where((s) => s.floor == floor && s.status != DistressStatus.resolved).toList();
    final clusters = computeLocationClusters(signalsOnFloor, floor);

    for (final cluster in clusters) {
      final center = cluster.center;
      final bool isSelected = selectedSignal != null &&
          cluster.signals.any((s) => (s as DistressSignal).id == selectedSignal!.id);
      final Color pulseColor = cluster.pulseColor;
      final int count = cluster.count;

      // Concentric pulsating animated waves in count-based pulse color:
      // Green for 1, Orange for 2, Red for 3+
      final double wave1Radius = 18.0 + (pulseValue * 38.0);
      final double wave1Alpha = (1.0 - pulseValue).clamp(0.0, 1.0) * (count >= 3 ? 0.85 : 0.65);

      final wave1Paint = Paint()
        ..color = pulseColor.withValues(alpha: wave1Alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = count >= 3 ? 3.5 : 2.5;
      canvas.drawCircle(center, wave1Radius, wave1Paint);

      final double secondPhase = (pulseValue + 0.45) % 1.0;
      final double wave2Radius = 14.0 + (secondPhase * 28.0);
      final double wave2Alpha = (1.0 - secondPhase).clamp(0.0, 1.0) * 0.45;

      final wave2Paint = Paint()
        ..color = pulseColor.withValues(alpha: wave2Alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, wave2Radius, wave2Paint);

      // Core Outer Glow Shadow
      final glowPaint = Paint()
        ..color = pulseColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, 18.0, glowPaint);

      // Core Solid Beacon
      final corePaint = Paint()
        ..color = pulseColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 15.0, corePaint);

      // White Border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, 15.0, borderPaint);

      // Center Icon: simultaneous count or exclamation
      final String centerText = count > 1 ? '$count' : '!';
      final iconPainter = TextPainter(
        text: TextSpan(
          text: centerText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
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
      _drawClusterCalloutBadge(canvas, center, cluster, isSelected);

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

  void _drawClusterCalloutBadge(Canvas canvas, Offset center, LocationDistressCluster cluster, bool isSelected) {
    final firstSig = cluster.signals.first as DistressSignal;
    String label;
    if (cluster.count == 1) {
      label = '${firstSig.studentName.split(' ').first}: ${cluster.locationName} (1 Alert)';
    } else if (cluster.count == 2) {
      label = '${cluster.locationName}: 2 Simultaneous Alerts';
    } else {
      label = 'CRITICAL: ${cluster.locationName} (${cluster.count} Alerts)';
    }

    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: cluster.count >= 3 ? '🔥 ' : (cluster.count == 2 ? '⚠️ ' : '🚨 '),
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
      ..color = isSelected ? const Color(0xFFFFD54F) : cluster.pulseColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.4;

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
