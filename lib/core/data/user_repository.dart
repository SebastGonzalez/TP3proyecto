import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/core/domain/my_user.dart';

/// Repositorio Firestore para jugadores.
///
/// ## Colección `users`
/// - **Documento:** `{firebaseAuthUid}`
/// - **Campos:** `username`, `coins`, `homeCompanionId`, `homeCompanionImagePath`,
///   `homeCompanionFacing`, `homeCompanionScale`, `homeCompanionBackgroundColor`
///   (caché visual de home; fuente de verdad en catálogo `monsters`),
///   `createdAt`, `updatedAt`
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
    final trimmedUsername = username?.trim();
    final existing = await ref.get();

    if (existing.exists) {
      final parsed = _parseDoc(uid, existing.data()!)!;
      if (trimmedUsername != null &&
          trimmedUsername.isNotEmpty &&
          (parsed.username == null || parsed.username!.trim().isEmpty)) {
        await ref.set({
          'username': trimmedUsername,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        final updated = await ref.get();
        return _parseDoc(uid, updated.data()!)!;
      }
      return parsed;
    }

    await ref.set({
      if (trimmedUsername != null && trimmedUsername.isNotEmpty)
        'username': trimmedUsername,
      'coins': initialCoins,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final created = await ref.get();
    return _parseDoc(uid, created.data()!)!;
  }

  Future<void> saveUsername(String uid, String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('El nombre de usuario no puede estar vacío');
    }
    await _doc(uid).set({
      'username': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveCoins(String uid, int coins) async {
    await _doc(uid).update({
      'coins': coins,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Compañero en la home: id + snapshot visual para el primer frame sin esperar catálogo.
  Future<void> saveHomeCompanion(
    String uid, {
    String? ownedInstanceId,
    String? imagePath,
    String? homeFacing,
    double? homeScale,
    int? homeBackgroundColor,
  }) async {
    final trimmedId = ownedInstanceId?.trim();
    if (trimmedId == null || trimmedId.isEmpty) {
      await _doc(uid).set({
        'homeCompanionId': FieldValue.delete(),
        'homeCompanionImagePath': FieldValue.delete(),
        'homeCompanionFacing': FieldValue.delete(),
        'homeCompanionScale': FieldValue.delete(),
        'homeCompanionBackgroundColor': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }
    await _doc(uid).set({
      'homeCompanionId': trimmedId,
      if (imagePath != null && imagePath.isNotEmpty)
        'homeCompanionImagePath': imagePath,
      if (homeFacing != null && homeFacing.isNotEmpty)
        'homeCompanionFacing': homeFacing,
      if (homeScale != null) 'homeCompanionScale': homeScale,
      if (homeBackgroundColor != null)
        'homeCompanionBackgroundColor': homeBackgroundColor,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveUser(MyUser user) async {
    await _doc(user.uid).set({
      if (user.username != null) 'username': user.username,
      'coins': user.coins,
      if (user.homeCompanionId != null)
        'homeCompanionId': user.homeCompanionId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  MyUser? _parseDoc(String uid, Map<String, dynamic> data) {
    final coins = (data['coins'] as num?)?.toInt() ?? defaultCoins;
    final username = data['username'] as String?;
    final homeCompanionId = data['homeCompanionId'] as String?;
    final homeCompanionImagePath = data['homeCompanionImagePath'] as String?;
    final homeCompanionFacing = data['homeCompanionFacing'] as String?;
    final homeCompanionScale = (data['homeCompanionScale'] as num?)?.toDouble();
    final homeCompanionBackgroundColor =
        (data['homeCompanionBackgroundColor'] as num?)?.toInt();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    return MyUser(
      uid: uid,
      coins: coins,
      username: username,
      homeCompanionId: homeCompanionId,
      homeCompanionImagePath: homeCompanionImagePath,
      homeCompanionFacing: homeCompanionFacing,
      homeCompanionScale: homeCompanionScale,
      homeCompanionBackgroundColor: homeCompanionBackgroundColor,
      createdAt: createdAt,
    );
  }
}
