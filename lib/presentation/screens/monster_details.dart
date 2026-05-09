import 'package:flutter/material.dart';
import 'package:prueba1/monsters/domain/monster.dart';

class MonsterDetails extends StatelessWidget {
  final Monster monster;

  const MonsterDetails({super.key, required this.monster});

   @override

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(monster.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: _DetailView(monster: monster,),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Monster monster;

  const _DetailView({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = monster.rarity.color;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen con fondo degradado
          Container(
            height: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  rarityColor.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: 400,
              height: 400,
              child: Image.asset(
                monster.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Info card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Rarity badge + Tier
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rarityColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        monster.rarity.label.toUpperCase(),
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tier ${monster.level}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Divider con label
                Row(
                  children: [
                    Text(
                      'DESCRIPCIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                const SizedBox(height: 12),

                // Descripción
                Text(
                  monster.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}