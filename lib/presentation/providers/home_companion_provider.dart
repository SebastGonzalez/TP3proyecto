import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';
import 'package:prueba1/presentation/providers/mymonster_provider.dart';
import 'package:prueba1/presentation/providers/owned_monsters_provider.dart';

/// Id de `owned_monsters/{id}` elegido para la home (persistido en `users`).
class HomeCompanionNotifier extends Notifier<String?> {
  String? _backfilledForId;

  @override
  String? build() {
    ref.listen(ownedMonstersProvider, (previous, next) {
      next.whenData((owned) {
        final user = ref.read(myUserProvider).value;
        final savedId = user?.homeCompanionId;
        if (savedId == null || savedId.isEmpty) return;

        // Lista vacía puede ser carga inicial; no borrar el compañero todavía.
        if (owned.isEmpty) return;

        final match = _findOwned(owned, savedId);
        if (match == null) {
          _backfilledForId = null;
          Future.microtask(() => clear());
          return;
        }

        final needsCache = user!.homeCompanionImagePath == null ||
            user.homeCompanionImagePath!.isEmpty;
        if (!needsCache || _backfilledForId == savedId) return;

        _backfilledForId = savedId;
        Future.microtask(
          () => _persistSnapshot(
            ownedInstanceId: savedId,
            imagePath: match.monster.imagePath,
          ),
        );
      });
    });

    return ref.watch(myUserProvider).value?.homeCompanionId;
  }

  OwnedMonster? _findOwned(List<OwnedMonster> owned, String id) {
    for (final o in owned) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> setCompanion(
    String ownedInstanceId, {
    required String imagePath,
  }) async {
    _backfilledForId = ownedInstanceId;
    await _persistSnapshot(
      ownedInstanceId: ownedInstanceId,
      imagePath: imagePath,
    );
  }

  Future<void> clear() async {
    _backfilledForId = null;
    final uid = ref.read(userProvider).value?.uid;
    if (uid == null) return;

    await ref.read(userRepositoryProvider).saveHomeCompanion(uid);
    ref.invalidate(myUserProvider);
  }

  Future<void> _persistSnapshot({
    required String ownedInstanceId,
    required String imagePath,
  }) async {
    final uid = ref.read(userProvider).value?.uid;
    if (uid == null) return;

    await ref.read(userRepositoryProvider).saveHomeCompanion(
          uid,
          ownedInstanceId: ownedInstanceId,
          imagePath: imagePath,
        );
    ref.invalidate(myUserProvider);
  }
}

final homeCompanionProvider =
    NotifierProvider<HomeCompanionNotifier, String?>(HomeCompanionNotifier.new);

/// Datos para dibujar el compañero en la home (imagen + lado).
class HomeCompanionView {
  const HomeCompanionView({
    required this.imagePath,
    this.side = HomeCompanionSide.left,
    this.scale = 1,
  });

  final String imagePath;
  final HomeCompanionSide side;
  final double scale;
}

/// Resuelve imagen y lado del compañero. `homeFacing` siempre del catálogo
/// `monsters` (vía instancia owned → `monsterId`), nunca de `users` ni
/// `owned_monsters`.
final homeCompanionViewProvider = Provider<HomeCompanionView?>((ref) {
  final user = ref.watch(myUserProvider).value;
  final companionId = user?.homeCompanionId;
  if (companionId == null || companionId.isEmpty) return null;

  final owned = ref.watch(capturedMonstersProvider);
  for (final o in owned) {
    if (o.id == companionId) {
      return HomeCompanionView(
        imagePath: o.monster.imagePath,
        side: o.monster.homeFacing,
        scale: o.monster.homeDisplayScale,
      );
    }
  }

  final cached = user?.homeCompanionImagePath;
  if (cached == null || cached.isEmpty) return null;

  // Caché de imagen en `users`: buscar `homeFacing` en el catálogo por ruta.
  final catalog = ref.watch(monstersProvider).asData?.value;
  if (catalog != null) {
    for (final m in catalog) {
      if (m.imagePath == cached) {
        return HomeCompanionView(
          imagePath: cached,
          side: m.homeFacing,
          scale: m.homeDisplayScale,
        );
      }
    }
  }

  return HomeCompanionView(imagePath: cached);
});

/// Solo la ruta del asset (compatibilidad).
final homeCompanionImageProvider = Provider<String?>((ref) {
  return ref.watch(homeCompanionViewProvider)?.imagePath;
});
