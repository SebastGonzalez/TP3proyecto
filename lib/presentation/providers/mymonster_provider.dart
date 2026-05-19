import 'package:prueba1/monsters/domain/monster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/data/monster_repository.dart';

final monsterRepositoryProvider = Provider((ref) => MonsterRepository());

/// Catálogo en Firestore (`monsters`). Se invalida al entrar en Gatcha, Pokedex o Sacrificios.
final monstersProvider = FutureProvider<List<Monster>>((ref) async {
  final repo = ref.read(monsterRepositoryProvider);
  return repo.getMonsters();
});