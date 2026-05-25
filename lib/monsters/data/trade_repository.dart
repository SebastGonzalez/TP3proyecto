import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prueba1/monsters/domain/trade_request.dart';

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
        throw StateError('El monstruo propuesto ya no pertenece al otro jugador');
      }

      tx.update(fromMonRef, {'ownerId': toUserId});
      tx.update(toMonRef, {'ownerId': fromUserId});

      final receivedMonsterId = toMonSnap.data()!['monsterId'] as String?;
      final receivedMonsterName = toMonSnap.data()!['name'] as String?;

      tx.update(tradeRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'receivedMonsterId': receivedMonsterId,
        'receivedMonsterName': receivedMonsterName,
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

  /// Trades pendientes creados por [userId] (para la UI "esperando").
  Stream<List<TradeRequest>> watchMyPendingTrades(String userId) {
    return _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => [
              for (final doc in snap.docs)
                TradeRequest.fromFirestore(doc.id, doc.data()),
            ]);
  }

  /// Trades con propuesta recibida (User B ya eligió, esperan confirmación de User A).
  Stream<List<TradeRequest>> watchMyProposedTrades(String userId) {
    return _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'proposed')
        .snapshots()
        .map((snap) => [
              for (final doc in snap.docs)
                TradeRequest.fromFirestore(doc.id, doc.data()),
            ]);
  }

  /// Trades donde User B propuso y espera respuesta de User A.
  Stream<List<TradeRequest>> watchMyWaitingTrades(String userId) {
    return _collection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'proposed')
        .snapshots()
        .map((snap) => [
              for (final doc in snap.docs)
                TradeRequest.fromFirestore(doc.id, doc.data()),
            ]);
  }

  /// Trades completados donde [userId] fue creador y aún no vio el resultado.
  Future<List<TradeRequest>> getUnseenCompletedTrades(String userId) async {
    final snap = await _collection
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .where('seen', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) {
      final fallback = await _collection
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      return [
        for (final doc in fallback.docs)
          if (doc.data()['seen'] == null)
            TradeRequest.fromFirestore(doc.id, doc.data()),
      ];
    }
    return [
      for (final doc in snap.docs)
        TradeRequest.fromFirestore(doc.id, doc.data()),
    ];
  }

  /// Marca un trade como visto (User A ya vio el reveal).
  Future<void> markSeen(String tradeId) async {
    await _collection.doc(tradeId).update({'seen': true});
  }
}
