import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/auth/application/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';

/// SBC completados del jugador (persistidos en `users.completedSbcIds`).
class SacrificeProgressNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen(myUserProvider, (previous, next) {
      final ids = next.value?.completedSbcIds;
      if (ids != null) {
        state = ids.toSet();
      } else if (next.value == null) {
        state = {};
      }
    });

    return ref.watch(myUserProvider).value?.completedSbcIds.toSet() ?? {};
  }

  Future<void> markCompleted(String challengeId) async {
    if (state.contains(challengeId)) return;

    final uid = ref.read(userProvider).value?.uid;
    if (uid == null) return;

    state = {...state, challengeId};
    await ref.read(userRepositoryProvider).markSbcCompleted(uid, challengeId);
  }

  bool isCompleted(String challengeId) => state.contains(challengeId);
}

final sacrificeProgressProvider =
    NotifierProvider<SacrificeProgressNotifier, Set<String>>(
  SacrificeProgressNotifier.new,
);
