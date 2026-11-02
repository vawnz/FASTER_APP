import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'base_map_painter.dart';

bool isGroundOffBoundaries(double x, double y) {
  // Outside canvas bounds
  if (x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0) return true;
  // Outer perimeter black walls and margins
  if (x <= 0.0650 || x >= 0.9750 || y <= 0.0300) return true;
  // Bottom black wall (except designated emergency exit doors / gates)
  if (y >= 0.9629) {
    final bool isBottomExit = (x >= 0.1082 && x <= 0.2496) ||
        (x >= 0.6656 && x <= 0.8053) ||
        (x >= 0.8136 && x <= 0.8735);
    return !isBottomExit;
  }
  return false;
}

String groundRoomAt(double x, double y) {
  if (isGroundOffBoundaries(x, y)) {
    return 'Off Boundaries';
  }
  // Far Left Wing (x < 0.19)
  if (x < 0.19) {
    if (y < 0.199) return 'SERVICE / STAIRS';
    if (y < 0.439) return 'HM LABORATORY COLD KITCHEN';
    if (y < 0.560) return 'HM LABORATORY HOT KITCHEN';
    return 'INVENTORY ROOM';
  }

  // Left Vertical Corridor (x in [0.19, 0.22], y < 0.664)
  if (x >= 0.19 && x < 0.22 && y < 0.664) {
    if (y < 0.14) return 'FIRE EXIT';
    return 'Ground Floor Hallway';
  }

  // Top Region (y < 0.395)
  if (y < 0.395) {
    if (x < 0.360) {
      if (y < 0.242) return 'HM DEPARTMENT';
      return 'AIHMS OFFICE';
    }
    if (x < 0.450) {
      if (y < 0.250) return 'BLEACHERS';
      return 'TERRACE';
    }
    if (x < 0.605) return 'GARDEN';
    if (x < 0.900) {
      if (y < 0.188) {
        if (x < 0.724) return 'FAST OFFICE';
        if (x < 0.784) return 'JMA OFFICE';
        if (x < 0.842) return 'ROTC OFFICE';
        return 'CSG OFFICE';
      } else {
        if (x < 0.842) return 'CANTEEN DINING AREA';
        return 'CANTEEN KITCHEN';
      }
    }
    return 'SERVICE / UTILITY';
  }

  // Middle Region (0.395 <= y < 0.650)
  if (y < 0.650) {
    if (x < 0.288) return 'IT / CS DEPARTMENT';
    if (x < 0.390) {
      if (y < 0.461) return 'EL CHABACANO';
      return 'MIS';
    }
    if (x < 0.470) {
      if (y < 0.461) return 'CR';
      if (y < 0.548) return 'REGISTRAR';
      return 'CASHIER';
    }
    if (x < 0.590) return 'LOBBY';
    if (x < 0.666) {
      if (y >= 0.548) return 'ROOM 108';
      return 'LOBBY';
    }
    if (x < 0.774) return 'ROOM 107 COM LAB';
    if (x < 0.882) return 'RDE OFFICE';
    if (x <= 0.940) {
      if (y >= 0.580) return 'FIRE EXIT';
      return 'WOMEN\'S CR';
    }
    return 'Ground Floor Hallway';
  }

  // Bottom Region (y >= 0.650)
  if (x < 0.216) {
    if (y < 0.766) return 'JPCS OFFICE';
    return 'GAD OFFICE';
  }
  if (x < 0.276) return 'OSAS';
  if (x < 0.339) return 'ROOM 119 COM LAB';
  if (x < 0.403) return 'ACCRE. OFFICE';
  if (x < 0.466) {
    if (y < 0.766) return 'GUIDANCE';
    return 'DEAN\'S OFFICE';
  }
  if (x < 0.602) {
    if (y >= 0.764 && y <= 0.820) return 'FIRE EXIT';
    return 'Ground Floor Hallway';
  }
  if (x < 0.666) return 'ROOM 109 COM LAB';
  if (x < 0.769) return 'ROOM 106 COM LAB';
  if (x < 0.879) return 'ROOM 104 COM LAB';
  if (x <= 0.975) {
    if (y < 0.799) return 'ELEC. ROOM';
    return 'GUARD HOUSE';
  }

  return 'Ground Floor Hallway / Lobby';
}

