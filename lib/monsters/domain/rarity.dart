import 'package:flutter/material.dart';

/// Rareza definida en Firestore (`monsters_rarity/{id}`). Los monstruos guardan [label]
/// en el campo `rarity` (ej. `"Legendario"`).
class Rarity {
  const Rarity({
    required this.id,
    required this.label,
    required this.color,
    required this.weight,
    required this.homeCompanionScale,
    required this.isAtLeastRare,
    this.gachaEligible = true,
  });

  final String id;
  final String label;
  final Color color;
  final int weight;
  final double homeCompanionScale;

  /// Efectos visuales “no común” (reveal, etc.): `weight >=` umbral de tier raro.
  final bool isAtLeastRare;

  /// Si `false`, no entra en ningún pool de gatcha (`monsters_rarity.gachaEligible`).
  final bool gachaEligible;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Rarity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Catálogo de rarezas cargado desde Firestore.
class RarityCatalog {
  RarityCatalog(
    List<Rarity> rarities, {
    Map<String, Rarity> aliases = const {},
  })  : rarities = List.unmodifiable(
          [...rarities]..sort((a, b) => a.weight.compareTo(b.weight)),
        ),
        _byLabel = {
          for (final r in rarities) r.label: r,
        },
        _byId = {
          for (final r in rarities) r.id: r,
        },
        _aliases = aliases {
    _rareMinWeight = computeRareMinWeight(this.rarities);
    _legendaryMinWeight = computeLegendaryMinWeight(this.rarities);
  }

  final List<Rarity> rarities;
  final Map<String, Rarity> _byLabel;
  final Map<String, Rarity> _byId;
  final Map<String, Rarity> _aliases;
  late final int _rareMinWeight;
  late final int? _legendaryMinWeight;

  Rarity get fallback => rarities.first;

  static int computeRareMinWeight(List<Rarity> list) {
    if (list.isEmpty) return 1;
    final weights = list.map((r) => r.weight).toSet().toList()..sort();
    return weights.length > 1 ? weights[1] : weights.first;
  }

  static int? computeLegendaryMinWeight(List<Rarity> list) {
    for (final id in const ['legendario', 'legendary']) {
      final w = list
          .where((r) => r.id.toLowerCase() == id)
          .map((r) => r.weight)
          .firstOrNull;
      if (w != null) return w;
    }
    if (list.length < 2) return null;
    final weights = list.map((r) => r.weight).toSet().toList()..sort();
    return weights.length > 2 ? weights[weights.length - 2] : weights.last;
  }

  bool isLegendary(Rarity rarity) {
    for (final id in const ['legendario', 'legendary']) {
      final leg = byId(id);
      if (leg != null) return rarity.id == leg.id;
    }
    final min = _legendaryMinWeight;
    return min != null && rarity.weight == min;
  }

  /// Resuelve rareza para monstruos; si no hay match, [fallback].
  Rarity byLabel(String? raw) => tryResolve(raw) ?? fallback;

  /// Resuelve solo si hay match real (p. ej. claves de `rarityRates` en gatcha).
  Rarity? tryResolve(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final key = raw.trim();

    final exact = _byLabel[key];
    if (exact != null) return exact;

    final byDocId = _byId[key] ?? _byId[key.toLowerCase()];
    if (byDocId != null) return byDocId;

    final lower = key.toLowerCase();
    final alias = _aliases[key] ?? _aliases[lower];
    if (alias != null) return alias;

    for (final r in rarities) {
      if (r.label.toLowerCase() == lower || r.id.toLowerCase() == lower) {
        return r;
      }
      if (_similarRarityKey(lower, r.id) || _similarRarityKey(lower, r.label)) {
        return r;
      }
    }
    return null;
  }

  static bool _similarRarityKey(String a, String b) {
    final x = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final y = b.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    return x.startsWith(y) || y.startsWith(x);
  }

  Rarity? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    return _byId[id] ?? _byId[id.toLowerCase()];
  }

  bool hasLabel(String label) => _byLabel.containsKey(label);

  bool isAtLeastRare(Rarity rarity) => rarity.weight >= _rareMinWeight;

  static RarityCatalog defaults() {
    const raw = [
      (
        id: 'common',
        label: 'Common',
        color: 0xFF26C6DA,
        weight: 0,
        scale: 1.0,
        gacha: true,
      ),
      (
        id: 'rare',
        label: 'Rare',
        color: 0xFF7C4DFF,
        weight: 1,
        scale: 1.08,
        gacha: true,
      ),
      (
        id: 'legendary',
        label: 'Legendary',
        color: 0xFFFFB300,
        weight: 2,
        scale: 1.22,
        gacha: true,
      ),
      (
        id: 'fusion',
        label: 'Fusion',
        color: 0xFF0EAD1B,
        weight: 3,
        scale: 1.28,
        gacha: false,
      ),
    ];
    final rareWeight = computeRareMinWeight([
      for (final e in raw)
        Rarity(
          id: e.id,
          label: e.label,
          color: Color(e.color),
          weight: e.weight,
          homeCompanionScale: e.scale,
          isAtLeastRare: false,
          gachaEligible: e.gacha,
        ),
    ]);
    return RarityCatalog([
      for (final e in raw)
        Rarity(
          id: e.id,
          label: e.label,
          color: Color(e.color),
          weight: e.weight,
          homeCompanionScale: e.scale,
          isAtLeastRare: e.weight >= rareWeight,
          gachaEligible: e.gacha,
        ),
    ]);
  }
}

