import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/glass_widgets.dart';
import '../map/map_screen.dart';
import '../contacts/contacts_screen.dart';
import '../what_to_do/what_to_do_screen.dart';
import '../profile/profile_screen.dart';

// ============================================================
// HOME PAGE NAVIGATION
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, currentMode, _) {
        final List<Widget> pages = [
          const MapHomePage(),
          const ContactsPage(),
          const WhatToDoPage(),
          const ProfilePage(),
        ];

        return GlassBackground(
          key: ValueKey(currentMode),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(child: pages[selectedTab]),
            bottomNavigationBar: GlassBottomNavBar(
              currentIndex: selectedTab,
              onTap: (index) => setState(() => selectedTab = index),
            ),
          ),
        );
      },
    );
  }
}

