import 'package:flutter/material.dart';

class Monster {
  String name;
  int level;
  String rarity;
  String description;
  String imagePath;
  int dropWeight;

  Monster({
    required this.name,
    required this.level,
    required this.rarity,
    required this.description,
    required this.imagePath,
    required this.dropWeight,
  });

  factory Monster.fromFirestore(Map<String, dynamic> data) {
    return Monster(
      name: data['name'],
      level: data['level'],
      rarity: data['rarity'],
      description: data['description'],
      imagePath: data['imagePath'],
      dropWeight: data['dropWeight'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'rarity': rarity,
      'description': description,
      'imagePath': imagePath,
      'dropWeight': dropWeight,
    };
  }
}