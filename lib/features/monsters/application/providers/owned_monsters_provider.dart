import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/monsters/domain/models/owned_monster.dart';
import 'package:prueba1/features/monsters/data/repositories/owned_monster_repository.dart';
import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/auth/application/providers/auth_provider.dart';
import 'package:prueba1/features/monsters/application/providers/mymonster_provider.dart';
import 'package:prueba1/features/monsters/application/providers/rarities_provider.dart';

final ownedMonsterRepositoryProvider = Provider(
  (ref) => OwnedMonsterRepository(),
);

/// Instancias del jugador en `owned_monsters` (una fila por captura).
final ownedMonstersProvider = StreamProvider<List<OwnedMonster>>((ref) async* {
  ref.listen(userProvider, (previous, next) {
    final prevUid = previous?.value?.uid;
    final nextUid = next.value?.uid;
    if (prevUid != nextUid) {
      ref.invalidateSelf();
    }
  });

  final authUser = ref.watch(userProvider).value;
  if (authUser == null) {
    yield const [];
    return;
  }

  await ref.watch(raritiesProvider.future);
  final catalog = await ref.watch(monstersProvider.future);
  final repo = ref.read(ownedMonsterRepositoryProvider);

  await repo.migrateLegacyMonstersFromUser(
    ownerId: authUser.uid,
    catalog: catalog,
  );

  yield* repo.watchByOwner(ownerId: authUser.uid, catalog: catalog);
});

/// Acciones sobre la colección (crear / borrar instancias).
final ownedMonstersControllerProvider = Provider(OwnedMonstersController.new);

class OwnedMonstersController {
  OwnedMonstersController(this._ref);

  final Ref _ref;

  Future<OwnedMonster?> capture(Monster catalogMonster) async {
    final uid = _ref.read(userProvider).value?.uid;
    if (uid == null) return null;

    await _ref.read(raritiesProvider.future);
    final catalog = await _ref.read(monstersProvider.future);
    return _ref
        .read(ownedMonsterRepositoryProvider)
        .create(ownerId: uid, monsterId: catalogMonster.id, catalog: catalog);
  }

  Future<List<OwnedMonster>> purchaseCaptures({
    required int cost,
    required List<Monster> monsters,
  }) async {
    final uid = _ref.read(userProvider).value?.uid;
    if (uid == null) return const [];

    await _ref.read(raritiesProvider.future);
    final catalog = await _ref.read(monstersProvider.future);
    return _ref
        .read(ownedMonsterRepositoryProvider)
        .purchaseCaptures(
          ownerId: uid,
          cost: cost,
          monsters: monsters,
          catalog: catalog,
        );
  }

  Future<void> remove(String ownedInstanceId) async {
    await _ref.read(ownedMonsterRepositoryProvider).delete(ownedInstanceId);
  }

  Future<void> removeMany(Iterable<String> ownedInstanceIds) async {
    await _ref
        .read(ownedMonsterRepositoryProvider)
        .deleteMany(ownedInstanceIds);
  }

  Future<void> clearAll() async {
    final uid = _ref.read(userProvider).value?.uid;
    if (uid == null) return;
    await _ref.read(ownedMonsterRepositoryProvider).deleteAllForOwner(uid);
  }
}
