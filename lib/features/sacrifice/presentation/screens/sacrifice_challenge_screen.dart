import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/features/monsters/domain/models/owned_monster.dart';
import 'package:prueba1/features/sacrifice/domain/models/sacrifice_challenge.dart';
import 'package:prueba1/features/sacrifice/domain/models/sacrifice_slot.dart';
import 'package:prueba1/features/monsters/application/providers/captured_monsters_provider.dart';
import 'package:prueba1/features/monsters/application/providers/owned_monsters_provider.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';
import 'package:prueba1/features/sacrifice/application/providers/sacrifice_challenges_provider.dart';
import 'package:prueba1/features/sacrifice/application/providers/sacrifice_progress_provider.dart';
import 'package:prueba1/presentation/widgets/gatcha_reveal.dart';
import 'package:prueba1/features/monsters/presentation/widgets/monster_card_tile.dart';

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

  /// Mientras se entrega: fija las cartas elegidas para que el stream no las “saque”.
  bool _submitting = false;
  Map<int, OwnedMonster>? _frozenPicks;

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

  OwnedMonster? _pickedForSlot(int slotIndex, List<OwnedMonster> captured) {
    if (_submitting && _frozenPicks != null) {
      return _frozenPicks![slotIndex];
    }
    return _ownedById(_slotOwnedIds[slotIndex], captured);
  }

  List<OwnedMonster> _capturedOrEmpty() {
    return ref.read(capturedMonstersAsyncProvider).value ?? const [];
  }

  void _openPicker(int slotIndex) {
    final need = ch.slots[slotIndex];
    final async = ref.read(capturedMonstersAsyncProvider);
    if (async.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando tu colección…')),
      );
      return;
    }
    final captured = async.value ?? const [];
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
    final captured = _capturedOrEmpty();
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

    final captured = _capturedOrEmpty();
    final frozen = <int, OwnedMonster>{};
    for (var i = 0; i < _slotOwnedIds.length; i++) {
      final owned = _ownedById(_slotOwnedIds[i], captured);
      if (owned != null) frozen[i] = owned;
    }

    setState(() {
      _submitting = true;
      _frozenPicks = frozen;
    });

    try {
      final actions = ref.read(capturedMonstersActionsProvider.notifier);
      final capture = ref.read(ownedMonstersControllerProvider);
      await actions.removeManyByIds(_slotOwnedIds.whereType<String>());
      await capture.capture(ch.reward);
      await ref.read(sacrificeProgressProvider.notifier).markCompleted(ch.id);

      if (!mounted) return;
      await showGatchaReveal(context, ch.reward);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _frozenPicks = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar: $e')),
      );
    }
  }

  String _slotTitle(int index, SacrificeSlotRequirement requirement) =>
      switch (requirement) {
        RaritySlotRequirement(:final rarity) =>
          'Espacio ${index + 1}: ${rarity.label}',
        MonsterNameSlotRequirement(:final monsterName) =>
          'Espacio ${index + 1}: $monsterName',
      };

  Widget _buildSlotContent({
    required int slotIndex,
    required OwnedMonster? picked,
    required bool locked,
  }) {
    if (picked == null) {
      if (locked) {
        return const SizedBox.shrink();
      }
      return _EmptySlot(onTap: () => _openPicker(slotIndex));
    }
    final card = MonsterCardTile(
      monster: picked.monster,
      rarityColor: picked.monster.rarity.color,
      onTap: locked ? null : () => _openPicker(slotIndex),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: card),
        if (!locked)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() => _slotOwnedIds[slotIndex] = null);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBody(List<OwnedMonster> captured, bool done) {
    final showCompleted = done && !_submitting;
    final content = ListView(
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
          width: double.infinity,
          child: MonsterCardTile(
            monster: ch.reward,
            rarityColor: ch.reward.rarity.color,
          ),
        ),
        if (showCompleted) ...[
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
            final picked = _pickedForSlot(i, captured);
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
                    child: _buildSlotContent(
                      slotIndex: i,
                      picked: picked,
                      locked: _submitting,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (!_submitting) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: !_valid ? null : _submit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Entregar y reclamar recompensa'),
            ),
          ],
        ],
      ],
    );

    if (!_submitting) return content;

    return Stack(
      children: [
        content,
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(sacrificeProgressProvider).contains(ch.id);
    final capturedAsync = ref.watch(capturedMonstersAsyncProvider);

    return Scaffold(
      appBar: AppPageAppBar(title: ch.title),
      body: capturedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (captured) => _buildBody(captured, done),
      ),
    );
  }
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
