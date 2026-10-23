import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'base_map_painter.dart';

bool isSecondOffBoundaries(double x, double y) {
  if (x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0) return true;
  // Black borders and outer letterbox padding
  if (x < 0.0350 || x > 0.9750 || y < 0.1250 || y > 0.8100) return true;
  return false;
}

String secondRoomAt(double x, double y) {
  if (isSecondOffBoundaries(x, y)) {
    return 'Off Boundaries';
  }
  // Left Wing Rooms (x < 0.185)
  if (x < 0.185) {
    if (y < 0.185) return 'FIRE EXIT (Top-Left)';
    if (y < 0.303) return 'ROOM 220';
    if (y < 0.432) return 'ROOM 219';
    if (y < 0.583) return 'ROOM 218';
    if (y <= 0.860) return 'ROOM 217 / READING ROOM';
    return 'Second Floor Hallway';
  }

  // Vertical Corridor: x in [0.185, 0.230], y in [0.106, 0.583]
  if (x >= 0.185 && x < 0.230 && y < 0.583) {
    return 'Second Floor Hallway';
  }

  // Inner Library area: x in [0.230, 0.385]
  if (x >= 0.230 && x < 0.385 && y < 0.583) {
    if (x < 0.350 && y < 0.303) return 'LIBRARY EXTENSION';
    return 'LIBRARY';
  }

  // North Row Rooms: y in [0.266, 0.583], x >= 0.385
  if (y >= 0.266 && y < 0.583 && x >= 0.385) {
    if (x < 0.457) return 'ROOM 211';
    if (x < 0.529) return 'ROOM 209';
    if (x < 0.605) return 'ROOM 207';
    if (x < 0.655) return 'FIRE EXIT (Central / Middle)';
    if (x < 0.728) return 'ROOM 205';
    if (x < 0.801) return 'ROOM 203';
    if (x < 0.874) return 'ROOM 202';
    if (x <= 0.965) return 'MEN\'S CR';
  }

  // Main Horizontal Hallway: y in [0.583, 0.644]
  if (y >= 0.583 && y < 0.644) {
    return 'Second Floor Hallway';
  }

  // South Row Rooms: y >= 0.644
  if (y >= 0.644) {
    if (x < 0.322) return 'DEPT.';
    if (x < 0.399) return 'ROOM 214';
    if (x < 0.467) return 'ROOM 213';
    if (x < 0.534) return 'ROOM 212';
    if (x < 0.605) return 'ROOM 210';
    if (x < 0.691) return 'ROOM 208';
    if (x < 0.779) return 'ROOM 206';
    if (x < 0.845) return 'ROOM 204';
    if (x < 0.889) return 'ROOM 201';
    if (x <= 0.965) return 'FIRE EXIT (Bottom-Right)';
  }

  return 'Second Floor Hallway';
}

class _RoomLabelItem {
  final String label;
  final double normX;
  final double normY;
  final double fontSize;

  const _RoomLabelItem(
    this.label,
    this.normX,
    this.normY, {
    this.fontSize = 10.0,
  });
}

class _SecondDoorData {
  final Offset door;
  final Offset hallway;

  const _SecondDoorData(this.door, this.hallway);
}

