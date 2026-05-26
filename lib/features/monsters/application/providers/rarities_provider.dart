import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/monsters/data/repositories/rarity_repository.dart';
import 'package:prueba1/features/monsters/domain/models/rarity.dart';

final rarityRepositoryProvider = Provider((ref) => RarityRepository());

/// Rarezas desde Firestore (`monsters_rarity`). Fallback local si la colección está vacía.
final raritiesProvider = FutureProvider<RarityCatalog>((ref) async {
  return ref.read(rarityRepositoryProvider).loadCatalog();
});

/// Recarga rarezas y catálogo de monstruos (misma llamada que [refreshMonstersCatalog]).
void refreshRaritiesCatalog(WidgetRef ref) {
  ref.invalidate(raritiesProvider);
}
