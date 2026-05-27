import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/monsters/domain/models/rarity.dart';

/// Requisito de un espacio en un desafío SBC.
sealed class SacrificeSlotRequirement {
  const SacrificeSlotRequirement();

  bool matches(Monster monster);

  String get displayLabel;
}

/// El jugador debe entregar un monstruo de esta rareza.
final class RaritySlotRequirement extends SacrificeSlotRequirement {
  const RaritySlotRequirement(this.rarity);

  final Rarity rarity;

  @override
  bool matches(Monster monster) => monster.rarity == rarity;

  @override
  String get displayLabel => rarity.label;
}

/// El jugador debe entregar un monstruo con este nombre exacto.
final class MonsterNameSlotRequirement extends SacrificeSlotRequirement {
  const MonsterNameSlotRequirement(this.monsterName);

  final String monsterName;

  @override
  bool matches(Monster monster) => monster.name == monsterName;

  @override
  String get displayLabel => monsterName;
}
