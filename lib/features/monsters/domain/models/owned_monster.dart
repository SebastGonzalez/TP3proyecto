import 'package:prueba1/features/monsters/domain/models/monster.dart';

/// Una instancia capturada: un documento en `owned_monsters/{id}`.
class OwnedMonster {
  const OwnedMonster({
    required this.id,
    required this.ownerId,
    required this.monsterId,
    required this.monster,
    this.capturedAt,
  });

  /// Id del documento en `owned_monsters`.
  final String id;

  /// UID del dueño (`users/{ownerId}`).
  final String ownerId;

  /// Id del catálogo (`monsters/{monsterId}`).
  final String monsterId;

  /// Datos del catálogo + [ownerId] y [Monster.ownedInstanceId] = [id].
  final Monster monster;

  /// Momento de captura (`owned_monsters.createdAt`). Null en docs legacy.
  final DateTime? capturedAt;
}