class _GroundRoomLabelItem {
  final String label;
  final double normX;
  final double normY;
  final double fontSize;
  final Color? color;

  const _GroundRoomLabelItem(
    this.label,
    this.normX,
    this.normY, {
    this.fontSize = 10.0,
    this.color,
  });
}

class _GroundDoorData {
  final Offset door;
  final Offset hallway;

  const _GroundDoorData(this.door, this.hallway);
}

// GROUND FLOOR PAINTER
// ============================================================
// Rendered on top of the 1:1 replica floor plan image.
// Contains ONLY the labeling (without labeling stairs) and interactive emergency route/pin.
class GroundFloorPainter extends BaseFloorPainter {
  GroundFloorPainter({
    required super.selectedLocation,
    required super.selectedRoom,
    required super.showEmergencyPath,
  });

  static const List<_GroundRoomLabelItem> _roomLabels = [
    // Top-Right Wing
    _GroundRoomLabelItem('FAST\nOFFICE', 0.6865, 0.1438, fontSize: 10.0, color: Color(0xFFB71C1C)),
    _GroundRoomLabelItem('JMA\nOFFICE', 0.7422, 0.1438, fontSize: 9.0),
    _GroundRoomLabelItem('ROTC\nOFFICE', 0.7930, 0.1438, fontSize: 9.0),
    _GroundRoomLabelItem('CSG\nOFFICE', 0.8418, 0.1438, fontSize: 9.0),
    _GroundRoomLabelItem('CANTEEN DINING AREA', 0.7383, 0.2400, fontSize: 11.0),
    _GroundRoomLabelItem('CANTEEN\nKITCHEN', 0.8438, 0.2400, fontSize: 9.5),

    // Courtyard (Garden & Bleachers Differentiated)
    _GroundRoomLabelItem('GARDEN', 0.5176, 0.1826, fontSize: 11.0, color: Color(0xFF1B5E20)),
    _GroundRoomLabelItem('BLEACHERS', 0.3711, 0.1867, fontSize: 9.5, color: Color(0xFF2E7D32)),
    _GroundRoomLabelItem('TERRACE', 0.3711, 0.3154, fontSize: 9.0, color: Color(0xFF455A64)),

    // Far Left Wing (Stairs at top-left are NOT labeled per user instruction)
    _GroundRoomLabelItem('HM LABORATORY\nCOLD KITCHEN', 0.1641, 0.3001, fontSize: 9.5),
    _GroundRoomLabelItem('HM LABORATORY\nHOT KITCHEN', 0.1641, 0.4564, fontSize: 9.5),
    _GroundRoomLabelItem('INVENTORY\nROOM', 0.1641, 0.6362, fontSize: 9.5),

    // Middle Wing (West of Lobby)
    _GroundRoomLabelItem('HM\nDEPARTMENT', 0.3057, 0.1881, fontSize: 10.0),
    _GroundRoomLabelItem('AIHMS\nOFFICE', 0.3057, 0.3250, fontSize: 10.0),
    _GroundRoomLabelItem('IT / CS\nDEPARTMENT', 0.2871, 0.4550, fontSize: 9.0),
    _GroundRoomLabelItem('EL CHABACANO', 0.3389, 0.4260, fontSize: 8.5),
    _GroundRoomLabelItem('MIS', 0.3398, 0.4993, fontSize: 9.0),
    _GroundRoomLabelItem('CR', 0.3877, 0.4260, fontSize: 8.5),
    _GroundRoomLabelItem('REGISTRAR', 0.3877, 0.4855, fontSize: 8.5),
    _GroundRoomLabelItem('CASHIER', 0.3877, 0.5228, fontSize: 8.5),
    _GroundRoomLabelItem('LOBBY', 0.5176, 0.4772, fontSize: 13.0),

    // Middle Row (East of Lobby)
    _GroundRoomLabelItem('ROOM 108', 0.6445, 0.4564, fontSize: 8.5),
    _GroundRoomLabelItem('ROOM 107\nCOM LAB', 0.7031, 0.4564, fontSize: 9.0),
    _GroundRoomLabelItem('RDE\nOFFICE', 0.7764, 0.4564, fontSize: 9.0),
    _GroundRoomLabelItem('WOMEN\'S\nCR', 0.8350, 0.4564, fontSize: 8.5),

    // Bottom Wing (Stairs at bottom-right are NOT labeled per user instruction)
    _GroundRoomLabelItem('JPCS\nOFFICE', 0.2305, 0.6404, fontSize: 8.5),
    _GroundRoomLabelItem('GAD\nOFFICE', 0.2305, 0.7068, fontSize: 8.5),
    _GroundRoomLabelItem('OSAS', 0.2861, 0.6694, fontSize: 9.5),
    _GroundRoomLabelItem('ROOM 119\nCOM LAB', 0.3418, 0.6694, fontSize: 9.0),
    _GroundRoomLabelItem('ACCRE.\nOFFICE', 0.3926, 0.6694, fontSize: 8.5),
    _GroundRoomLabelItem('GUIDANCE', 0.4414, 0.6404, fontSize: 8.5),
    _GroundRoomLabelItem('DEAN\'S\nOFFICE', 0.4404, 0.7068, fontSize: 8.5),
    _GroundRoomLabelItem('ROOM 109\nCOM LAB', 0.6240, 0.6694, fontSize: 9.0),
    _GroundRoomLabelItem('ROOM 106\nCOM LAB', 0.7051, 0.6694, fontSize: 9.0),
    _GroundRoomLabelItem('ROOM 104\nCOM LAB', 0.8066, 0.6694, fontSize: 9.0),
    _GroundRoomLabelItem('GUARD HOUSE', 0.9141, 0.9225, fontSize: 9.5),
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
        color: item.color ?? const Color(0xFF202124),
        fontWeight: FontWeight.bold,
      );
    }

    // 2. Location Pinning function ONLY (Pathing temporarily removed per user request)
    if (selectedLocation != null && !isGroundOffBoundaries(selectedLocation!.dx, selectedLocation!.dy)) {
      drawPin(canvas, Offset(selectedLocation!.dx * size.width, selectedLocation!.dy * size.height));
    }
  }

  // Lookup table mapping enclosed indoor rooms to their physical door & corridor waypoints
  _GroundDoorData _getGroundRoomDoor(String room, Offset targetNorm) {
    switch (room) {
      case 'FAST OFFICE':
        return const _GroundDoorData(Offset(0.6318, 0.2200), Offset(0.6318, 0.2200));
      case 'SERVICE / STAIRS':
        return const _GroundDoorData(Offset(0.1800, 0.1500), Offset(0.2334, 0.1500));
      case 'HM LABORATORY COLD KITCHEN':
        return const _GroundDoorData(Offset(0.1800, 0.3000), Offset(0.2334, 0.3000));
      case 'HM LABORATORY HOT KITCHEN':
        return const _GroundDoorData(Offset(0.1800, 0.4500), Offset(0.2334, 0.4500));
      case 'INVENTORY ROOM':
        return const _GroundDoorData(Offset(0.1800, 0.6000), Offset(0.2334, 0.6000));
      case 'HM DEPARTMENT':
        return const _GroundDoorData(Offset(0.2334, 0.1800), Offset(0.2334, 0.3527));
      case 'AIHMS OFFICE':
        return const _GroundDoorData(Offset(0.2334, 0.3000), Offset(0.2334, 0.3527));
      case 'JMA OFFICE':
        return const _GroundDoorData(Offset(0.7400, 0.2000), Offset(0.7400, 0.3527));
      case 'ROTC OFFICE':
        return const _GroundDoorData(Offset(0.7950, 0.2000), Offset(0.7950, 0.3527));
      case 'CSG OFFICE':
        return const _GroundDoorData(Offset(0.8500, 0.2000), Offset(0.8500, 0.3527));
      case 'CANTEEN DINING AREA':
        return const _GroundDoorData(Offset(0.6500, 0.2800), Offset(0.6318, 0.2800));
      case 'CANTEEN KITCHEN':
        return const _GroundDoorData(Offset(0.8400, 0.2800), Offset(0.6318, 0.2800));
      case 'IT / CS DEPARTMENT':
        return const _GroundDoorData(Offset(0.2334, 0.4800), Offset(0.2334, 0.5588));
      case 'EL CHABACANO':
        return const _GroundDoorData(Offset(0.3400, 0.4000), Offset(0.3400, 0.3527));
      case 'MIS':
        return const _GroundDoorData(Offset(0.3600, 0.4800), Offset(0.5303, 0.4800));
      case 'CR':
        return const _GroundDoorData(Offset(0.4000, 0.4000), Offset(0.4000, 0.3527));
      case 'REGISTRAR':
        return const _GroundDoorData(Offset(0.4400, 0.4800), Offset(0.5303, 0.4800));
      case 'CASHIER':
        return const _GroundDoorData(Offset(0.4400, 0.5300), Offset(0.5303, 0.5300));
      case 'LOBBY':
        return const _GroundDoorData(Offset(0.5303, 0.5000), Offset(0.5303, 0.3527));
      case 'ROOM 108':
        return const _GroundDoorData(Offset(0.6318, 0.5200), Offset(0.6318, 0.5588));
      case 'ROOM 107 COM LAB':
        return const _GroundDoorData(Offset(0.7000, 0.5200), Offset(0.7000, 0.5588));
      case 'RDE OFFICE':
        return const _GroundDoorData(Offset(0.7900, 0.5200), Offset(0.7900, 0.5588));
      case 'WOMEN\'S CR':
        return const _GroundDoorData(Offset(0.8900, 0.5200), Offset(0.8900, 0.5588));
      case 'JPCS OFFICE':
        return const _GroundDoorData(Offset(0.2100, 0.6800), Offset(0.2334, 0.6800));
      case 'GAD OFFICE':
        return const _GroundDoorData(Offset(0.2100, 0.7800), Offset(0.2334, 0.7800));
      case 'OSAS':
        return const _GroundDoorData(Offset(0.2450, 0.6500), Offset(0.2450, 0.5588));
      case 'ROOM 119 COM LAB':
        return const _GroundDoorData(Offset(0.3100, 0.6500), Offset(0.3100, 0.5588));
      case 'ACCRE. OFFICE':
        return const _GroundDoorData(Offset(0.3750, 0.6500), Offset(0.3750, 0.5588));
      case 'GUIDANCE':
        return const _GroundDoorData(Offset(0.4300, 0.6500), Offset(0.4300, 0.5588));
      case 'DEAN\'S OFFICE':
        return const _GroundDoorData(Offset(0.4300, 0.7500), Offset(0.4300, 0.5588));
      case 'ROOM 109 COM LAB':
        return const _GroundDoorData(Offset(0.6318, 0.6500), Offset(0.6318, 0.5588));
      case 'ROOM 106 COM LAB':
        return const _GroundDoorData(Offset(0.7000, 0.6500), Offset(0.7000, 0.5588));
      case 'ROOM 104 COM LAB':
        return const _GroundDoorData(Offset(0.8000, 0.6500), Offset(0.8000, 0.5588));
      case 'ELEC. ROOM':
        return const _GroundDoorData(Offset(0.8900, 0.6500), Offset(0.8900, 0.5588));
      case 'GUARD HOUSE':
        return const _GroundDoorData(Offset(0.9200, 0.7800), Offset(0.9200, 0.5588));
      case 'FIRE EXIT':
      case 'FIRE EXIT (Far-Left)':
      case 'FIRE EXIT (Upper-Right)':
      case 'FIRE EXIT (Center-South)':
        return const _GroundDoorData(Offset(0.5303, 0.6500), Offset(0.5303, 0.5588));
      default:
        return _GroundDoorData(targetNorm, targetNorm);
    }
  }

  // Consistent Door-to-Door Corridor Routing (Preserved for when emergency routing is re-enabled):
  // - Responders start at FAST Office and exit through FAST Office door.
  // - Garden & Bleachers are outdoor open areas directly pathed across the courtyard to FAST Office.
  // - Enclosed rooms travel strictly via hallways and enter through the room's specific door.
  void drawGroundEmergencyRoute(Canvas canvas, Size size, Offset targetNorm) {
    if (isGroundOffBoundaries(targetNorm.dx, targetNorm.dy)) {
      return;
    }

    final double w = size.width;
    final double h = size.height;

    // Responders start at FAST Office on the Ground Floor
    final Offset fastOfficeStart = Offset(w * 0.6600, h * 0.1400);
    final Offset fastOfficeDoor = Offset(w * 0.6318, h * 0.2200);
    final Offset target = Offset(targetNorm.dx * w, targetNorm.dy * h);

    const double fastCorrXNorm = 0.6318;
    const double crossWalkYNorm = 0.3527;
    const double mainCorrYNorm = 0.5588;
    const double westCorrXNorm = 0.2334;
    const double lobbyXNorm = 0.5303;

    final double fastCorrX = w * fastCorrXNorm;
    final double crossWalkY = h * crossWalkYNorm;
    final double mainCorrY = h * mainCorrYNorm;
    final double westCorrX = w * westCorrXNorm;
    final double lobbyX = w * lobbyXNorm;

    final path = Path();
    path.moveTo(fastOfficeStart.dx, fastOfficeStart.dy);

    final String roomName = selectedRoom ?? groundRoomAt(targetNorm.dx, targetNorm.dy);
    final bool isInsideFastOffice = roomName == 'FAST OFFICE' ||
        (targetNorm.dx >= 0.622 && targetNorm.dx <= 0.724 && targetNorm.dy <= 0.188);

    if (isInsideFastOffice) {
      path.lineTo(target.dx, target.dy);
    } else {
      // 1. Exit FAST Office through its designated west door onto corridor (X = 647)
      path.lineTo(fastOfficeDoor.dx, fastOfficeDoor.dy);

      // 2. Identify open outdoor courtyard circulation areas (Garden, Bleachers, Terrace)
      final bool isOutsideGarden = roomName == 'GARDEN' ||
          (targetNorm.dx >= 0.450 && targetNorm.dx <= 0.605 && targetNorm.dy < 0.360);
      final bool isOutsideBleachersOrTerrace = roomName == 'BLEACHERS' || roomName == 'TERRACE' ||
          (targetNorm.dx >= 0.320 && targetNorm.dx < 0.450 && targetNorm.dy < 0.360);

      if (isOutsideGarden || isOutsideBleachersOrTerrace) {
        // Courtyard is open outdoor area: route directly across courtyard to target
        path.lineTo(fastCorrX, target.dy);
        path.lineTo(target.dx, target.dy);
      } else if (roomName.contains('Hallway') || roomName == 'LOBBY') {
        // Open hallways / Lobby
        path.lineTo(fastCorrX, crossWalkY);
        if (targetNorm.dy <= crossWalkYNorm + 0.05) {
          path.lineTo(target.dx, crossWalkY);
          path.lineTo(target.dx, target.dy);
        } else if (targetNorm.dx <= westCorrXNorm + 0.05) {
          path.lineTo(westCorrX, crossWalkY);
          path.lineTo(westCorrX, target.dy);
          path.lineTo(target.dx, target.dy);
        } else if (targetNorm.dx >= 0.45 && targetNorm.dx <= 0.60) {
          path.lineTo(lobbyX, crossWalkY);
          path.lineTo(lobbyX, target.dy);
          path.lineTo(target.dx, target.dy);
        } else {
          path.lineTo(fastCorrX, mainCorrY);
          path.lineTo(target.dx, mainCorrY);
          path.lineTo(target.dx, target.dy);
        }
      } else {
        // Enclosed indoor room: route strictly along grid corridors and enter through room's designated door
        final doorData = _getGroundRoomDoor(roomName, targetNorm);
        final Offset targetDoor = Offset(doorData.door.dx * w, doorData.door.dy * h);
        final Offset targetHallway = Offset(doorData.hallway.dx * w, doorData.hallway.dy * h);

        if (doorData.hallway.dx >= fastCorrXNorm - 0.02 && doorData.hallway.dy <= crossWalkYNorm + 0.02) {
          // Top-right wing (JMA, ROTC, CSG, Canteen)
          path.lineTo(fastCorrX, targetHallway.dy);
          if ((targetHallway.dx - fastCorrX).abs() > 1.0) {
            path.lineTo(targetHallway.dx, targetHallway.dy);
          }
        } else if (doorData.hallway.dy <= crossWalkYNorm + 0.02 && doorData.hallway.dx >= westCorrXNorm - 0.02) {
          // North row rooms off cross walkway (CR, El Chabacano)
          path.lineTo(fastCorrX, crossWalkY);
          path.lineTo(targetHallway.dx, crossWalkY);
          if ((targetHallway.dy - crossWalkY).abs() > 1.0) {
            path.lineTo(targetHallway.dx, targetHallway.dy);
          }
        } else if (doorData.hallway.dx <= westCorrXNorm + 0.02) {
          // West wing rooms (HM rooms, JPCS, GAD)
          path.lineTo(fastCorrX, crossWalkY);
          path.lineTo(westCorrX, crossWalkY);
          path.lineTo(westCorrX, targetHallway.dy);
          if ((targetHallway.dx - westCorrX).abs() > 1.0) {
            path.lineTo(targetHallway.dx, targetHallway.dy);
          }
        } else if (doorData.hallway.dx >= 0.45 && doorData.hallway.dx <= 0.60 && doorData.hallway.dy <= mainCorrYNorm) {
          // Central lobby row (Lobby, Registrar, Cashier, MIS)
          path.lineTo(fastCorrX, crossWalkY);
          path.lineTo(lobbyX, crossWalkY);
          path.lineTo(lobbyX, targetHallway.dy);
          if ((targetHallway.dx - lobbyX).abs() > 1.0) {
            path.lineTo(targetHallway.dx, targetHallway.dy);
          }
        } else {
          // Main corridor row (Room 108, 107, RDE, Women's CR, OSAS, 119, Accre, Guidance, Dean's, 109, 106, 104, Elec, Guard)
          path.lineTo(fastCorrX, mainCorrY);
          path.lineTo(targetHallway.dx, mainCorrY);
          if ((targetHallway.dy - mainCorrY).abs() > 1.0) {
            path.lineTo(targetHallway.dx, targetHallway.dy);
          }
        }

        // Pass through room door
        if ((targetDoor.dx - targetHallway.dx).abs() > 1.0 || (targetDoor.dy - targetHallway.dy).abs() > 1.0) {
          path.lineTo(targetDoor.dx, targetDoor.dy);
        }

        // Connect to pin inside room
        if ((target.dx - targetDoor.dx).abs() > 1.0 || (target.dy - targetDoor.dy).abs() > 1.0) {
          path.lineTo(target.dx, target.dy);
        }
      }
    }

    final glow = Paint()
      ..color = kGoogleRed.withValues(alpha: 0.30)
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
