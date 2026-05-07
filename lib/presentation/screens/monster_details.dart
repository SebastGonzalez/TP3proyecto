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
        title: Text('Monster Details'),
      ),
      body: _DetailView(monster: monster,),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Monster monster;

  const _DetailView({
    super.key,
    required this.monster,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('${monster.name}', style: textStyle.headlineLarge),
        Image.asset(monster.imagePath),
        Card(
          child: Column(
            children: [
              Text('Tier: ${monster.level}'),
              Text('Rarity: ${monster.rarity}'),
              Text('Description: ${monster.description}'),
            ],
          ),
        )
        
      ],
    );
  }
}