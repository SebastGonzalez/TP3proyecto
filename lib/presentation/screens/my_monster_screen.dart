import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';

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
                      return _CapturedCard(
                        entry: entry,
                        rarityColor: entry.monster.rarity.color,
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

class _CapturedCard extends StatelessWidget {
  const _CapturedCard({
    required this.entry,
    required this.rarityColor,
    required this.onTap,
  });

  final CapturedEntry entry;
  final Color rarityColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: rarityColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      entry.monster.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.monster.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    entry.monster.rarity.label,
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.count > 1)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'x${entry.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
