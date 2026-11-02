import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'core/constants.dart';
import 'modules/auth/login_screen.dart';
import 'modules/home/home_screen.dart';

// Calling Modules
export 'core/constants.dart';
export 'models/student_profile.dart';
export 'widgets/glass_widgets.dart';
export 'widgets/resq_logo.dart';
export 'modules/auth/login_screen.dart';
export 'modules/home/home_screen.dart';
export 'modules/map/map_screen.dart';
export 'modules/map/base_map_painter.dart';
export 'modules/map/ground_floor.dart';
export 'modules/map/second_floor.dart';
export 'modules/map/map_search.dart';
export 'modules/contacts/contacts_screen.dart';
export 'modules/what_to_do/what_to_do_screen.dart';
export 'modules/profile/profile_screen.dart';
export 'modules/admin/admin_main_screen.dart';
export 'modules/admin/admin_home_tab.dart';
export 'modules/admin/admin_history_tab.dart';
export 'modules/admin/admin_profile_tab.dart';
export 'modules/admin/models/distress_signal.dart';
export 'modules/admin/services/distress_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const CardApp());
}

class CardApp extends StatelessWidget {
  const CardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'FASTER',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kGoogleRed,
              primary: kGoogleRed,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F4F8),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kGoogleRed,
              primary: kGoogleRed,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0A0B0E),
          ),
          home: const AuthSplashScreen(),
        );
      },
    );
  }
}

typedef FASTER = CardApp;
typedef HomeScreen = HomePage;
typedef SplashScreen = AuthSplashScreen;
