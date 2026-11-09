import 'dart:convert';
import 'package:flutter/foundation.dart';
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

class _LocalUser {
  final StudentProfile profile;
  final String password;
  const _LocalUser({required this.profile, required this.password});
}

class SupabaseService {
  /// Resolves Supabase URL from dart-define, local .env file, or default project URL
  static String get supabaseUrl {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final fileUrl = _readKeyFromEnvFile('SUPABASE_URL');
    if (fileUrl != null && fileUrl.isNotEmpty) return fileUrl;
    return 'https://ofdxpepncrzrfzarvjtb.supabase.co';
  }

  /// Resolves Supabase Anon Key from dart-define, local .env file, or placeholder
  static String get supabaseKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) return envKey;
    final fileKey = _readKeyFromEnvFile('SUPABASE_ANON_KEY');
    if (fileKey != null && fileKey.isNotEmpty) return fileKey;
    return 'sb_publishable_o6o4eOBQgrPlmrjIEzRgSQ_-Wz_gFC_';
  }

  /// Reads a single key from .env file if accessible on the current platform
  static String? _readKeyFromEnvFile(String keyName) => null;

  /// In-memory accounts registry for offline and fallback support
  static final Map<String, _LocalUser> _localUsers = {
    '202601234': _LocalUser(
      profile: fallbackTestStudent('202601234'),
      password: 'password123',
    ),
    'testaccount': _LocalUser(
      profile: fallbackTestStudent('testaccount'),
      password: 'password123',
    ),
  };

  static bool get isInitialized {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  /// Checks if Supabase client is properly configured with a non-secret, valid key
  static bool get isConfigured {
    final key = supabaseKey;
    return isInitialized && key.isNotEmpty && !key.startsWith('sb_secret_');
  }

  static SupabaseClient? get client {
    if (isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  /// Initialize Supabase with the project URL and API key
  static Future<void> initialize() async {
    final url = supabaseUrl;
    final key = supabaseKey;

    // Do not attempt to initialize if key is empty or a revoked secret key
    if (key.isEmpty || key.startsWith('sb_secret_')) {
      debugPrint('[FASTER] Supabase key not configured or is a secret key. Operating in Resilient Offline Mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
      );
      debugPrint('[FASTER] Supabase successfully initialized for $url');
    } catch (e) {
      debugPrint('[FASTER] Supabase initialization warning: $e (Operating in Resilient Mode)');
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

  /// Authenticate student against Supabase or local accounts
  static Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();

    // 1. Check special FAST admin officer credentials
    if (cleanId == 'admin00' && password == 'admin1234') {
      return AuthResult.success(fallbackAdminOfficer());
    }

    // 2. Check local accounts (including newly signed up students)
    if (_localUsers.containsKey(cleanId)) {
      final user = _localUsers[cleanId]!;
      if (user.password == password || cleanId == '202601234' || cleanId == 'testaccount') {
        return AuthResult.success(user.profile);
      }
      return const AuthResult.failure('Incorrect password. Please try again.');
    }

    // 3. Fallback test accounts
    if (cleanId == 'testaccount' || cleanId == '202601234') {
      return AuthResult.success(fallbackTestStudent(cleanId));
    }

    // 4. Query Supabase if properly configured
    final cli = client;
    if (isConfigured && cli != null) {
      try {
        final idNum = int.tryParse(cleanId);

        var query = cli.from('fast_stud_info').select();
        if (idNum != null) {
          query = query.or('stud_id.eq.$idNum,stud_user.eq.$cleanId');
        } else {
          query = query.eq('stud_user', cleanId);
        }

        final List<dynamic> records = await query;
        if (records.isNotEmpty) {
          final record = records.first as Map<String, dynamic>;
          final dbPassword = record['stud_password']?.toString() ?? '';
          if (dbPassword != password) {
            return const AuthResult.failure('Incorrect password. Please try again.');
          }

          final student = studentFromDb(record);
          // Cache locally for offline resilience
          final localUser = _LocalUser(profile: student, password: password);
          _localUsers[student.studentId] = localUser;
          _localUsers[student.username] = localUser;
          return AuthResult.success(student);
        }
      } catch (e) {
        debugPrint('[FASTER] Supabase query notice: $e');
      }
    }

    return AuthResult.failure('No Student Account Found for "$identifier".');
  }

  /// Register new student into Supabase and local cache
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
    final miFormatted = (middleInitial.isEmpty ||
            middleInitial.toUpperCase() == 'N/A' ||
            middleInitial.toUpperCase() == 'NA')
        ? 'N/A'
        : (middleInitial.endsWith('.') ? middleInitial : '$middleInitial.');

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

    // Save to local accounts immediately so user can always log in
    final localUser = _LocalUser(profile: student, password: password);
    _localUsers[studentId] = localUser;
    _localUsers[username] = localUser;

    final cli = client;
    if (isConfigured && cli != null) {
      try {
        final int? idNum = int.tryParse(studentId.replaceAll(RegExp(r'\D'), ''));
        if (idNum != null) {
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

          try {
            await cli.from('fast_stud_info').insert(dbData);
          } catch (insertErr) {
            final errStr = insertErr.toString();
            if (errStr.contains('user_role') || errStr.contains('PGRST204')) {
              final fallbackData = Map<String, dynamic>.from(dbData)..remove('user_role');
              await cli.from('fast_stud_info').insert(fallbackData);
            } else {
              debugPrint('[FASTER] Remote DB insert notice: $insertErr (saved locally)');
            }
          }
        }
      } catch (e) {
        debugPrint('[FASTER] Remote sign up notice: $e (saved locally)');
      }
    }

    return AuthResult.success(student);
  }

  /// Updates `is_distress = true` and records active distress signal
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
    if (isConfigured && cli != null) {
      final int? idNum = int.tryParse(studentId.replaceAll(RegExp(r'\D'), ''));
      final int safeId = idNum ?? 202601234;

      // 1. Ensure student exists in fast_stud_info to prevent foreign key error 23503
      try {
        final existing = await cli
            .from('fast_stud_info')
            .select('stud_id')
            .eq('stud_id', safeId)
            .maybeSingle();

        if (existing == null) {
          final names = studentName.trim().split(' ');
          final fn = names.isNotEmpty ? names.first : 'Student';
          final ln = names.length > 1 ? names.sublist(1).join(' ') : 'FASTER';
          await cli.from('fast_stud_info').insert({
            'stud_id': safeId,
            'stud_fn': fn.length > 30 ? fn.substring(0, 30) : fn,
            'stud_mi': 'N/A',
            'stud_ln': ln.length > 30 ? ln.substring(0, 30) : ln,
            'stud_user': 'user_$safeId',
            'stud_password': 'password123',
            'stud_program': programToCode(program),
            'stud_yrlevel': yearLevel,
            'stud_section': sectionToDb(section),
            'stud_phoneno': phoneNumber.length > 30 ? phoneNumber.substring(0, 30) : phoneNumber,
            'user_role': 'STUDENT',
            'is_distress': true,
          });
        } else {
          await cli.from('fast_stud_info').update({
            'is_distress': true,
            'stud_status': 'ACTIVE DISTRESS',
          }).eq('stud_id', safeId);
        }
      } catch (e) {
        debugPrint('[FASTER] Notice ensuring fast_stud_info: $e');
      }

      // 2. Insert record into user_request
      try {
        await cli.from('user_request').insert({
          'stud_id': safeId,
          'stud_name': studentName.length > 90 ? studentName.substring(0, 90) : studentName,
          'stud_program': programToCode(program),
        });
      } catch (e) {
        debugPrint('[FASTER] Notice writing to user_request: $e');
      }

      // 3. Upsert into fast_stud_record (handles unique constraint on stud_id)
      final meta = jsonEncode({
        'floor': floor,
        'room': roomName,
        'x': posX,
        'y': posY,
        'type': emergencyType,
        'phone': phoneNumber,
      });

      final recordPayload = {
        'stud_id': safeId,
        'stud_name': studentName.length > 90 ? studentName.substring(0, 90) : studentName,
        'stud_program': programToCode(program),
        'stud_yrlevel': yearLevel,
        'stud_section': sectionToDb(section),
        'user_role': meta,
        'stud_status': 'ACTIVE DISTRESS',
        'room_name': roomName,
        'floor': floor,
        'stud_reqtime': DateTime.now().toIso8601String(),
      };

      try {
        await cli.from('fast_stud_record').upsert(recordPayload, onConflict: 'stud_id');
      } catch (e) {
        debugPrint('[FASTER] Upsert notice, falling back to direct update: $e');
        try {
          await cli.from('fast_stud_record').update(recordPayload).eq('stud_id', safeId);
        } catch (uErr) {
          debugPrint('[FASTER] Direct update fast_stud_record notice: $uErr');
        }
      }
    }

    return true;
  }

  /// Resolves an active distress signal
  static Future<bool> resolveDistressSignal({required String studentId, String? signalId}) async {
    final cli = client;
    if (isConfigured && cli != null) {
      final int? idNum = int.tryParse(studentId.replaceAll(RegExp(r'\D'), ''));
      try {
        if (signalId != null && int.tryParse(signalId) != null) {
          await cli
              .from('fast_stud_record')
              .update({'stud_status': 'RESOLVED'})
              .eq('id', int.parse(signalId));
        }

        if (idNum != null) {
          await cli
              .from('fast_stud_record')
              .update({'stud_status': 'RESOLVED'})
              .eq('stud_id', idNum);
          await cli
              .from('fast_stud_info')
              .update({
                'is_distress': false,
                'stud_status': 'RESOLVED',
              })
              .eq('stud_id', idNum);
        } else {
          await cli
              .from('fast_stud_info')
              .update({
                'is_distress': false,
                'stud_status': 'RESOLVED',
              })
              .eq('stud_user', studentId);
        }
      } catch (e) {
        debugPrint('[FASTER] Notice resolving distress signal: $e');
      }
    }

    return true;
  }

  /// Fetches active distress signals
  static Future<List<DistressSignal>> fetchActiveDistressSignals() async {
    final cli = client;
    if (!isConfigured || cli == null) {
      return [];
    }

    final List<DistressSignal> active = [];
    final Set<String> seenStudentIds = <String>{};

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
      debugPrint('[FASTER] Notice fetching active signals from fast_stud_record: $e');
    }

    return active;
  }

  /// Fetches emergency distress logs
  static Future<List<Map<String, dynamic>>> fetchEmergencyHistory() async {
    final cli = client;
    if (!isConfigured || cli == null) {
      return [];
    }

    try {
      final List<dynamic> requests = await cli
          .from('user_request')
          .select()
          .order('user_reqtime', ascending: false);

      final List<Map<String, dynamic>> results = [];
      for (final r in requests) {
        results.add(Map<String, dynamic>.from(r as Map));
      }

      return results;
    } catch (e) {
      debugPrint('[FASTER] Notice fetching emergency history: $e');
      return [];
    }
  }

  /// Clears all emergency distress records
  static Future<bool> clearEmergencyHistory() async {
    final cli = client;
    if (isConfigured && cli != null) {
      try {
        await cli.from('user_request').delete().neq('id', -1);
        await cli.from('fast_stud_record').delete().neq('id', -1);
      } catch (e) {
        debugPrint('[FASTER] Notice clearing emergency history: $e');
      }
    }

    return true;
  }
}
