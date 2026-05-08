import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con avatar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF8F0), Color(0xFFFFF3E0)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: Image.network( 'https://www.pngall.com/wp-content/uploads/5/Profile-PNG-High-Quality-Image.png').image,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'User Name',
                      style: TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Level: 1',
                      style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas
                  Row(
                    children: [
                      _StatCard(label: 'Monstruos', value: '0'),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Capturas', value: '0'),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Legendarios', value: '0'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sección info
                  _SectionLabel('INFORMACIÓN'),
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.badge_outlined, label: 'Nombre', value: 'Entrenador'),
                  _InfoTile(icon: Icons.star_outline, label: 'Nivel', value: '1'),
                  _InfoTile(icon: Icons.emoji_events_outlined, label: 'Rango', value: 'Novato'),

                  const SizedBox(height: 24),

                  // Sección ajustes
                  _SectionLabel('AJUSTES'),
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.notifications_outlined, label: 'Notificaciones', value: 'Activadas'),
                  _InfoTile(icon: Icons.language_outlined, label: 'Idioma', value: 'Español'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B00))),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.grey.shade500)),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF6B00)),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}