/// Perfil del jugador en Firestore (`users/{firebaseAuthUid}`).
class MyUser {
  const MyUser({
    required this.uid,
    required this.coins,
    this.username,
  });

  /// UID de [FirebaseAuth] — mismo id del documento en `users`.
  final String uid;
  final int coins;
  final String? username;

  MyUser copyWith({
    String? uid,
    int? coins,
    String? username,
  }) {
    return MyUser(
      uid: uid ?? this.uid,
      coins: coins ?? this.coins,
      username: username ?? this.username,
    );
  }
}

/// Formato legado en `users.monsters` (solo para migración a `owned_monsters`).
class OwnedMonsterStamp {
  const OwnedMonsterStamp({
    required this.monsterId,
    required this.count,
    this.ownerId,
    this.legacyName,
  });

  final String monsterId;
  final int count;
  final String? ownerId;
  final String? legacyName;

  factory OwnedMonsterStamp.fromMap(Map<String, dynamic> data) {
    final id = data['monsterId'] as String? ?? data['id'] as String?;
    if (id != null && id.isNotEmpty) {
      return OwnedMonsterStamp(
        monsterId: id,
        count: (data['count'] as num).toInt(),
        ownerId: data['ownerId'] as String?,
      );
    }
    return OwnedMonsterStamp(
      monsterId: '',
      count: (data['count'] as num).toInt(),
      legacyName: data['name'] as String?,
      ownerId: data['ownerId'] as String?,
    );
  }
}
