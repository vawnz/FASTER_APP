import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faster/main.dart';
import 'package:faster/supabase_service.dart';

void main() {
  testWidgets('Splash -> Login -> Home -> Profile -> Sign Out flow',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardApp());

    // 1. Initial state: Splash animation with new FASTER logo (3000ms)
    expect(find.byType(AuthSplashScreen), findsOneWidget);
    expect(find.byType(ResQLogo), findsWidgets);

    // 2. Advance animation by 3000ms to complete splash and transition into Login page
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // Verify Login page elements from Figma
    expect(find.text('LOG IN'), findsNWidgets(2)); // Header title and button
    expect(find.text('Log In to Existing Account'), findsOneWidget);
    expect(find.text('Enter Student ID or Username'), findsOneWidget);
    expect(find.text('Enter Password'), findsOneWidget);
    expect(find.text('• Sign in using your Student ID or Username'), findsOneWidget);

    // 3. Verify validation when fields are empty, then enter credentials
    final logInButton = find.widgetWithText(ElevatedButton, 'LOG IN');
    expect(logInButton, findsOneWidget);
    await tester.tap(logInButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear for empty inputs
    expect(find.text('Please enter your Student ID or Username.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);

    // Enter user credentials (fields are now initially blank)
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '202601234');
    await tester.enterText(textFields.at(1), 'resqPass2026');
    await tester.pumpAndSettle();

    // Tap LOG IN with entered credentials
    await tester.tap(logInButton);

    // Settle transition to HomePage
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify HomePage is displayed
    expect(find.byType(HomePage), findsOneWidget);

    // 4. Navigate to Profile page
    final profileTab = find.text('MY PROFILE');
    expect(profileTab, findsOneWidget);
    await tester.tap(profileTab);
    await tester.pumpAndSettle();

    // Verify Profile page elements and Sign Out button
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Test A. Ccount'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Campus'), findsOneWidget);
    // Settings tile removed in favor of direct theme switch
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Dark Mode'), findsOneWidget);
    final signOutTile = find.widgetWithText(ListTile, 'Sign Out');
    expect(signOutTile, findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);

    // 5. Tap Sign Out and verify it leads back to the Log In screen
    await tester.tap(signOutTile);
    await tester.pumpAndSettle();

    expect(find.byType(AuthSplashScreen), findsOneWidget);
    expect(find.text('LOG IN'), findsNWidgets(2));
    expect(find.text('Enter Student ID or Username'), findsOneWidget);
  });

  testWidgets('Sign Up module verifies all required student fields, dropdown options, and phone number submission',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardApp());
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // Tap "Create an Account?"
    final createAccountLink = find.text('Create an Account?');
    expect(createAccountLink, findsOneWidget);
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    // Verify Sign Up page header and title
    expect(find.text('SIGN UP'), findsOneWidget);
    expect(find.text('Create an Account'), findsOneWidget);

    // Verify required form fields in Phase 1
    expect(find.text('Enter Student ID (e.g. 202601234)'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('M.I. / N/A'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Student Username'), findsOneWidget);
    expect(find.text('Student Password'), findsOneWidget);

    // Verify Dropdown placeholders/hints
    expect(find.text('Select Degree Program'), findsOneWidget);
    expect(find.text('Year Level'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);

    // Enter user credentials for Phase 1
    final signUpFields = find.byType(TextField);
    // Student ID
    await tester.ensureVisible(signUpFields.at(0));
    await tester.enterText(signUpFields.at(0), '202601234');

    // First Name
    await tester.ensureVisible(signUpFields.at(1));
    await tester.enterText(signUpFields.at(1), 'Juan');

    // M.I. - enter N/A
    await tester.ensureVisible(signUpFields.at(2));
    await tester.enterText(signUpFields.at(2), 'N/A');
    await tester.pumpAndSettle();

    // Last Name
    await tester.ensureVisible(signUpFields.at(3));
    await tester.enterText(signUpFields.at(3), 'Dela Cruz');

    // Username and Password
    await tester.ensureVisible(signUpFields.at(4));
    await tester.enterText(signUpFields.at(4), 'juandelacruz');

    await tester.ensureVisible(signUpFields.at(5));
    await tester.enterText(signUpFields.at(5), 'resqPass2026');
    await tester.pumpAndSettle();

    // Select Program dropdown (with horizontal scrolling)
    final programDropdown = find.text('Select Degree Program');
    await tester.ensureVisible(programDropdown);
    await tester.tap(programDropdown, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('(BSCS) Bachelor of Science in Computer Science').last);
    await tester.pumpAndSettle();

    // Select Year Level dropdown
    final yearDropdown = find.text('Year Level');
    await tester.ensureVisible(yearDropdown);
    await tester.tap(yearDropdown, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('4th Year').last);
    await tester.pumpAndSettle();

    // Select Section dropdown
    final sectionDropdown = find.text('Section');
    await tester.ensureVisible(sectionDropdown);
    await tester.tap(sectionDropdown, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Section A').last);
    await tester.pumpAndSettle();

    // Advance to Phase 2: Phone Verification
    final continueBtn = find.widgetWithText(ElevatedButton, 'CONTINUE TO VERIFICATION');
    expect(continueBtn, findsOneWidget);
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Phase 2 assertions: Phone number verification
    expect(find.text('Phone Number (Step 2 of 2)'), findsOneWidget);
    expect(find.text('09XXXXXXXXX'), findsOneWidget);

    final phoneField = find.widgetWithText(TextField, '09XXXXXXXXX');
    expect(phoneField, findsOneWidget);
    await tester.enterText(phoneField, '09123456789');
    await tester.pumpAndSettle();

    // Complete Sign Up
    final completeSignUpBtn = find.widgetWithText(ElevatedButton, 'COMPLETE SIGN UP');
    expect(completeSignUpBtn, findsOneWidget);
    await tester.tap(completeSignUpBtn);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify it proceeds to HomePage
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Verifies no back arrow in headers, Other options for Year/Section, and Phone validation constraints',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardApp());
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // 1. Verify no back arrow in Login header
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);

    // Switch to Sign Up
    await tester.tap(find.text('Create an Account?'));
    await tester.pumpAndSettle();

    // Verify no back arrow in Sign Up header
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);

    // 1. Student ID
    final signUpFields = find.byType(TextField);
    await tester.ensureVisible(signUpFields.at(0));
    await tester.enterText(signUpFields.at(0), '202654321');

    // 2. Select Program dropdown
    final programDropdown = find.text('Select Degree Program');
    await tester.ensureVisible(programDropdown);
    await tester.tap(programDropdown, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('(BSIT) Bachelor of Science in Information Technology').last);
    await tester.pumpAndSettle();

    // 3. First Name, M.I., Last Name
    await tester.ensureVisible(signUpFields.at(1));
    await tester.enterText(signUpFields.at(1), 'Maria');
    await tester.ensureVisible(signUpFields.at(2));
    await tester.enterText(signUpFields.at(2), 'C');
    await tester.ensureVisible(signUpFields.at(3));
    await tester.enterText(signUpFields.at(3), 'Santos');

    // Select 'Other' in Year Level dropdown
    await tester.ensureVisible(find.text('Year Level'));
    await tester.tap(find.text('Year Level'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    // Verify custom Year input field appears with 1-char hint
    expect(find.text('Year (1 char)'), findsOneWidget);
    final otherYearField = find.widgetWithText(TextField, 'Year (1 char)');
    await tester.enterText(otherYearField, '5');

    // Select Section dropdown
    await tester.ensureVisible(find.text('Section'));
    await tester.tap(find.text('Section'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Section B').last);
    await tester.pumpAndSettle();

    // Fill username and password
    final usernameField = find.widgetWithText(TextField, 'Student Username');
    await tester.ensureVisible(usernameField);
    await tester.enterText(usernameField, 'mariasantos');

    final passwordField = find.widgetWithText(TextField, 'Student Password');
    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'mariaspass123');
    await tester.pumpAndSettle();

    // Advance to Phase 2
    final continueBtn = find.widgetWithText(ElevatedButton, 'CONTINUE TO VERIFICATION');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Phase 2: Test phone number validation constraints
    final phoneField = find.widgetWithText(TextField, '09XXXXXXXXX');
    final completeBtn = find.widgetWithText(ElevatedButton, 'COMPLETE SIGN UP');

    // Constraint 1: Must start with 09
    await tester.enterText(phoneField, '08123456789');
    await tester.tap(completeBtn);
    await tester.pumpAndSettle();
    expect(find.text('Must start with 09 (Philippine mobile standard).'), findsOneWidget);

    // Constraint 2: Must be 11 digits only
    await tester.enterText(phoneField, '0912345');
    await tester.tap(completeBtn);
    await tester.pumpAndSettle();
    expect(find.text('Must contain 11 digits ONLY.'), findsOneWidget);

    // Valid 11-digit number starting with 09
    await tester.enterText(phoneField, '09987654321');
    await tester.tap(completeBtn);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify HomePage
    expect(find.byType(HomePage), findsOneWidget);
  });

  test('Second Floor Blueprint room hit-testing for all sectors', () {
    // Left Wing
    expect(secondRoomAt(0.12, 0.14), 'FIRE EXIT (Top-Left)');
    expect(secondRoomAt(0.12, 0.24), 'ROOM 220');
    expect(secondRoomAt(0.12, 0.35), 'ROOM 219');
    expect(secondRoomAt(0.12, 0.50), 'ROOM 218');
    expect(secondRoomAt(0.12, 0.70), 'ROOM 217 / READING ROOM');

    // Hallways
    expect(secondRoomAt(0.20, 0.30), 'Second Floor Hallway');
    expect(secondRoomAt(0.50, 0.61), 'Second Floor Hallway');

    // Library area
    expect(secondRoomAt(0.28, 0.20), 'LIBRARY EXTENSION');
    expect(secondRoomAt(0.30, 0.45), 'LIBRARY');

    // North row
    expect(secondRoomAt(0.42, 0.48), 'ROOM 211');
    expect(secondRoomAt(0.49, 0.48), 'ROOM 209');
    expect(secondRoomAt(0.56, 0.48), 'ROOM 207');
    expect(secondRoomAt(0.63, 0.48), 'FIRE EXIT (Central / Middle)');
    expect(secondRoomAt(0.70, 0.48), 'ROOM 205');
    expect(secondRoomAt(0.77, 0.48), 'ROOM 203');
    expect(secondRoomAt(0.84, 0.48), 'ROOM 202');
    expect(secondRoomAt(0.92, 0.48), 'MEN\'S CR');

    // South row
    expect(secondRoomAt(0.25, 0.72), 'DEPT.');
    expect(secondRoomAt(0.36, 0.72), 'ROOM 214');
    expect(secondRoomAt(0.43, 0.72), 'ROOM 213');
    expect(secondRoomAt(0.50, 0.72), 'ROOM 212');
    expect(secondRoomAt(0.57, 0.72), 'ROOM 210');
    expect(secondRoomAt(0.65, 0.72), 'ROOM 208');
    expect(secondRoomAt(0.74, 0.72), 'ROOM 206');
    expect(secondRoomAt(0.82, 0.72), 'ROOM 204');
    expect(secondRoomAt(0.92, 0.72), 'FIRE EXIT (Bottom-Right)');

    // Off Boundaries
    expect(isSecondOffBoundaries(0.02, 0.50), isTrue);
    expect(isSecondOffBoundaries(0.98, 0.50), isTrue);
    expect(secondRoomAt(0.02, 0.50), 'Off Boundaries');
  });

  testWidgets('MapHomePage verifies removal of center-pin button, modernized search with real-time predictions and tracking',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapHomePage(),
        ),
      ),
    );

    // 1. Verify center-pin button is completely removed
    expect(find.byIcon(Icons.my_location), findsNothing);

    // 2. Verify modernized search button exists on the upper right
    final searchBtn = find.text('Search Location');
    expect(searchBtn, findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    // 3. Tap search button to open blurred search overlay
    await tester.tap(searchBtn);
    await tester.pumpAndSettle();

    // Verify search overlay and search input field with BackdropFilter
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Where are you? (e.g. Room 107, Library, FAST)...'), findsOneWidget);

    // 4. Test real-time prediction by typing "Central"
    final searchInput = find.byType(TextField);
    await tester.enterText(searchInput, 'Central');
    await tester.pumpAndSettle();

    expect(find.text('FIRE EXIT (Central / Middle)'), findsOneWidget);

    // 5. Select the location and verify automatic floor switch & tracking
    await tester.tap(find.text('FIRE EXIT (Central / Middle)'));
    await tester.pumpAndSettle();

    // Verify search overlay dismissed and 2nd Floor tracking active
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('FIRE EXIT (Central / Middle)'), findsOneWidget);
    expect(find.text('Climbing up Central Staircase • 2nd Floor'), findsOneWidget);

    // 6. Test searching for a Ground Floor room from 2nd floor
    await tester.tap(find.text('Search Location'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'FAST Office');
    await tester.pumpAndSettle();

    expect(find.text('FAST OFFICE'), findsOneWidget);
    await tester.tap(find.text('FAST OFFICE'));
    await tester.pumpAndSettle();

    // Verify switched to Ground Floor and tracking FAST Office
    expect(find.text('FAST OFFICE'), findsOneWidget);
    expect(find.text('Dispatch from FAST Office • Ground Floor'), findsOneWidget);
  });

  test('First Floor Blueprint room hit-testing for all sectors', () {
    // Far Left Wing
    expect(groundRoomAt(0.12, 0.17), 'SERVICE / STAIRS');
    expect(groundRoomAt(0.12, 0.30), 'HM LABORATORY COLD KITCHEN');
    expect(groundRoomAt(0.12, 0.50), 'HM LABORATORY HOT KITCHEN');
    expect(groundRoomAt(0.12, 0.70), 'INVENTORY ROOM');

    // Top Region
    expect(groundRoomAt(0.30, 0.18), 'HM DEPARTMENT');
    expect(groundRoomAt(0.30, 0.30), 'AIHMS OFFICE');
    expect(groundRoomAt(0.40, 0.32), 'TERRACE');
    expect(groundRoomAt(0.52, 0.20), 'GARDEN');
    expect(groundRoomAt(0.66, 0.15), 'FAST OFFICE');
    expect(groundRoomAt(0.75, 0.15), 'JMA OFFICE');
    expect(groundRoomAt(0.80, 0.15), 'ROTC OFFICE');
    expect(groundRoomAt(0.86, 0.15), 'CSG OFFICE');
    expect(groundRoomAt(0.70, 0.28), 'CANTEEN DINING AREA');
    expect(groundRoomAt(0.86, 0.28), 'CANTEEN KITCHEN');

    // Middle Region
    expect(groundRoomAt(0.25, 0.51), 'IT / CS DEPARTMENT');
    expect(groundRoomAt(0.34, 0.43), 'EL CHABACANO');
    expect(groundRoomAt(0.34, 0.54), 'MIS');
    expect(groundRoomAt(0.41, 0.43), 'CR');
    expect(groundRoomAt(0.43, 0.50), 'REGISTRAR');
    expect(groundRoomAt(0.43, 0.58), 'CASHIER');
    expect(groundRoomAt(0.53, 0.50), 'LOBBY');
    expect(groundRoomAt(0.64, 0.59), 'ROOM 108');
    expect(groundRoomAt(0.72, 0.51), 'ROOM 107 COM LAB');
    expect(groundRoomAt(0.82, 0.51), 'RDE OFFICE');
    expect(groundRoomAt(0.91, 0.51), 'WOMEN\'S CR');

    // Bottom Region
    expect(groundRoomAt(0.20, 0.71), 'JPCS OFFICE');
    expect(groundRoomAt(0.20, 0.83), 'GAD OFFICE');
    expect(groundRoomAt(0.24, 0.78), 'OSAS');
    expect(groundRoomAt(0.31, 0.78), 'ROOM 119 COM LAB');
    expect(groundRoomAt(0.37, 0.78), 'ACCRE. OFFICE');
    expect(groundRoomAt(0.43, 0.71), 'GUIDANCE');
    expect(groundRoomAt(0.43, 0.83), 'DEAN\'S OFFICE');
    expect(groundRoomAt(0.53, 0.78), 'FIRE EXIT');
    expect(groundRoomAt(0.63, 0.78), 'ROOM 109 COM LAB');
    expect(groundRoomAt(0.72, 0.78), 'ROOM 106 COM LAB');
    expect(groundRoomAt(0.82, 0.78), 'ROOM 104 COM LAB');
    expect(groundRoomAt(0.91, 0.73), 'ELEC. ROOM');
    expect(groundRoomAt(0.92, 0.87), 'GUARD HOUSE');

    // Off Boundaries (Black area walls & outside canvas)
    expect(isGroundOffBoundaries(0.01, 0.50), isTrue);
    expect(isGroundOffBoundaries(0.50, 0.01), isTrue);
    expect(isGroundOffBoundaries(0.99, 0.50), isTrue);
    expect(isGroundOffBoundaries(0.50, 0.98), isTrue);
    expect(isGroundOffBoundaries(-0.05, 0.50), isTrue);
    expect(isGroundOffBoundaries(1.05, 0.50), isTrue);

    expect(groundRoomAt(0.01, 0.50), 'Off Boundaries');
    expect(groundRoomAt(0.50, 0.01), 'Off Boundaries');
    expect(groundRoomAt(0.99, 0.50), 'Off Boundaries');
    expect(groundRoomAt(0.50, 0.98), 'Off Boundaries');

    // Designated emergency exit doors at the bottom are accessible
    expect(isGroundOffBoundaries(0.18, 0.98), isFalse);
    expect(isGroundOffBoundaries(0.72, 0.98), isFalse);
    expect(isGroundOffBoundaries(0.84, 0.98), isFalse);
  });

  testWidgets('ProfilePage verifies direct theme toggle between light and dark mode without settings tile',
      (WidgetTester tester) async {
    // Start with dark mode
    appThemeMode.value = ThemeMode.dark;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfilePage(),
        ),
      ),
    );

    // 1. Verify Profile page and theme toggle switch is in Dark Mode
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(appThemeMode.value, ThemeMode.dark);
    // Verify Settings tile is removed
    expect(find.text('Settings'), findsNothing);

    // 2. Toggle the switch to Light Mode
    final themeSwitch = find.byType(Switch);
    expect(themeSwitch, findsOneWidget);
    await tester.tap(themeSwitch);
    await tester.pumpAndSettle();

    // Verify appThemeMode switched to light
    expect(appThemeMode.value, ThemeMode.light);
    expect(find.text('Light Mode'), findsOneWidget);

    // 3. Toggle back to Dark Mode
    await tester.tap(themeSwitch);
    await tester.pumpAndSettle();

    expect(appThemeMode.value, ThemeMode.dark);
    expect(find.text('Dark Mode'), findsOneWidget);
  });

  testWidgets('Log In / Sign Up navigation executes short fade animation and assigns STUDENT user_role',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardApp());
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // Verify initial state is Log In
    expect(find.text('LOG IN'), findsNWidgets(2));
    expect(find.text('Create an Account?'), findsOneWidget);

    // Tap "Create an Account?" to navigate to Sign Up
    await tester.tap(find.text('Create an Account?'));

    // Mid-animation check: FadeTransition is active during transition
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(FadeTransition), findsWidgets);

    // Settle transition
    await tester.pumpAndSettle();

    // Verify Sign Up page is active
    expect(find.text('SIGN UP'), findsOneWidget);
    // Tap "Log into Existing Account?" to navigate back to Log In
    final logInLink = find.text('Log into Existing Account?');
    await tester.ensureVisible(logInLink);
    await tester.tap(logInLink);

    // Mid-animation check: FadeTransition is active during reverse transition
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(FadeTransition), findsWidgets);

    // Settle reverse transition
    await tester.pumpAndSettle();

    // Verify back on Log In page
    expect(find.text('LOG IN'), findsNWidgets(2));

    // Verify that Supabase sign up creates profile with user_role 'STUDENT'
    final authRes = await SupabaseService.signUp(
      studentId: '202699999',
      firstName: 'Maria',
      middleInitial: 'S',
      lastName: 'Clara',
      program: '(BSCS) Bachelor of Science in Computer Science',
      yearLevel: '1st Year',
      section: 'Section A',
      username: 'mariaclara',
      password: 'password123',
      phoneNumber: '09123456789',
    );

    expect(authRes.isSuccess, isTrue);
    expect(authRes.student?.userRole, 'STUDENT');
  });

  testWidgets('Admin UI: Special credentials admin00/admin1234 login, 3 tabs navigation, heat map monitoring, history data, and profile functions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CardApp());
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    // 1. Log in using special sample admin credentials
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'admin00');
    await tester.enterText(textFields.at(1), 'admin1234');
    await tester.pumpAndSettle();

    final logInButton = find.widgetWithText(ElevatedButton, 'LOG IN');
    await tester.tap(logInButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify AdminMainScreen is displayed
    expect(find.byType(AdminMainScreen), findsOneWidget);
    expect(find.text('FAST'), findsWidgets);
    expect(find.text('OFFICER PORTAL'), findsOneWidget);
    // Verify upper right refresh button exists instead of theme toggle
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // 2. Verify 3 navigation options (HOME, HISTORY, PROFILE)
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);

    // 3. HOME Tab: Verify Live Monitoring & Heat Map features
    expect(find.text('LIVE EMERGENCY MONITORING'), findsOneWidget);
    expect(find.text('GROUND FLOOR'), findsOneWidget);
    expect(find.text('SECOND FLOOR'), findsOneWidget);
    expect(find.text('Heat Map'), findsOneWidget);
    expect(find.text('Live Beacons'), findsOneWidget);

    // Switch to Second Floor
    await tester.tap(find.text('SECOND FLOOR'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2nd Floor'), findsWidgets);

    // Switch back to Ground Floor
    await tester.tap(find.text('GROUND FLOOR'));
    await tester.pumpAndSettle();

    // 4. HISTORY Tab: Initially 0 mock samples
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminHistoryTab), findsOneWidget);
    expect(find.text('Distress History'), findsOneWidget);
    expect(find.textContaining('No emergency records found'), findsOneWidget);

    // 5. Transmit a live distress signal from student to verify real-time Admin UI reflection
    await DistressSyncService.sendDistressSignal(
      studentId: '202600816',
      studentName: 'Juan A. Dela Cruz',
      program: '(BSCS) Bachelor of Science in Computer Science',
      yearLevel: '3rd Year',
      phoneNumber: '09123456789',
      roomName: 'ComLab 1',
      floor: 0,
      posX: 0.28,
      posY: 0.16,
      emergencyType: 'Medical Emergency',
    );
    await tester.pumpAndSettle();

    // Verify live alert notification banner pops up
    expect(find.textContaining('LIVE DISTRESS ALERT'), findsOneWidget);
    expect(find.textContaining('Juan A. Dela Cruz'), findsWidgets);
    expect(find.textContaining('ComLab 1'), findsWidgets);

    // Tap VIEW ON MAP from alert notification
    await tester.tap(find.text('VIEW ON MAP'));
    await tester.pumpAndSettle();

    // Verify beacon is now displayed on HOME map tab
    expect(find.textContaining('ComLab 1'), findsWidgets);

    // Return to HISTORY Tab and verify populated record with all required fields
    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    // - Student Complete Name (from fast_stud_record)
    expect(find.text('Juan A. Dela Cruz'), findsOneWidget);
    // - Student ID
    expect(find.text('Student ID: 202600816'), findsOneWidget);
    // - Program & Year Level
    expect(find.textContaining('(BSCS) Bachelor of Science in Computer Science • 3rd Year'), findsOneWidget);
    // - user_reqtime
    expect(find.textContaining('2026-'), findsWidgets);

    // Resolve signal and verify history reflects RESOLVED status
    await DistressSyncService.resolveDistressSignal('202600816');
    await tester.pumpAndSettle();
    expect(find.text('RESOLVED'), findsWidgets);

    // Verify clear history delete button beside refresh button in History page
    final deleteHistoryBtn = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteHistoryBtn, findsOneWidget);
    await tester.tap(deleteHistoryBtn);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Clear History?'), findsOneWidget);
    final confirmClearBtn = find.widgetWithText(ElevatedButton, 'CLEAR HISTORY');
    expect(confirmClearBtn, findsOneWidget);
    await tester.tap(confirmClearBtn);
    await tester.pumpAndSettle();

    // Verify history records are cleared
    expect(find.textContaining('No emergency records found'), findsOneWidget);

    // 6. PROFILE Tab: Navigate and verify functions
    await tester.tap(find.text('PROFILE'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminProfileTab), findsOneWidget);
    expect(find.text('Officer Profile'), findsOneWidget);
    expect(find.text('FAST Officer'), findsOneWidget);
    expect(find.text('HQ DISPATCH'), findsOneWidget);
    expect(find.text('@admin00 • ID: admin00'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Campus'), findsOneWidget);
    // Settings function removed per instruction
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Dark Mode'), findsOneWidget);

    // Verify Sign Out
    final signOutTile = find.widgetWithText(ListTile, 'Sign Out');
    expect(signOutTile, findsOneWidget);
    await tester.tap(signOutTile);
    await tester.pumpAndSettle();

    // Verify returned to Login Screen
    expect(find.byType(AuthSplashScreen), findsOneWidget);
    expect(find.text('LOG IN'), findsNWidgets(2));
  });
}
