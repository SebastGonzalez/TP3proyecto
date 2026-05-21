import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';
import 'package:prueba1/presentation/providers/mymonster_provider.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';
import 'package:prueba1/presentation/widgets/monster_card_tile.dart';

class MyMonsterScreen extends ConsumerStatefulWidget {
  const MyMonsterScreen({super.key});

  @override
  ConsumerState<MyMonsterScreen> createState() => _MyMonsterScreenState();
}

class _MyMonsterScreenState extends ConsumerState<MyMonsterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshMonstersCatalog(ref);
    });
  }

  void _showCompanionHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compañero en la home'),
        content: const Text(
          'Mantené presionado un monstruo de tu colección para que '
          'aparezca detrás de tu personaje en la pantalla principal.\n\n'
          'Volvé a mantener presionado el mismo para quitarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _onCompanionLongPress(
    BuildContext context,
    WidgetRef ref,
    OwnedMonster entry,
    bool isCompanion,
  ) async {
    final notifier = ref.read(homeCompanionProvider.notifier);
    if (isCompanion) {
      await notifier.clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.monster.name} ya no te acompaña en la home')),
      );
    } else {
      await notifier.setCompanion(
        entry.id,
        imagePath: entry.monster.imagePath,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.monster.name} te acompañará en la home')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final captured = ref.watch(capturedMonstersProvider);
    final companionId = ref.watch(homeCompanionProvider);
    final unique = captured.map((e) => e.monsterId).toSet().length;
    final total = captured.length;

    return Scaffold(
      appBar: AppPageAppBar(
        title: 'Mis monstruos',
        actions: [
          if (captured.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar colección',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(capturedMonstersActionsProvider.notifier).clear(),
            ),
        ],
      ),
      body: captured.isEmpty
          ? _EmptyState()
          : Column(
              children: [
                if (companionId == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Material(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              color: Colors.blue.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mantené presionado un monstruo para mostrarlo en la home.',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                      final isCompanion = companionId == entry.id;
                      return MonsterCardTile(
                        monster: entry.monster,
                        rarityColor: entry.monster.rarity.color,
                        highlighted: isCompanion,
                        onTap: () => context.push(
                          '/details',
                          extra: entry.monster,
                        ),
                        onLongPress: () => _onCompanionLongPress(
                          context,
                          ref,
                          entry,
                          isCompanion,
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
