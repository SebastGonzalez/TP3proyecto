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

  const GatchaMachine({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.haloColor,
    required this.accentColor,
    required this.strategy,
  });

  /// Construye desde un documento de Firestore (`gatcha_machines/{id}`).
  /// `rarityBoosts` usa las mismas claves que [Rarity.label] (p. ej. `Common`).
  factory GatchaMachine.fromFirestore(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    final boosts = _parseRarityBoosts(data['rarityBoosts']);
    return GatchaMachine(
      id: documentId,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      cost: (data['cost'] as num?)?.toInt() ?? 0,
      haloColor: Color((data['haloColor'] as num?)?.toInt() ?? 0xFF000000),
      accentColor: Color((data['accentColor'] as num?)?.toInt() ?? 0xFF000000),
      strategy: WeightedRarityStrategy(rarityBoosts: boosts),
    );
  }

  static Map<Rarity, double> _parseRarityBoosts(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <Rarity, double>{};
    for (final e in raw.entries) {
      final k = e.key;
      final v = e.value;
      if (k is! String || v is! num) continue;
      out[Rarity.fromLabel(k)] = v.toDouble();
    }
    return out;
  }

  Monster roll(List<Monster> pool, Random rng) => strategy.roll(pool, rng);
}
