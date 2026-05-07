import 'package:flutter/material.dart';

class Monster {
  String name;
  int level;
  String rarity;
  String description;
  Image image;

  Monster({
    required this.name,
    required this.level,
    required this.rarity,
    required this.description,
    required this.image,
  });
}