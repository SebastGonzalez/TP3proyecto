import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:prueba1/features/gatcha/domain/gatcha_machine.dart';

import 'package:prueba1/features/monsters/domain/models/rarity.dart';

/// Lee máquinas gacha desde Firestore.
///
/// Colección: `gatcha_machines`. Cada documento es una máquina; el **id del
/// documento** es el `id` de dominio (`standard`, `premium`, …).
///
/// Campos esperados:
/// - `name` (String), `description` (String), `cost` (int)
/// - `haloColor`, `accentColor` (int ARGB, mismo formato que [Color.value])
/// - **`rarityRates`** (mapa, recomendado): claves = [Rarity.label], valores = número
///   (idealmente suman 100). Solo rarezas listadas participan en esa máquina.
/// - **`monsterWeights`** (mapa, opcional): `monsterId` → peso relativo dentro de la rareza
/// - **`poolMode`**: `"all_active"` (default) o `"whitelist"`
/// - **`poolMonsterIds`** (array, opcional): ids en `monsters` si `poolMode` es whitelist
/// - `rollsPerPull` (int, opcional): monstruos por tirada (default 1, máx. 10)
/// - `active` (bool, opcional): `false` oculta la máquina; si falta, se muestra
/// - `order` (int, opcional): orden en el carrusel (menor = primero)
///
/// Requiere `rarityRates` con al menos una entrada (ver `docs/GATCHA_BALANCE.md`).
class GatchaMachineRepository {
  GatchaMachineRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'gatcha_machines';

  Stream<List<GatchaMachine>> watchMachines({required RarityCatalog rarities}) {
    return _db
        .collection(collectionPath)
        .snapshots()
        .map((snap) => _parseSnapshot(snap, rarities));
  }

  Future<List<GatchaMachine>> getMachines({required RarityCatalog rarities}) async {
    final snapshot = await _db.collection(collectionPath).get();
    return _parseSnapshot(snapshot, rarities);
  }

  bool _isActive(Map<String, dynamic> data) => data['active'] as bool? ?? true;

  List<GatchaMachine> _parseSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    RarityCatalog rarities,
  ) {
    final parsed = <({int order, GatchaMachine machine})>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isActive(data)) continue;
      final order = (data['order'] as num?)?.toInt() ?? 1 << 20;
      parsed.add((
        order: order,
        machine: GatchaMachine.fromFirestore(
          data,
          documentId: doc.id,
          rarities: rarities,
        ),
      ));
    }
    parsed.sort((a, b) => a.order.compareTo(b.order));
    return parsed.map((e) => e.machine).toList();
  }
}
