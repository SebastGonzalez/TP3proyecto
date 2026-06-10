import 'dart:math';

import 'package:prueba1/features/gatcha/domain/gatcha_drop_config.dart';
import 'package:prueba1/features/gatcha/domain/roll_strategy.dart';

import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/monsters/domain/models/rarity.dart';

/// Tirada en dos pasos: rareza según [GatchaDropConfig.rarityRates], luego
/// monstruo ponderado por [GatchaDropConfig.monsterWeights] (default 1).
///
/// El pool ya debe venir filtrado por [GatchaDropConfig.filterPool] y
/// `gachaEligible` (lo hace [GatchaMachine]).
class TieredGatchaStrategy implements RollStrategy, RarityRatesInfo {
  const TieredGatchaStrategy(this.config);

  final GatchaDropConfig config;

  @override
  Map<Rarity, double> get rarityRatesPercent => config.displayPercents;

  @override
  Monster roll(List<Monster> pool, Random rng) {
    if (pool.isEmpty) {
      throw StateError('No se puede rolear con un pool vacío');
    }

    final rarity = _pickRarity(pool, rng);
    final inTier = pool.where((m) => m.rarity == rarity).toList();
    return _pickMonster(inTier, rng);
  }

  Rarity _pickRarity(List<Monster> pool, Random rng) {
    final weights = <Rarity, double>{};
    for (final entry in config.rarityRates.entries) {
      if (pool.any((m) => m.rarity == entry.key)) {
        weights[entry.key] = entry.value;
      }
    }

    if (weights.isEmpty) {
      final present = pool.map((m) => m.rarity).toSet().toList();
      return present[rng.nextInt(present.length)];
    }

    final total = weights.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) {
      final keys = weights.keys.toList();
      return keys[rng.nextInt(keys.length)];
    }

    var roll = rng.nextDouble() * total;
    for (final e in weights.entries) {
      roll -= e.value;
      if (roll < 0) return e.key;
    }
    return weights.keys.last;
  }

  Monster _pickMonster(List<Monster> tier, Random rng) {
    final weights = [
      for (final m in tier)
        (config.monsterWeights[m.id] ?? 1).clamp(1, 1 << 30).toDouble(),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return tier[rng.nextInt(tier.length)];

    var roll = rng.nextDouble() * total;
    for (var i = 0; i < tier.length; i++) {
      roll -= weights[i];
      if (roll < 0) return tier[i];
    }
    return tier.last;
  }
}
