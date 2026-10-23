class StudentProfile {
  final String studentId;
  final String firstName;
  final String middleInitial;
  final String lastName;
  final String program;
  final String yearLevel;
  final String section;
  final String username;
  final String phoneNumber;
  final String userRole;

  const StudentProfile({
    required this.studentId,
    required this.firstName,
    required this.middleInitial,
    required this.lastName,
    required this.program,
    required this.yearLevel,
    required this.section,
    required this.username,
    this.phoneNumber = '09123456789',
    this.userRole = 'STUDENT',
  });

  String get fullName {
    final mi = middleInitial.trim();
    if (mi.isEmpty || mi.toUpperCase() == 'N/A' || mi.toUpperCase() == 'NA') {
      return '$firstName $lastName';
    }
    final formattedMi = mi.endsWith('.') ? mi : '$mi.';
    return '$firstName $formattedMi $lastName';
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'first_name': firstName,
      'middle_initial': middleInitial,
      'last_name': lastName,
      'program': program,
      'year_level': yearLevel,
      'section': section,
      'username': username,
      'phone_number': phoneNumber,
      'user_role': userRole,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

const List<String> kStudentPrograms = [
  '(BSCS) Bachelor of Science in Computer Science',
  '(BSIT) Bachelor of Science in Information Technology',
  '(BSED-MATH) Bachelor of Secondary Education - Major in Mathematics',
  '(BSED-ENGLISH) Bachelor of Secondary Education - Major in English',
  '(BSED-ECED) Bachelor of Early Childhood Education',
  '(BSHM) Bachelor of Science in Hospitality Management',
  '(BSBA) Bachelor of Science in Business Administration',
];

const List<String> kYearLevels = [
  '1st Year',
  '2nd Year',
  '3rd Year',
  '4th Year',
  'Other',
];

const List<String> kSections = [
  'IRREGULAR',
  'Section A',
  'Section B',
  'Section C',
  'Section D',
  'Section E',
  'Section F',
  'Section G',
  'Section H',
  'Other',
];

/// Default initial profile for student session before authentication.
const StudentProfile kDefaultStudentProfile = StudentProfile(
  studentId: '202601234',
  firstName: 'Juan',
  middleInitial: 'A',
  lastName: 'Dela Cruz',
  program: '(BSCS) Bachelor of Science in Computer Science',
  yearLevel: '4th Year',
  section: 'Section A',
  username: 'juandelacruz',
  phoneNumber: '09123456789',
  userRole: 'STUDENT',
);

/// Active logged-in student profile session.
/// This global session variable holds the authenticated user's profile across screens
/// and is dynamically overwritten when a student or admin logs in or registers.
StudentProfile currentStudent = kDefaultStudentProfile;
