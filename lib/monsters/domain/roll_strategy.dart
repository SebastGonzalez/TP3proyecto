import 'dart:math';

import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';

/// Contrato del patrón Strategy aplicado al roll de un gatcha.
///
/// Toda mecánica concreta (ponderado por rareza, pity, banner con un
/// destacado, multi-roll, etc.) implementa esta interfaz. La pantalla
/// no sabe ni le importa cómo se decide el monstruo: sólo delega.
///
/// `Random` se inyecta para que las estrategias sean fáciles de testear
/// con una semilla fija.
abstract interface class RollStrategy {
  Monster roll(List<Monster> pool, Random rng);
}

/// Capability para mostrar % por rareza (`TieredGatchaStrategy` + `rarityRates`).
abstract interface class RarityRatesInfo {
  /// Valores 0–100 (normalizados para display).
  Map<Rarity, double> get rarityRatesPercent;
}
