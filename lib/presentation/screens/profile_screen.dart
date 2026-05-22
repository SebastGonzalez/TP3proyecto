import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';
import 'package:prueba1/presentation/providers/profile_stats_provider.dart';
import 'package:prueba1/presentation/widgets/complete_dex_badge.dart';
import 'package:prueba1/presentation/widgets/default_user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static Future<void> _showEditUsernameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nombre'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nombre de usuario',
              hintText: 'Mínimo 3 caracteres',
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Ingresá un nombre';
              if (trimmed.length < 3) {
                return 'Debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    final newName = saved == true ? controller.text.trim() : null;

    // Liberar el controller después de que el diálogo termine de cerrarse.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (newName == null || !context.mounted) return;

    try {
      await ref.read(myUserProvider.notifier).updateUsername(newName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('ArgumentError: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String _formatMemberSince(DateTime? date) {
    if (date == null) return '—';
    final d = date;
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: stats.ownsCompleteCatalog ? 268 : 220,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar nombre',
                onPressed: stats.isLoading
                    ? null
                    : () => _showEditUsernameDialog(
                          context,
                          ref,
                          stats.displayName,
                        ),
              ),
            ],
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
                    const DefaultUserAvatar(),
                    const SizedBox(height: 12),
                    Text(
                      stats.displayName,
                      style: const TextStyle(
                        color: Color(0xFF2D2D2D),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (stats.ownsCompleteCatalog) ...[
                      const SizedBox(height: 10),
                      const CompleteDexAward(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (stats.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          label: 'Especies',
                          value: '${stats.uniqueSpecies}',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Capturas',
                          value: '${stats.totalCaptures}',
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Legendarios',
                          value: '${stats.legendaryCount}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('INFORMACIÓN'),
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.emoji_events_outlined,
                      label: 'Rango',
                      value: stats.rank,
                    ),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Usuario desde',
                      value: _formatMemberSince(stats.createdAt),
                    ),
                    _InfoTile(
                      icon: Icons.monetization_on_outlined,
                      label: 'Monedas',
                      value: '${stats.coins}',
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

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
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B00),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}

/// Ancho fijo de la columna de etiquetas para alinear los valores a la derecha.
const _kInfoLabelWidth = 132.0;

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF6B00)),
          const SizedBox(width: 14),
          SizedBox(
            width: _kInfoLabelWidth,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
