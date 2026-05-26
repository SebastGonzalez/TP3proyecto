import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';

/// Modo de pool en `gatcha_machines` (Firestore: `poolMode`).
enum GatchaPoolMode {
  /// Todos los monstruos activos elegibles por rareza.
  allActive,

  /// Solo ids en [poolMonsterIds].
  whitelist,
}

/// Configuración de drops en un documento `gatcha_machines/{id}`.
///
/// - [rarityRates]: claves = [Rarity.label]; solo rarezas listadas participan.
/// - [monsterWeights]: peso relativo dentro de la rareza (default 1).
/// - [poolMode] / [poolMonsterIds]: acotar el pool de la máquina.
class GatchaDropConfig {
  const GatchaDropConfig({
    this.rarityRates = const {},
    this.monsterWeights = const {},
    this.poolMode = GatchaPoolMode.allActive,
    this.poolMonsterIds = const {},
  });

  final Map<Rarity, double> rarityRates;
  final Map<String, int> monsterWeights;
  final GatchaPoolMode poolMode;
  final Set<String> poolMonsterIds;

  bool get isTiered => rarityRates.isNotEmpty;

  /// Porcentajes para UI (normaliza la suma de [rarityRates] a 100).
  Map<Rarity, double> get displayPercents {
    if (rarityRates.isEmpty) return const {};
    final sum = rarityRates.values.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return const {};
    return {
      for (final e in rarityRates.entries) e.key: e.value / sum * 100,
    };
  }

  static GatchaDropConfig fromFirestore(
    Map<String, dynamic> data, {
    required RarityCatalog rarities,
  }) {
    return GatchaDropConfig(
      rarityRates: _parseRarityRates(data['rarityRates'], rarities),
      monsterWeights: _parseMonsterWeights(data['monsterWeights']),
      poolMode: _parsePoolMode(data['poolMode']),
      poolMonsterIds: _parsePoolIds(data['poolMonsterIds']),
    );
  }

  /// Pool tras `gachaEligible`, whitelist y rarezas listadas en [rarityRates].
  List<Monster> filterPool(List<Monster> catalog) {
    var pool = catalog.where((m) => m.rarity.gachaEligible).toList();

    if (poolMode == GatchaPoolMode.whitelist && poolMonsterIds.isNotEmpty) {
      pool = pool.where((m) => poolMonsterIds.contains(m.id)).toList();
    }

    if (rarityRates.isNotEmpty) {
      final allowed = rarityRates.keys.toSet();
      pool = pool.where((m) => allowed.contains(m.rarity)).toList();
    }

    return pool;
  }

  static Map<Rarity, double> _parseRarityRates(
    dynamic raw,
    RarityCatalog rarities,
  ) {
    if (raw is! Map) return const {};
    final out = <Rarity, double>{};
    for (final e in raw.entries) {
      if (e.key is! String || e.value is! num) continue;
      final rarity = rarities.tryResolve(e.key as String);
      if (rarity == null) continue;
      final v = (e.value as num).toDouble();
      if (v > 0) out[rarity] = v;
    }
    return out;
  }

  static Map<String, int> _parseMonsterWeights(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, int>{};
    for (final e in raw.entries) {
      if (e.key is! String || e.value is! num) continue;
      final w = (e.value as num).toInt();
      if (w > 0) out[e.key as String] = w;
    }
    return out;
  }

  static GatchaPoolMode _parsePoolMode(dynamic raw) {
    if (raw is String && raw.toLowerCase() == 'whitelist') {
      return GatchaPoolMode.whitelist;
    }
    return GatchaPoolMode.allActive;
  }

  static Set<String> _parsePoolIds(dynamic raw) {
    if (raw is! List) return const {};
    return {
      for (final id in raw)
        if (id is String && id.isNotEmpty) id,
    };
  }
}
