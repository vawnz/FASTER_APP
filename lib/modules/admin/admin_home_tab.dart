import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../map/ground_floor.dart';
import '../map/second_floor.dart';
import 'admin_heat_map_painter.dart';
import 'models/distress_signal.dart';
import 'services/distress_sync_service.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab>
    with SingleTickerProviderStateMixin {
  int _floor = 0; // 0: Ground Floor, 1: Second Floor
  late AnimationController _pulseController;
  final TransformationController _transformController = TransformationController();

  late List<DistressSignal> _distressSignals;
  DistressSignal? _selectedSignal;
  Offset? _pinnedLocation;
  String? _pinnedRoom;
  bool _showHeatMap = true;
  bool _showBeacons = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (WidgetsBinding.instance.runtimeType.toString() != 'AutomatedTestWidgetsFlutterBinding') {
      _pulseController.repeat();
    } else {
      _pulseController.value = 0.5;
    }

    _distressSignals = DistressSyncService.activeSignalsNotifier.value;
    DistressSyncService.activeSignalsNotifier.addListener(_onSignalsUpdated);
    DistressSyncService.initialize();
  }

  void _onSignalsUpdated() {
    if (mounted) {
      setState(() {
        _distressSignals = DistressSyncService.activeSignalsNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    DistressSyncService.activeSignalsNotifier.removeListener(_onSignalsUpdated);
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _switchFloor(int newFloor) {
    if (_floor == newFloor) return;
    setState(() {
      _floor = newFloor;
      _selectedSignal = null;
      _pinnedLocation = null;
      _pinnedRoom = null;
    });
  }

  void _selectSignal(DistressSignal signal) {
    setState(() {
      _floor = signal.floor;
      _selectedSignal = signal;
    });
    _showIncidentSheet(signal);
  }

  void _dispatchTeam(DistressSignal signal) {
    setState(() {
      signal.status = DistressStatus.dispatched;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'FAST TEAM DISPATCHED: Responders en route to ${signal.roomName} for ${signal.studentName}.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resolveSignal(DistressSignal signal) {
    setState(() {
      signal.status = DistressStatus.resolved;
      if (_selectedSignal?.id == signal.id) {
        _selectedSignal = null;
      }
    });
    DistressSyncService.resolveDistressSignal(signal.studentId);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Text(
          'Incident ${signal.id} at ${signal.roomName} marked as RESOLVED.',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showIncidentSheet(DistressSignal sig) {
    final dark = isGlassDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: dark ? const Color(0xF2141622) : Colors.white.withValues(alpha: 0.95),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header row with status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sig.urgencyColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.emergency, color: sig.urgencyColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sig.emergencyType,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: dark ? Colors.white : const Color(0xFF16181F),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${sig.roomName} • ${sig.floor == 0 ? "Ground Floor" : "Second Floor"}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: dark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sig.urgencyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sig.urgencyColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            sig.urgencyLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: sig.urgencyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: dark ? Colors.white12 : Colors.black12, height: 1),
                    const SizedBox(height: 14),

                    // Student Information Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1E2130) : const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.person,
                            label: 'Student Name',
                            value: sig.studentName,
                            dark: dark,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.badge,
                            label: 'Student ID',
                            value: sig.studentId,
                            dark: dark,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.school,
                            label: 'Program & Year',
                            value: '${sig.program} • ${sig.yearLevel}',
                            dark: dark,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.access_time,
                            label: 'Request Time',
                            value: sig.reqTime,
                            dark: dark,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.phone,
                            label: 'Contact Number',
                            value: sig.phoneNumber,
                            dark: dark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons: Dispatch & Resolve
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(modalCtx);
                              _dispatchTeam(sig);
                            },
                            icon: const Icon(Icons.flash_on, size: 18),
                            label: const Text(
                              'DISPATCH TEAM',
                              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGoogleRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(modalCtx);
                            _resolveSignal(sig);
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text(
                            'RESOLVE',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool dark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kGoogleRed),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.white60 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);
    final activeSignals = _distressSignals.where((s) => s.status == DistressStatus.active).toList();
    final activeOnFloor = activeSignals.where((s) => s.floor == _floor).toList();

    return Column(
      children: [
        // Top Header & Monitoring Status Bar
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Column(
            children: [
              // Active Distress Notification Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFB71C1C).withValues(alpha: dark ? 0.85 : 0.90),
                      const Color(0xFFE50914).withValues(alpha: dark ? 0.85 : 0.90),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE EMERGENCY MONITORING',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${activeSignals.length} Active Distress Signal${activeSignals.length == 1 ? '' : 's'} Detected',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, color: Color(0xFF00E676), size: 10),
                          SizedBox(width: 4),
                          Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Floor Switcher & Layer Controls
              Row(
                children: [
                  Expanded(
                    child: _buildFloorTab(
                      label: 'GROUND FLOOR',
                      floorIndex: 0,
                      activeCount: activeSignals.where((s) => s.floor == 0).length,
                      dark: dark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFloorTab(
                      label: 'SECOND FLOOR',
                      floorIndex: 1,
                      activeCount: activeSignals.where((s) => s.floor == 1).length,
                      dark: dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Heat Map & Beacon View Toggles
              Row(
                children: [
                  _buildTogglePill(
                    icon: Icons.local_fire_department,
                    label: 'Heat Map',
                    active: _showHeatMap,
                    activeColor: const Color(0xFFFF5722),
                    dark: dark,
                    onTap: () => setState(() => _showHeatMap = !_showHeatMap),
                  ),
                  const SizedBox(width: 6),
                  _buildTogglePill(
                    icon: Icons.notifications_active,
                    label: 'Live Beacons',
                    active: _showBeacons,
                    activeColor: kGoogleRed,
                    dark: dark,
                    onTap: () => setState(() => _showBeacons = !_showBeacons),
                  ),
                  const Spacer(),
                  // Heat Map Legend indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x991E2130) : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: dark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Heat:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFC107),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5722),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE50914),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Map Layout
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InteractiveViewer(
              key: ValueKey(_floor),
              transformationController: _transformController,
              constrained: false,
              minScale: _floor == 1 ? 0.15 : 0.35,
              maxScale: 4.5,
              boundaryMargin: EdgeInsets.all(_floor == 1 ? 250 : 120),
              child: SizedBox(
                width: 1024.0,
                height: 723.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final normX = details.localPosition.dx / constraints.maxWidth;
                        final normY = details.localPosition.dy / constraints.maxHeight;

                        // Check if tapped near an existing distress signal beacon
                        final signalsOnFloor = _distressSignals.where((s) => s.floor == _floor).toList();
                        DistressSignal? tappedSignal;
                        for (final sig in signalsOnFloor) {
                          final dx = (sig.position.dx - normX).abs();
                          final dy = (sig.position.dy - normY).abs();
                          if (dx < 0.045 && dy < 0.045) {
                            tappedSignal = sig;
                            break;
                          }
                        }

                        if (tappedSignal != null) {
                          _selectSignal(tappedSignal);
                        } else {
                          // Tap on room/area
                          final isOff = _floor == 0
                              ? isGroundOffBoundaries(normX, normY)
                              : isSecondOffBoundaries(normX, normY);
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
                          final room = _floor == 0 ? groundRoomAt(normX, normY) : secondRoomAt(normX, normY);
                          setState(() {
                            _selectedSignal = null;
                            _pinnedLocation = Offset(normX, normY);
                            _pinnedRoom = room;
                          });
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pinned: $room (Floor ${_floor == 0 ? "Ground" : "2nd"})'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              _floor == 0
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
                                    floor: _floor,
                                    heatPoints: computeDynamicHeatPoints(_distressSignals, _floor),
                                    distressSignals: _distressSignals,
                                    pulseValue: _pulseController.value,
                                    selectedSignal: _selectedSignal,
                                    pinnedLocation: _pinnedLocation,
                                    pinnedRoom: _pinnedRoom,
                                    showHeatMap: _showHeatMap,
                                    showBeacons: _showBeacons,
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

        // Live Incident Counter
        Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: dark ? const Color(0xCC161824) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: kGoogleRed, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Active Distress Signals (${activeOnFloor.length} on ${_floor == 0 ? "Ground" : "2nd"} Floor)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : const Color(0xFF16181F),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedSignal != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedSignal = null),
                      child: Text(
                        'Clear Selection',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (activeOnFloor.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'No active distress signals on ${_floor == 0 ? "Ground Floor" : "Second Floor"}.',
                      style: TextStyle(
                        fontSize: 12,
                        color: dark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: activeOnFloor.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final sig = activeOnFloor[idx];
                      final isSelected = _selectedSignal?.id == sig.id;

                      return GestureDetector(
                        onTap: () => _selectSignal(sig),
                        child: Container(
                          width: 230,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (dark ? const Color(0xFF2C1920) : const Color(0xFFFFEBEE))
                                : (dark ? const Color(0xFF1E2130) : const Color(0xFFF5F6FA)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? kGoogleRed : (dark ? Colors.white10 : Colors.black12),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: sig.urgencyColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.crisis_alert, color: sig.urgencyColor, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      sig.studentName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: dark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${sig.roomName} • ${sig.reqTime}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: dark ? Colors.white60 : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      sig.emergencyType,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: sig.urgencyColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloorTab({
    required String label,
    required int floorIndex,
    required int activeCount,
    required bool dark,
  }) {
    final isSelected = _floor == floorIndex;

    return GestureDetector(
      onTap: () => _switchFloor(floorIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? kGoogleRed
              : (dark ? const Color(0xCC1A1C28) : Colors.white.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? kGoogleRed
                : (dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kGoogleRed.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              floorIndex == 0 ? Icons.looks_one : Icons.looks_two,
              color: isSelected ? Colors.white : (dark ? Colors.white70 : Colors.black87),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (dark ? Colors.white70 : Colors.black87),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : kGoogleRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    color: isSelected ? kGoogleRed : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTogglePill({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.20)
              : (dark ? const Color(0x991E2130) : Colors.white.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : (dark ? Colors.white12 : Colors.black12),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? activeColor : (dark ? Colors.white60 : Colors.black54)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? (dark ? Colors.white : activeColor) : (dark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
