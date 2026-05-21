/// Perfil del jugador en Firestore (`users/{firebaseAuthUid}`).
class MyUser {
  const MyUser({
    required this.uid,
    required this.coins,
    this.username,
    this.homeCompanionId,
    this.homeCompanionImagePath,
    this.homeCompanionFacing,
    this.homeCompanionScale,
    this.homeCompanionBackgroundColor,
    this.completedSbcIds = const [],
    this.createdAt,
  });

  /// UID de [Firebase Auth] — mismo id del documento en `users`.
  final String uid;
  final int coins;
  final String? username;

  /// Id de `owned_monsters/{id}` mostrado en la home.
  final String? homeCompanionId;

  /// Ruta de asset para pintar el compañero sin esperar la colección.
  final String? homeCompanionImagePath;

  /// Caché de visual en home: `"left"` | `"right"` (desde catálogo al elegir compañero).
  final String? homeCompanionFacing;

  /// Caché de escala en home (`monsters.homeScale` o rareza).
  final double? homeCompanionScale;

  /// Caché de fondo en home (ARGB, ver [Monster.homeDisplayBackgroundColor]).
  final int? homeCompanionBackgroundColor;

  /// Ids de documentos en `sbc/{id}` ya completados (una sola vez por desafío).
  final List<String> completedSbcIds;

  /// Fecha de creación del documento en Firestore (`createdAt`).
  final DateTime? createdAt;

  MyUser copyWith({
    String? uid,
    int? coins,
    String? username,
    String? homeCompanionId,
    String? homeCompanionImagePath,
    String? homeCompanionFacing,
    double? homeCompanionScale,
    int? homeCompanionBackgroundColor,
    List<String>? completedSbcIds,
    DateTime? createdAt,
    bool clearHomeCompanion = false,
  }) {
    return MyUser(
      uid: uid ?? this.uid,
      coins: coins ?? this.coins,
      username: username ?? this.username,
      homeCompanionId: clearHomeCompanion
          ? null
          : (homeCompanionId ?? this.homeCompanionId),
      homeCompanionImagePath: clearHomeCompanion
          ? null
          : (homeCompanionImagePath ?? this.homeCompanionImagePath),
      homeCompanionFacing: clearHomeCompanion
          ? null
          : (homeCompanionFacing ?? this.homeCompanionFacing),
      homeCompanionScale: clearHomeCompanion
          ? null
          : (homeCompanionScale ?? this.homeCompanionScale),
      homeCompanionBackgroundColor: clearHomeCompanion
          ? null
          : (homeCompanionBackgroundColor ??
              this.homeCompanionBackgroundColor),
      completedSbcIds: completedSbcIds ?? this.completedSbcIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool hasCompletedSbc(String sbcId) => completedSbcIds.contains(sbcId);
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
