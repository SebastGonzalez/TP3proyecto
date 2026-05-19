import 'package:flutter/material.dart';
import 'package:prueba1/monsters/domain/monster.dart';

/// Card tile matching the My Monsters grid style (image, name, rarity).
class MonsterCardTile extends StatelessWidget {
  const MonsterCardTile({
    super.key,
    required this.monster,
    required this.rarityColor,
    this.onTap,
    this.stackCount,
  });

  final Monster monster;
  final Color rarityColor;
  final VoidCallback? onTap;
  /// When non-null and > 1, shows an "xN" badge like duplicate stacks.
  final int? stackCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: rarityColor.withValues(alpha: 0.3)),
      ),
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: _cardBody(),
            )
          : _cardBody(),
    );
  }

  Widget _cardBody() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  monster.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                monster.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                monster.rarity.label,
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (stackCount != null && stackCount! > 1)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x$stackCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
