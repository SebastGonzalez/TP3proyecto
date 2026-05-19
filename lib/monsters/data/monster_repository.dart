import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/monsters/domain/monster.dart';

class MonsterRepository {
  MonsterRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'monsters';

  Stream<List<Monster>> watchMonsters() {
    return _db.collection(collectionPath).snapshots().map(_parseSnapshot);
  }

  Future<List<Monster>> getMonsters() async {
    final snapshot = await _db.collection(collectionPath).get();
    return _parseSnapshot(snapshot);
  }

  List<Monster> _parseSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => Monster.fromFirestore(doc.data()))
        .toList();
  }
}
