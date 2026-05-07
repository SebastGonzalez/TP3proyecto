import 'package:prueba1/monsters/domain/monster.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonsterRepository {
  final _db = FirebaseFirestore.instance;

  Future<List<Monster>> getMonsters() async {
    final snapshot = await _db.collection('monsters').get();
    return snapshot.docs
        .map((doc) => Monster.fromFirestore(doc.data()))
        .toList();
  }
}
