import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';

/// Monstruo elegido para mostrarse detrás del personaje en la home.
class HomeCompanionNotifier extends Notifier<Monster?> {
  @override
  Monster? build() => null;

  void setCompanion(Monster monster) => state = monster;

  void clear() => state = null;
}

final homeCompanionProvider =
    NotifierProvider<HomeCompanionNotifier, Monster?>(HomeCompanionNotifier.new);

/// Solo muestra compañero si sigue en la colección del jugador.
final homeCompanionVisibleProvider = Provider<Monster?>((ref) {
  final selected = ref.watch(homeCompanionProvider);
  if (selected == null) return null;
  final owned = ref.watch(capturedMonstersProvider);
  final stillOwned = owned.any((e) => e.monster.id == selected.id);
  return stillOwned ? selected : null;
});
