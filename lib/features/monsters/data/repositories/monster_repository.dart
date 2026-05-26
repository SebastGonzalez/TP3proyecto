import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/monsters/domain/models/rarity.dart';

/// Catálogo en `monsters`.
///
/// Campos relevantes: `name`, `imagePath`, `rarity` (string = [Rarity.label] en `monsters_rarity`),
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
  Stream<List<Monster>> watchMonsters({required RarityCatalog rarities}) {
    return _db
        .collection(collectionPath)
        .snapshots()
        .map((snap) => _parseSnapshot(snap, rarities));
  }

  Future<List<Monster>> getMonsters({required RarityCatalog rarities}) async {
    final snapshot = await _db.collection(collectionPath).get();
    return _parseSnapshot(snapshot, rarities);
  }

  bool _isActive(Map<String, dynamic> data) => data['active'] as bool? ?? true;

  List<Monster> _parseSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    RarityCatalog rarities,
  ) {
    return [
      for (final doc in snapshot.docs)
        if (_isActive(doc.data()))
          Monster.fromFirestore(doc.id, doc.data(), rarities: rarities),
    ];
  }
}
