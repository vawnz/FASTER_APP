import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/student_profile.dart';
import '../auth/login_screen.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, currentMode, _) {
        final dark = isGlassDark(context);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          children: [
            Text(
              'Officer Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: dark ? Colors.white : const Color(0xFF16181F),
              ),
            ),
            const SizedBox(height: 8),

            // Profile Header Glass Card
            Card(
              elevation: 0,
              color: dark ? const Color(0xB3141620) : Colors.white.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFFF5252)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE50914).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: dark ? const Color(0xFF161822) : Colors.white,
                        child: Icon(Icons.shield_rounded, size: 28, color: dark ? Colors.white : kGoogleRed),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentStudent.userRole == 'ADMIN' ? 'FAST Officer' : currentStudent.fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: dark ? Colors.white : const Color(0xFF16181F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE50914).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HQ DISPATCH',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE50914),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '@${currentStudent.username} • ID: ${currentStudent.studentId}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: dark ? Colors.white70 : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFFE50914).withValues(alpha: 0.16)
                                  : kFastOfficePink.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE50914).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              'Campus Emergency Response Team • FAST Officer',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: dark ? const Color(0xFFFF6B6B) : const Color(0xFF880E4F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Information & Settings Glass Card
            Card(
              elevation: 0,
              color: dark ? const Color(0xB3141620) : Colors.white.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone, color: Color(0xFFE50914), size: 16),
                    ),
                    title: Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF16181F),
                      ),
                    ),
                    subtitle: Text(
                      currentStudent.phoneNumber.isNotEmpty
                          ? currentStudent.phoneNumber
                          : '09123456789',
                      style: TextStyle(fontSize: 11.5, color: dark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  Divider(height: 1, color: dark ? Colors.white10 : Colors.black12),
                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: Color(0xFFE50914), size: 16),
                    ),
                    title: Text(
                      'Campus',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF16181F),
                      ),
                    ),
                    subtitle: Text(
                      'Cavite State University - Cavite City Campus',
                      style: TextStyle(fontSize: 11.5, color: dark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  Divider(height: 1, color: dark ? Colors.white10 : Colors.black12),
                  ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: const Color(0xFFE50914),
                        size: 16,
                      ),
                    ),
                    title: Text(
                      dark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : const Color(0xFF16181F),
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: dark,
                      activeThumbColor: const Color(0xFFE50914),
                      activeTrackColor: const Color(0xFFE50914).withValues(alpha: 0.40),
                      onChanged: (bool value) {
                        appThemeMode.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Sign Out Card
            Card(
              elevation: 0,
              color: dark ? const Color(0xB3141620) : Colors.white.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kGoogleRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: kGoogleRed, size: 16),
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: kGoogleRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: kGoogleRed),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, _, _) => const AuthSplashScreen(skipSplash: true),
                      transitionsBuilder: (_, anim, _, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
