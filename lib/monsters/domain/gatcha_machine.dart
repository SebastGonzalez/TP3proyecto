import 'dart:math';

import 'package:flutter/material.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';
import 'package:prueba1/monsters/domain/roll_strategy.dart';
import 'package:prueba1/monsters/domain/strategies/weighted_rarity_strategy.dart';

/// Una máquina de gatcha. Es sólo el "contenedor" con datos de presentación
/// (nombre, costo, colores) y delega la lógica del roll en una `RollStrategy`.
class GatchaMachine {
  final String id;
  final String name;
  final String description;
  final int cost;
  final Color haloColor;
  final Color accentColor;
  final RollStrategy strategy;

  /// Cuántos monstruos se obtienen por cada tirada (Firestore: `rollsPerPull`).
  final int rollsPerPull;

  const GatchaMachine({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.haloColor,
    required this.accentColor,
    required this.strategy,
    this.rollsPerPull = 1,
  });

  /// Construye desde un documento de Firestore (`gatcha_machines/{id}`).
  /// `rarityBoosts`: claves = label (`Legendario`) o id (`legendario`). Claves
  /// sin match (p. ej. `Legendary` con label `Legendario`) se ignoran.
  /// `rollsPerPull` opcional (default 1, máximo 10).
  /// En Firestore, `active: false` excluye la máquina (filtrado en el repository).
  factory GatchaMachine.fromFirestore(
    Map<String, dynamic> data, {
    required String documentId,
    required RarityCatalog rarities,
  }) {
    final boosts = _parseRarityBoosts(data['rarityBoosts'], rarities);
    return GatchaMachine(
      id: documentId,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      cost: (data['cost'] as num?)?.toInt() ?? 0,
      haloColor: Color((data['haloColor'] as num?)?.toInt() ?? 0xFF000000),
      accentColor: Color((data['accentColor'] as num?)?.toInt() ?? 0xFF000000),
      strategy: WeightedRarityStrategy(rarityBoosts: boosts),
      rollsPerPull: _parseRollsPerPull(data['rollsPerPull']),
    );
  }

  static int _parseRollsPerPull(dynamic raw) {
    final n = (raw as num?)?.toInt() ?? 1;
    return n.clamp(1, 10);
  }

  static Map<Rarity, double> _parseRarityBoosts(
    dynamic raw,
    RarityCatalog rarities,
  ) {
    if (raw is! Map) return const {};
    final out = <Rarity, double>{};
    for (final e in raw.entries) {
      final k = e.key;
      final v = e.value;
      if (k is! String || v is! num) continue;
      final rarity = rarities.tryResolve(k);
      if (rarity == null) continue;
      out[rarity] = v.toDouble();
    }
    return out;
  }

  Monster roll(List<Monster> pool, Random rng) => strategy.roll(pool, rng);

  /// Ejecuta [rollsPerPull] tiradas independientes sobre el mismo pool.
  List<Monster> rollMany(List<Monster> pool, Random rng) => [
        for (var i = 0; i < rollsPerPull; i++) roll(pool, rng),
      ];
}
