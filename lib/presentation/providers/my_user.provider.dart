import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/data/user_repository.dart';
import 'package:prueba1/core/domain/my_user.dart';
import 'package:prueba1/core/services/auth_service.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/owned_monsters_provider.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

/// Perfil del jugador logueado (uid de Firebase Auth y monedas).
final myUserProvider =
    AsyncNotifierProvider<MyUserNotifier, MyUser?>(MyUserNotifier.new);

/// Monedas del usuario activo (misma fuente que [coinProvider] cuando hay sesión).
final myUserCoinsProvider = Provider<int>((ref) {
  final asyncUser = ref.watch(myUserProvider);
  return asyncUser.value?.coins ?? UserRepository.defaultCoins;
});

class MyUserNotifier extends AsyncNotifier<MyUser?> {
  @override
  Future<MyUser?> build() async {
    ref.listen(userProvider, (previous, next) {
      final prevUid = previous?.value?.uid;
      final nextUid = next.value?.uid;
      if (prevUid != nextUid) {
        ref.invalidateSelf();
        ref.invalidate(ownedMonstersProvider);
      }
    });

    final authUser = ref.watch(userProvider).value;
    if (authUser == null) return null;

    final repo = ref.read(userRepositoryProvider);
    final uid = authUser.uid;

    // Escucha cambios en Firestore (consola, otra pestaña, etc.).
    final subscription = repo.watchUser(uid: uid).listen((remote) {
      if (remote != null) state = AsyncData(remote);
    });
    ref.onDispose(subscription.cancel);

    var user = await repo.getUser(uid: uid);
    user ??= await repo.createUser(
      uid: uid,
      username: AuthService.usernameFromUser(authUser),
    );

    return user;
  }

  Future<void> updateCoins(int Function(int current) updater) async {
    final current = state.value;
    if (current == null) return;
    await ref.read(userRepositoryProvider).saveCoins(
          current.uid,
          updater(current.coins),
        );
  }

  Future<void> setCoins(int coins) async {
    final current = state.value;
    if (current == null) return;
    await ref.read(userRepositoryProvider).saveCoins(current.uid, coins);
  }

  Future<void> updateUsername(String username) async {
    final current = state.value;
    if (current == null) return;

    final trimmed = username.trim();
    if (trimmed.length < 3) {
      throw ArgumentError(
        'El nombre de usuario debe tener al menos 3 caracteres',
      );
    }

    await ref.read(userRepositoryProvider).saveUsername(current.uid, trimmed);
    await AuthService.updateDisplayName(trimmed);
    ref.read(loggedInUsernameProvider.notifier).state = trimmed;
  }
}
