import 'package:flutter/material.dart';

/// Rareza definida en Firestore (`monsters_rarity/{id}`). Los monstruos guardan [label]
/// en el campo `rarity` (ej. `"Common"`).
class Rarity {
  const Rarity({
    required this.id,
    required this.label,
    required this.color,
    required this.weight,
    required this.homeCompanionScale,
    required this.isAtLeastRare,
  });

  final String id;
  final String label;
  final Color color;
  final int weight;
  final double homeCompanionScale;

  /// Efectos visuales “no común” (reveal, etc.): `weight >=` rareza `Rare`.
  final bool isAtLeastRare;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Rarity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Catálogo de rarezas cargado desde Firestore.
class RarityCatalog {
  RarityCatalog(List<Rarity> rarities)
      : rarities = List.unmodifiable(
          [...rarities]..sort((a, b) => a.weight.compareTo(b.weight)),
        ),
        _byLabel = {
          for (final r in rarities) r.label: r,
        },
        _byId = {
          for (final r in rarities) r.id: r,
        } {
    final rareWeight = _byLabel['Rare']?.weight ?? 1;
    _rareMinWeight = rareWeight;
  }

  final List<Rarity> rarities;
  final Map<String, Rarity> _byLabel;
  final Map<String, Rarity> _byId;
  late final int _rareMinWeight;

  Rarity get fallback => _byLabel['Common'] ?? rarities.first;

  Rarity byLabel(String? label) {
    if (label == null || label.isEmpty) return fallback;
    return _byLabel[label] ?? fallback;
  }

  Rarity? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    return _byId[id];
  }

  bool hasLabel(String label) => _byLabel.containsKey(label);

  bool isAtLeastRare(Rarity rarity) => rarity.weight >= _rareMinWeight;

  /// Defaults si la colección `monsters_rarity` está vacía (misma data que el enum anterior).
  static RarityCatalog defaults() {
    const raw = [
      (id: 'common', label: 'Common', color: 0xFF26C6DA, weight: 0, scale: 1.0),
      (id: 'rare', label: 'Rare', color: 0xFF7C4DFF, weight: 1, scale: 1.08),
      (
        id: 'legendary',
        label: 'Legendary',
        color: 0xFFFFB300,
        weight: 2,
        scale: 1.22,
      ),
      (
        id: 'fusion',
        label: 'Fusion',
        color: 0xFF0EAD1B,
        weight: 3,
        scale: 1.28,
      ),
    ];
    final rareWeight = raw.firstWhere((e) => e.label == 'Rare').weight;
    return RarityCatalog([
      for (final e in raw)
        Rarity(
          id: e.id,
          label: e.label,
          color: Color(e.color),
          weight: e.weight,
          homeCompanionScale: e.scale,
          isAtLeastRare: e.weight >= rareWeight,
        ),
    ]);
  }
}
