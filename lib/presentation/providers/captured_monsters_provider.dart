import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';

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

/// Notifier que guarda los monstruos capturados por el jugador en memoria.
/// Si se cierra la app, la lista se reinicia (persistencia "fake").
class CapturedMonstersNotifier extends Notifier<List<CapturedEntry>> {
  @override
  List<CapturedEntry> build() => const [];

  void add(Monster monster) {
    final idx = state.indexWhere((e) => e.monster.name == monster.name);
    if (idx == -1) {
      state = [...state, CapturedEntry(monster: monster, count: 1)];
    } else {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(count: updated[idx].count + 1);
      state = updated;
    }
  }

  /// Removes one copy of [monster] from the collection (for sacrifices / SBC).
  void removeOne(Monster monster) {
    final idx = state.indexWhere((e) => e.monster.name == monster.name);
    if (idx == -1) return;
    final cur = state[idx];
    if (cur.count <= 1) {
      final next = [...state]..removeAt(idx);
      state = next;
    } else {
      final updated = [...state];
      updated[idx] = cur.copyWith(count: cur.count - 1);
      state = updated;
    }
    _clearCompanionIfNeeded(monster.name);
  }

  void clear() {
    state = const [];
    ref.read(homeCompanionProvider.notifier).clear();
  }

  void _clearCompanionIfNeeded(String monsterName) {
    final companion = ref.read(homeCompanionProvider);
    if (companion?.name != monsterName) return;
    final stillOwned = state.any((e) => e.monster.name == monsterName);
    if (!stillOwned) {
      ref.read(homeCompanionProvider.notifier).clear();
    }
  }
}

final capturedMonstersProvider =
    NotifierProvider<CapturedMonstersNotifier, List<CapturedEntry>>(
  CapturedMonstersNotifier.new,
);
