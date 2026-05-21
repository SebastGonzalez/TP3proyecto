import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/domain/my_user.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';
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

        if (owned.isEmpty) return;

        final match = _findOwned(owned, savedId);
        if (match == null) {
          _backfilledForId = null;
          Future.microtask(() => clear());
          return;
        }

        if (_userSnapshotMatchesMonster(user!, match.monster)) {
          _backfilledForId = savedId;
          return;
        }

        _backfilledForId = savedId;
        Future.microtask(() => _persistSnapshot(match));
      });
    });

    return ref.watch(myUserProvider).value?.homeCompanionId;
  }

  bool _userSnapshotMatchesMonster(MyUser user, Monster monster) {
    if (user.homeCompanionImagePath != monster.imagePath) return false;
    if (user.homeCompanionFacing != monster.homeFacingLabel) return false;
    if (user.homeCompanionScale != monster.homeDisplayScale) return false;
    if (user.homeCompanionBackgroundColor !=
        monster.homeDisplayBackgroundColor.toARGB32()) {
      return false;
    }
    return user.homeCompanionImagePath != null &&
        user.homeCompanionImagePath!.isNotEmpty;
  }

  OwnedMonster? _findOwned(List<OwnedMonster> owned, String id) {
    for (final o in owned) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> setCompanion(String ownedInstanceId, {required Monster monster}) async {
    _backfilledForId = ownedInstanceId;
    await _persistSnapshotFromMonster(
      ownedInstanceId: ownedInstanceId,
      monster: monster,
    );
  }

  Future<void> clear() async {
    _backfilledForId = null;
    final uid = ref.read(userProvider).value?.uid;
    if (uid == null) return;

    await ref.read(userRepositoryProvider).saveHomeCompanion(uid);
    ref.invalidate(myUserProvider);
  }

  Future<void> _persistSnapshot(OwnedMonster owned) async {
    await _persistSnapshotFromMonster(
      ownedInstanceId: owned.id,
      monster: owned.monster,
    );
  }

  Future<void> _persistSnapshotFromMonster({
    required String ownedInstanceId,
    required Monster monster,
  }) async {
    final uid = ref.read(userProvider).value?.uid;
    if (uid == null) return;

    await ref.read(userRepositoryProvider).saveHomeCompanion(
          uid,
          ownedInstanceId: ownedInstanceId,
          imagePath: monster.imagePath,
          homeFacing: monster.homeFacingLabel,
          homeScale: monster.homeDisplayScale,
          homeBackgroundColor: monster.homeDisplayBackgroundColor.toARGB32(),
        );
    ref.invalidate(myUserProvider);
  }
}

final homeCompanionProvider =
    NotifierProvider<HomeCompanionNotifier, String?>(HomeCompanionNotifier.new);

/// Datos para dibujar el compañero en la home (imagen + lado + fondo).
class HomeCompanionView {
  const HomeCompanionView({
    required this.imagePath,
    this.side = HomeCompanionSide.left,
    this.scale = 1,
    this.backgroundColor,
  });

  final String imagePath;
  final HomeCompanionSide side;
  final double scale;
  final Color? backgroundColor;
}

HomeCompanionView _viewFromMonster(Monster monster) {
  return HomeCompanionView(
    imagePath: monster.imagePath,
    side: monster.homeFacing,
    scale: monster.homeDisplayScale,
    backgroundColor: monster.homeDisplayBackgroundColor,
  );
}

/// Snapshot en `users` para pintar la home al instante (antes de catálogo/owned).
HomeCompanionView? homeCompanionViewFromUser(MyUser? user) {
  if (user == null) return null;
  final companionId = user.homeCompanionId;
  if (companionId == null || companionId.isEmpty) return null;

  final imagePath = user.homeCompanionImagePath;
  if (imagePath == null || imagePath.isEmpty) return null;

  final facing = user.homeCompanionFacing;
  if (facing == null || facing.isEmpty) return null;

  final argb = user.homeCompanionBackgroundColor;
  if (argb == null) return null;

  final side = facing == 'right'
      ? HomeCompanionSide.right
      : HomeCompanionSide.left;

  return HomeCompanionView(
    imagePath: imagePath,
    side: side,
    scale: user.homeCompanionScale ?? 1,
    backgroundColor: argb != null ? Color(argb) : null,
  );
}

HomeCompanionView? _resolveFromOwnedCatalog({
  required String companionId,
  required List<OwnedMonster>? owned,
  required List<Monster>? catalog,
  required MyUser? user,
}) {
  if (owned != null) {
    for (final o in owned) {
      if (o.id == companionId) return _viewFromMonster(o.monster);
    }
  }

  final cached = user?.homeCompanionImagePath;
  if (cached == null || cached.isEmpty || catalog == null) return null;

  for (final m in catalog) {
    if (m.imagePath == cached) return _viewFromMonster(m);
  }

  return null;
}

/// Catálogo es fuente de verdad; `users` guarda caché para el primer frame.
final homeCompanionViewProvider = Provider<HomeCompanionView?>((ref) {
  final user = ref.watch(myUserProvider).value;
  final companionId = user?.homeCompanionId;
  if (companionId == null || companionId.isEmpty) return null;

  final userSnapshot = homeCompanionViewFromUser(user);

  final ownedAsync = ref.watch(ownedMonstersProvider);
  final catalogAsync = ref.watch(monstersProvider);

  if (ownedAsync.isLoading || catalogAsync.isLoading) {
    return userSnapshot;
  }

  final resolved = _resolveFromOwnedCatalog(
    companionId: companionId,
    owned: ownedAsync.asData?.value,
    catalog: catalogAsync.asData?.value,
    user: user,
  );

  return resolved ?? userSnapshot;
});

/// Solo la ruta del asset (compatibilidad).
final homeCompanionImageProvider = Provider<String?>((ref) {
  return ref.watch(homeCompanionViewProvider)?.imagePath;
});
