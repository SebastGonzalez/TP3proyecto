import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/features/trades/domain/models/trade_request.dart';

/// Repositorio de trades (colección `trades`).
///
/// Flujo:
/// 1. User A crea trade → genera código de 6 dígitos.
/// 2. User B busca por código → ve propuesta.
/// 3. User B acepta → transacción atómica swap de `ownerId`.
class TradeRepository {
  TradeRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const String collectionPath = 'trades';
  static const Duration tradeTtl = Duration(minutes: 10);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(collectionPath);

  /// Genera un código alfanumérico de 6 caracteres (mayúsculas + dígitos).
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return String.fromCharCodes(
      List.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }

  /// Crea un trade pendiente y devuelve el [TradeRequest] con código.
  Future<TradeRequest> createTrade({
    required String fromUserId,
    required String fromOwnedMonsterId,
    required String fromMonsterName,
    String? fromMonsterImagePath,
  }) async {
    final code = _generateCode();
    final now = DateTime.now();
    final expires = now.add(tradeTtl);

    final ref = _collection.doc();
    final data = <String, dynamic>{
      'code': code,
      'fromUserId': fromUserId,
      'fromOwnedMonsterId': fromOwnedMonsterId,
      'fromMonsterName': fromMonsterName,
      if (fromMonsterImagePath != null)
        'fromMonsterImagePath': fromMonsterImagePath,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expires),
    };
    await ref.set(data);

