import 'package:prueba1/monsters/domain/monster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/monsters/data/monster_repository.dart';

final monsterRepositoryProvider = Provider((ref) => MonsterRepository());

final monstersProvider = FutureProvider<List<Monster>>((ref) async {
  final repo = ref.read(monsterRepositoryProvider);
  return repo.getMonsters();
});