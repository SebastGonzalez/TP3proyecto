import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';

/// A single SBC-style challenge: sacrifice monsters matching [slotRarities]
/// to earn [reward].
class SacrificeChallenge {
  const SacrificeChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.slotRarities,
  });

  final String id;
  final String title;
  final String description;
  final Monster reward;
  final List<Rarity> slotRarities;

  int get slotCount => slotRarities.length;
}
