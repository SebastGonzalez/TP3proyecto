import 'package:flutter_riverpod/legacy.dart';
import 'package:prueba1/monsters/domain/monster.dart';

StateProvider<List<Monster>> myMonsterProvider = StateProvider<List<Monster>>((ref) => []);