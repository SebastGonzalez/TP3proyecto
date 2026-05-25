import 'package:flutter_test/flutter_test.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';
import 'package:prueba1/monsters/domain/sacrifice_slot.dart';

void main() {
  group('SacrificeSlotRequirement', () {
    test('rarity slots match monsters by rarity id equality', () {
      final rare = RarityCatalog.defaults().byLabel('Rare');
      final sameIdRare = Rarity(
        id: rare.id,
        label: 'Different Label',
        color: rare.color,
        weight: rare.weight,
        homeCompanionScale: rare.homeCompanionScale,
        isAtLeastRare: rare.isAtLeastRare,
      );
      final common = RarityCatalog.defaults().byLabel('Common');

      final requirement = RaritySlotRequirement(rare);

      expect(requirement.matches(_monster('A', sameIdRare)), isTrue);
      expect(requirement.matches(_monster('B', common)), isFalse);
      expect(requirement.displayLabel, 'Rare');
    });

    test('monster name slots match exact case-sensitive names', () {
      const requirement = MonsterNameSlotRequirement('Chispin');
      final rarity = RarityCatalog.defaults().fallback;

      expect(requirement.matches(_monster('Chispin', rarity)), isTrue);
      expect(requirement.matches(_monster('chispin', rarity)), isFalse);
      expect(requirement.matches(_monster('Goterin', rarity)), isFalse);
      expect(requirement.displayLabel, 'Chispin');
    });
  });
}

Monster _monster(String name, Rarity rarity) {
  return Monster(
    id: name.toLowerCase(),
    name: name,
    level: 1,
    rarity: rarity,
    description: '',
    imagePath: '',
  );
}
