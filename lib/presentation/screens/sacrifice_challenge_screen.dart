import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/monsters/domain/sacrifice_challenge.dart';
import 'package:prueba1/monsters/domain/sacrifice_slot.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';
import 'package:prueba1/presentation/providers/owned_monsters_provider.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';
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
  /// Ids de `owned_monsters/{id}` elegidos por espacio.
  late List<String?> _slotOwnedIds;

  SacrificeChallenge get ch => widget.challenge;

  @override
  void initState() {
    super.initState();
    _slotOwnedIds = List<String?>.filled(ch.slotCount, null);
  }

  @override
  void dispose() {
    ref.invalidate(sacrificeChallengesProvider);
    super.dispose();
  }

  bool _isPickedElsewhere(String ownedId, int excludeSlot) {
    for (var i = 0; i < _slotOwnedIds.length; i++) {
      if (i == excludeSlot) continue;
      if (_slotOwnedIds[i] == ownedId) return true;
    }
    return false;
  }

  bool _availableForSlot(OwnedMonster entry, int slotIndex) {
    return !_isPickedElsewhere(entry.id, slotIndex);
  }

  OwnedMonster? _ownedById(String? id, List<OwnedMonster> captured) {
    if (id == null) return null;
    for (final o in captured) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _openPicker(int slotIndex) {
    final need = ch.slots[slotIndex];
    final captured = ref.read(capturedMonstersProvider);
    final options = captured
        .where(
          (o) => need.matches(o.monster) && _availableForSlot(o, slotIndex),
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
            final o = options[i];
            return ListTile(
              leading: Image.asset(o.monster.imagePath, width: 48, height: 48),
              title: Text(o.monster.name),
              subtitle: Text(o.monster.rarity.label),
              onTap: () {
                setState(() {
                  _slotOwnedIds[slotIndex] = o.id;
                });
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  bool get _allFilled => _slotOwnedIds.every((e) => e != null);

  String _emptySlotMessage(SacrificeSlotRequirement need) => switch (need) {
        RaritySlotRequirement(:final rarity) =>
          'No tenés monstruos ${rarity.label} disponibles para este espacio.',
        MonsterNameSlotRequirement(:final monsterName) =>
          'No tenés a $monsterName disponible para este espacio.',
      };

  bool get _valid {
    if (!_allFilled) return false;
    final captured = ref.read(capturedMonstersProvider);
    for (var i = 0; i < _slotOwnedIds.length; i++) {
      final owned = _ownedById(_slotOwnedIds[i], captured);
      if (owned == null || !ch.slots[i].matches(owned.monster)) return false;
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

    final actions = ref.read(capturedMonstersActionsProvider.notifier);
    final capture = ref.read(ownedMonstersControllerProvider);
    for (final ownedId in _slotOwnedIds) {
      if (ownedId != null) await actions.removeById(ownedId);
    }
    await capture.capture(ch.reward);
    await ref.read(sacrificeProgressProvider.notifier).markCompleted(ch.id);

    if (!mounted) return;
    await showGatchaReveal(context, ch.reward);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(sacrificeProgressProvider).contains(ch.id);
    final captured = ref.watch(capturedMonstersProvider);

    return Scaffold(
      appBar: AppPageAppBar(title: ch.title),
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
              final picked = _ownedById(_slotOwnedIds[i], captured);
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
                                    monster: picked.monster,
                                    rarityColor: picked.monster.rarity.color,
                                    onTap: () => _openPicker(i),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton.filledTonal(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      setState(() => _slotOwnedIds[i] = null);
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
