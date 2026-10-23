import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/glass_widgets.dart';
import 'admin_home_tab.dart';
import 'admin_history_tab.dart';
import 'admin_profile_tab.dart';
import 'models/distress_signal.dart';
import 'services/distress_sync_service.dart';

class AdminMainScreen extends StatefulWidget {
  final int initialTab;
  const AdminMainScreen({super.key, this.initialTab = 0});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _selectedTab;
  DistressSignal? _activeAlertBanner;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    DistressSyncService.initialize();
    DistressSyncService.newAlertNotifier.addListener(_onNewAlertReceived);
  }

  @override
  void dispose() {
    DistressSyncService.newAlertNotifier.removeListener(_onNewAlertReceived);
    super.dispose();
  }

  void _onNewAlertReceived() {
    final alert = DistressSyncService.newAlertNotifier.value;
    if (alert != null && mounted) {
      setState(() {
        _activeAlertBanner = alert;
      });
    }
  }

  void _dismissAlert() {
    setState(() {
      _activeAlertBanner = null;
    });
    DistressSyncService.clearAlertNotification();
  }

  void _viewAlertOnMap(DistressSignal signal) {
    _dismissAlert();
    setState(() {
      _selectedTab = 0; // Go to HOME tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, currentMode, _) {
        final dark = isGlassDark(context);

        final List<Widget> pages = [
          const AdminHomeTab(),
          const AdminHistoryTab(),
          const AdminProfileTab(),
        ];

        return GlassBackground(
          key: ValueKey(currentMode),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kGoogleRed.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kGoogleRed.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.shield_rounded, color: kGoogleRed, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'FAST',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: kGoogleRed,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'OFFICER PORTAL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: dark ? Colors.white : const Color(0xFF16181F),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'CvSU - Cavite City Campus',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: dark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // REFRESH BUTTON (Replaced upper right theme toggle per instruction)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: kGoogleRed,
                          size: 22,
                        ),
                        tooltip: 'Refresh Live Distress Signals & History',
                        onPressed: () async {
                          await DistressSyncService.refresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Distress signals & History refreshed.'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  pages[_selectedTab],

                  // LIVE NOTIFICATION OVERLAY (Directly notifies admin's phone with FASTER app open)
                  if (_activeAlertBanner != null)
                    Positioned(
                      top: 10,
                      left: 14,
                      right: 14,
                      child: _buildLiveAlertNotificationBanner(_activeAlertBanner!, dark),
                    ),
                ],
              ),
            ),
            bottomNavigationBar: _AdminGlassBottomNavBar(
              currentIndex: _selectedTab,
              onTap: (index) => setState(() => _selectedTab = index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveAlertNotificationBanner(DistressSignal signal, bool dark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.crisis_alert, color: Color(0xFFB71C1C), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🚨 LIVE DISTRESS ALERT RECEIVED!',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                        Text(
                          '${signal.studentName} at ${signal.roomName} (${signal.floor == 0 ? "Ground Floor" : "2nd Floor"})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${signal.studentId} • ${signal.program} • ${signal.reqTime}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    onPressed: _dismissAlert,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewAlertOnMap(signal),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text(
                        'VIEW ON MAP',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB71C1C),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _dismissAlert,
                    child: const Text(
                      'DISMISS',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminGlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AdminGlassBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_AdminNavItem> _items = [
    _AdminNavItem(
      label: 'HOME',
      icon: Icons.radar_outlined,
      selectedIcon: Icons.radar,
    ),
    _AdminNavItem(
      label: 'HISTORY',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _AdminNavItem(
      label: 'PROFILE',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        height: 66,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xCC111219)
                    : Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(33),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: dark
                        ? Colors.black.withValues(alpha: 0.50)
                        : Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: isSelected
                            ? BoxDecoration(
                                color: const Color(0xFFE50914).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE50914).withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? const Color(0xFFE50914)
                                  : (dark ? Colors.white54 : const Color(0xFF757575)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                letterSpacing: 0.6,
                                color: isSelected
                                    ? const Color(0xFFE50914)
                                    : (dark ? Colors.white54 : const Color(0xFF757575)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
