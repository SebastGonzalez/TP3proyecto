import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/data/user_repository.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';

/// Monedas del jugador. Con sesión activa lee/escribe vía [myUserProvider] en Firestore.
class CoinNotifier extends Notifier<int> {
  @override
  int build() {
    ref.listen(myUserProvider, (_, next) {
      next.whenData((user) {
        state = user?.coins ?? UserRepository.defaultCoins;
      });
    });
    return ref.watch(myUserCoinsProvider);
  }

  void update(int Function(int current) updater) {
    ref.read(myUserProvider.notifier).updateCoins(updater);
  }
}

final coinProvider = NotifierProvider<CoinNotifier, int>(CoinNotifier.new);
