import 'package:prueba1/monsters/domain/rarity.dart';

/// Lado de la home donde se dibuja el compañero (respecto al personaje).
/// Solo se persiste en el catálogo `monsters/{id}`; las instancias en
/// `owned_monsters` lo heredan al resolver `monsterId`.
enum HomeCompanionSide {
  /// Compañero a la izquierda del personaje.
  left,
  /// Compañero a la derecha del personaje.
  right,
}

class Monster {
  /// Id del documento en Firestore (`monsters/{id}`).
  final String id;
  String name;
  int level;
  Rarity rarity;
  String description;
  String imagePath;
  int dropWeight;
  /// Tamaño del compañero en la home. Catálogo `monsters.homeScale` (p. ej. `2`).
  /// Si es null, usa [Rarity.homeCompanionScale].
  final double? homeScale;

  /// Catálogo `monsters` → `homeFacing`: `"left"` | `"right"` (default `"left"`).
  final HomeCompanionSide homeFacing;

  /// UID del dueño (`users/{uid}`). Null en el catálogo global; se asigna al capturar.
  final String? ownerId;

  /// Id del documento en `owned_monsters/{ownedInstanceId}`.
  final String? ownedInstanceId;

  Monster({
    required this.id,
    required this.name,
    required this.level,
    required this.rarity,
    required this.description,
    required this.imagePath,
    required this.dropWeight,
    this.homeScale,
    this.homeFacing = HomeCompanionSide.left,
    this.ownerId,
    this.ownedInstanceId,
  });

  Monster copyWith({
    String? id,
    String? name,
    int? level,
    Rarity? rarity,
    String? description,
    String? imagePath,
    int? dropWeight,
    double? homeScale,
    HomeCompanionSide? homeFacing,
    String? ownerId,
    String? ownedInstanceId,
  }) {
    return Monster(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      rarity: rarity ?? this.rarity,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      dropWeight: dropWeight ?? this.dropWeight,
      homeScale: homeScale ?? this.homeScale,
      homeFacing: homeFacing ?? this.homeFacing,
      ownerId: ownerId ?? this.ownerId,
      ownedInstanceId: ownedInstanceId ?? this.ownedInstanceId,
    );
  }

  double get homeDisplayScale => homeScale ?? rarity.homeCompanionScale;

  /// Valor para Firestore (`monsters.homeFacing`).
  String get homeFacingLabel =>
      homeFacing == HomeCompanionSide.right ? 'right' : 'left';

  factory Monster.fromFirestore(String id, Map<String, dynamic> data) {
    return Monster(
      id: id,
      name: data['name'] as String,
      level: data['level'] as int,
      rarity: Rarity.fromLabel(data['rarity'] as String?),
      description: data['description'] as String,
      imagePath: data['imagePath'] as String,
      dropWeight: data['dropWeight'] as int,
      homeScale: (data['homeScale'] as num?)?.toDouble(),
      homeFacing: _homeFacingFromFirestore(data['homeFacing']),
    );
  }

  static HomeCompanionSide _homeFacingFromFirestore(dynamic value) {
    if (value == 'right') return HomeCompanionSide.right;
    return HomeCompanionSide.left;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'rarity': rarity.label,
      'description': description,
      'imagePath': imagePath,
      'dropWeight': dropWeight,
      if (homeScale != null) 'homeScale': homeScale,
      'homeFacing': homeFacingLabel,
    };
  }
}
