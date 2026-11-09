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

  static final ValueNotifier<DistressSignal?> focusedSignalNotifier =
      ValueNotifier<DistressSignal?>(null);

  static RealtimeChannel? _realtimeChannel;
  static Timer? _pollingTimer;
  static bool _isInitialized = false;
  static final Set<String> _knownSignalIds = <String>{};
  static final Set<String> _resolvedStudentIds = <String>{};
  static final Set<String> _resolvedSignalIds = <String>{};
  static final Map<String, String> _resolvedStudentReqTimes = <String, String>{};

  static String _signalSignature(DistressSignal s) =>
      '${s.studentId}_${s.floor}_${s.roomName}_${s.reqTime}';

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
    _knownSignalIds.add(_signalSignature(distress));
    _resolvedStudentIds.remove(studentId);
    _resolvedStudentReqTimes.remove(studentId);
    _resolvedSignalIds.remove(signalId);
    activeSignalsNotifier.value = [
      distress,
      ...activeSignalsNotifier.value.where((s) => s.studentId != studentId),
    ];
    historyRecordsNotifier.value = [
      historyItem,
      ...historyRecordsNotifier.value.where((h) => h.studentId != studentId),
    ];

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
      await refresh();
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

    focusedSignalNotifier.value = signal;
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

      final existingActive = activeSignalsNotifier.value;
      final Map<String, DistressSignal> localActiveByStudent = {
        for (final s in existingActive)
          if (s.roomName != 'Campus Grounds') s.studentId: s,
      };

      // Exclude any distress signals that were resolved locally or in tombstone
      final activeFiltered = <DistressSignal>[];
      for (final rawSig in activeSignals) {
        if (rawSig.status == DistressStatus.resolved) {
          continue;
        }
        // Enrich with local floor/room if DB record temporarily had default Campus Grounds
        DistressSignal s = rawSig;
        if (s.roomName == 'Campus Grounds' && localActiveByStudent.containsKey(s.studentId)) {
          final local = localActiveByStudent[s.studentId]!;
          s = DistressSignal(
            id: s.id,
            studentId: s.studentId,
            studentName: s.studentName,
            program: s.program,
            yearLevel: s.yearLevel,
            phoneNumber: s.phoneNumber,
            floor: local.floor,
            roomName: local.roomName,
            position: local.position,
            emergencyType: local.emergencyType,
            urgency: s.urgency,
            status: s.status,
            reqTime: s.reqTime,
            timestamp: s.timestamp,
          );
        }

        if (_resolvedStudentIds.contains(s.studentId)) {
          final resolvedTime = _resolvedStudentReqTimes[s.studentId];
          if (resolvedTime != null && resolvedTime == s.reqTime) {
            continue;
          }
          // Student sent a brand-new distress signal with a new timestamp; lift tombstones
          _resolvedStudentIds.remove(s.studentId);
          _resolvedStudentReqTimes.remove(s.studentId);
          _resolvedSignalIds.remove(s.id);
        } else if (_resolvedSignalIds.contains(s.id)) {
          continue;
        }

        activeFiltered.add(s);
      }

      // Check for any newly incoming distress signal not seen before
      for (final sig in activeFiltered) {
        final sigKey = _signalSignature(sig);
        if (!_knownSignalIds.contains(sig.id) && !_knownSignalIds.contains(sigKey)) {
          _knownSignalIds.add(sig.id);
          _knownSignalIds.add(sigKey);
          triggerAlertNotification(sig);
        } else {
          _knownSignalIds.add(sig.id);
          _knownSignalIds.add(sigKey);
        }
      }

      // Merge with any in-memory active signals not yet resolved
      final Set<String> loadedIds = activeFiltered.map((s) => s.id).toSet();
      final Set<String> loadedActiveStudentIds = activeFiltered.map((s) => s.studentId).toSet();
      final List<DistressSignal> merged = [
        ...activeFiltered,
        ...existingActive.where((s) =>
            !loadedIds.contains(s.id) &&
            !loadedActiveStudentIds.contains(s.studentId) &&
            s.status != DistressStatus.resolved &&
            !_resolvedSignalIds.contains(s.id)),
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
  static Future<void> resolveDistressSignal(String studentId, {String? signalId}) async {
    // Add to tombstone sets so polling and Realtime updates never bring it back
    _resolvedStudentIds.add(studentId);
    if (signalId != null && signalId.isNotEmpty) {
      _resolvedSignalIds.add(signalId);
    }

    // Also record any active signals matching this studentId or signalId
    for (final s in activeSignalsNotifier.value) {
      if (s.studentId == studentId || (signalId != null && s.id == signalId)) {
        _resolvedStudentIds.add(s.studentId);
        _resolvedStudentReqTimes[s.studentId] = s.reqTime;
        _resolvedSignalIds.add(s.id);
      }
    }

    activeSignalsNotifier.value = activeSignalsNotifier.value
        .where((s) =>
            s.studentId != studentId &&
            s.id != signalId &&
            !_resolvedStudentIds.contains(s.studentId) &&
            !_resolvedSignalIds.contains(s.id))
        .toList();

    // Dismiss active banner if it corresponds to this resolved emergency
    if (newAlertNotifier.value != null) {
      final currentAlert = newAlertNotifier.value!;
      if (currentAlert.studentId == studentId ||
          currentAlert.id == signalId ||
          _resolvedStudentIds.contains(currentAlert.studentId) ||
          _resolvedSignalIds.contains(currentAlert.id)) {
        clearAlertNotification();
      }
    }

    // Immediately update in-memory history status to RESOLVED
    historyRecordsNotifier.value = historyRecordsNotifier.value.map((rec) {
      if (rec.studentId == studentId ||
          rec.studentId.contains(studentId) ||
          (signalId != null && rec.id == signalId)) {
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
      await SupabaseService.resolveDistressSignal(studentId: studentId, signalId: signalId);
      await refresh();
    } catch (e) {
      debugPrint('Error resolving distress signal in Supabase: $e');
    }
  }

  /// Clears all emergency history records in memory and Supabase
  static Future<bool> clearHistory() async {
    historyRecordsNotifier.value = [];
    _resolvedStudentIds.clear();
    _resolvedStudentReqTimes.clear();
    _resolvedSignalIds.clear();
    final success = await SupabaseService.clearEmergencyHistory();
    return success;
  }

  /// Supabase Realtime WebSocket subscription
  static void _startRealtimeChannel() {
    if (!SupabaseService.isConfigured) return;
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
      if (SupabaseService.isConfigured) {
        refresh();
      }
    });
  }

  static void dispose() {
    _pollingTimer?.cancel();
    _realtimeChannel?.unsubscribe();
  }
}
