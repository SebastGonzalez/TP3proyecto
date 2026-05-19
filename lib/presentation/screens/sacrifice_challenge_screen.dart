import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/sacrifice_challenge.dart';
import 'package:prueba1/monsters/domain/sacrifice_slot.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';
import 'package:prueba1/presentation/providers/mymonster_provider.dart';
import 'package:prueba1/presentation/providers/sacrifice_challenges_provider.dart';
import 'package:prueba1/presentation/providers/sacrifice_progress_provider.dart';
import 'package:prueba1/presentation/widgets/gatcha_reveal.dart';
import 'package:prueba1/presentation/widgets/monster_card_tile.dart';

class SacrificeChallengeScreen extends ConsumerStatefulWidget {
  const SacrificeChallengeScreen({super.key, required this.challenge});

  final SacrificeChallenge challenge;

  @override
  ConsumerState<SacrificeChallengeScreen> createState() =>
      _SacrificeChallengeScreenState();
}

class _SacrificeChallengeScreenState
    extends ConsumerState<SacrificeChallengeScreen> {
  late List<Monster?> _slots;

  SacrificeChallenge get ch => widget.challenge;

  @override
  void initState() {
    super.initState();
    _slots = List<Monster?>.filled(ch.slotCount, null);
  }

  @override
  void dispose() {
    // Al volver a la lista, recargar catálogo y SBC por si cambió Firestore.
    ref.invalidate(monstersProvider);
    ref.invalidate(sacrificeChallengesProvider);
    super.dispose();
  }

  int _usesElsewhere(Monster monster, int excludeSlot) {
    var n = 0;
    for (var i = 0; i < _slots.length; i++) {
      if (i == excludeSlot) continue;
      final p = _slots[i];
      if (p != null && p.name == monster.name) n++;
    }
    return n;
  }

  bool _availableForSlot(CapturedEntry entry, int slotIndex) {
    final usedElse = _usesElsewhere(entry.monster, slotIndex);
    return entry.count - usedElse >= 1;
  }

  void _openPicker(int slotIndex) {
    final need = ch.slots[slotIndex];
    final captured = ref.read(capturedMonstersProvider);
    final options = captured
        .where(
          (e) => need.matches(e.monster) && _availableForSlot(e, slotIndex),
        )
        .toList();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        if (options.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _emptySlotMessage(need),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: options.length,
          itemBuilder: (_, i) {
            final e = options[i];
            final free = e.count - _usesElsewhere(e.monster, slotIndex);
            return ListTile(
              leading: Image.asset(e.monster.imagePath, width: 48, height: 48),
              title: Text(e.monster.name),
              subtitle: Text('${e.monster.rarity.label}  •  Disponibles: $free'),
              onTap: () {
                setState(() {
                  _slots[slotIndex] = e.monster;
                });
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  bool get _allFilled => _slots.every((e) => e != null);

  String _emptySlotMessage(SacrificeSlotRequirement need) => switch (need) {
        RaritySlotRequirement(:final rarity) =>
          'No tenés monstruos ${rarity.label} disponibles para este espacio.',
        MonsterNameSlotRequirement(:final monsterName) =>
          'No tenés a $monsterName disponible para este espacio.',
      };

  bool get _valid {
    if (!_allFilled) return false;
    for (var i = 0; i < _slots.length; i++) {
      if (!ch.slots[i].matches(_slots[i]!)) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_valid) return;
    final completed = ref.read(sacrificeProgressProvider);
    if (completed.contains(ch.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este desafío ya fue completado.')),
      );
      return;
    }

    final notifier = ref.read(capturedMonstersProvider.notifier);
    for (final m in _slots) {
      if (m != null) notifier.removeOne(m);
    }
    notifier.add(ch.reward);
    ref.read(sacrificeProgressProvider.notifier).markCompleted(ch.id);

    if (!mounted) return;
    await showGatchaReveal(context, ch.reward);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(sacrificeProgressProvider).contains(ch.id);

    return Scaffold(
      appBar: AppBar(title: Text(ch.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            ch.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Recompensa',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: MonsterCardTile(
              monster: ch.reward,
              rarityColor: ch.reward.rarity.color,
            ),
          ),
          if (done) ...[
            const SizedBox(height: 16),
            const Chip(
              avatar: Icon(Icons.check_circle, size: 20),
              label: Text('Desafío completado'),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Text(
              'Elegí tus monstruos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(ch.slotCount, (i) {
              final requirement = ch.slots[i];
              final picked = _slots[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _slotTitle(i, requirement),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 168,
                      child: picked == null
                          ? _EmptySlot(onTap: () => _openPicker(i))
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: MonsterCardTile(
                                    monster: picked,
                                    rarityColor: picked.rarity.color,
                                    onTap: () => _openPicker(i),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton.filledTonal(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      setState(() => _slots[i] = null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: !_valid ? null : _submit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Entregar y reclamar recompensa'),
            ),
          ],
        ],
      ),
    );
  }

  String _slotTitle(int index, SacrificeSlotRequirement requirement) =>
      switch (requirement) {
        RaritySlotRequirement(:final rarity) =>
          'Espacio ${index + 1}: ${rarity.label}',
        MonsterNameSlotRequirement(:final monsterName) =>
          'Espacio ${index + 1}: $monsterName',
      };
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 40,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 6),
              Text(
                'Tocá para elegir',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
