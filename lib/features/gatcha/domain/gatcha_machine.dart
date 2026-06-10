import 'dart:math';
import 'package:flutter/material.dart';

import 'package:prueba1/features/gatcha/domain/gatcha_drop_config.dart';
import 'package:prueba1/features/gatcha/domain/roll_strategy.dart';
import 'package:prueba1/features/gatcha/domain/strategies/tiered_gatcha_strategy.dart';

import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/monsters/domain/models/rarity.dart';

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
  ///
  /// Requiere `rarityRates` con al menos una rareza. Opcional: `monsterWeights`,
  /// `poolMode`, `poolMonsterIds`.
  factory GatchaMachine.fromFirestore(
    Map<String, dynamic> data, {
    required String documentId,
    required RarityCatalog rarities,
  }) {
    final dropConfig = GatchaDropConfig.fromFirestore(data, rarities: rarities);
    if (!dropConfig.isTiered) {
      throw StateError(
        'gatcha_machines/$documentId: falta rarityRates (al menos una rareza).',
      );
    }

    return GatchaMachine(
      id: documentId,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      cost: (data['cost'] as num?)?.toInt() ?? 0,
      haloColor: Color((data['haloColor'] as num?)?.toInt() ?? 0xFF000000),
      accentColor: Color((data['accentColor'] as num?)?.toInt() ?? 0xFF000000),
      strategy: TieredGatchaStrategy(dropConfig),
      rollsPerPull: _parseRollsPerPull(data['rollsPerPull']),
    );
  }

  //es 1
  static int _parseRollsPerPull(dynamic raw) {
    final n = (raw as num?)?.toInt() ?? 1;
    return n.clamp(1, 10);
  }

  GatchaDropConfig get dropConfig =>
      (strategy as TieredGatchaStrategy).config;

  /// Pool elegible para esta máquina (gacha + rarezas/pool configurados).
  List<Monster> filteredPool(List<Monster> catalog) =>
      dropConfig.filterPool(catalog);

  Monster roll(List<Monster> pool, Random rng) {
    final eligible = filteredPool(pool);
    if (eligible.isEmpty) {
      throw StateError('No hay monstruos elegibles para esta máquina');
    }
    return strategy.roll(eligible, rng);
  }

  /// Ejecuta [rollsPerPull] tiradas independientes sobre el mismo pool.
  List<Monster> rollMany(List<Monster> pool, Random rng) => [
        for (var i = 0; i < rollsPerPull; i++) roll(pool, rng),
      ];
}
