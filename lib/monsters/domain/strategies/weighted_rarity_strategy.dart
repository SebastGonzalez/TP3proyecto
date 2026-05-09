import 'dart:math';

import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';
import 'package:prueba1/monsters/domain/roll_strategy.dart';

/// Strategy clásica: selección ponderada por `dropWeight`, aplicando un
/// multiplicador específico por rareza. El multiplicador escala el peso
/// base de cada monstruo, así que pesos altos siguen siendo más probables
/// pero la rareza puede inclinarlos.
///
/// Ejemplo:
///   `WeightedRarityStrategy(rarityBoosts: {Rarity.legendary: 8.0})`
///   multiplica por 8 el peso de los Legendary, deja el resto en 1.0.
class WeightedRarityStrategy implements RollStrategy, RarityBoostInfo {
  @override
  final Map<Rarity, double> rarityBoosts;

  const WeightedRarityStrategy({this.rarityBoosts = const {}});

  double _multiplierFor(Rarity rarity) => rarityBoosts[rarity] ?? 1.0;

  @override
  Monster roll(List<Monster> pool, Random rng) {
    if (pool.isEmpty) {
      throw StateError('No se puede rolear con un pool vacío');
    }

    final weights = [
      for (final m in pool)
        (m.dropWeight * _multiplierFor(m.rarity))
            .clamp(0, double.infinity)
            .toDouble(),
    ];
    final total = weights.fold<double>(0, (sum, w) => sum + w);

    // Si todos los pesos quedaron en 0 (ej: multipliers a 0), caemos a una
    // selección uniforme para no romper el flujo.
    if (total <= 0) return pool[rng.nextInt(pool.length)];

    final roll = rng.nextDouble() * total;
    double acc = 0;
    for (var i = 0; i < pool.length; i++) {
      acc += weights[i];
      if (roll < acc) return pool[i];
    }
    return pool.last;
  }
}
