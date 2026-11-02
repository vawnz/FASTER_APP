import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../core/constants.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);
    final baseColor = dark ? const Color(0xFF0A0B0E) : const Color(0xFFF0F3F8);

    return Container(
      color: baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Radial Red Glows (Matching Reference)
          // 1. Top-right ruby glow
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE50914).withValues(alpha: dark ? 0.28 : 0.14),
                      const Color(0xFFE50914).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 2. Mid-left organic deep red glow
          Positioned(
            top: 260,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB71C1C).withValues(alpha: dark ? 0.24 : 0.10),
                      const Color(0xFFB71C1C).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 3. Bottom-center crimson glow
          Positioned(
            bottom: -40,
            right: 40,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF1E27).withValues(alpha: dark ? 0.18 : 0.08),
                      const Color(0xFFFF1E27).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          child,
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? customBgColor;
  final Border? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 22,
    this.blur = 16,
    this.customBgColor,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);
    final bgColor = customBgColor ??
        (dark
            ? const Color(0xB3141620)
            : Colors.white.withValues(alpha: 0.82));
    final effectiveBorder = border ??
        Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        );

    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (dark)
            BoxShadow(
              color: const Color(0xFFE50914).withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: onTap != null
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(borderRadius),
                    onTap: onTap,
                    child: card,
                  ),
                )
              : card,
        ),
      ),
    );
  }
}

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavBarItemData> _items = [
    _NavBarItemData(
      label: 'HOME',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
    ),
    _NavBarItemData(
      label: 'CONTACTS',
      icon: Icons.contacts_outlined,
      selectedIcon: Icons.contacts,
    ),
    _NavBarItemData(
      label: 'WHAT TO DO?',
      icon: Icons.warning_amber_outlined,
      selectedIcon: Icons.warning_amber_rounded,
    ),
    _NavBarItemData(
      label: 'MY PROFILE',
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 68,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xCC111219)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(34),
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
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  )
                              : null,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE50914).withValues(alpha: 0.40),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : (dark ? Colors.white70 : const Color(0xFF555B68)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                letterSpacing: 0.3,
                                color: isSelected
                                    ? Colors.white
                                    : (dark ? Colors.white60 : const Color(0xFF6B7280)),
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

class _NavBarItemData {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavBarItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
