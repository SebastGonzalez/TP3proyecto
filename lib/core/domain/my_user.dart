import 'package:prueba1/presentation/providers/captured_monsters_provider.dart';

/// Perfil del jugador en Firestore (`users/{firebaseAuthUid}`).
class MyUser {
  const MyUser({
    required this.uid,
    required this.coins,
    required this.monsters,
    this.username,
  });

  /// UID de [FirebaseAuth] — mismo id del documento en `users`.
  final String uid;
  final int coins;
  final List<CapturedEntry> monsters;
  final String? username;

  MyUser copyWith({
    String? uid,
    int? coins,
    List<CapturedEntry>? monsters,
    String? username,
  }) {
    return MyUser(
      uid: uid ?? this.uid,
      coins: coins ?? this.coins,
      monsters: monsters ?? this.monsters,
      username: username ?? this.username,
    );
  }
}

/// Referencia mínima en `users.monsters`: id del doc en `monsters/{monsterId}`.
class OwnedMonsterStamp {
  const OwnedMonsterStamp({
    required this.monsterId,
    required this.count,
    this.legacyName,
  });

  final String monsterId;
  final int count;

  /// Solo para leer documentos viejos guardados con `name` en lugar de `monsterId`.
  final String? legacyName;

  factory OwnedMonsterStamp.fromMap(Map<String, dynamic> data) {
    final id = data['monsterId'] as String? ?? data['id'] as String?;
    if (id != null && id.isNotEmpty) {
      return OwnedMonsterStamp(
        monsterId: id,
        count: (data['count'] as num).toInt(),
      );
    }
    return OwnedMonsterStamp(
      monsterId: '',
      count: (data['count'] as num).toInt(),
      legacyName: data['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'monsterId': monsterId,
        'count': count,
      };
}
