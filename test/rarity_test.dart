import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba1/monsters/domain/rarity.dart';

void main() {
  group('RarityCatalog', () {
    test('defaults resolve labels, ids, and fallback behavior', () {
      final catalog = RarityCatalog.defaults();

      expect(catalog.byLabel('Common').id, 'common');
      expect(catalog.tryResolve('rare')?.label, 'Rare');
      expect(catalog.tryResolve('LEGENDARY')?.id, 'legendary');
      expect(catalog.tryResolve('does-not-exist'), isNull);
      expect(catalog.byLabel('does-not-exist'), catalog.fallback);
    });

    test('similar keys and aliases resolve to the expected rarity', () {
      const mythic = Rarity(
        id: 'mythic-tier',
        label: 'Mythic Tier',
        color: Color(0xFFAA00FF),
        weight: 3,
        homeCompanionScale: 1.3,
        isAtLeastRare: true,
      );
      final catalog = RarityCatalog(
        [
          const Rarity(
            id: 'common',
            label: 'Common',
            color: Color(0xFF26C6DA),
            weight: 0,
            homeCompanionScale: 1,
            isAtLeastRare: false,
          ),
          mythic,
        ],
        aliases: {'m': mythic},
      );

      expect(catalog.tryResolve('m'), mythic);
      expect(catalog.tryResolve('mythictier'), mythic);
      expect(catalog.tryResolve('Mythic'), mythic);
    });

    test('legendary detection prefers legendary ids', () {
      final catalog = RarityCatalog.defaults();
      final legendary = catalog.byId('legendary')!;
      final fusion = catalog.byId('fusion')!;

      expect(catalog.isLegendary(legendary), isTrue);
      expect(catalog.isLegendary(fusion), isFalse);
    });
  });
}
