import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/monsters/domain/monster.dart';
import 'package:prueba1/monsters/domain/rarity.dart';
import 'package:prueba1/monsters/domain/sacrifice_challenge.dart';
import 'package:prueba1/monsters/domain/sacrifice_slot.dart';

/// Resultado de cargar SBC: lista usable + cuántos docs tenían `active: true`.
class SacrificeChallengesState {
  const SacrificeChallengesState({
    required this.challenges,
    required this.activeDocumentsCount,
  });

  final List<SacrificeChallenge> challenges;
  /// Documentos devueltos por la query `active == true` (antes de validar datos).
  final int activeDocumentsCount;
}

/// Lee desafíos SBC desde la colección Firestore `sbc`.
///
/// Solo se listan documentos con **`active: true`** (query en Firestore).
///
/// Campos por documento:
/// - **`active`** (bool, obligatorio para aparecer): debe ser `true`.
/// - `rewardName` (string): igual que `name` de un doc en `monsters`.
/// - **`slots`** (array, obligatorio): requisitos de cada espacio. Cada ítem puede ser:
///   - string de rareza (`Common`, `Rare`, …) o nombre de monstruo del catálogo;
///   - map `{ "type": "rarity", "value": "Rare" }` o `{ "type": "monster", "value": "Tormentolito" }`.
/// - `title`, `description` (opcionales)
/// - `sortOrder` (number, opcional)
/// - `id` (string, opcional): id estable del desafío; si no, se usa el id del doc.
class SacrificeRepository {
  SacrificeRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<SacrificeChallengesState> loadChallenges(List<Monster> catalog) async {
    final snapshot = await _db
        .collection('sbc')
        .where('active', isEqualTo: true)
        .get();

    final activeDocumentsCount = snapshot.docs.length;
    final mapped = <({SacrificeChallenge ch, int order})>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final challenge = _tryBuild(doc.id, data, catalog);
      if (challenge == null) continue;
      final order = (data['sortOrder'] as num?)?.toInt() ?? 0;
      mapped.add((ch: challenge, order: order));
    }

    mapped.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.ch.id.compareTo(b.ch.id);
    });

    return SacrificeChallengesState(
      challenges: mapped.map((e) => e.ch).toList(),
      activeDocumentsCount: activeDocumentsCount,
    );
  }

  SacrificeChallenge? _tryBuild(
    String docId,
    Map<String, dynamic> data,
    List<Monster> catalog,
  ) {
    final rewardName = data['rewardName'] as String?;
    if (rewardName == null || rewardName.trim().isEmpty) return null;

    Monster? reward;
    for (final m in catalog) {
      if (m.name == rewardName) {
        reward = m;
        break;
      }
    }
    if (reward == null) return null;

    final rawSlots = data['slots'];
    if (rawSlots is! List || rawSlots.isEmpty) return null;
    final slots = _parseSlotsList(rawSlots, catalog);
    if (slots == null || slots.isEmpty) return null;

    final stableId = (data['id'] as String?)?.trim();
    final challengeId =
        stableId != null && stableId.isNotEmpty ? stableId : docId;

    return SacrificeChallenge(
      id: challengeId,
      title: data['title'] as String? ?? challengeId,
      description: data['description'] as String? ?? '',
      reward: reward,
      slots: slots,
    );
  }

  List<SacrificeSlotRequirement>? _parseSlotsList(
    List<dynamic> raw,
    List<Monster> catalog,
  ) {
    final slots = <SacrificeSlotRequirement>[];
    for (final e in raw) {
      final slot = _parseOneSlot(e, catalog);
      if (slot == null) return null;
      slots.add(slot);
    }
    return slots;
  }

  SacrificeSlotRequirement? _parseOneSlot(
    dynamic raw,
    List<Monster> catalog,
  ) {
    if (raw is Map) {
      final type = (raw['type'] as String?)?.toLowerCase().trim();
      if (type == 'rarity' || raw.containsKey('rarity')) {
        final value = raw['value'] ?? raw['rarity'];
        return RaritySlotRequirement(Rarity.fromLabel(value?.toString()));
      }
      if (type == 'monster' ||
          type == 'name' ||
          raw.containsKey('monsterName') ||
          raw.containsKey('name')) {
        final value = raw['value'] ?? raw['monsterName'] ?? raw['name'];
        final name = value?.toString().trim();
        if (name == null || name.isEmpty) return null;
        if (!_monsterExists(name, catalog)) return null;
        return MonsterNameSlotRequirement(name);
      }
      return null;
    }

    if (raw is String) {
      final label = raw.trim();
      if (label.isEmpty) return null;
      if (_isRarityLabel(label)) {
        return RaritySlotRequirement(Rarity.fromLabel(label));
      }
      if (_monsterExists(label, catalog)) {
        return MonsterNameSlotRequirement(label);
      }
      return null;
    }

    return null;
  }

  bool _isRarityLabel(String label) =>
      Rarity.values.any((r) => r.label == label);

  bool _monsterExists(String name, List<Monster> catalog) =>
      catalog.any((m) => m.name == name);
}