_SecondDoorData _getSecondRoomDoor(String room, Offset targetNorm) {
  switch (room) {
    case 'ROOM 220':
      return const _SecondDoorData(Offset(0.1543, 0.2683), Offset(0.1543, 0.2683));
    case 'ROOM 219':
      return const _SecondDoorData(Offset(0.1543, 0.4080), Offset(0.1543, 0.4080));
    case 'ROOM 218':
      return const _SecondDoorData(Offset(0.1543, 0.5256), Offset(0.1543, 0.5256));
    case 'ROOM 217 / READING ROOM':
      return const _SecondDoorData(Offset(0.1543, 0.6708), Offset(0.1543, 0.6003));
    case 'DEPT.':
      return const _SecondDoorData(Offset(0.1543, 0.6708), Offset(0.1543, 0.6003));
    case 'LIBRARY EXTENSION':
      return const _SecondDoorData(Offset(0.1543, 0.2683), Offset(0.1543, 0.2683));
    case 'LIBRARY':
      return const _SecondDoorData(Offset(0.2939, 0.5256), Offset(0.2939, 0.6003));
    case 'ROOM 211':
      return const _SecondDoorData(Offset(0.4014, 0.5256), Offset(0.4014, 0.6003));
    case 'ROOM 209':
      return const _SecondDoorData(Offset(0.4463, 0.5256), Offset(0.4463, 0.6003));
    case 'ROOM 207':
      return const _SecondDoorData(Offset(0.5547, 0.5256), Offset(0.5547, 0.6003));
    case 'ROOM 205':
      return const _SecondDoorData(Offset(0.6924, 0.5256), Offset(0.6924, 0.6003));
    case 'ROOM 203':
      return const _SecondDoorData(Offset(0.7891, 0.5256), Offset(0.7891, 0.6003));
    case 'ROOM 202':
      return const _SecondDoorData(Offset(0.8799, 0.5256), Offset(0.8799, 0.6003));
    case 'MEN\'S CR':
      return const _SecondDoorData(Offset(0.9297, 0.5256), Offset(0.9297, 0.6003));
    case 'ROOM 214':
      return const _SecondDoorData(Offset(0.2939, 0.6708), Offset(0.2939, 0.6003));
    case 'ROOM 213':
      return const _SecondDoorData(Offset(0.3447, 0.6708), Offset(0.3447, 0.6003));
    case 'ROOM 212':
      return const _SecondDoorData(Offset(0.4463, 0.6708), Offset(0.4463, 0.6003));
    case 'ROOM 210':
      return const _SecondDoorData(Offset(0.5547, 0.6708), Offset(0.5547, 0.6003));
    case 'ROOM 208':
      return const _SecondDoorData(Offset(0.6563, 0.6708), Offset(0.6563, 0.6003));
    case 'ROOM 206':
      return const _SecondDoorData(Offset(0.7891, 0.6708), Offset(0.7891, 0.6003));
    case 'ROOM 204':
      return const _SecondDoorData(Offset(0.8447, 0.6708), Offset(0.8447, 0.6003));
    case 'ROOM 201':
      return const _SecondDoorData(Offset(0.8936, 0.6708), Offset(0.8936, 0.6003));
    case 'FIRE EXIT (Top-Left)':
      return const _SecondDoorData(Offset(0.0957, 0.2061), Offset(0.1543, 0.2061));
    case 'FIRE EXIT (Central / Middle)':
      return const _SecondDoorData(Offset(0.6221, 0.5187), Offset(0.6221, 0.6003));
    case 'FIRE EXIT (Bottom-Right)':
      return const _SecondDoorData(Offset(0.9570, 0.7123), Offset(0.9570, 0.6003));
    default:
      if (targetNorm.dx <= 0.185) {
        return _SecondDoorData(Offset(0.1543, targetNorm.dy), Offset(0.1543, targetNorm.dy));
      }
      return _SecondDoorData(Offset(targetNorm.dx, 0.6003), Offset(targetNorm.dx, 0.6003));
  }
}

// SECOND FLOOR PAINTER
// ============================================================
// Rendered on top of the 1:1 replica floor plan image.
// Contains ONLY the labeling (without labeling stairs) and interactive emergency route/pin.
class SecondFloorPainter extends BaseFloorPainter {
  SecondFloorPainter({
    required super.selectedLocation,
    required super.selectedRoom,
    required super.showEmergencyPath,
  });

