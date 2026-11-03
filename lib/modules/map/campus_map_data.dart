import 'package:flutter/material.dart';

/// Categories of areas according to the architectural layout specifications
enum CampusAreaCategory {
  /// Pink (#FF66C4) - Assigned for classrooms, laboratories, offices, CRs
  room,

  /// Orange (#FF715F) - Assigned for gardens, parking, bleachers, outdoor paths
  outdoor,

  /// Green (#00BF63) - Assigned for hallways, lobbies, entrances
  indoor,

  /// Black - Assigned for out of bounds areas that cannot be pinned
  outOfBound,
}

/// Precise definition of a campus area with exact pixel dimensions on the 1024x723 canvas
class CampusMapArea {
  final String id;
  final String name;
  final int floor; // 0: Ground Floor, 1: Second Floor
  final CampusAreaCategory category;
  final Rect rect; // Absolute pixel coordinates on 1024x723 blueprint
  final String dimensionLabel; // Formatted as: width x height pixel

  const CampusMapArea({
    required this.id,
    required this.name,
    required this.floor,
    required this.category,
    required this.rect,
    required this.dimensionLabel,
  });

  /// Center point of the area in pixels
  Offset get center => rect.center;

  /// Normalized center point (0.0 to 1.0) for placing pins accurately at the center
  Offset get normalizedCenter => Offset(center.dx / 1024.0, center.dy / 723.0);

  bool containsPixel(double px, double py) => rect.contains(Offset(px, py));
  bool containsNormalized(double nx, double ny) => containsPixel(nx * 1024.0, ny * 723.0);

  Color get categoryColor {
    switch (category) {
      case CampusAreaCategory.room:
        return const Color(0xFFFF66C4); // pink (#ff66c4)
      case CampusAreaCategory.outdoor:
        return const Color(0xFFFF715F); // orange (#ff715f)
      case CampusAreaCategory.indoor:
        return const Color(0xFF00BF63); // green (#00bf63)
      case CampusAreaCategory.outOfBound:
        return Colors.black;
    }
  }

  String get categoryLabel {
    switch (category) {
      case CampusAreaCategory.room:
        return 'Room';
      case CampusAreaCategory.outdoor:
        return 'Outdoor Area';
      case CampusAreaCategory.indoor:
        return 'Non-room Indoor';
      case CampusAreaCategory.outOfBound:
        return 'Out of Bounds';
    }
  }
}

