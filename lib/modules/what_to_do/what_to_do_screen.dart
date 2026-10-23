import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/glass_widgets.dart';

// ============================================================
// WHAT TO DO? PAGE
// ============================================================

class WhatToDoPage extends StatelessWidget {
  const WhatToDoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(
          'WHAT TO DO?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: dark ? Colors.white : const Color(0xFF16181F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Emergency procedures and safety instructions.',
          style: TextStyle(
            fontSize: 13,
            color: dark ? Colors.white60 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),
        const _ProcedureCard(
          title: 'EARTHQUAKE',
          icon: Icons.public,
          instructions: [
            '→ Drop, Cover, and Hold.',
            '→ Stay away from windows.',
            '→ Follow the nearest emergency route to the Fire Exit.'
          ],
        ),
        const _ProcedureCard(
          title: 'FIRE',
          icon: Icons.local_fire_department,
          instructions: [
            '→ Stay calm.',
            '→ Follow emergency exit signs.',
            '→ Proceed to the designated assembly area via Fire Exits.'
          ],
        ),
        const _ProcedureCard(
          title: 'TYPHOON / FLOOD',
          icon: Icons.water,
          instructions: [
            '→ Move away from flooded areas.',
            '→ Follow campus announcements.',
            '→ Stay inside designated safe areas.',
          ],
        ),
      ],
    );
  }
}

class _ProcedureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> instructions;

  const _ProcedureCard({required this.title, required this.icon, required this.instructions});

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.40)),
                ),
                child: Icon(icon, color: const Color(0xFFE50914), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 0.5,
                  color: dark ? Colors.white : const Color(0xFF16181F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...instructions.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right, color: Color(0xFFE50914), size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.replaceFirst('→ ', ''),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