  static const List<_RoomLabelItem> _roomLabels = [
    // Left Wing Rooms (Stairs at top-left are NOT labeled per user instruction)
    _RoomLabelItem('ROOM 220', 0.0645, 0.2877, fontSize: 10.0),
    _RoomLabelItem('ROOM 219', 0.0645, 0.3928, fontSize: 10.0),
    _RoomLabelItem('ROOM 218', 0.0645, 0.5021, fontSize: 10.0),
    _RoomLabelItem('ROOM 217 /\nREADING ROOM', 0.0645, 0.6680, fontSize: 8.5),

    // Library Area
    _RoomLabelItem('LIBRARY\nEXTENSION', 0.2598, 0.2573, fontSize: 9.5),
    _RoomLabelItem('LIBRARY', 0.2734, 0.4481, fontSize: 11.5),

    // North Row Rooms (Central staircase is NOT labeled per user instruction)
    _RoomLabelItem('ROOM 211', 0.3877, 0.4910, fontSize: 9.5),
    _RoomLabelItem('ROOM 209', 0.4648, 0.4910, fontSize: 9.5),
    _RoomLabelItem('ROOM 207', 0.5420, 0.4910, fontSize: 9.5),
    _RoomLabelItem('ROOM 205', 0.7070, 0.4910, fontSize: 9.5),
    _RoomLabelItem('ROOM 203', 0.7842, 0.4910, fontSize: 9.5),
    _RoomLabelItem('ROOM 202', 0.8613, 0.4910, fontSize: 9.5),
    _RoomLabelItem('MEN\'S CR', 0.9385, 0.4910, fontSize: 8.5),

    // South Row Rooms (Right staircase is NOT labeled per user instruction)
    _RoomLabelItem('DEPT.', 0.1807, 0.6985, fontSize: 10.5),
    _RoomLabelItem('ROOM 214', 0.2822, 0.6985, fontSize: 9.5),
    _RoomLabelItem('ROOM 213', 0.3594, 0.6985, fontSize: 9.5),
    _RoomLabelItem('ROOM 212', 0.4365, 0.6985, fontSize: 9.5),
    _RoomLabelItem('ROOM 210', 0.5264, 0.6985, fontSize: 9.5),
    _RoomLabelItem('ROOM 208', 0.6289, 0.6985, fontSize: 9.5),
    _RoomLabelItem('ROOM 206', 0.7236, 0.6985, fontSize: 9.5),
    _RoomLabelItem('ROOM 204', 0.8066, 0.6985, fontSize: 9.5),
    _RoomLabelItem('ROOM 201', 0.8770, 0.6985, fontSize: 9.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Render ONLY the Room Labeling
    for (final item in _roomLabels) {
      drawText(
        canvas,
        item.label,
        Offset(item.normX * w, item.normY * h),
        item.fontSize,
        color: const Color(0xFF202124),
        fontWeight: FontWeight.bold,
      );
    }

    // 2. Location Pinning function ONLY (Pathing temporarily removed per user request)
    if (selectedLocation != null && !isSecondOffBoundaries(selectedLocation!.dx, selectedLocation!.dy)) {
      drawPin(canvas, Offset(selectedLocation!.dx * size.width, selectedLocation!.dy * size.height));
    }
  }

  // Emergency Response Route (Preserved for when emergency routing is re-enabled):
  void drawSecondFloorEmergencyRoute(Canvas canvas, Size size, Offset targetNorm) {
    if (isSecondOffBoundaries(targetNorm.dx, targetNorm.dy)) {
      return;
    }
    final double w = size.width;
    final double h = size.height;

    final Offset target = Offset(targetNorm.dx * w, targetNorm.dy * h);

    // Grid Spines
    const double vertHallwayXNorm = 0.1543;
    const double horizHallwayYNorm = 0.6003;
    final double vertHallwayX = w * vertHallwayXNorm;
    final double horizHallwayY = h * horizHallwayYNorm;

    // Staircase locations (exit points)
    final Offset leftWingStairs = Offset(w * 0.0957, h * 0.2061);
    final Offset centralStairs = Offset(w * 0.6221, h * 0.5187);
    final Offset rightWingStairs = Offset(w * 0.9570, h * 0.7123);

    final String room = selectedRoom ?? secondRoomAt(targetNorm.dx, targetNorm.dy);
    final doorData = _getSecondRoomDoor(room, targetNorm);

    final Offset targetDoor = Offset(doorData.door.dx * w, doorData.door.dy * h);
    final Offset targetHallway = Offset(doorData.hallway.dx * w, doorData.hallway.dy * h);

    final path = Path();
    path.moveTo(target.dx, target.dy);

    // 1. Move to room's designated door
    if ((target.dx - targetDoor.dx).abs() > 1.0 || (target.dy - targetDoor.dy).abs() > 1.0) {
      path.lineTo(targetDoor.dx, targetDoor.dy);
    }

    // 2. Move from door onto hallway grid spine
    if ((targetDoor.dx - targetHallway.dx).abs() > 1.0 || (targetDoor.dy - targetHallway.dy).abs() > 1.0) {
      path.lineTo(targetHallway.dx, targetHallway.dy);
    }

    // 3. Route along grid hallways to the nearest stairs/exit
    if (doorData.hallway.dx <= vertHallwayXNorm + 0.01 && doorData.hallway.dy <= horizHallwayYNorm + 0.02) {
      // Left Wing: follow vertical corridor north to Top-Left stairs junction, then turn west to stairs
      path.lineTo(vertHallwayX, leftWingStairs.dy);
      path.lineTo(leftWingStairs.dx, leftWingStairs.dy);
    } else {
      // Along horizontal hallway spine (Y = 434)
      if ((targetHallway.dy - horizHallwayY).abs() > 1.0) {
        path.lineTo(targetHallway.dx, horizHallwayY);
      }

      // Midpoint between Central Stairs (0.6221) and Right Stairs (0.9570) is ~0.8085
      if (doorData.hallway.dx <= 0.8085) {
        // Nearest is Central Stairs: travel along hallway to Central junction, then north into stairs
        path.lineTo(centralStairs.dx, horizHallwayY);
        path.lineTo(centralStairs.dx, centralStairs.dy);
      } else {
        // Nearest is Right Stairs: travel along hallway to Right junction, then south into stairs
        path.lineTo(rightWingStairs.dx, horizHallwayY);
        path.lineTo(rightWingStairs.dx, rightWingStairs.dy);
      }
    }

    final glow = Paint()
      ..color = kGoogleRed.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glow);

    final route = Paint()
      ..color = kGoogleRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, route);
  }
}
