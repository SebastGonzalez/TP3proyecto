import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';
import 'package:prueba1/presentation/providers/owned_monsters_provider.dart';

/// Colección del jugador con estado de carga/error (fuente: [ownedMonstersProvider]).
final capturedMonstersAsyncProvider =
    Provider<AsyncValue<List<OwnedMonster>>>((ref) {
  return ref.watch(ownedMonstersProvider);
});

/// Lista resuelta; vacía mientras carga. Preferí [capturedMonstersAsyncProvider] en UI.
final capturedMonstersProvider = Provider<List<OwnedMonster>>((ref) {
  return ref.watch(capturedMonstersAsyncProvider).value ?? const [];
});

/// Crea / elimina instancias en Firestore.
class CapturedMonstersNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> add(Monster catalogMonster) async {
    await ref.read(ownedMonstersControllerProvider).capture(catalogMonster);
  }

  Future<void> removeById(String ownedInstanceId) async {
    await removeManyByIds([ownedInstanceId]);
  }

  Future<void> removeManyByIds(Iterable<String> ownedInstanceIds) async {
    final ids = ownedInstanceIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return;
    final companion = ref.read(homeCompanionProvider);
    if (companion != null && ids.contains(companion)) {
      await ref.read(homeCompanionProvider.notifier).clear();
    }
    await ref.read(ownedMonstersControllerProvider).removeMany(ids);
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
