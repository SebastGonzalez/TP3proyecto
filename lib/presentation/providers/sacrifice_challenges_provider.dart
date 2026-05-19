import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/data/sacrifice_repository.dart';
import 'package:prueba1/presentation/providers/mymonster_provider.dart';

final sacrificeRepositoryProvider = Provider((ref) => SacrificeRepository());

/// Desafíos SBC activos (`active: true` en Firestore), resueltos contra `monsters`.
final sacrificeChallengesProvider =
    FutureProvider<SacrificeChallengesState>((ref) async {
  final monsters = await ref.watch(monstersProvider.future);
  final repo = ref.read(sacrificeRepositoryProvider);
  return repo.loadChallenges(monsters);
});