/// Ground Floor Areas with exact dimensions from blueprint guidelines
const List<CampusMapArea> kGroundFloorAreas = [
  // --- OUTDOOR PERIMETERS & PATHS (Orange #FF715F) ---
  CampusMapArea(
    id: 'g_outdoor_top',
    name: 'North Outdoor Perimeter',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(104, 20, 871, 41),
    dimensionLabel: '871x41px',
  ),
  CampusMapArea(
    id: 'g_outdoor_north_walkway',
    name: 'North Walkway Outdoor',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(104, 61, 561, 17),
    dimensionLabel: '561x17px',
  ),
  CampusMapArea(
    id: 'g_outdoor_west_strip',
    name: 'West Outdoor Perimeter',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(104, 78, 22, 470),
    dimensionLabel: '22x470px',
  ),
  CampusMapArea(
    id: 'g_outdoor_east_canteen',
    name: 'East Canteen Outdoor',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(894, 55, 25, 164),
    dimensionLabel: '25x164px',
  ),
  CampusMapArea(
    id: 'g_outdoor_east_strip',
    name: 'East Outdoor Perimeter',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(948, 218, 24, 323),
    dimensionLabel: '24x323px',
  ),
  CampusMapArea(
    id: 'g_garden',
    name: 'GARDEN',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(443, 73, 220, 198),
    dimensionLabel: '220x198px',
  ),
  CampusMapArea(
    id: 'g_bleachers',
    name: 'BLEACHERS',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(362, 73, 76, 118),
    dimensionLabel: '76x118px',
  ),
  CampusMapArea(
    id: 'g_student_lounge',
    name: 'STUDENT LOUNGE',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(676, 218, 273, 59),
    dimensionLabel: '273x59px',
  ),
  CampusMapArea(
    id: 'g_pathway',
    name: 'PATHWAY',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(105, 542, 868, 72),
    dimensionLabel: '868x72px',
  ),
  CampusMapArea(
    id: 'g_parking_area',
    name: 'PARKING AREA',
    floor: 0,
    category: CampusAreaCategory.outdoor,
    rect: Rect.fromLTWH(105, 615, 786, 86),
    dimensionLabel: '786x86px',
  ),

  // --- NON-ROOM INDOOR AREAS (Green #00BF63) ---
  CampusMapArea(
    id: 'g_left_wing_hallway',
    name: 'LEFT WING HALLWAY',
    floor: 0,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(216, 78, 52, 306),
    dimensionLabel: '52x306px',
  ),
  CampusMapArea(
    id: 'g_lobby',
    name: 'LOBBY',
    floor: 0,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(502, 281, 138, 151),
    dimensionLabel: '138x151px',
  ),
  CampusMapArea(
    id: 'g_central_hallway_left',
    name: 'CENTRAL HALLWAY LEFT',
    floor: 0,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(218, 386, 280, 48),
    dimensionLabel: '280x48px',
  ),
  CampusMapArea(
    id: 'g_central_hallway_right',
    name: 'CENTRAL HALLWAY RIGHT',
    floor: 0,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(644, 386, 294, 48),
    dimensionLabel: '294x48px',
  ),
  CampusMapArea(
    id: 'g_lobby_entrance',
    name: 'LOBBY ENTRANCE',
    floor: 0,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(483, 434, 121, 96),
    dimensionLabel: '121x96px',
  ),

  // --- FAR LEFT WING ROOMS & STAIRS ---
  CampusMapArea(
    id: 'g_service_stairs',
    name: 'SERVICE / STAIRS',
    floor: 0,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(126, 78, 85, 88),
    dimensionLabel: '85x88px',
  ),
  CampusMapArea(
    id: 'g_hm_lab_cold',
    name: 'HM LABORATORY COLD KITCHEN',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(126, 167, 85, 105),
    dimensionLabel: '72x105px',
  ),
  CampusMapArea(
    id: 'g_hm_lab_hot',
    name: 'HM LABORATORY HOT KITCHEN',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(126, 277, 85, 107),
    dimensionLabel: '72x107px',
  ),
  CampusMapArea(
    id: 'g_inventory_room',
    name: 'INVENTORY ROOM',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(126, 389, 85, 140),
    dimensionLabel: '72x140px',
  ),
  CampusMapArea(
    id: 'g_hm_faculty',
    name: 'HM DEPARTMENT',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(272, 83, 85, 115),
    dimensionLabel: '75x107px',
  ),
  CampusMapArea(
    id: 'g_aihhms_office',
    name: 'AIHMS OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(272, 204, 85, 74),
    dimensionLabel: '77x74px',
  ),
  CampusMapArea(
    id: 'g_terrace',
    name: 'TERRACE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(362, 204, 63, 74),
    dimensionLabel: '63x74px',
  ),
  CampusMapArea(
    id: 'g_fast_office',
    name: 'FAST OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(670, 68, 65, 73),
    dimensionLabel: '56x73px',
  ),
  CampusMapArea(
    id: 'g_jma_office',
    name: 'JMA OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(738, 68, 48, 73),
    dimensionLabel: '44x73px',
  ),
  CampusMapArea(
    id: 'g_rotc_office',
    name: 'ROTC OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(788, 68, 48, 73),
    dimensionLabel: '44x73px',
  ),
  CampusMapArea(
    id: 'g_csg_office',
    name: 'CSG OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(838, 68, 52, 73),
    dimensionLabel: '44x73px',
  ),
  CampusMapArea(
    id: 'g_canteen_dining',
    name: 'CANTEEN DINING AREA',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(674, 149, 164, 54),
    dimensionLabel: '164x54px',
  ),
  CampusMapArea(
    id: 'g_canteen_kitchen',
    name: 'CANTEEN KITCHEN',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(840, 149, 50, 54),
    dimensionLabel: '41x54px',
  ),
  CampusMapArea(
    id: 'g_it_cs_office',
    name: 'IT / CS DEPARTMENT',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(250, 336, 120, 92),
    dimensionLabel: '97x92px',
  ),
  CampusMapArea(
    id: 'g_el_chabacano',
    name: 'EL CHABACANO',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(323, 281, 52, 50),
    dimensionLabel: '50x50px',
  ),
  CampusMapArea(
    id: 'g_cr_mid',
    name: 'CR',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(378, 282, 52, 26),
    dimensionLabel: '47x26px',
  ),
  CampusMapArea(
    id: 'g_mis',
    name: 'MIS',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(378, 336, 52, 39),
    dimensionLabel: '47x39px',
  ),
  CampusMapArea(
    id: 'g_registrar',
    name: 'REGISTRAR',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(434, 281, 64, 45),
    dimensionLabel: '26x45px',
  ),
  CampusMapArea(
    id: 'g_cashier',
    name: 'CASHIER',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(434, 336, 64, 36),
    dimensionLabel: '26x36px',
  ),
  CampusMapArea(
    id: 'g_room_108',
    name: 'ROOM 108',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(644, 336, 32, 45),
    dimensionLabel: '22x43px',
  ),
  CampusMapArea(
    id: 'g_room_107',
    name: 'ROOM 107 COM LAB',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(680, 285, 86, 90),
    dimensionLabel: '78x90px',
  ),
  CampusMapArea(
    id: 'g_rde_office',
    name: 'RDE OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(768, 285, 110, 90),
    dimensionLabel: '107x90px',
  ),
  CampusMapArea(
    id: 'g_womens_cr',
    name: "WOMEN'S CR",
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(880, 285, 62, 90),
    dimensionLabel: '56x90px',
  ),
  CampusMapArea(
    id: 'g_jpcs_room',
    name: 'JPCS OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(200, 440, 48, 48),
    dimensionLabel: '44x90px',
  ),
  CampusMapArea(
    id: 'g_gad_room',
    name: 'GAD OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(200, 488, 48, 48),
    dimensionLabel: '44x90px',
  ),
  CampusMapArea(
    id: 'g_osas',
    name: 'OSAS',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(250, 440, 60, 90),
    dimensionLabel: '54x90px',
  ),
  CampusMapArea(
    id: 'g_room_119',
    name: 'ROOM 119 COM LAB',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(312, 440, 56, 90),
    dimensionLabel: '44x90px',
  ),
  CampusMapArea(
    id: 'g_accre_office',
    name: 'ACCRE. OFFICE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(370, 440, 56, 90),
    dimensionLabel: '49x90px',
  ),
  CampusMapArea(
    id: 'g_guidance_office',
    name: 'GUIDANCE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(428, 440, 52, 45),
    dimensionLabel: '44x90px',
  ),
  CampusMapArea(
    id: 'g_deans_office',
    name: "DEAN'S OFFICE",
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(428, 485, 52, 45),
    dimensionLabel: '44x90px',
  ),
  CampusMapArea(
    id: 'g_room_109',
    name: 'ROOM 109 COM LAB',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(610, 440, 58, 90),
    dimensionLabel: '47x90px',
  ),
  CampusMapArea(
    id: 'g_room_106',
    name: 'ROOM 106 COM LAB',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(670, 440, 102, 90),
    dimensionLabel: '97x90px',
  ),
  CampusMapArea(
    id: 'g_room_104',
    name: 'ROOM 104 COM LAB',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(774, 440, 106, 90),
    dimensionLabel: '100x90px',
  ),
  CampusMapArea(
    id: 'g_elec_room',
    name: 'ELEC. ROOM',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(890, 440, 55, 90),
    dimensionLabel: '50x90px',
  ),
  CampusMapArea(
    id: 'g_fire_exit',
    name: 'FIRE EXIT',
    floor: 0,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(520, 542, 65, 45),
    dimensionLabel: '65x45px',
  ),
  CampusMapArea(
    id: 'g_guard_house',
    name: 'GUARD HOUSE',
    floor: 0,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(894, 620, 78, 78),
    dimensionLabel: '72x74px',
  ),
];

