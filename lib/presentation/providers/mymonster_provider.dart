import 'package:prueba1/monsters/domain/monster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/data/monster_repository.dart';

final monsterRepositoryProvider = Provider((ref) => MonsterRepository());

/// Catálogo en Firestore (`monsters`). Se refresca al entrar en Pokédex, Mis monstruos o Gatcha.
final monstersProvider = FutureProvider<List<Monster>>((ref) async {
  final repo = ref.read(monsterRepositoryProvider);
  return repo.getMonsters();
});

/// Vuelve a leer `monsters` (nombre, homeScale, homeFacing, etc.).
void refreshMonstersCatalog(WidgetRef ref) {
  ref.invalidate(monstersProvider);
}