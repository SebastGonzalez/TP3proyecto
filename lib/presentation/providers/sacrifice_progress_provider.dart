import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory set of completed sacrifice challenge ids.
class SacrificeProgressNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markCompleted(String challengeId) {
    state = {...state, challengeId};
  }

  bool isCompleted(String challengeId) => state.contains(challengeId);
}

final sacrificeProgressProvider =
    NotifierProvider<SacrificeProgressNotifier, Set<String>>(
  SacrificeProgressNotifier.new,
);
