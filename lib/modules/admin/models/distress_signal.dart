import 'dart:convert';
import 'package:flutter/material.dart';

enum DistressUrgency { critical, high, moderate }
enum DistressStatus { active, dispatched, resolved }

class DistressSignal {
  final String id;
  final String studentId;
  final String studentName;
  final String program;
  final String yearLevel;
  final String phoneNumber;
  final int floor; // 0: Ground Floor, 1: Second Floor
  final String roomName;
  final Offset position; // Normalized coordinates (0.0 to 1.0)
  final String emergencyType;
  final DistressUrgency urgency;
  DistressStatus status;
  final String reqTime; // user_reqtime formatted string
  final DateTime timestamp;

  DistressSignal({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.program,
    required this.yearLevel,
    required this.phoneNumber,
    required this.floor,
    required this.roomName,
    required this.position,
    required this.emergencyType,
    required this.urgency,
    this.status = DistressStatus.active,
    required this.reqTime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get urgencyLabel {
    switch (urgency) {
      case DistressUrgency.critical:
        return 'CRITICAL';
      case DistressUrgency.high:
        return 'HIGH';
      case DistressUrgency.moderate:
        return 'MODERATE';
    }
  }

  Color get urgencyColor {
    switch (urgency) {
      case DistressUrgency.critical:
        return const Color(0xFFE50914);
      case DistressUrgency.high:
        return const Color(0xFFFF9100);
      case DistressUrgency.moderate:
        return const Color(0xFFFFD600);
    }
  }

  String get statusLabel {
    switch (status) {
      case DistressStatus.active:
        return 'ACTIVE DISTRESS';
      case DistressStatus.dispatched:
        return 'DISPATCHED';
      case DistressStatus.resolved:
        return 'RESOLVED';
    }
  }

  factory DistressSignal.fromMap(Map<String, dynamic> map) {
    int floorVal = int.tryParse(map['floor']?.toString() ?? '0') ?? 0;
    double posX = double.tryParse(map['coord_x']?.toString() ?? '') ?? 0.5;
    double posY = double.tryParse(map['coord_y']?.toString() ?? '') ?? 0.5;
    String room = map['room_name']?.toString() ?? 'Campus Grounds';
    String emergencyType = map['emergency_type']?.toString() ?? 'Emergency Distress Call';
    String phone = map['phone_number']?.toString() ?? map['stud_phoneno']?.toString() ?? '09123456789';

    if (map['user_role'] != null) {
      final userRoleStr = map['user_role'].toString().trim();
      if (userRoleStr.startsWith('{') && userRoleStr.endsWith('}')) {
        try {
          final decoded = jsonDecode(userRoleStr);
          if (decoded is Map) {
            if (decoded['floor'] != null) floorVal = int.tryParse(decoded['floor'].toString()) ?? floorVal;
            if (decoded['x'] != null) posX = double.tryParse(decoded['x'].toString()) ?? posX;
            if (decoded['y'] != null) posY = double.tryParse(decoded['y'].toString()) ?? posY;
            if (decoded['room'] != null) room = decoded['room'].toString();
            if (decoded['type'] != null) emergencyType = decoded['type'].toString();
            if (decoded['phone'] != null) phone = decoded['phone'].toString();
          }
        } catch (_) {}
      }
    }

    final urgStr = (map['urgency'] ?? emergencyType).toString().toUpperCase();
    DistressUrgency urgency = DistressUrgency.critical;
    if (urgStr.contains('HIGH')) urgency = DistressUrgency.high;
    if (urgStr.contains('MODERATE') || urgStr.contains('LOW')) urgency = DistressUrgency.moderate;

    final statusStr = (map['stud_status'] ?? map['status'])?.toString().toUpperCase() ?? '';
    DistressStatus status = DistressStatus.active;
    if (statusStr.contains('DISPATCH')) status = DistressStatus.dispatched;
    if (statusStr.contains('RESOLVE')) status = DistressStatus.resolved;

    return DistressSignal(
      id: map['id']?.toString() ?? map['record_id']?.toString() ?? 'DS-${map['stud_id'] ?? DateTime.now().millisecondsSinceEpoch}',
      studentId: map['stud_id']?.toString() ?? map['student_id']?.toString() ?? 'Unknown ID',
      studentName: map['stud_name']?.toString() ??
          map['complete_name']?.toString() ??
          map['stud_fullname']?.toString() ??
          map['student_name']?.toString() ??
          '${map['stud_fn'] ?? ''} ${map['stud_ln'] ?? ''}'.trim(),
      program: map['stud_program']?.toString() ?? map['program']?.toString() ?? 'BSCS',
      yearLevel: map['stud_yrlevel']?.toString() ?? map['year_level']?.toString() ?? '1st Year',
      phoneNumber: phone,
      floor: floorVal,
      roomName: room,
      position: Offset(posX, posY),
      emergencyType: emergencyType,
      urgency: urgency,
      status: status,
      reqTime: map['stud_reqtime']?.toString() ?? map['user_reqtime']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

class HeatPoint {
  final double normX;
  final double normY;
  final double intensity; // 0.0 to 1.0
  final double radius;

  const HeatPoint({
    required this.normX,
    required this.normY,
    required this.intensity,
    this.radius = 90.0,
  });
}

class EmergencyHistoryRecord {
  final String id;
  final String studentId;
  final String completeName; // from fast_stud_record
  final String program;
  final String yearLevel;
  final String userReqTime; // user_reqtime
  final String roomName;
  final int floor;
  final String emergencyCategory;
  final String status;
  final String? responderNotes;

  const EmergencyHistoryRecord({
    required this.id,
    required this.studentId,
    required this.completeName,
    required this.program,
    required this.yearLevel,
    required this.userReqTime,
    required this.roomName,
    required this.floor,
    required this.emergencyCategory,
    required this.status,
    this.responderNotes,
  });

  factory EmergencyHistoryRecord.fromMap(Map<String, dynamic> map) {
    String roomName = map['room_name']?.toString() ?? map['location']?.toString() ?? 'Campus Grounds';
    int floorVal = int.tryParse(map['floor']?.toString() ?? '0') ?? 0;
    String category = map['emergency_type']?.toString() ?? map['category']?.toString() ?? 'Medical Emergency';

    if (map['user_role'] != null) {
      final userRoleStr = map['user_role'].toString().trim();
      if (userRoleStr.startsWith('{') && userRoleStr.endsWith('}')) {
        try {
          final decoded = jsonDecode(userRoleStr);
          if (decoded is Map) {
            if (decoded['room'] != null) roomName = decoded['room'].toString();
            if (decoded['floor'] != null) floorVal = int.tryParse(decoded['floor'].toString()) ?? floorVal;
            if (decoded['type'] != null) category = decoded['type'].toString();
          }
        } catch (_) {}
      }
    }

    final rawStatus = (map['stud_status'] ?? map['status'])?.toString().toUpperCase() ?? '';
    String status = 'RESOLVED';
    if (rawStatus.contains('ACTIVE')) {
      status = 'ACTIVE DISTRESS';
    } else if (rawStatus.contains('DISPATCH')) {
      status = 'DISPATCHED';
    }

    return EmergencyHistoryRecord(
      id: map['id']?.toString() ?? map['record_id']?.toString() ?? 'REC-${DateTime.now().millisecondsSinceEpoch}',
      studentId: map['stud_id']?.toString() ?? map['student_id']?.toString() ?? '202601234',
      completeName: map['stud_name']?.toString() ??
          map['complete_name']?.toString() ??
          map['stud_fullname']?.toString() ??
          map['student_name']?.toString() ??
          '${map['stud_fn'] ?? ''} ${map['stud_ln'] ?? ''}'.trim().replaceAll(RegExp(r'\s+'), ' '),
      program: map['stud_program']?.toString() ?? map['program']?.toString() ?? 'BSCS',
      yearLevel: map['stud_yrlevel']?.toString() ?? map['year_level']?.toString() ?? '4th Year',
      userReqTime: (map['user_reqtime']?.toString() ?? map['stud_reqtime']?.toString() ?? map['created_at']?.toString() ?? '2026-10-12 10:30:00')
          .replaceAll('T', ' ')
          .split('.')
          .first,
      roomName: roomName,
      floor: floorVal,
      emergencyCategory: category,
      status: status,
      responderNotes: map['responder_notes']?.toString() ?? map['notes']?.toString(),
    );
  }

}

/// Heat Map via amount of incidents
List<HeatPoint> computeDynamicHeatPoints(List<DistressSignal> signals, int floor) {
  final floorSignals = signals.where((s) => s.floor == floor && s.status != DistressStatus.resolved).toList();
  return floorSignals.map((s) {
    final double intensity = s.urgency == DistressUrgency.critical
        ? 0.95
        : (s.urgency == DistressUrgency.high ? 0.75 : 0.55);
    return HeatPoint(
      normX: s.position.dx,
      normY: s.position.dy,
      intensity: intensity,
      radius: 110.0,
    );
  }).toList();
}
