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

  Monster roll(List<Monster> pool, Random rng) => strategy.roll(pool, rng);
}

/// Catálogo "hard-coded" de máquinas. Costo creciente y mejores tasas de
/// rarezas altas. Se exponen vía `gatchaMachinesProvider` para poder
/// reemplazar por un FutureProvider que las traiga de Firestore más adelante.
const List<GatchaMachine> kGatchaMachines = [
  GatchaMachine(
    id: 'standard',
    name: 'Standard',
    description: 'Probabilidades clásicas',
    cost: 500,
    haloColor: Color(0xFFFF9800),
    accentColor: Color(0xFFE65100),
    strategy: WeightedRarityStrategy(
      rarityBoosts: {
        Rarity.common: 1.0,
        Rarity.rare: 1.0,
        Rarity.legendary: 1.0,
      },
    ),
  ),
  GatchaMachine(
    id: 'premium',
    name: 'Premium',
    description: 'Más chances de Rare y Legendary',
    cost: 1500,
    haloColor: Color(0xFF2196F3),
    accentColor: Color(0xFF0D47A1),
    strategy: WeightedRarityStrategy(
      rarityBoosts: {
        Rarity.common: 0.4,
        Rarity.rare: 3.0,
        Rarity.legendary: 2.5,
      },
    ),
  ),
  GatchaMachine(
    id: 'elite',
    name: 'Elite',
    description: 'Foco en Legendary',
    cost: 5000,
    haloColor: Color(0xFF9C27B0),
    accentColor: Color(0xFF4A148C),
    strategy: WeightedRarityStrategy(
      rarityBoosts: {
        Rarity.common: 0.1,
        Rarity.rare: 1.0,
        Rarity.legendary: 8.0,
      },
    ),
  ),
];
