import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/core/domain/my_user.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/monsters/domain/monster.dart';

/// Colección `owned_monsters`: una fila por cada captura (gatcha, recompensa, etc.).
///
/// Campos del documento:
/// - `ownerId` (string): UID de Firebase Auth
/// - `monsterId` (string): id en `monsters/{monsterId}`
/// - `name` (string): nombre del catálogo (solo lectura humana en consola)
/// - `createdAt` (timestamp, server)
///
/// `homeFacing` / `homeScale` viven solo en `monsters`; la app los aplica al
/// armar [OwnedMonster] desde el catálogo.
class OwnedMonsterRepository {
  OwnedMonsterRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionPath = 'owned_monsters';
  static const String usersCollectionPath = 'users';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(collectionPath);

  /// Crea un documento nuevo y devuelve la instancia resuelta contra [catalog].
  Future<OwnedMonster> create({
    required String ownerId,
    required String monsterId,
    required List<Monster> catalog,
  }) async {
    final template = _resolveCatalog(catalog, monsterId);
    if (template == null) {
      throw StateError('Monstruo de catálogo no encontrado: $monsterId');
    }

    final ref = _collection.doc();
    await ref.set(_newDocFields(ownerId: ownerId, template: template));

    return _fromDoc(ref.id, {
      'ownerId': ownerId,
      'monsterId': monsterId,
      'name': template.name,
    }, template);
  }

  Stream<List<OwnedMonster>> watchByOwner({
    required String ownerId,
    required List<Monster> catalog,
  }) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => _parseSnapshot(snap, catalog));
  }

  Future<List<OwnedMonster>> getByOwner({
    required String ownerId,
    required List<Monster> catalog,
  }) async {
    final snap = await _collection.where('ownerId', isEqualTo: ownerId).get();
    return _parseSnapshot(snap, catalog);
  }

  Future<void> delete(String ownedId) async {
    await _collection.doc(ownedId).delete();
  }

  Future<void> deleteAllForOwner(String ownerId) async {
    final snap = await _collection.where('ownerId', isEqualTo: ownerId).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Migra `users/{uid}.monsters` (array con count) a documentos individuales.
  Future<void> migrateLegacyMonstersFromUser({
    required String ownerId,
    required List<Monster> catalog,
  }) async {
    final userRef = _db.collection(usersCollectionPath).doc(ownerId);
    final userSnap = await userRef.get();
    if (!userSnap.exists) return;

    final data = userSnap.data()!;
    final rawList = data['monsters'] as List<dynamic>?;
    if (rawList == null || rawList.isEmpty) return;

    final existing = await _collection.where('ownerId', isEqualTo: ownerId).get();
    if (existing.docs.isNotEmpty) {
      await userRef.update({
        'monsters': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final batch = _db.batch();
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;
      final stamp = OwnedMonsterStamp.fromMap(item);
      final monsterId = stamp.monsterId.isNotEmpty
          ? stamp.monsterId
          : (stamp.legacyName != null
              ? _resolveCatalogByName(catalog, stamp.legacyName!)?.id
              : null);
      if (monsterId == null || monsterId.isEmpty) continue;
      final template = _resolveCatalog(catalog, monsterId);
      if (template == null) continue;

      for (var i = 0; i < stamp.count; i++) {
        final ref = _collection.doc();
        batch.set(ref, _newDocFields(ownerId: ownerId, template: template));
      }
    }

    batch.update(userRef, {
      'monsters': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  List<OwnedMonster> _parseSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
    List<Monster> catalog,
  ) {
    final list = <OwnedMonster>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final monsterId = data['monsterId'] as String?;
      if (monsterId == null) continue;
      final template = _resolveCatalog(catalog, monsterId);
      if (template == null) continue;
      list.add(_fromDoc(doc.id, data, template));
    }
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  OwnedMonster _fromDoc(
    String docId,
    Map<String, dynamic> data,
    Monster template,
  ) {
    final ownerId = data['ownerId'] as String? ?? '';
    return OwnedMonster(
      id: docId,
      ownerId: ownerId,
      monsterId: template.id,
      monster: template.copyWith(
        ownerId: ownerId,
        ownedInstanceId: docId,
      ),
    );
  }

  Map<String, dynamic> _newDocFields({
    required String ownerId,
    required Monster template,
  }) =>
      {
        'ownerId': ownerId,
        'monsterId': template.id,
        'name': template.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Monster? _resolveCatalog(List<Monster> catalog, String monsterId) {
    for (final m in catalog) {
      if (m.id == monsterId) return m;
    }
    return null;
  }

  Monster? _resolveCatalogByName(List<Monster> catalog, String name) {
    for (final m in catalog) {
      if (m.name == name) return m;
    }
    return null;
  }
}