/// Second Floor Areas with exact dimensions from blueprint guidelines
const List<CampusMapArea> kSecondFloorAreas = [
  // --- NON-ROOM INDOOR HALLWAYS (Green #00BF63) ---
  CampusMapArea(
    id: 's_fire_exit_top_left',
    name: 'FIRE EXIT (Top-Left)',
    floor: 1,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(16, 70, 104, 98),
    dimensionLabel: '104x98px',
  ),
  CampusMapArea(
    id: 's_left_wing_hallway_top',
    name: '2F LEFT WING HALLWAY (NORTH)',
    floor: 1,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(101, 128, 98, 36),
    dimensionLabel: '98x36px',
  ),
  CampusMapArea(
    id: 's_left_wing_hallway',
    name: 'Second Floor Hallway',
    floor: 1,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(120, 164, 86, 242),
    dimensionLabel: '76x242px',
  ),
  CampusMapArea(
    id: 's_central_hallway',
    name: 'Second Floor Hallway',
    floor: 1,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(125, 408, 878, 46),
    dimensionLabel: '873x46px',
  ),
  CampusMapArea(
    id: 's_fire_exit_central',
    name: 'FIRE EXIT (Central / Middle)',
    floor: 1,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(590, 313, 94, 83),
    dimensionLabel: '90x83px',
  ),

  // --- ROOMS (Pink #FF66C4) ---
  CampusMapArea(
    id: 's_room_220',
    name: 'ROOM 220',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(16, 170, 104, 73),
    dimensionLabel: '102x69px',
  ),
  CampusMapArea(
    id: 's_room_219',
    name: 'ROOM 219',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(16, 245, 104, 79),
    dimensionLabel: '102x77px',
  ),
  CampusMapArea(
    id: 's_room_218',
    name: 'ROOM 218',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(16, 324, 104, 80),
    dimensionLabel: '102x76px',
  ),
  CampusMapArea(
    id: 's_room_217',
    name: 'ROOM 217 / READING ROOM',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(16, 406, 107, 156),
    dimensionLabel: '105x154px',
  ),
  CampusMapArea(
    id: 's_library_ext',
    name: 'LIBRARY EXTENSION',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(208, 126, 120, 117),
    dimensionLabel: '115x113px',
  ),
  CampusMapArea(
    id: 's_library',
    name: 'LIBRARY',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(208, 245, 147, 155),
    dimensionLabel: '143x151px',
  ),
  CampusMapArea(
    id: 's_room_211',
    name: 'ROOM 211',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(358, 311, 78, 89),
    dimensionLabel: '74x89px',
  ),
  CampusMapArea(
    id: 's_room_209',
    name: 'ROOM 209',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(436, 313, 78, 84),
    dimensionLabel: '74x82px',
  ),
  CampusMapArea(
    id: 's_room_207',
    name: 'ROOM 207',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(516, 313, 76, 84),
    dimensionLabel: '74x83px',
  ),
  CampusMapArea(
    id: 's_room_205',
    name: 'ROOM 205',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(684, 313, 78, 84),
    dimensionLabel: '77x83px',
  ),
  CampusMapArea(
    id: 's_room_203',
    name: 'ROOM 203',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(762, 313, 78, 84),
    dimensionLabel: '77x83px',
  ),
  CampusMapArea(
    id: 's_room_202',
    name: 'ROOM 202',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(839, 313, 78, 84),
    dimensionLabel: '77x83px',
  ),
  CampusMapArea(
    id: 's_mens_cr',
    name: "MEN'S CR",
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(916, 311, 80, 86),
    dimensionLabel: '78x85px',
  ),
  CampusMapArea(
    id: 's_dept',
    name: 'DEPT.',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(118, 474, 132, 88),
    dimensionLabel: '127x85px',
  ),
  CampusMapArea(
    id: 's_room_214',
    name: 'ROOM 214',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(250, 474, 78, 88),
    dimensionLabel: '75x85px',
  ),
  CampusMapArea(
    id: 's_room_213',
    name: 'ROOM 213',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(328, 474, 78, 88),
    dimensionLabel: '75x85px',
  ),
  CampusMapArea(
    id: 's_room_212',
    name: 'ROOM 212',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(404, 474, 78, 88),
    dimensionLabel: '75x85px',
  ),
  CampusMapArea(
    id: 's_room_210',
    name: 'ROOM 210',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(484, 474, 105, 88),
    dimensionLabel: '101x85px',
  ),
  CampusMapArea(
    id: 's_room_208',
    name: 'ROOM 208',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(592, 474, 102, 88),
    dimensionLabel: '97x85px',
  ),
  CampusMapArea(
    id: 's_room_206',
    name: 'ROOM 206',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(694, 474, 88, 88),
    dimensionLabel: '84x85px',
  ),
  CampusMapArea(
    id: 's_room_204',
    name: 'ROOM 204',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(784, 474, 80, 88),
    dimensionLabel: '76x85px',
  ),
  CampusMapArea(
    id: 's_room_201',
    name: 'ROOM 201',
    floor: 1,
    category: CampusAreaCategory.room,
    rect: Rect.fromLTWH(866, 474, 64, 88),
    dimensionLabel: '59x85px',
  ),
  CampusMapArea(
    id: 's_fire_exit_bottom_right',
    name: 'FIRE EXIT (Bottom-Right)',
    floor: 1,
    category: CampusAreaCategory.indoor,
    rect: Rect.fromLTWH(916, 474, 60, 88),
    dimensionLabel: '60x88px',
  ),
];

