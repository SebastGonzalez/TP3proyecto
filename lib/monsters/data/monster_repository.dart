import 'package:flutter/material.dart';
import 'package:prueba1/monsters/domain/monster.dart';

class MonsterRepository {

  final List<Monster> monsters = [
    Monster(
      name: 'Chispin',
      level: 1,
      rarity: 'Common',
      description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      image: Image.asset('assets/images/Chispin.png',),
    ),
    Monster(
      name: 'Goterin',
      level: 1,
      rarity: 'Common',
      description: 'A slightly tougher opponent.',
      image: Image.asset('assets/images/Goterin.png',),
    ),
    Monster(
      name: 'Hojarasco',
      level: 1,
      rarity: 'Common',
      description: 'A formidable foe.',
      image: Image.asset('assets/images/Hojarasco.png',),
    ),
    Monster(
      name: 'Piedrin',
      level: 1,
      rarity: 'Common',
      description: 'A powerful and dangerous monster.',
      image: Image.asset('assets/images/Piedrin.png',),
    ),
    Monster(
      name: 'Pluma',
      level: 1,
      rarity: 'Common',
      description: 'The ultimate challenge.',
      image: Image.asset('assets/images/Pluma.png',),
    ),
    Monster(
      name: 'Titanimo',
      level: 2,
      rarity: 'Rare',
      description: 'The ultimate challenge.',
      image: Image.asset('assets/images/Titanimo.png',),
    ),
    Monster(
      name: 'Vueltin',
      level: 2,
      rarity: 'Rare',
      description: 'The ultimate challenge.',
      image: Image.asset('assets/images/Vueltin.png',),
    ),
    Monster(
      name: 'Zancadon',
      level: 2,
      rarity: 'Rare',
      description: 'The ultimate challenge.',
      image: Image.asset('assets/images/Zancadon.png',),
    ),
    Monster(
      name: 'Huellama',
      level: 3,
      rarity: 'Legendary',
      description: 'The ultimate challenge.',
      image: Image.asset('assets/images/Huellama.png',),
    ),
  ];

  List<Monster> getMonsters() {
    return monsters;
  }
}
