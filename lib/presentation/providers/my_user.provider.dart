import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/data/user_repository.dart';
import 'package:prueba1/core/domain/my_user.dart';
import 'package:prueba1/core/services/auth_service.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';
import 'package:prueba1/presentation/providers/mymonster_provider.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

/// Perfil del jugador logueado (uid de Firebase Auth, monedas y monstruos).
final myUserProvider =
    AsyncNotifierProvider<MyUserNotifier, MyUser?>(MyUserNotifier.new);

/// Monedas del usuario activo (misma fuente que [coinProvider] cuando hay sesión).
final myUserCoinsProvider = Provider<int>((ref) {
  final asyncUser = ref.watch(myUserProvider);
  return asyncUser.value?.coins ?? UserRepository.defaultCoins;
});

/// Colección de monstruos del usuario (resuelta contra el catálogo `monsters`).
final myUserMonstersProvider = Provider<List<CapturedEntry>>((ref) {
  return ref.watch(myUserProvider).value?.monsters ?? const [];
});

class MyUserNotifier extends AsyncNotifier<MyUser?> {
  @override
  Future<MyUser?> build() async {
    ref.listen(userProvider, (previous, next) {
      final prevUid = previous?.value?.uid;
      final nextUid = next.value?.uid;
      if (prevUid != nextUid) {
        ref.invalidateSelf();
      }
    });

    final authUser = ref.watch(userProvider).value;
    if (authUser == null) return null;

    final repo = ref.read(userRepositoryProvider);
    final catalog = await ref.watch(monstersProvider.future);

    var user = await repo.getUser(uid: authUser.uid, catalog: catalog);
    user ??= await repo.createUser(
      uid: authUser.uid,
      username: AuthService.usernameFromUser(authUser),
      catalog: catalog,
    );

    return user;
  }

  Future<void> updateCoins(int Function(int current) updater) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(coins: updater(current.coins));
    state = AsyncData(next);
    await ref.read(userRepositoryProvider).saveCoins(next.uid, next.coins);
  }

  Future<void> setCoins(int coins) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(coins: coins);
    state = AsyncData(next);
    await ref.read(userRepositoryProvider).saveCoins(next.uid, coins);
  }

  Future<void> addMonster(Monster monster) async {
    final current = state.value;
    if (current == null) return;

    final list = [...current.monsters];
    final idx = list.indexWhere((e) => e.monster.id == monster.id);
    if (idx == -1) {
      list.add(CapturedEntry(monster: monster, count: 1));
    } else {
      list[idx] = list[idx].copyWith(count: list[idx].count + 1);
    }

    await _applyMonsters(current.copyWith(monsters: list));
  }

  Future<void> removeOneMonster(Monster monster) async {
    final current = state.value;
    if (current == null) return;

    final list = [...current.monsters];
    final idx = list.indexWhere((e) => e.monster.id == monster.id);
    if (idx == -1) return;

    final cur = list[idx];
    if (cur.count <= 1) {
      list.removeAt(idx);
    } else {
      list[idx] = cur.copyWith(count: cur.count - 1);
    }

    await _applyMonsters(current.copyWith(monsters: list));
  }

  Future<void> clearMonsters() async {
    final current = state.value;
    if (current == null) return;
    await _applyMonsters(current.copyWith(monsters: const []));
  }

  Future<void> _applyMonsters(MyUser next) async {
    state = AsyncData(next);
    final repo = ref.read(userRepositoryProvider);
    final stamps = [
      for (final e in next.monsters)
        OwnedMonsterStamp(monsterId: e.monster.id, count: e.count),
    ];
    await repo.saveMonsters(next.uid, stamps);
  }
}
