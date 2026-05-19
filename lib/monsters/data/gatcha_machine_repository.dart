import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/monsters/domain/gatcha_machine.dart';

/// Lee máquinas gacha desde Firestore.
///
/// Colección: `gatcha_machines`. Cada documento es una máquina; el **id del
/// documento** es el `id` de dominio (`standard`, `premium`, …).
///
/// Campos esperados:
/// - `name` (String), `description` (String), `cost` (int)
/// - `haloColor`, `accentColor` (int ARGB, mismo formato que [Color.value])
/// - `rarityBoosts` (mapa): claves = [Rarity.label] (`Common`, `Rare`,
///   `Legendary`), valores = double
/// - `rollsPerPull` (int, opcional): monstruos por tirada (default 1, máx. 10)
/// - `active` (bool, opcional): `false` oculta la máquina; si falta, se muestra
/// - `order` (int, opcional): orden en el carrusel (menor = primero)
class GatchaMachineRepository {
  GatchaMachineRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'gatcha_machines';

  Stream<List<GatchaMachine>> watchMachines() {
    return _db.collection(collectionPath).snapshots().map(_parseSnapshot);
  }

  Future<List<GatchaMachine>> getMachines() async {
    final snapshot = await _db.collection(collectionPath).get();
    return _parseSnapshot(snapshot);
  }

  bool _isActive(Map<String, dynamic> data) => data['active'] as bool? ?? true;

  List<GatchaMachine> _parseSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final parsed = <({int order, GatchaMachine machine})>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isActive(data)) continue;
      final order = (data['order'] as num?)?.toInt() ?? 1 << 20;
      parsed.add((
        order: order,
        machine: GatchaMachine.fromFirestore(data, documentId: doc.id),
      ));
    }
    parsed.sort((a, b) => a.order.compareTo(b.order));
    return parsed.map((e) => e.machine).toList();
  }
}
