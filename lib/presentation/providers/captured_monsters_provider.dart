import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';

/// Una entrada en la colección del jugador: el monstruo capturado y cuántas
/// veces lo obtuvo (para mostrar duplicados como "x2", "x3", etc.).
class CapturedEntry {
  final Monster monster;
  final int count;

  const CapturedEntry({required this.monster, required this.count});

  CapturedEntry copyWith({Monster? monster, int? count}) => CapturedEntry(
        monster: monster ?? this.monster,
        count: count ?? this.count,
      );
}

/// Colección del jugador. Con sesión activa persiste en `users/{uid}.monsters`.
class CapturedMonstersNotifier extends Notifier<List<CapturedEntry>> {
  @override
  List<CapturedEntry> build() {
    ref.listen(myUserProvider, (_, next) {
      next.whenData((user) {
        state = user?.monsters ?? const [];
      });
    });
    return ref.watch(myUserMonstersProvider);
  }

  void add(Monster monster) {
    ref.read(myUserProvider.notifier).addMonster(monster);
  }

  /// Removes one copy of [monster] from the collection (for sacrifices / SBC).
  void removeOne(Monster monster) {
    ref.read(myUserProvider.notifier).removeOneMonster(monster);
    final monsters = ref.read(myUserProvider).value?.monsters ?? const [];
    final companion = ref.read(homeCompanionProvider);
    if (companion?.id != monster.id) return;
    final stillOwned = monsters.any((e) => e.monster.id == monster.id);
    if (!stillOwned) {
      ref.read(homeCompanionProvider.notifier).clear();
    }
  }

  void clear() {
    ref.read(myUserProvider.notifier).clearMonsters();
    ref.read(homeCompanionProvider.notifier).clear();
  }
}

final capturedMonstersProvider =
    NotifierProvider<CapturedMonstersNotifier, List<CapturedEntry>>(
  CapturedMonstersNotifier.new,
);
