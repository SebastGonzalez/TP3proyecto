import 'package:flutter/material.dart';

/// Rarezas conocidas. Una sola fuente de verdad: agregar una rareza
/// nueva = sumar un valor al enum y listo, el resto del código (UI,
/// strategies, badges, sort) la consulta por acá y se adapta solo.
///
/// `label` es el string que se persiste en Firestore (compat con docs
/// que ya tengas cargados). `color` es el color visual asociado.
/// `weight` da un orden canónico para mostrar y comparar (mayor =
/// más raro).
enum Rarity {
  common(
    label: 'Common',
    color: Color(0xFF26C6DA),
    weight: 0,
  ),
  rare(
    label: 'Rare',
    color: Color(0xFF7C4DFF),
    weight: 1,
  ),
  legendary(
    label: 'Legendary',
    color: Color(0xFFFFB300),
    weight: 2,
  ),
  fusion(
    label: 'Fusion',
    color: Color.fromARGB(255, 14, 173, 27),
    weight: 3,
  );


  const Rarity({
    required this.label,
    required this.color,
    required this.weight,
  });

  final String label;
  final Color color;
  final int weight;

  /// Parsea desde el string que viene de Firestore. Si no matchea
  /// ninguna conocida, cae a `Common` (defensivo: que no rompa la app
  /// por un dato inesperado).
  static Rarity fromLabel(String? label) => values.firstWhere(
        (r) => r.label == label,
        orElse: () => Rarity.common,
      );

  /// Para condiciones tipo "muestra rayos / shine sólo si no es Common".
  /// Más legible que `monster.rarity != Rarity.common` y más
  /// extensible (hoy hay 1 nivel "no común", mañana puede haber más).
  bool get isAtLeastRare => weight >= Rarity.rare.weight;
}
