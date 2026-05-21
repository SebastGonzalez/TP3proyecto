import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prueba1/monsters/domain/rarity.dart';

/// Colección `monsters_rarity`: catálogo editable sin actualizar la APK.
///
/// Campos por documento (`monsters_rarity/{id}`):
/// - `label` (string): valor en `monsters.rarity` (ej. `"Common"`)
/// - `color` (int ARGB)
/// - `weight` (int): orden y umbral “al menos Rare”
/// - `homeCompanionScale` (number, opcional)
/// - `active` (bool, opcional): `false` oculta la rareza
/// - `order` (int, opcional): orden en listados
class RarityRepository {
  RarityRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'monsters_rarity';

  Future<RarityCatalog> loadCatalog() async {
    final snapshot = await _db.collection(collectionPath).get();
    if (snapshot.docs.isEmpty) return RarityCatalog.defaults();

    final parsed = <({int order, Rarity rarity})>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['active'] as bool?) == false) continue;
      final rarity = _parseDoc(doc.id, data);
      if (rarity == null) continue;
      final order = (data['order'] as num?)?.toInt() ?? rarity.weight;
      parsed.add((order: order, rarity: rarity));
    }

    if (parsed.isEmpty) return RarityCatalog.defaults();

    parsed.sort((a, b) => a.order.compareTo(b.order));
    final list = parsed.map((e) => e.rarity).toList();
    final rareWeight =
        list.where((r) => r.label == 'Rare').map((r) => r.weight).firstOrNull ??
            1;
    return RarityCatalog([
      for (final r in list)
        Rarity(
          id: r.id,
          label: r.label,
          color: r.color,
          weight: r.weight,
          homeCompanionScale: r.homeCompanionScale,
          isAtLeastRare: r.weight >= rareWeight,
        ),
    ]);
  }

  Rarity? _parseDoc(String id, Map<String, dynamic> data) {
    final label = data['label'] as String?;
    if (label == null || label.isEmpty) return null;

    final colorRaw = data['color'];
    final color =
        colorRaw is num ? Color(colorRaw.toInt()) : const Color(0xFF9E9E9E);

    final weight = (data['weight'] as num?)?.toInt() ?? 0;
    final homeCompanionScale =
        (data['homeCompanionScale'] as num?)?.toDouble() ?? 1.0;

    return Rarity(
      id: id,
      label: label,
      color: color,
      weight: weight,
      homeCompanionScale: homeCompanionScale,
      isAtLeastRare: false,
    );
  }
}
