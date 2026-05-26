import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/monsters/domain/sacrifice_slot.dart';

/// A single SBC-style challenge: sacrifice monsters matching [slots]
/// to earn [reward].
class SacrificeChallenge {
  const SacrificeChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.slots,
  });

  final String id;
  final String title;
  final String description;
  final Monster reward;
  final List<SacrificeSlotRequirement> slots;

  int get slotCount => slots.length;
}
