import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/monsters/domain/monster.dart';

/// Catálogo en `monsters`. Campo `active` (bool): `false` oculta el monstruo.
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
        if (_isActive(doc.data())) Monster.fromFirestore(doc.data()),
    ];
  }
}