    return TradeRequest(
      id: ref.id,
      code: code,
      fromUserId: fromUserId,
      fromOwnedMonsterId: fromOwnedMonsterId,
      fromMonsterName: fromMonsterName,
      fromMonsterImagePath: fromMonsterImagePath,
      status: TradeStatus.pending,
      createdAt: now,
      expiresAt: expires,
    );
  }

  /// Busca un trade pendiente por código (case-insensitive).
  Future<TradeRequest?> findByCode(String code) async {
    final snap = await _collection
        .where('code', isEqualTo: code.toUpperCase().trim())
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final trade = TradeRequest.fromFirestore(doc.id, doc.data());
    if (trade.isExpired) return null;
    return trade;
  }

  /// User B propone su monstruo. El trade pasa a estado `proposed`.
  Future<void> proposeTrade({
    required String tradeId,
    required String toUserId,
    required String toOwnedMonsterId,
    required String toMonsterName,
    String? toMonsterImagePath,
    required String toMonsterId,
  }) async {
    final ref = _collection.doc(tradeId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('Trade no encontrado');
    final data = snap.data()!;
    if (data['status'] != 'pending') {
      throw StateError('Trade ya no está pendiente');
    }
    if (data['fromUserId'] == toUserId) {
      throw StateError('No podés intercambiar con vos mismo');
    }
    await ref.update({
      'status': 'proposed',
      'toUserId': toUserId,
      'toOwnedMonsterId': toOwnedMonsterId,
      'toMonsterName': toMonsterName,
      'toMonsterId': toMonsterId,
      if (toMonsterImagePath != null) 'toMonsterImagePath': toMonsterImagePath,
    });
  }

  /// User A confirma la propuesta → transacción atómica swap de ownerId.
  Future<void> confirmTrade(String tradeId) async {
    final tradeRef = _collection.doc(tradeId);

    await _db.runTransaction((tx) async {
      final tradeSnap = await tx.get(tradeRef);
      if (!tradeSnap.exists) throw StateError('Trade no encontrado');
      final tradeData = tradeSnap.data()!;

      if (tradeData['status'] != 'proposed') {
        throw StateError('Trade no está en estado propuesto');
      }

      final fromUserId = tradeData['fromUserId'] as String;
      final fromOwnedId = tradeData['fromOwnedMonsterId'] as String;
      final toUserId = tradeData['toUserId'] as String;
      final toOwnedId = tradeData['toOwnedMonsterId'] as String;

      final ownedCol = _db.collection('owned_monsters');
      final fromMonRef = ownedCol.doc(fromOwnedId);
      final toMonRef = ownedCol.doc(toOwnedId);

      final fromMonSnap = await tx.get(fromMonRef);
      final toMonSnap = await tx.get(toMonRef);

      if (!fromMonSnap.exists || !toMonSnap.exists) {
        throw StateError('Monstruo no encontrado');
      }

      if (fromMonSnap.data()!['ownerId'] != fromUserId) {
        throw StateError('El monstruo ofrecido ya no pertenece al creador');
      }
      if (toMonSnap.data()!['ownerId'] != toUserId) {
        throw StateError(
          'El monstruo propuesto ya no pertenece al otro jugador',
        );
      }

      tx.update(fromMonRef, {
        'ownerId': toUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(toMonRef, {
        'ownerId': fromUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final fromReceivedMonsterId = toMonSnap.data()!['monsterId'] as String?;
      final fromReceivedMonsterName = toMonSnap.data()!['name'] as String?;
      final toReceivedMonsterId = fromMonSnap.data()!['monsterId'] as String?;
      final toReceivedMonsterName = fromMonSnap.data()!['name'] as String?;

      tx.update(tradeRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'receivedMonsterId': fromReceivedMonsterId,
        'receivedMonsterName': fromReceivedMonsterName,
        'fromReceivedMonsterId': fromReceivedMonsterId,
        'fromReceivedMonsterName': fromReceivedMonsterName,
        'toReceivedMonsterId': toReceivedMonsterId,
        'toReceivedMonsterName': toReceivedMonsterName,
        'fromRevealSeen': true,
        'toRevealSeen': false,
        'seen': true,
      });
    });
  }

  /// User B retira su propuesta → vuelve a pending.
  Future<void> withdrawProposal(String tradeId, String userId) async {
    final ref = _collection.doc(tradeId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    if (data['toUserId'] != userId) return;
    if (data['status'] != 'proposed') return;
    await ref.update({
      'status': 'pending',
      'toUserId': FieldValue.delete(),
      'toOwnedMonsterId': FieldValue.delete(),
      'toMonsterName': FieldValue.delete(),
      'toMonsterId': FieldValue.delete(),
      'toMonsterImagePath': FieldValue.delete(),
    });
  }

  /// User A rechaza la propuesta de User B → vuelve a pending.
  Future<void> rejectProposal(String tradeId) async {
    final ref = _collection.doc(tradeId);
    await ref.update({
      'status': 'pending',
      'toUserId': FieldValue.delete(),
      'toOwnedMonsterId': FieldValue.delete(),
      'toMonsterName': FieldValue.delete(),
      'toMonsterId': FieldValue.delete(),
      'toMonsterImagePath': FieldValue.delete(),
    });
  }

  /// Cancela un trade (solo el creador, en estado pending o proposed).
  Future<void> cancelTrade(String tradeId, String userId) async {
    final ref = _collection.doc(tradeId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    if (data['fromUserId'] != userId) return;
    final status = data['status'] as String?;
    if (status != 'pending' && status != 'proposed') return;
    await ref.update({'status': 'cancelled'});
  }

  /// Limpia trades activos que referencian monstruos eliminados.
  ///
  /// - Si el usuario creó el trade con ese monstruo, el trade se cancela.
  /// - Si el usuario propuso ese monstruo en un trade ajeno, se retira la
  ///   propuesta y el trade vuelve a `pending`.
  Future<void> cleanupActiveTradesForDeletedOwnedMonsters({
    required String userId,
    required Iterable<String> ownedMonsterIds,
  }) async {
    final ids = ownedMonsterIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return;

    for (final chunk in _chunks(ids, 10)) {
      await _cancelCreatedTradesForDeletedOwnedIds(userId, chunk);
      await _withdrawProposalsForDeletedOwnedIds(userId, chunk);
    }
  }

  Future<void> _cancelCreatedTradesForDeletedOwnedIds(
    String userId,
    List<String> ownedIds,
  ) async {
    final snap = await _collection
        .where('fromUserId', isEqualTo: userId)
        .where('fromOwnedMonsterId', whereIn: ownedIds)
        .get();

    final batch = _db.batch();
    var hasWrites = false;
    for (final doc in snap.docs) {
      final status = doc.data()['status'] as String?;
      if (status != 'pending' && status != 'proposed') continue;
      batch.update(doc.reference, {'status': 'cancelled'});
      hasWrites = true;
    }
    if (hasWrites) await batch.commit();
  }

  Future<void> _withdrawProposalsForDeletedOwnedIds(
    String userId,
    List<String> ownedIds,
  ) async {
    final snap = await _collection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'proposed')
        .where('toOwnedMonsterId', whereIn: ownedIds)
        .get();

    final batch = _db.batch();
    var hasWrites = false;
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': 'pending',
        'toUserId': FieldValue.delete(),
        'toOwnedMonsterId': FieldValue.delete(),
        'toMonsterName': FieldValue.delete(),
        'toMonsterId': FieldValue.delete(),
        'toMonsterImagePath': FieldValue.delete(),
      });
      hasWrites = true;
    }
    if (hasWrites) await batch.commit();
  }

  /// Trades pendientes creados por [userId] (para la UI "esperando").
  Stream<List<TradeRequest>> watchMyPendingTrades(String userId) {
    return _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              TradeRequest.fromFirestore(doc.id, doc.data()),
          ],
        );
  }

  /// Trades con propuesta recibida (User B ya eligió, esperan confirmación de User A).
  Stream<List<TradeRequest>> watchMyProposedTrades(String userId) {
    return _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'proposed')
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              TradeRequest.fromFirestore(doc.id, doc.data()),
          ],
        );
  }

  /// Trades donde User B propuso y espera respuesta de User A.
  Stream<List<TradeRequest>> watchMyWaitingTrades(String userId) {
    return _collection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'proposed')
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              TradeRequest.fromFirestore(doc.id, doc.data()),
          ],
        );
  }

  /// Trades completados donde [userId] fue creador y aún no vio el resultado.
  Future<List<TradeRequest>> getUnseenCompletedTrades(String userId) async {
    final fromSnap = await _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    final toSnap = await _collection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    final byId = <String, TradeRequest>{};
    for (final doc in [...fromSnap.docs, ...toSnap.docs]) {
      final trade = TradeRequest.fromFirestore(doc.id, doc.data());
      if (!trade.revealSeenForUser(userId)) {
        byId[trade.id] = trade;
      }
    }

    final trades = byId.values.toList();
    trades.sort((a, b) {
      final aAt = a.completedAt ?? a.createdAt;
      final bAt = b.completedAt ?? b.createdAt;
      return aAt.compareTo(bAt);
    });
    return trades;
  }

  /// Trades completados sin reveal visto para cualquiera de los dos lados.
  Stream<List<TradeRequest>> watchUnseenCompletedTrades(String userId) {
    final controller = StreamController<List<TradeRequest>>();
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? fromDocs;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? toDocs;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? fromSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? toSub;

    void emitIfReady() {
      final from = fromDocs;
      final to = toDocs;
      if (from == null || to == null || controller.isClosed) return;

      final byId = <String, TradeRequest>{};
      for (final doc in [...from, ...to]) {
        final trade = TradeRequest.fromFirestore(doc.id, doc.data());
        if (!trade.revealSeenForUser(userId)) {
          byId[trade.id] = trade;
        }
      }

      final trades = byId.values.toList();
      trades.sort((a, b) {
        final aAt = a.completedAt ?? a.createdAt;
        final bAt = b.completedAt ?? b.createdAt;
        return aAt.compareTo(bAt);
      });
      controller.add(trades);
    }

    fromSub = _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snap) {
          fromDocs = snap.docs;
          emitIfReady();
        }, onError: controller.addError);

    toSub = _collection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snap) {
          toDocs = snap.docs;
          emitIfReady();
        }, onError: controller.addError);

    controller.onCancel = () async {
      await fromSub?.cancel();
      await toSub?.cancel();
    };

    return controller.stream;
  }

  /// Marca un trade como visto para el usuario actual.
  Future<void> markSeen(String tradeId, String userId) async {
    final ref = _collection.doc(tradeId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    if (data['fromUserId'] == userId) {
      await ref.update({'fromRevealSeen': true, 'seen': true});
      return;
    }

    if (data['toUserId'] == userId) {
      await ref.update({'toRevealSeen': true});
    }
  }

  Iterable<List<String>> _chunks(Set<String> ids, int size) sync* {
    final list = ids.toList();
    for (var i = 0; i < list.length; i += size) {
      final end = min(i + size, list.length);
      yield list.sublist(i, end);
    }
  }
}
