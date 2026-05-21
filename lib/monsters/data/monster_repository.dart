import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/monsters/domain/monster.dart';

/// Catálogo en `monsters`.
///
/// Campos relevantes: `name`, `imagePath`, `rarity`,
/// `homeScale` (número, opcional; ej. `2` = doble en la home; si falta, escala por rareza),
/// `homeFacing` (`left` | `right`, default `left`),
/// `homeBackgroundColor` (int ARGB o `"#RRGGBB"`, opcional; fondo de la home con compañero),
/// `active` (`false` oculta).
///
/// `homeFacing` no va en `owned_monsters` ni en `users`: las instancias
/// capturadas usan el valor del documento de catálogo vía `monsterId`.
class MonsterRepository {
  MonsterRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'monsters';

  /// Solo documentos con `active != false` (si no existe el campo, se incluye).
  Stream<List<Monster>> watchMonsters() {
    return _db.collection(collectionPath).snapshots().map(_parseSnapshot);
  }

  Future<List<Monster>> getMonsters() async {
    final snapshot = await _db.collection(collectionPath).get();
    return _parseSnapshot(snapshot);
  }

  bool _isActive(Map<String, dynamic> data) => data['active'] as bool? ?? true;

  List<Monster> _parseSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return [
      for (final doc in snapshot.docs)
        if (_isActive(doc.data())) Monster.fromFirestore(doc.id, doc.data()),
    ];
  }
}
