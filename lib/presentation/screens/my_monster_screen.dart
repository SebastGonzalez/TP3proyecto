import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';
import 'package:prueba1/presentation/widgets/monster_card_tile.dart';

class MyMonsterScreen extends ConsumerWidget {
  const MyMonsterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captured = ref.watch(capturedMonstersProvider);
    final unique = captured.length;
    final total = captured.fold<int>(0, (s, e) => s + e.count);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Monsters'),
        actions: [
          if (captured.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar colección',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(capturedMonstersProvider.notifier).clear(),
            ),
        ],
      ),
      body: captured.isEmpty
          ? _EmptyState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Únicos: $unique  •  Total: $total',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: captured.length,
                    itemBuilder: (context, i) {
                      final entry = captured[i];
                      return MonsterCardTile(
                        monster: entry.monster,
                        rarityColor: entry.monster.rarity.color,
                        stackCount: entry.count,
                        onTap: () => context.push(
                          '/details',
                          extra: entry.monster,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Todavía no tenés monstruos',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Probá la máquina Gatcha!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/gatcha'),
            icon: const Icon(Icons.casino),
            label: const Text('Ir al Gatcha'),
          ),
        ],
      ),
    );
  }
}
