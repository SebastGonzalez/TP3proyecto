import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/core/domain/my_user.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';

/// Repositorio Firestore para jugadores.
///
/// ## Colección `users`
/// - **Documento:** `{firebaseAuthUid}` (mismo id que `FirebaseAuth.currentUser.uid`)
/// - **Campos:**
///   - `username` (string, opcional)
///   - `coins` (number)
///   - `monsters` (array de maps `{ monsterId, count }`)
///   - `createdAt`, `updatedAt` (timestamp, server)
///
/// ## Queries usadas en la app
/// ```dart
/// _db.collection('users').doc(uid).get();
/// _db.collection('users').doc(uid).snapshots();
/// _db.collection('users').doc(uid).set({ ... }, SetOptions(merge: true));
/// _db.collection('users').doc(uid).update({ 'coins': coins, ... });
/// _db.collection('users').doc(uid).update({ 'monsters': stamps, ... });
/// ```
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'users';
  static const int defaultCoins = 1000;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(collectionPath).doc(uid);

  Future<MyUser?> getUser({
    required String uid,
    required List<Monster> catalog,
  }) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return _parseDoc(uid, snap.data()!, catalog);
  }

  Stream<MyUser?> watchUser({
    required String uid,
    required List<Monster> catalog,
  }) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return _parseDoc(uid, snap.data()!, catalog);
    });
  }

  Future<MyUser> createUser({
    required String uid,
    String? username,
    int initialCoins = defaultCoins,
    required List<Monster> catalog,
  }) async {
    final ref = _doc(uid);
    final existing = await ref.get();
    if (existing.exists) {
      return _parseDoc(uid, existing.data()!, catalog)!;
    }

    await ref.set({
      if (username != null) 'username': username,
      'coins': initialCoins,
      'monsters': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final created = await ref.get();
    return _parseDoc(uid, created.data()!, catalog)!;
  }

  Future<void> saveCoins(String uid, int coins) async {
    await _doc(uid).update({
      'coins': coins,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveMonsters(String uid, List<OwnedMonsterStamp> stamps) async {
    await _doc(uid).update({
      'monsters': stamps.map((s) => s.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveUser(MyUser user) async {
    await _doc(user.uid).set({
      if (user.username != null) 'username': user.username,
      'coins': user.coins,
      'monsters': _stampsFromEntries(user.monsters).map((s) => s.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  MyUser? _parseDoc(
    String uid,
    Map<String, dynamic> data,
    List<Monster> catalog,
  ) {
    final coins = (data['coins'] as num?)?.toInt() ?? defaultCoins;
    final username = data['username'] as String?;
    final rawList = data['monsters'] as List<dynamic>? ?? [];
    final stamps = [
      for (final item in rawList)
        if (item is Map<String, dynamic>) OwnedMonsterStamp.fromMap(item),
    ];
    final monsters = _entriesFromStamps(stamps, catalog);
    return MyUser(uid: uid, coins: coins, monsters: monsters, username: username);
  }

  List<CapturedEntry> _entriesFromStamps(
    List<OwnedMonsterStamp> stamps,
    List<Monster> catalog,
  ) {
    final byId = {for (final m in catalog) m.id: m};
    final byName = {for (final m in catalog) m.name: m};
    final entries = <CapturedEntry>[];
    for (final stamp in stamps) {
      final monster = stamp.monsterId.isNotEmpty
          ? byId[stamp.monsterId]
          : (stamp.legacyName != null ? byName[stamp.legacyName] : null);
      if (monster == null) continue;
      entries.add(CapturedEntry(monster: monster, count: stamp.count));
    }
    return entries;
  }

  List<OwnedMonsterStamp> _stampsFromEntries(List<CapturedEntry> entries) {
    return [
      for (final e in entries)
        OwnedMonsterStamp(monsterId: e.monster.id, count: e.count),
    ];
  }
}
