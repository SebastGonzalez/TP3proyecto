import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/monsters/data/monster_repository.dart';
import 'package:prueba1/monsters/domain/monster.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final monsterRepository = MonsterRepository();

  List<Monster> getMonsters() {
    return monsterRepository.getMonsters();
  }
  List<Monster> monsters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokedex Screen'),
      ),

      body: _ListView(monsters: monsterRepository.getMonsters(),),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Monster> monsters;

  const _ListView({super.key, required this.monsters});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        return _ListItem(monster: monsters[index]);
      },
    );
  }
}

class _ListItem extends StatelessWidget {
  final Monster monster;

  const _ListItem({super.key, required this.monster,});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: monster.image,
        title: Text(monster.name),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tier: ${monster.level}'),
            Text('${monster.rarity}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {

          context.push('/details', extra: monster);

        },
      ),
    );
  }
}