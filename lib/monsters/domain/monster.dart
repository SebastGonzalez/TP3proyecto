import 'package:prueba1/monsters/domain/rarity.dart';

class Monster {
  String name;
  int level;
  Rarity rarity;
  String description;
  String imagePath;
  int dropWeight;
  /// Escala extra en la home (opcional). Si es null, usa [Rarity.homeCompanionScale].
  final double? homeScale;

  Monster({
    required this.name,
    required this.level,
    required this.rarity,
    required this.description,
    required this.imagePath,
    required this.dropWeight,
    this.homeScale,
  });

  double get homeDisplayScale => homeScale ?? rarity.homeCompanionScale;

  factory Monster.fromFirestore(Map<String, dynamic> data) {
    return Monster(
      name: data['name'] as String,
      level: data['level'] as int,
      rarity: Rarity.fromLabel(data['rarity'] as String?),
      description: data['description'] as String,
      imagePath: data['imagePath'] as String,
      dropWeight: data['dropWeight'] as int,
      homeScale: (data['homeScale'] as num?)?.toDouble(),
    );
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
    };
  }
}
