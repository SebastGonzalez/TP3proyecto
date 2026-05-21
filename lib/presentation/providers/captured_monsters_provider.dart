import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';
import 'package:prueba1/presentation/providers/owned_monsters_provider.dart';

/// Colección del jugador: una entrada por documento en `owned_monsters`.
final capturedMonstersProvider = Provider<List<OwnedMonster>>((ref) {
  return ref.watch(ownedMonstersProvider).when(
        data: (list) => list,
        loading: () => const [],
        error: (_, __) => const [],
      );
});

/// Crea / elimina instancias en Firestore.
class CapturedMonstersNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> add(Monster catalogMonster) async {
    await ref.read(ownedMonstersControllerProvider).capture(catalogMonster);
  }

  Future<void> removeById(String ownedInstanceId) async {
    if (ref.read(homeCompanionProvider) == ownedInstanceId) {
      await ref.read(homeCompanionProvider.notifier).clear();
    }
    await ref.read(ownedMonstersControllerProvider).remove(ownedInstanceId);
  }

  Future<void> clear() async {
    await ref.read(ownedMonstersControllerProvider).clearAll();
    await ref.read(homeCompanionProvider.notifier).clear();
  }
}

final capturedMonstersActionsProvider =
    NotifierProvider<CapturedMonstersNotifier, void>(
  CapturedMonstersNotifier.new,
);
