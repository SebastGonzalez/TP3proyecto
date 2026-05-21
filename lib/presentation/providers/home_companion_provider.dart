import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';

/// Id de `owned_monsters/{id}` elegido para la home.
class HomeCompanionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCompanion(String ownedInstanceId) => state = ownedInstanceId;

  void clear() => state = null;
}

final homeCompanionProvider =
    NotifierProvider<HomeCompanionNotifier, String?>(HomeCompanionNotifier.new);

/// Monstruo visible en home si la instancia sigue en la colección.
final homeCompanionVisibleProvider = Provider<Monster?>((ref) {
  final selectedId = ref.watch(homeCompanionProvider);
  if (selectedId == null) return null;
  final owned = ref.watch(capturedMonstersProvider);
  for (final o in owned) {
    if (o.id == selectedId) return o.monster;
  }
  return null;
});