/// Returns all pinnable areas for a given floor
List<CampusMapArea> getAreasForFloor(int floor) {
  return floor == 0 ? kGroundFloorAreas : kSecondFloorAreas;
}

/// Finds the area covering the given normalized coordinates (0.0 to 1.0)
CampusMapArea? findAreaAt(int floor, double nx, double ny) {
  final areas = getAreasForFloor(floor);
  final px = nx * 1024.0;
  final py = ny * 723.0;

  for (final area in areas) {
    if (area.containsPixel(px, py)) {
      return area;
    }
  }
  return null;
}

/// Determines whether a location is outside the allowable pinnable boundary
bool isFloorOffBoundaries(int floor, double nx, double ny) {
  if (nx < 0.0 || nx > 1.0 || ny < 0.0 || ny > 1.0) return true;

  if (floor == 0) {
    // Outer black perimeter walls
    if (nx <= 0.0650 || nx >= 0.9750 || ny <= 0.0300) return true;
    if (ny >= 0.9629) {
      final bool isBottomExit = (nx >= 0.1082 && nx <= 0.2496) ||
          (nx >= 0.6656 && nx <= 0.8053) ||
          (nx >= 0.8136 && nx <= 0.8735);
      return !isBottomExit;
    }
    return false;
  } else {
    // 2F boundaries
    if (nx < 0.035 || nx > 0.975 || ny < 0.125 || ny > 0.810) {
      return true;
    }
    // Top black out of bound cavity on 2F
    if (ny < 0.400 && nx > 0.355 && nx < 0.980) {
      final area = findAreaAt(floor, nx, ny);
      return area == null;
    }
    return false;
  }
}

