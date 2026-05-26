import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/core/domain/owned_monster.dart';
import 'package:prueba1/monsters/domain/trade_request.dart';
import 'package:prueba1/features/auth/application/providers/auth_provider.dart';
import 'package:prueba1/presentation/providers/trade_provider.dart';

final tradeControllerProvider = Provider<TradeController>(TradeController.new);

class TradeController {
  TradeController(this._ref);

  final Ref _ref;

  String? get _uid => _ref.read(userProvider).value?.uid;

  bool get hasCurrentUser => _uid != null;

  Future<TradeRequest?> createTrade({
    required String ownedMonsterId,
    required String monsterName,
    String? monsterImagePath,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    return _ref
        .read(tradeRepositoryProvider)
        .createTrade(
          fromUserId: uid,
          fromOwnedMonsterId: ownedMonsterId,
          fromMonsterName: monsterName,
          fromMonsterImagePath: monsterImagePath,
        );
  }

  Future<TradeRequest?> createTradeFromOwned(OwnedMonster owned) {
    return createTrade(
      ownedMonsterId: owned.id,
      monsterName: owned.monster.name,
      monsterImagePath: owned.monster.imagePath,
    );
  }

  Future<TradeRequest?> findByCode(String code) {
    return _ref.read(tradeRepositoryProvider).findByCode(code);
  }

  bool isOwnTrade(TradeRequest trade) => trade.fromUserId == _uid;

  Future<void> proposeTrade({
    required TradeRequest trade,
    required OwnedMonster selected,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _ref
        .read(tradeRepositoryProvider)
        .proposeTrade(
          tradeId: trade.id,
          toUserId: uid,
          toOwnedMonsterId: selected.id,
          toMonsterName: selected.monster.name,
          toMonsterImagePath: selected.monster.imagePath,
          toMonsterId: selected.monster.id,
        );
  }

  Future<void> confirmTrade(TradeRequest trade) {
    return _ref.read(tradeRepositoryProvider).confirmTrade(trade.id);
  }

  Future<void> rejectProposal(TradeRequest trade) {
    return _ref.read(tradeRepositoryProvider).rejectProposal(trade.id);
  }

  Future<void> withdrawProposal(TradeRequest trade) async {
    final uid = _uid;
    if (uid == null) return;

    await _ref.read(tradeRepositoryProvider).withdrawProposal(trade.id, uid);
  }

  Future<void> cancelTrade(TradeRequest trade) async {
    final uid = _uid;
    if (uid == null) return;

    await _ref.read(tradeRepositoryProvider).cancelTrade(trade.id, uid);
  }

  Future<void> markCompletedRevealSeen(TradeRequest trade) async {
    final uid = _uid;
    if (uid == null) return;

    await _ref.read(tradeRepositoryProvider).markSeen(trade.id, uid);
  }

  Future<void> cleanupActiveTradesForDeletedOwnedMonsters(
    Iterable<String> ownedMonsterIds,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    await _ref
        .read(tradeRepositoryProvider)
        .cleanupActiveTradesForDeletedOwnedMonsters(
          userId: uid,
          ownedMonsterIds: ownedMonsterIds,
        );
  }
}
