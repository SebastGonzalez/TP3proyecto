import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prueba1/features/monsters/domain/models/rarity.dart';

/// Colección `monsters_rarity`: catálogo editable sin actualizar la APK.
///
/// Campos por documento (`monsters_rarity/{id}`):
/// - `label` (string): valor en `monsters.rarity` (ej. `"Legendario"`)
/// - `color` (int ARGB)
/// - `weight` (int): orden y umbral “al menos raro” (no es % de gatcha)
/// - `gachaEligible` (bool, opcional): `false` excluye la rareza de todas las máquinas
/// - `homeCompanionScale` (number, opcional)
/// - `active` (bool, opcional): `false` oculta la rareza
/// - `order` (int, opcional): orden en listados
/// - `aliases` (array, opcional): sinónimos (`Legendary`, `legendary`, …)
class RarityRepository {
  RarityRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'monsters_rarity';

  Future<RarityCatalog> loadCatalog() async {
    final snapshot = await _db.collection(collectionPath).get();
    if (snapshot.docs.isEmpty) return RarityCatalog.defaults();

    final parsed = <({int order, Rarity rarity, List<String> aliases})>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['active'] as bool?) == false) continue;
      final rarity = _parseDoc(doc.id, data);
      if (rarity == null) continue;
      final order = (data['order'] as num?)?.toInt() ?? rarity.weight;
      parsed.add((
        order: order,
        rarity: rarity,
        aliases: _parseAliases(data['aliases']),
      ));
    }

    if (parsed.isEmpty) return RarityCatalog.defaults();

    parsed.sort((a, b) => a.order.compareTo(b.order));
    final rareWeight = RarityCatalog.computeRareMinWeight(
      parsed.map((e) => e.rarity).toList(),
    );
    final aliases = <String, Rarity>{};
    for (final e in parsed) {
      for (final a in e.aliases) {
        aliases[a] = e.rarity;
      }
    }
    return RarityCatalog(
      [
        for (final e in parsed)
          Rarity(
            id: e.rarity.id,
            label: e.rarity.label,
            color: e.rarity.color,
            weight: e.rarity.weight,
            homeCompanionScale: e.rarity.homeCompanionScale,
            isAtLeastRare: e.rarity.weight >= rareWeight,
            gachaEligible: e.rarity.gachaEligible,
          ),
      ],
      aliases: aliases,
    );
  }

  static List<String> _parseAliases(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final a in raw)
        if (a is String && a.trim().isNotEmpty) a.trim(),
    ];
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

    final gachaEligible = data['gachaEligible'] as bool? ?? true;

    return Rarity(
      id: id,
      label: label,
      color: color,
      weight: weight,
      homeCompanionScale: homeCompanionScale,
      isAtLeastRare: false,
      gachaEligible: gachaEligible,
    );
  }
}
