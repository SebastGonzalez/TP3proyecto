import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/data/monster_repository.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/features/monsters/application/providers/rarities_provider.dart';

final monsterRepositoryProvider = Provider((ref) => MonsterRepository());

/// Catálogo en Firestore (`monsters`). Depende de [raritiesProvider].
final monstersProvider = FutureProvider<List<Monster>>((ref) async {
  final rarities = await ref.watch(raritiesProvider.future);
  final repo = ref.read(monsterRepositoryProvider);
  return repo.getMonsters(rarities: rarities);
});

/// Vuelve a leer `monsters_rarity` y `monsters` desde Firestore.
void refreshMonstersCatalog(WidgetRef ref) {
  ref.invalidate(raritiesProvider);
  ref.invalidate(monstersProvider);
}
