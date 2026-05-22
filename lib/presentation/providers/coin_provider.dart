import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/data/user_repository.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';

/// Saldo actual del jugador (Firestore vía [myUserProvider]).
final coinProvider = Provider<int>((ref) {
  final user = ref.watch(myUserProvider);
  return user.value?.coins ?? UserRepository.defaultCoins;
});

/// Persiste cambios de monedas en `users` (delega en [MyUserNotifier]).
final coinControllerProvider = Provider<CoinController>(
  (ref) => CoinController(ref),
);

class CoinController {
  CoinController(this._ref);

  final Ref _ref;

  Future<void> update(int Function(int current) updater) {
    return _ref.read(myUserProvider.notifier).updateCoins(updater);
  }

  Future<void> set(int coins) {
    return _ref.read(myUserProvider.notifier).setCoins(coins);
  }
}