/// Returns the pulse color based on the number of simultaneous distress signals at a single location:
/// - 1 signal: Green pulse (#00BF63)
/// - 2 signals: Orange pulse (#FF715F)
/// - 3 or more signals: Red pulse (#E50914)
Color getDistressPulseColor(int simultaneousCount) {
  if (simultaneousCount <= 1) {
    return const Color(0xFF00BF63); // Green pulse for 1
  } else if (simultaneousCount == 2) {
    return const Color(0xFFFF715F); // Orange pulse for 2
  } else {
    return const Color(0xFFE50914); // Red pulse for 3 or more
  }
}

/// Represents a clustered group of simultaneous distress signals at a single location
class LocationDistressCluster {
  final String locationName;
  final Offset position; // Normalized coordinates (0.0 to 1.0)
  final Offset center; // Canvas pixel coordinates (0 to 1024, 0 to 723)
  final int count;
  final Color pulseColor;
  final List<dynamic> signals;

  const LocationDistressCluster({
    required this.locationName,
    required this.position,
    required this.center,
    required this.count,
    required this.pulseColor,
    required this.signals,
  });
}

/// Computes clusters of simultaneous distress signals per location on a floor
List<LocationDistressCluster> computeLocationClusters(List<dynamic> signals, int floor) {
  final floorSignals = signals.where((s) {
    if (s.floor != floor) return false;
    final st = s.status.toString().toUpperCase();
    return !st.contains('RESOLVE');
  }).toList();

  final Map<String, List<dynamic>> grouped = {};
  for (final sig in floorSignals) {
    final String room = (sig.roomName ?? '').toString().trim().toUpperCase();
    final key = room.isEmpty ? 'CAMPUS' : room;
    grouped.putIfAbsent(key, () => []).add(sig);
  }

  final areas = getAreasForFloor(floor);
  final List<LocationDistressCluster> clusters = [];

  for (final entry in grouped.entries) {
    final roomKey = entry.key;
    final sigs = entry.value;
    final int count = sigs.length;

    // Find matching area by name
    CampusMapArea? matchedArea;
    for (final area in areas) {
      final an = area.name.toUpperCase();
      if (an == roomKey || an.contains(roomKey) || roomKey.contains(an)) {
        matchedArea = area;
        break;
      }
    }

    Offset normPos;
    Offset pixelCenter;
    if (matchedArea != null) {
      normPos = matchedArea.normalizedCenter;
      pixelCenter = matchedArea.center;
    } else {
      final dynamic firstSig = sigs.first;
      final dynamic p = firstSig.position;
      if (p is Offset) {
        normPos = p;
        pixelCenter = Offset(p.dx * 1024.0, p.dy * 723.0);
      } else {
        normPos = const Offset(0.5, 0.5);
        pixelCenter = const Offset(512.0, 361.5);
      }
    }

    clusters.add(
      LocationDistressCluster(
        locationName: sigs.first.roomName?.toString() ?? roomKey,
        position: normPos,
        center: pixelCenter,
        count: count,
        pulseColor: getDistressPulseColor(count),
        signals: sigs,
      ),
    );
  }

  return clusters;
}
