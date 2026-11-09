import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/student_profile.dart';
import '../../widgets/resq_logo.dart';
import '../admin/admin_heat_map_painter.dart';
import '../admin/models/distress_signal.dart';
import '../admin/services/distress_sync_service.dart';
import 'campus_map_data.dart';
import 'ground_floor.dart';
import 'second_floor.dart';
import 'map_search.dart';


bool isFloorOffBoundaries(int floor, double x, double y) {
  return floor == 0 ? isGroundOffBoundaries(x, y) : isSecondOffBoundaries(x, y);
}

class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key});

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> with SingleTickerProviderStateMixin {
  int floor = 0;
  Offset? selectedLocation;
  String? selectedRoom;
  bool showEmergencyPath = false;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  CampusAreaCategory? _categoryFilter;
  late final AnimationController _pulseController;
  List<DistressSignal> _activeSignals = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (WidgetsBinding.instance.runtimeType.toString() != 'AutomatedTestWidgetsFlutterBinding') {
      _pulseController.repeat();
    } else {
      _pulseController.value = 0.5;
    }
    _activeSignals = DistressSyncService.activeSignalsNotifier.value;
    DistressSyncService.activeSignalsNotifier.addListener(_onSignalsUpdated);
    DistressSyncService.initialize();
  }

  void _onSignalsUpdated() {
    if (mounted) {
      setState(() {
        _activeSignals = DistressSyncService.activeSignalsNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    DistressSyncService.activeSignalsNotifier.removeListener(_onSignalsUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void selectCampusLocation(CampusLocation loc) {
    if (isFloorOffBoundaries(loc.floor, loc.coordinates.dx, loc.coordinates.dy)) {
      return;
    }
    final area = findAreaAt(loc.floor, loc.coordinates.dx, loc.coordinates.dy);
    final targetLoc = area != null ? area.normalizedCenter : loc.coordinates;

    setState(() {
      _isSearching = false;
      floor = loc.floor;
      selectedLocation = targetLoc;
      selectedRoom = loc.name;
      showEmergencyPath = false;
    });
  }

  String _getSecondFloorStaircase(Offset? loc) {
    if (loc == null) return 'Central Staircase';
    if (loc.dx <= 0.185) return 'Left Wing Staircase';
    if (loc.dx >= 0.820) return 'Right Wing Staircase';
    return 'Central Staircase';
  }

  void selectArea(CampusMapArea area) {
    setState(() {
      selectedLocation = area.normalizedCenter;
      selectedRoom = area.name;
      showEmergencyPath = false;
    });
  }

  void selectLocation(Offset location, String name) {
    if (isFloorOffBoundaries(floor, location.dx, location.dy) || name == 'Off Boundaries') {
      return;
    }
    final area = findAreaAt(floor, location.dx, location.dy);
    final targetLocation = area != null ? area.normalizedCenter : location;
    final targetName = area != null ? area.name : name;

    setState(() {
      selectedLocation = targetLocation;
      selectedRoom = targetName;
      showEmergencyPath = false;
    });
  }

  void openHelpDialog() {
    if (selectedRoom == null || selectedRoom == 'Off Boundaries') return;
    final dark = isGlassDark(context);

    final String routeInfo = floor == 0
        ? 'Responders dispatch immediately from the FAST Office on the Ground Floor.'
        : 'Responders climb up the ${_getSecondFloorStaircase(selectedLocation)} to reach $selectedRoom.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: dark ? const Color(0xFA12131A) : Colors.white.withValues(alpha: 0.96),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Icon(Icons.location_on, color: kGoogleRed, size: 50),
                    const SizedBox(height: 12),
                    Text(
                      selectedRoom!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Floor: ${floor == 0 ? "Ground Floor" : "Second Floor"}',
                      style: TextStyle(color: dark ? Colors.white60 : Colors.grey),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final room = selectedRoom ?? 'Campus Area';
                          await DistressSyncService.sendDistressSignal(
                            studentId: currentStudent.studentId,
                            studentName: currentStudent.fullName,
                            program: currentStudent.program,
                            yearLevel: currentStudent.yearLevel,
                            phoneNumber: currentStudent.phoneNumber,
                            roomName: room,
                            floor: floor,
                            posX: selectedLocation?.dx ?? 0.5,
                            posY: selectedLocation?.dy ?? 0.5,
                            emergencyType: 'Emergency Distress Call',
                            section: currentStudent.section,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFB71C1C),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                                content: Row(
                                  children: [
                                    const Icon(Icons.emergency_share, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'DISTRESS SIGNAL TRANSMITTED: FAST Officers notified at $room.',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('CALL FOR HELP', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGoogleRed,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      routeInfo,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void changeFloor(int newFloor) {
    setState(() {
      floor = newFloor;
      selectedLocation = null;
      selectedRoom = null;
      showEmergencyPath = false;
      if (newFloor == 1 && _categoryFilter == CampusAreaCategory.outdoor) {
        _categoryFilter = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  const ResQLogo(height: 38, animate: false),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x99181A24) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _isSearching = true;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_rounded, color: kGoogleRed, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Search Location',
                                style: TextStyle(
                                  color: dark ? Colors.white : const Color(0xFF202124),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(
                    'CVSU-CCC Map',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : const Color(0xFF16181F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: _FloorButton(
                      label: 'GROUND FLOOR',
                      icon: Icons.looks_one,
                      selected: floor == 0,
                      onTap: () => changeFloor(0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FloorButton(
                      label: 'SECOND FLOOR',
                      icon: Icons.looks_two,
                      selected: floor == 1,
                      onTap: () => changeFloor(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InteractiveViewer(
                  key: ValueKey(floor),
                  constrained: false,
                  minScale: floor == 1 ? 0.15 : 0.35,
                  maxScale: 4.5,
                  boundaryMargin: EdgeInsets.all(floor == 1 ? 250 : 120),
                  child: SizedBox(
                    width: 1024.0,
                    height: 723.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) {
                            final x = details.localPosition.dx / constraints.maxWidth;
                            final y = details.localPosition.dy / constraints.maxHeight;
                            final isOff = floor == 0 ? isGroundOffBoundaries(x, y) : isSecondOffBoundaries(x, y);
                            if (isOff) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.block, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Location pinning is disabled in out-of-boundary areas.'),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF1A1A1A),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            final area = findAreaAt(floor, x, y);
                            if (area != null) {
                              if (area.category == CampusAreaCategory.outOfBound) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.block, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Location pinning is disabled in out-of-boundary areas.'),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF1A1A1A),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              selectArea(area);
                            } else {
                              final room = floor == 0 ? groundRoomAt(x, y) : secondRoomAt(x, y);
                              selectLocation(Offset(x, y), room);
                            }
                          },
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  floor == 0
                                      ? 'assets/maps/ground_floor.png'
                                      : 'assets/maps/second_floor.png',
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: AdminHeatMapPainter(
                                        floor: floor,
                                        heatPoints: computeDynamicHeatPoints(_activeSignals, floor),
                                        distressSignals: _activeSignals,
                                        pulseValue: _pulseController.value,
                                        pinnedLocation: selectedLocation,
                                        pinnedRoom: selectedRoom,
                                        showHeatMap: true,
                                        showBeacons: true,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Radio Button Location Selector below the Map Layer
            Expanded(
              flex: 2,
              child: _buildRadioSelectorBelowMap(dark),
            ),
          ],
        ),

        // Modernized Blurred Search Overlay
        if (_isSearching)
          _buildSearchOverlay(),
      ],
    );
  }

  Widget _buildRadioSelectorBelowMap(bool dark) {
    final areas = getAreasForFloor(floor).where((a) {
      if (a.category == CampusAreaCategory.outOfBound) return false;
      if (_categoryFilter != null && a.category != _categoryFilter) return false;
      return true;
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xEE161824) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Header with Category Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 16, color: kGoogleRed),
                const SizedBox(width: 6),
                Text(
                  'PIN LOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: dark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const Spacer(),
                // Filter Pills
                _buildCategoryPill('ALL', null, null, dark),
                const SizedBox(width: 4),
                _buildCategoryPill('ROOMS', CampusAreaCategory.room, const Color(0xFFFF66C4), dark),
                const SizedBox(width: 4),
                _buildCategoryPill('INDOOR', CampusAreaCategory.indoor, const Color(0xFF00BF63), dark),
                if (floor == 0) ...[
                  const SizedBox(width: 4),
                  _buildCategoryPill('OUTDOOR', CampusAreaCategory.outdoor, const Color(0xFFFF715F), dark),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.8),

          // 2. Scrollable Radio List of Areas
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: areas.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 36),
              itemBuilder: (context, index) {
                final area = areas[index];
                final isSelected = selectedRoom == area.name;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => selectArea(area),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Row(
                      children: [
                        // Radio button
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: Radio<String>(
                            value: area.name,
                            // ignore: deprecated_member_use
                            groupValue: selectedRoom,
                            activeColor: area.categoryColor,
                            // ignore: deprecated_member_use
                            onChanged: (_) => selectArea(area),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Category dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: area.categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Area Name
                        Expanded(
                          child: Text(
                            area.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? (dark ? Colors.white : const Color(0xFF16181F))
                                  : (dark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Active Emergency Call Banner (when a location is pinned)
          if (selectedRoom != null && selectedRoom != 'Off Boundaries')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1C1E2B) : const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: dark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.navigation, color: kGoogleRed, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedRoom!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : const Color(0xFF16181F),
                          ),
                        ),
                        Text(
                          floor == 0
                              ? 'Dispatch from FAST Office • Ground Floor'
                              : 'Climbing up ${_getSecondFloorStaircase(selectedLocation)} • 2nd Floor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: dark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: openHelpDialog,
                    icon: const Icon(Icons.phone, size: 14),
                    label: const Text('CALL FOR HELP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGoogleRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, CampusAreaCategory? cat, Color? color, bool dark) {
    final isSelected = _categoryFilter == cat;
    return GestureDetector(
      onTap: () => setState(() => _categoryFilter = isSelected ? null : cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? (dark ? Colors.white24 : Colors.black12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color ?? (dark ? Colors.white24 : Colors.black12),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? Colors.white
                    : (dark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    final dark = isGlassDark(context);
    final query = _searchQuery.trim().toLowerCase();
    final List<CampusLocation> matches = kCampusLocations.where((loc) {
      if (query.isEmpty) return true;
      final name = loc.name.toLowerCase();
      final sub = loc.subtitle.toLowerCase();
      final keywords = loc.keywords.join(' ').toLowerCase();
      return name.contains(query) || sub.contains(query) || keywords.contains(query);
    }).toList();

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: Colors.black.withValues(alpha: dark ? 0.65 : 0.40),
            child: SafeArea(
              child: Column(
                children: [
                  // Modernized Search Bar Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xEE161822) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: dark ? Colors.white : const Color(0xFF202124),
                          ),
                          tooltip: 'Back to Map',
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: dark ? Colors.white : const Color(0xFF202124),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Where are you? (e.g. Room 107, Library, FAST)...',
                              hintStyle: TextStyle(
                                color: dark ? Colors.white54 : Colors.grey.shade500,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: dark ? Colors.white60 : Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),

                  // Prediction count / hint header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          query.isEmpty
                              ? 'ALL CAMPUS LOCATIONS (${matches.length})'
                              : 'PREDICTED RESULTS (${matches.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Prediction List
                  Expanded(
                    child: matches.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xEE161822)
                                    : Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: dark ? Colors.white54 : Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No location found matching "$_searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: dark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try searching by room number (e.g. 107, 219), department, lab, or office name.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dark ? Colors.white60 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                            itemCount: matches.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final loc = matches[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => selectCampusLocation(loc),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: dark
                                          ? const Color(0xCC1A1C28)
                                          : Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: dark
                                            ? Colors.white.withValues(alpha: 0.10)
                                            : Colors.black.withValues(alpha: 0.06),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: dark ? 0.25 : 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: loc.isFireExit
                                                ? (dark ? const Color(0x33FF1744) : const Color(0xFFFFEBEE))
                                                : loc.floor == 0
                                                    ? (dark ? const Color(0x3300E676) : const Color(0xFFE8F5E9))
                                                    : (dark ? const Color(0x332979FF) : const Color(0xFFE3F2FD)),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: loc.isFireExit
                                                  ? const Color(0xFFE50914).withValues(alpha: 0.5)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: loc.isFireExit
                                              ? Icon(
                                                  Icons.emergency,
                                                  color: dark ? const Color(0xFFFF5252) : const Color(0xFFC62828),
                                                  size: 20,
                                                )
                                              : Text(
                                                  loc.floor == 0 ? 'G' : '2F',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 13,
                                                    color: loc.floor == 0
                                                        ? (dark ? const Color(0xFF69F0AE) : const Color(0xFF2E7D32))
                                                        : (dark ? const Color(0xFF82B1FF) : const Color(0xFF1565C0)),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                loc.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5,
                                                  color: dark ? Colors.white : const Color(0xFF202124),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${loc.floor == 0 ? "Ground Floor" : "Second Floor"} • ${loc.subtitle}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: dark ? Colors.white70 : Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.navigation_rounded, size: 18, color: kGoogleRed),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// FLOOR BUTTON WIDGET
// ============================================================

class _FloorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FloorButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected
              ? null
              : (dark
                  ? const Color(0x99181A24)
                  : Colors.white.withValues(alpha: 0.82)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFFE50914)
                : (dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08)),
            width: 1.0,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: const Color(0xFFE50914).withValues(alpha: 0.40),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? Colors.white
                  : (dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: selected
                    ? Colors.white
                    : (dark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
