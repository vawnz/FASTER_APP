import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase_service.dart';
import '../models/distress_signal.dart';

class DistressSyncService {
  static final ValueNotifier<List<DistressSignal>> activeSignalsNotifier =
      ValueNotifier<List<DistressSignal>>([]);

  static final ValueNotifier<List<EmergencyHistoryRecord>> historyRecordsNotifier =
      ValueNotifier<List<EmergencyHistoryRecord>>([]);

  static final ValueNotifier<DistressSignal?> newAlertNotifier =
      ValueNotifier<DistressSignal?>(null);

  static RealtimeChannel? _realtimeChannel;
  static Timer? _pollingTimer;
  static bool _isInitialized = false;
  static final Set<String> _knownSignalIds = <String>{};

  /// Initialize real-time synchronization and polling
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Initial fetch
    await refresh();

    // Start Realtime channel & background polling if not running under automated test
    if (WidgetsBinding.instance.runtimeType.toString() != 'AutomatedTestWidgetsFlutterBinding') {
      _startRealtimeChannel();
      _startPollingTimer();
    }
  }

  /// Sends a distress signal from student to Supabase & notifies admins
  static Future<bool> sendDistressSignal({
    required String studentId,
    required String studentName,
    required String program,
    required String yearLevel,
    required String phoneNumber,
    required String roomName,
    required int floor,
    required double posX,
    required double posY,
    required String emergencyType,
    String section = 'Section A',
  }) async {
    final now = DateTime.now();
    final String signalId = 'DS-${now.millisecondsSinceEpoch}';
    final String formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final distress = DistressSignal(
      id: signalId,
      studentId: studentId,
      studentName: studentName,
      program: program,
      yearLevel: yearLevel,
      phoneNumber: phoneNumber,
      floor: floor,
      roomName: roomName,
      position: Offset(posX, posY),
      emergencyType: emergencyType,
      urgency: DistressUrgency.critical,
      status: DistressStatus.active,
      reqTime: formattedTime,
      timestamp: now,
    );

    final historyItem = EmergencyHistoryRecord(
      id: signalId,
      studentId: studentId,
      completeName: studentName,
      program: program,
      yearLevel: yearLevel,
      userReqTime: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $formattedTime:00',
      roomName: roomName,
      floor: floor,
      emergencyCategory: emergencyType,
      status: 'ACTIVE DISTRESS',
      responderNotes: 'Live request transmitted by user via FASTER Mobile App.',
    );

    // 1. Immediately reflect in memory for instant local UI responsiveness
    _knownSignalIds.add(signalId);
    activeSignalsNotifier.value = [distress, ...activeSignalsNotifier.value];
    historyRecordsNotifier.value = [historyItem, ...historyRecordsNotifier.value];

    // 2. Trigger high-priority live alert notification for any open admin session
    triggerAlertNotification(distress);

    // 3. Persist asynchronously in Supabase fast_stud_record table
    try {
      await SupabaseService.sendDistressSignal(
        studentId: studentId,
        studentName: studentName,
        program: program,
        yearLevel: yearLevel,
        phoneNumber: phoneNumber,
        roomName: roomName,
        floor: floor,
        posX: posX,
        posY: posY,
        emergencyType: emergencyType,
        section: section,
      );
    } catch (e) {
      debugPrint('Supabase insert warning: $e');
    }

    return true;
  }

  /// Triggers haptic, sound, and floating notification on admin screen
  static void triggerAlertNotification(DistressSignal signal) {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    newAlertNotifier.value = signal;
  }

  /// Dismisses active alert banner
  static void clearAlertNotification() {
    newAlertNotifier.value = null;
  }

  /// Refreshes distress signals and history from Supabase fast_stud_record
  static Future<void> refresh() async {
    try {
      final historyData = await SupabaseService.fetchEmergencyHistory();
      final records = historyData.map((m) => EmergencyHistoryRecord.fromMap(m)).toList();

      final activeSignals = await SupabaseService.fetchActiveDistressSignals();

      // Check for any newly incoming distress signal not seen before
      for (final sig in activeSignals) {
        if (!_knownSignalIds.contains(sig.id)) {
          _knownSignalIds.add(sig.id);
          triggerAlertNotification(sig);
        }
      }

      // Merge with any in-memory active signals not yet resolved
      final existingActive = activeSignalsNotifier.value;
      final Set<String> loadedIds = activeSignals.map((s) => s.id).toSet();
      final List<DistressSignal> merged = [
        ...activeSignals,
        ...existingActive.where((s) => !loadedIds.contains(s.id) && s.status != DistressStatus.resolved),
      ];

      activeSignalsNotifier.value = merged;

      // Merge history
      final existingHistory = historyRecordsNotifier.value;
      final Set<String> loadedHistIds = records.map((r) => r.id).toSet();
      final Set<String> loadedStudentIds = records.map((r) => r.studentId).toSet();

      // Preserve local roomName and floor if DB record only had default room name
      final Map<String, EmergencyHistoryRecord> localInfo = {
        for (final h in existingHistory)
          if (h.roomName != 'Campus Grounds') h.studentId: h
      };

      final List<EmergencyHistoryRecord> enrichedRecords = records.map((r) {
        if (r.roomName == 'Campus Grounds' && localInfo.containsKey(r.studentId)) {
          final local = localInfo[r.studentId]!;
          return EmergencyHistoryRecord(
            id: r.id,
            studentId: r.studentId,
            completeName: r.completeName,
            program: r.program,
            yearLevel: r.yearLevel,
            userReqTime: r.userReqTime,
            roomName: local.roomName,
            floor: local.floor,
            emergencyCategory: local.emergencyCategory,
            status: r.status,
            responderNotes: r.responderNotes,
          );
        }
        return r;
      }).toList();

      final List<EmergencyHistoryRecord> mergedHistory = [
        ...enrichedRecords,
        ...existingHistory.where((r) => !loadedHistIds.contains(r.id) && !loadedStudentIds.contains(r.studentId)),
      ];

      historyRecordsNotifier.value = mergedHistory;
    } catch (e) {
      debugPrint('DistressSyncService refresh error: $e');
    }
  }

  /// Resolves an active distress signal and clears is_distress in fast_stud_info
  static Future<void> resolveDistressSignal(String studentId) async {
    activeSignalsNotifier.value = activeSignalsNotifier.value
        .where((s) => s.studentId != studentId)
        .toList();

    // Immediately update in-memory history status to RESOLVED
    historyRecordsNotifier.value = historyRecordsNotifier.value.map((rec) {
      if (rec.studentId == studentId || rec.studentId.contains(studentId)) {
        return EmergencyHistoryRecord(
          id: rec.id,
          studentId: rec.studentId,
          completeName: rec.completeName,
          program: rec.program,
          yearLevel: rec.yearLevel,
          userReqTime: rec.userReqTime,
          roomName: rec.roomName,
          floor: rec.floor,
          emergencyCategory: rec.emergencyCategory,
          status: 'RESOLVED',
          responderNotes: 'Resolved by FAST Officer.',
        );
      }
      return rec;
    }).toList();

    try {
      await SupabaseService.resolveDistressSignal(studentId: studentId);
      await refresh();
    } catch (e) {
      debugPrint('Error resolving distress signal in Supabase: $e');
    }
  }

  /// Clears all emergency history records in memory and Supabase
  static Future<bool> clearHistory() async {
    historyRecordsNotifier.value = [];
    final success = await SupabaseService.clearEmergencyHistory();
    return success;
  }

  /// Supabase Realtime WebSocket subscription
  static void _startRealtimeChannel() {
    final cli = SupabaseService.client;
    if (cli == null) return;

    try {
      _realtimeChannel = cli.channel('public:distress_sync')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_request',
          callback: (payload) {
            debugPrint('Realtime PostgresChangeEvent on user_request received');
            refresh();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'fast_stud_info',
          callback: (payload) {
            debugPrint('Realtime PostgresChangeEvent on fast_stud_info received');
            refresh();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'fast_stud_record',
          callback: (payload) {
            debugPrint('Realtime PostgresChangeEvent on fast_stud_record received');
            refresh();
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('Realtime subscription warning: $e');
    }
  }

  /// Background polling timer (every 3 seconds) for guaranteed synchronization
  static void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      refresh();
    });
  }

  static void dispose() {
    _pollingTimer?.cancel();
    _realtimeChannel?.unsubscribe();
  }
}
