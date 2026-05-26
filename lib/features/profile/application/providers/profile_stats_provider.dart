import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/monsters/domain/models/owned_monster.dart';
import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/monsters/domain/models/rarity.dart';
import 'package:prueba1/features/auth/application/providers/auth_provider.dart';
import 'package:prueba1/features/monsters/application/providers/captured_monsters_provider.dart';
import 'package:prueba1/features/monsters/application/providers/mymonster_provider.dart';
import 'package:prueba1/features/monsters/application/providers/rarities_provider.dart';
import 'package:prueba1/features/shop/application/providers/coin_provider.dart';
import 'package:prueba1/presentation/providers/my_user.provider.dart';

/// Estadísticas del perfil calculadas desde datos reales de la app.
class ProfileStats {
  const ProfileStats({
    required this.displayName,
    required this.coins,
    required this.uniqueSpecies,
    required this.totalCaptures,
    required this.legendaryCount,
    required this.hasHomeCompanion,
    required this.ownsCompleteCatalog,
    required this.trainerLevel,
    required this.rank,
    this.createdAt,
    this.isLoading = false,
  });

  final String displayName;
  final int coins;
  final int uniqueSpecies;
  final int totalCaptures;
  final int legendaryCount;
  final bool hasHomeCompanion;

  /// Al menos una captura de cada monstruo activo en `monsters`.
  final bool ownsCompleteCatalog;

  final int trainerLevel;
  final String rank;
  final DateTime? createdAt;
  final bool isLoading;

  static const ProfileStats loading = ProfileStats(
    displayName: '…',
    coins: 0,
    uniqueSpecies: 0,
    totalCaptures: 0,
    legendaryCount: 0,
    hasHomeCompanion: false,
    ownsCompleteCatalog: false,
    trainerLevel: 1,
    rank: '—',
    isLoading: true,
  );
}

int trainerLevelFromCaptures(int captures) => 1 + captures ~/ 5;

String rankFromCaptures(int captures) {
  if (captures == 0) return 'Novato';
  if (captures < 5) return 'Entrenador';
  if (captures < 15) return 'Experto';
  if (captures < 30) return 'Veterano';
  return 'Maestro';
}

/// `true` si [ownedSpeciesIds] incluye cada id activo del [catalog].
bool computeOwnsCompleteCatalog(
  List<Monster> catalog,
  Set<String> ownedSpeciesIds,
) {
  if (catalog.isEmpty) return false;
  for (final m in catalog) {
    if (!ownedSpeciesIds.contains(m.id)) return false;
  }
  return true;
}

ProfileStats _statsFrom({
  required String displayName,
  required int coins,
  required List<OwnedMonster> owned,
  required List<Monster> catalog,
  required bool hasHomeCompanion,
  RarityCatalog? rarities,
  DateTime? createdAt,
}) {
  final species = <String>{};
  var legendaries = 0;
  for (final o in owned) {
    species.add(o.monsterId);
    if (rarities != null && rarities.isLegendary(o.monster.rarity)) {
      legendaries++;
    }
  }
  final captures = owned.length;
  return ProfileStats(
    displayName: displayName,
    coins: coins,
    uniqueSpecies: species.length,
    totalCaptures: captures,
    legendaryCount: legendaries,
    hasHomeCompanion: hasHomeCompanion,
    ownsCompleteCatalog: computeOwnsCompleteCatalog(catalog, species),
    trainerLevel: trainerLevelFromCaptures(captures),
    rank: rankFromCaptures(captures),
    createdAt: createdAt,
  );
}

final profileStatsProvider = Provider<ProfileStats>((ref) {
  final myUserAsync = ref.watch(myUserProvider);
  if (myUserAsync.isLoading) return ProfileStats.loading;

  final myUser = myUserAsync.value;
  final fallbackName = ref.watch(currentUsernameProvider);
  final displayName = (myUser?.username?.trim().isNotEmpty ?? false)
      ? myUser!.username!.trim()
      : fallbackName;

  final ownedAsync = ref.watch(capturedMonstersAsyncProvider);
  if (ownedAsync.isLoading) return ProfileStats.loading;

  final catalogAsync = ref.watch(monstersProvider);
  if (catalogAsync.isLoading) return ProfileStats.loading;

  final owned = ownedAsync.value ?? const [];
  final catalog = catalogAsync.value ?? const [];
  final coins = ref.watch(coinProvider);
  final rarities = ref.watch(raritiesProvider).value;
  final hasCompanion = myUser?.homeCompanionId != null &&
      myUser!.homeCompanionId!.isNotEmpty;

  return _statsFrom(
    displayName: displayName,
    coins: coins,
    owned: owned,
    catalog: catalog,
    hasHomeCompanion: hasCompanion,
    rarities: rarities,
    createdAt: myUser?.createdAt,
  );
});
