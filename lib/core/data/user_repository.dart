import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/core/domain/my_user.dart';

/// Repositorio Firestore para jugadores.
///
/// ## Colección `users`
/// - **Documento:** `{firebaseAuthUid}`
/// - **Campos:** `username`, `coins`, `createdAt`, `updatedAt`
///
/// Los monstruos capturados viven en `owned_monsters` (ver [OwnedMonsterRepository]).
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'users';
  static const int defaultCoins = 1000;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(collectionPath).doc(uid);

  Future<MyUser?> getUser({required String uid}) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return _parseDoc(uid, snap.data()!);
  }

  Stream<MyUser?> watchUser({required String uid}) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return _parseDoc(uid, snap.data()!);
    });
  }

  Future<MyUser> createUser({
    required String uid,
    String? username,
    int initialCoins = defaultCoins,
  }) async {
    final ref = _doc(uid);
    final existing = await ref.get();
    if (existing.exists) {
      return _parseDoc(uid, existing.data()!)!;
    }

    await ref.set({
      if (username != null) 'username': username,
      'coins': initialCoins,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final created = await ref.get();
    return _parseDoc(uid, created.data()!)!;
  }

  Future<void> saveCoins(String uid, int coins) async {
    await _doc(uid).update({
      'coins': coins,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveUser(MyUser user) async {
    await _doc(user.uid).set({
      if (user.username != null) 'username': user.username,
      'coins': user.coins,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  MyUser? _parseDoc(String uid, Map<String, dynamic> data) {
    final coins = (data['coins'] as num?)?.toInt() ?? defaultCoins;
    final username = data['username'] as String?;
    return MyUser(uid: uid, coins: coins, username: username);
  }
}
