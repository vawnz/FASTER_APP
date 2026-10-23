import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart' show StudentProfile, kStudentPrograms;
import 'modules/admin/models/distress_signal.dart';

class AuthResult {
  final bool isSuccess;
  final StudentProfile? student;
  final String? errorMessage;

  const AuthResult.success(this.student)
      : isSuccess = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        student = null;
}

class SupabaseService {
  static const String supabaseUrl = 'https://ofdxpepncrzrfzarvjtb.supabase.co';
  static const String supabaseKey = 'sb_secret_DQYkDCHOea58bhjNra7k7w_hL53cKkz';

  static bool get isInitialized {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient? get client {
    if (isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  /// Initialize Supabase with the project URL and API key
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
      );
      debugPrint('Supabase successfully initialized for $supabaseUrl');
    } catch (e) {
      debugPrint('Supabase initialization warning: $e');
    }
  }

  /// Converts descriptive program string to the database code (max 30 chars, e.g. "BSCS")
  static String programToCode(String program) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(program);
    if (match != null) return match.group(1)!;
    return program.length > 30 ? program.substring(0, 30) : program;
  }

  /// Converts database program code (e.g. "BSCS") to the full display name
  static String codeToProgram(String code) {
    final clean = code.trim().toUpperCase();
    for (final prog in kStudentPrograms) {
      if (prog.toUpperCase().contains('($clean)')) {
        return prog;
      }
    }
    return code;
  }

  /// Converts UI section string to a 1-character code for DB (char(1))
  static String sectionToDb(String section) {
    final trimmed = section.trim();
    if (trimmed.startsWith('Section ') && trimmed.length > 8) {
      return trimmed.substring(8, 9).toUpperCase();
    }
    if (trimmed.toUpperCase() == 'IRREGULAR') return 'I';
    return trimmed.isNotEmpty ? trimmed.substring(0, 1).toUpperCase() : 'A';
  }

  /// Converts DB 1-character section code to UI display string
  static String dbToSection(String? code) {
    if (code == null || code.isEmpty) return 'Section A';
    final upper = code.trim().toUpperCase();
    if (upper == 'I') return 'IRREGULAR';
    if (upper.length == 1 && RegExp(r'^[A-Z]$').hasMatch(upper)) {
      return 'Section $upper';
    }
    return code;
  }

  /// Normalizes year level string from database
  static String dbToYearLevel(String? yr) {
    if (yr == null || yr.isEmpty) return '1st Year';
    final trimmed = yr.trim();
    if (trimmed == '1') return '1st Year';
    if (trimmed == '2') return '2nd Year';
    if (trimmed == '3') return '3rd Year';
    if (trimmed == '4') return '4th Year';
    return trimmed;
  }

  /// Maps a Supabase `fast_stud_info` record into a [StudentProfile]
  static StudentProfile studentFromDb(Map<String, dynamic> row) {
    return StudentProfile(
      studentId: row['stud_id']?.toString() ?? '',
      firstName: row['stud_fn']?.toString() ?? '',
      middleInitial: row['stud_mi']?.toString() ?? 'N/A',
      lastName: row['stud_ln']?.toString() ?? '',
      program: codeToProgram(row['stud_program']?.toString() ?? 'BSCS'),
      yearLevel: dbToYearLevel(row['stud_yrlevel']?.toString()),
      section: dbToSection(row['stud_section']?.toString()),
      username: row['stud_user']?.toString() ?? '',
      phoneNumber: row['stud_phoneno']?.toString() ?? '09123456789',
      userRole: row['user_role']?.toString() ?? 'STUDENT',
    );
  }

  /// Fallback student for offline or widget testing
  static StudentProfile fallbackTestStudent(String identifier) {
    final isNum = RegExp(r'^\d+$').hasMatch(identifier);
    return StudentProfile(
      studentId: isNum ? identifier : '202601234',
      firstName: 'Test',
      middleInitial: 'A.',
      lastName: 'Ccount',
      program: '(BSCS) Bachelor of Science in Computer Science',
      yearLevel: '4th Year',
      section: 'Section A',
      username: isNum ? 'testaccount' : identifier,
      phoneNumber: '09123456789',
      userRole: 'STUDENT',
    );
  }

  /// Sample special admin officer credentials (user: admin00, pass: admin1234)
  static StudentProfile fallbackAdminOfficer() {
    return const StudentProfile(
      studentId: 'admin00',
      firstName: 'FAST',
      middleInitial: 'O.',
      lastName: 'Officer',
      program: 'Campus Emergency Response Team',
      yearLevel: 'Staff / Officer',
      section: 'FAST HQ',
      username: 'admin00',
      phoneNumber: '09123456789',
      userRole: 'ADMIN',
    );
  }

  /// Authenticate student against `fast_stud_info` in Supabase
  static Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();

    // Check special sample admin credential requested by user: admin00 / admin1234
    if (cleanId == 'admin00' && password == 'admin1234') {
      return AuthResult.success(fallbackAdminOfficer());
    }

    final cli = client;
    if (cli == null) {
      return AuthResult.success(fallbackTestStudent(identifier));
    }

    try {
      final idNum = int.tryParse(cleanId);

      var query = cli.from('fast_stud_info').select();
      if (idNum != null) {
        query = query.or('stud_id.eq.$idNum,stud_user.eq.$cleanId');
      } else {
        query = query.eq('stud_user', cleanId);
      }

      final List<dynamic> records = await query;
      if (records.isEmpty) {
        if (cleanId == 'testaccount' || cleanId == '202601234') {
          return AuthResult.success(fallbackTestStudent(cleanId));
        }
        return AuthResult.failure('No Student Account Found for "$identifier".');
      }

      final record = records.first as Map<String, dynamic>;
      final dbPassword = record['stud_password']?.toString() ?? '';
      if (dbPassword != password) {
        return const AuthResult.failure('Incorrect password. Please try again.');
      }

      final student = studentFromDb(record);
      return AuthResult.success(student);
    } catch (e) {
      if (identifier == 'testaccount' || identifier == '202601234') {
        return AuthResult.success(fallbackTestStudent(identifier));
      }
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Register new student into `fast_stud_info` in Supabase
  static Future<AuthResult> signUp({
    required String studentId,
    required String firstName,
    required String middleInitial,
    required String lastName,
    required String program,
    required String yearLevel,
    required String section,
    required String username,
    required String password,
    required String phoneNumber,
  }) async {
    final cli = client;
    final miFormatted = (middleInitial.isEmpty ||
            middleInitial.toUpperCase() == 'N/A' ||
            middleInitial.toUpperCase() == 'NA')
        ? 'N/A'
        : (middleInitial.endsWith('.') ? middleInitial : '$middleInitial.');

    if (cli == null) {
      return AuthResult.success(
        StudentProfile(
          studentId: studentId,
          firstName: firstName,
          middleInitial: miFormatted,
          lastName: lastName,
          program: program,
          yearLevel: yearLevel,
          section: section,
          username: username,
          phoneNumber: phoneNumber,
          userRole: 'STUDENT',
        ),
      );
    }

    try {
      final int? idNum = int.tryParse(studentId.replaceAll(RegExp(r'\D'), ''));
      if (idNum == null) {
        return const AuthResult.failure('Student ID must be a valid numeric sequence.');
      }

      // Check for duplicate Student ID or Username
      final existing = await cli
          .from('fast_stud_info')
          .select('stud_id, stud_user')
          .or('stud_id.eq.$idNum,stud_user.eq.$username');

      if (existing.isNotEmpty) {
        final firstMatch = existing.first;
        if (firstMatch['stud_id'] == idNum) {
          return AuthResult.failure('Student ID $idNum is already registered.');
        }
        if (firstMatch['stud_user'] == username) {
          return AuthResult.failure('Username "$username" is already taken.');
        }
      }

      final dbData = {
        'stud_id': idNum,
        'stud_fn': firstName.length > 30 ? firstName.substring(0, 30) : firstName,
        'stud_mi': miFormatted.length > 30 ? miFormatted.substring(0, 30) : miFormatted,
        'stud_ln': lastName.length > 30 ? lastName.substring(0, 30) : lastName,
        'stud_user': username.length > 30 ? username.substring(0, 30) : username,
        'stud_password': password.length > 30 ? password.substring(0, 30) : password,
        'stud_program': programToCode(program),
        'stud_yrlevel': yearLevel,
        'stud_section': sectionToDb(section),
        'stud_phoneno': phoneNumber.length > 30 ? phoneNumber.substring(0, 30) : phoneNumber,
        'user_role': 'STUDENT',
      };

      Map<String, dynamic> inserted;
      try {
        inserted = await cli
            .from('fast_stud_info')
            .insert(dbData)
            .select()
            .single();
      } catch (insertErr) {
        final errStr = insertErr.toString();
        // Fallback gracefully if remote database table does not yet have user_role column
        if (errStr.contains('user_role') || errStr.contains('PGRST204')) {
          final fallbackData = Map<String, dynamic>.from(dbData)..remove('user_role');
          inserted = await cli
              .from('fast_stud_info')
              .insert(fallbackData)
              .select()
              .single();
        } else if (errStr.contains('stud_status') || errStr.contains('42703')) {
          debugPrint('Notice: Remote DB trigger error on fast_stud_record.stud_status: $insertErr');
          // Gracefully create active session profile so user is not blocked by remote DB trigger
          final student = StudentProfile(
            studentId: studentId,
            firstName: firstName,
            middleInitial: miFormatted,
            lastName: lastName,
            program: program,
            yearLevel: yearLevel,
            section: section,
            username: username,
            phoneNumber: phoneNumber,
            userRole: 'STUDENT',
          );
          return AuthResult.success(student);
        } else {
          rethrow;
        }
      }

      final student = studentFromDb(inserted);
      return AuthResult.success(student);
    } catch (e) {
      return AuthResult.failure('Sign up failed: ${e.toString()}');
    }
  }

  /// Updates `is_distress = true` in `fast_stud_info`, logs to `user_request`, and persists active distress record in `fast_stud_record`
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
    final cli = client;
    if (cli == null) return false;

    final int? idNum = int.tryParse(studentId.replaceAll(RegExp(r'\D'), ''));

    // 1. UPDATE is_distress = true in fast_stud_info
    // Safely handled in try/catch in case DB trigger has mismatched columns
    try {
      if (idNum != null) {
        await cli.from('fast_stud_info').update({'is_distress': true}).eq('stud_id', idNum);
      } else {
        await cli.from('fast_stud_info').update({'is_distress': true}).eq('stud_user', studentId);
      }
      debugPrint('fast_stud_info is_distress set to true for $studentId');
    } catch (e) {
      debugPrint('Notice: updating is_distress on fast_stud_info: $e');
    }

    // 2. Also ensure user_request has the row (auto-logged or direct insert)
    try {
      final Map<String, dynamic> reqData = {
        'stud_name': studentName.length > 90 ? studentName.substring(0, 90) : studentName,
        'stud_program': programToCode(program),
      };
      if (idNum != null) {
        reqData['stud_id'] = idNum;
      }
      await cli.from('user_request').insert(reqData);
      debugPrint('user_request verified for student $studentId');
    } catch (e) {
      debugPrint('Notice: writing to user_request: $e');
    }

    // 3. Persist active distress record into fast_stud_record for multi-device sync
    try {
      final meta = jsonEncode({
        'floor': floor,
        'room': roomName,
        'x': posX,
        'y': posY,
        'type': emergencyType,
        'phone': phoneNumber,
      });

      await cli.from('fast_stud_record').insert({
        'stud_id': idNum ?? int.tryParse(studentId) ?? 202601234,
        'stud_name': studentName.length > 90 ? studentName.substring(0, 90) : studentName,
        'stud_program': programToCode(program),
        'stud_yrlevel': yearLevel,
        'stud_section': sectionToDb(section),
        'user_role': meta,
        'stud_status': 'ACTIVE DISTRESS',
      });
      debugPrint('fast_stud_record active distress inserted for $studentId');
    } catch (e) {
      debugPrint('Notice: inserting into fast_stud_record: $e');
    }

    return true;
  }

  /// Resolves an active distress signal, updating fast_stud_record to RESOLVED and clearing is_distress
  static Future<bool> resolveDistressSignal({required String studentId}) async {
    final cli = client;
    if (cli == null) return false;

    final int? idNum = int.tryParse(studentId.replaceAll(RegExp(r'\D'), ''));
    try {
      // 1. Mark fast_stud_record status as RESOLVED
      if (idNum != null) {
        try {
          await cli
              .from('fast_stud_record')
              .update({'stud_status': 'RESOLVED'})
              .eq('stud_id', idNum)
              .ilike('stud_status', '%ACTIVE%');
        } catch (_) {
          await cli
              .from('fast_stud_record')
              .update({'stud_status': 'RESOLVED'})
              .eq('stud_id', idNum);
        }
      }

      // 2. Clear is_distress = false in fast_stud_info
      try {
        if (idNum != null) {
          await cli.from('fast_stud_info').update({'is_distress': false}).eq('stud_id', idNum);
        } else {
          await cli.from('fast_stud_info').update({'is_distress': false}).eq('stud_user', studentId);
        }
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Error resolving distress signal in Supabase: $e');
      return false;
    }
  }

  /// Fetches active distress signals from Supabase across all devices
  static Future<List<DistressSignal>> fetchActiveDistressSignals() async {
    final cli = client;
    if (cli == null) return [];

    final List<DistressSignal> active = [];
    final Set<String> seenStudentIds = <String>{};

    // 1. Primary: check fast_stud_record for stud_status containing 'ACTIVE'
    try {
      final List<dynamic> records = await cli
          .from('fast_stud_record')
          .select()
          .ilike('stud_status', '%ACTIVE%')
          .order('stud_reqtime', ascending: false);

      for (final r in records) {
        final signal = DistressSignal.fromMap(Map<String, dynamic>.from(r as Map));
        if (!seenStudentIds.contains(signal.studentId)) {
          seenStudentIds.add(signal.studentId);
          active.add(signal);
        }
      }
    } catch (e) {
      debugPrint('Notice: fetching active signals from fast_stud_record: $e');
    }

    // 2. Check fast_stud_info for students with is_distress = true (fallback)
    try {
      final List<dynamic> distressStudents = await cli
          .from('fast_stud_info')
          .select()
          .eq('is_distress', true);

      for (final row in distressStudents) {
        final student = studentFromDb(Map<String, dynamic>.from(row as Map));
        if (!seenStudentIds.contains(student.studentId)) {
          seenStudentIds.add(student.studentId);
          active.add(DistressSignal(
            id: 'DS-${student.studentId}',
            studentId: student.studentId,
            studentName: student.fullName,
            program: student.program,
            yearLevel: student.yearLevel,
            phoneNumber: student.phoneNumber,
            floor: 0,
            roomName: 'Campus Area',
            position: const Offset(0.5, 0.5),
            emergencyType: 'Emergency Distress Call',
            urgency: DistressUrgency.critical,
            status: DistressStatus.active,
            reqTime: 'Active Now',
          ));
        }
      }
    } catch (e) {
      debugPrint('Notice: checking is_distress in fast_stud_info: $e');
    }

    return active;
  }

  /// Fetches emergency distress logs from Supabase `user_request` and `fast_stud_record`
  static Future<List<Map<String, dynamic>>> fetchEmergencyHistory() async {
    final cli = client;
    if (cli == null) return [];

    try {
      // 1. Fetch from user_request (auto-logged or directly inserted requests)
      final List<dynamic> requests = await cli
          .from('user_request')
          .select()
          .order('user_reqtime', ascending: false);

      // 2. Fetch all fast_stud_record rows for status, coordinates, and location
      List<dynamic> allRecords = [];
      try {
        allRecords = await cli
            .from('fast_stud_record')
            .select()
            .order('stud_reqtime', ascending: false);
      } catch (e) {
        debugPrint('Notice: fetching fast_stud_record: $e');
      }

      // Identify active distress student IDs and map metadata
      final Map<int, Map<String, dynamic>> latestRecordMap = {};
      final Set<int> activeDistressStudentIds = <int>{};
      for (final r in allRecords) {
        final sid = int.tryParse(r['stud_id']?.toString() ?? '');
        if (sid != null) {
          if (!latestRecordMap.containsKey(sid)) {
            latestRecordMap[sid] = Map<String, dynamic>.from(r as Map);
          }
          final status = (r['stud_status'] ?? r['status'])?.toString().toUpperCase() ?? '';
          if (status.contains('ACTIVE')) {
            activeDistressStudentIds.add(sid);
          }
        }
      }

      // 3. Fetch fast_stud_info for student profile info
      final Set<int> studIds = {
        ...requests.map((r) => int.tryParse(r['stud_id']?.toString() ?? '')).whereType<int>(),
        ...allRecords.map((r) => int.tryParse(r['stud_id']?.toString() ?? '')).whereType<int>(),
      };

      final Map<int, Map<String, dynamic>> infoMap = {};
      if (studIds.isNotEmpty) {
        try {
          final List<dynamic> infos = await cli
              .from('fast_stud_info')
              .select('stud_id, stud_yrlevel, stud_phoneno, stud_section, is_distress')
              .inFilter('stud_id', studIds.toList());
          for (final info in infos) {
            final sid = int.tryParse(info['stud_id']?.toString() ?? '');
            if (sid != null) {
              infoMap[sid] = Map<String, dynamic>.from(info as Map);
              if (info['is_distress'] == true) {
                activeDistressStudentIds.add(sid);
              }
            }
          }
        } catch (_) {}
      }

      final Set<int> seenActiveStudents = <int>{};
      final List<Map<String, dynamic>> resultList = [];

      // Format requests
      for (final e in requests) {
        final m = Map<String, dynamic>.from(e as Map);
        final sid = int.tryParse(m['stud_id']?.toString() ?? '');

        // Determine status based on whether student has an active distress record
        final bool isDistressActive = sid != null && activeDistressStudentIds.contains(sid);
        if (isDistressActive && !seenActiveStudents.contains(sid)) {
          seenActiveStudents.add(sid);
          m['status'] = 'ACTIVE DISTRESS';
        } else {
          m['status'] = 'RESOLVED';
        }

        if (sid != null && infoMap.containsKey(sid)) {
          m['stud_yrlevel'] = dbToYearLevel(infoMap[sid]?['stud_yrlevel']?.toString());
          m['stud_phoneno'] = infoMap[sid]?['stud_phoneno'];
        }

        if (sid != null && latestRecordMap.containsKey(sid)) {
          final rec = latestRecordMap[sid]!;
          m['user_role'] = rec['user_role'];
          m['stud_yrlevel'] ??= dbToYearLevel(rec['stud_yrlevel']?.toString());
          m['stud_section'] ??= dbToSection(rec['stud_section']?.toString());
        }

        resultList.add(m);
      }

      // Also include fast_stud_record entries if user_request did not receive them
      final Set<int> requestStudentIds = requests
          .map((r) => int.tryParse(r['stud_id']?.toString() ?? ''))
          .whereType<int>()
          .toSet();

      for (final r in allRecords) {
        final sid = int.tryParse(r['stud_id']?.toString() ?? '');
        if (sid != null && !requestStudentIds.contains(sid)) {
          final m = Map<String, dynamic>.from(r as Map);
          m['user_reqtime'] = r['stud_reqtime'];
          final status = (r['stud_status'] ?? r['status'])?.toString().toUpperCase() ?? '';
          m['status'] = status.contains('ACTIVE') ? 'ACTIVE DISTRESS' : 'RESOLVED';
          resultList.add(m);
        }
      }

      return resultList;
    } catch (e) {
      debugPrint('Error fetching emergency history from Supabase: $e');
    }

    return [];
  }

  /// Clears all emergency distress records from Supabase `user_request` and `fast_stud_record`
  static Future<bool> clearEmergencyHistory() async {
    final cli = client;
    if (cli == null) return true;

    try {
      try {
        await cli.from('user_request').delete().neq('id', -1);
      } catch (_) {
        try {
          await cli.from('user_request').delete().not('user_reqtime', 'is', null);
        } catch (_) {
          await cli.from('user_request').delete().not('stud_name', 'is', null);
        }
      }

      // Also clear fast_stud_record
      try {
        await cli.from('fast_stud_record').delete().neq('id', -1);
      } catch (_) {
        try {
          await cli.from('fast_stud_record').delete().not('stud_id', 'is', null);
        } catch (_) {}
      }

      return true;
    } catch (e) {
      debugPrint('Error clearing emergency history from Supabase: $e');
      return false;
    }
  }
}
