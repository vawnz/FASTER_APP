import 'package:flutter/material.dart';
import '../../core/constants.dart';

// ============================================================
// CONTACTS PAGE
// ============================================================

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: dark ? Colors.white : const Color(0xFF16181F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap any contact to initiate direct emergency response.',
          style: TextStyle(
            fontSize: 13,
            color: dark ? Colors.white60 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),
        const _ContactCard(title: 'Campus Emergency', subtitle: 'Emergency Response Team', icon: Icons.local_police),
        const _ContactCard(title: 'Campus Security', subtitle: 'Security Office', icon: Icons.security),
        const _ContactCard(title: 'Medical Assistance', subtitle: 'Campus Clinic', icon: Icons.local_hospital),
        const _ContactCard(title: 'Fire Emergency', subtitle: 'Fire Response', icon: Icons.local_fire_department),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ContactCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: dark ? const Color(0xB3141620) : Colors.white.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: dark ? Colors.white : const Color(0xFF16181F),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: dark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE50914).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.40)),
          ),
          child: const Icon(Icons.phone, color: Color(0xFFE50914), size: 18),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFE50914),
              content: Text('Calling $title ($subtitle)...'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

