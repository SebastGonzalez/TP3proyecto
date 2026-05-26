import 'package:flutter_test/flutter_test.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';
import 'package:prueba1/features/profile/application/providers/profile_stats_provider.dart';

void main() {
  group('profile stats pure logic', () {
    test('trainer level increases every five captures', () {
      expect(trainerLevelFromCaptures(0), 1);
      expect(trainerLevelFromCaptures(4), 1);
      expect(trainerLevelFromCaptures(5), 2);
      expect(trainerLevelFromCaptures(10), 3);
    });

    test('rank uses the current capture thresholds', () {
      expect(rankFromCaptures(0), 'Novato');
      expect(rankFromCaptures(1), 'Entrenador');
      expect(rankFromCaptures(4), 'Entrenador');
      expect(rankFromCaptures(5), 'Experto');
      expect(rankFromCaptures(14), 'Experto');
      expect(rankFromCaptures(15), 'Veterano');
      expect(rankFromCaptures(29), 'Veterano');
      expect(rankFromCaptures(30), 'Maestro');
    });

    test('complete catalog requires every catalog monster id to be owned', () {
      final catalog = [
        _monster('chispin'),
        _monster('goterin'),
      ];

      expect(computeOwnsCompleteCatalog([], {'chispin'}), isFalse);
      expect(computeOwnsCompleteCatalog(catalog, {'chispin'}), isFalse);
      expect(
        computeOwnsCompleteCatalog(catalog, {'chispin', 'goterin'}),
        isTrue,
      );
    });
  });
}

Monster _monster(String id) {
  final rarity = RarityCatalog.defaults().fallback;
  return Monster(
    id: id,
    name: id,
    level: 1,
    rarity: rarity,
    description: '',
    imagePath: '',
  );
}
