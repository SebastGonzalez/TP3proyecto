import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/monsters/data/trade_repository.dart';
import 'package:prueba1/monsters/domain/trade_request.dart';
import 'package:prueba1/presentation/providers/auth_provider.dart';

final tradeRepositoryProvider = Provider((ref) => TradeRepository());

/// Trades pendientes del usuario actual (creados por él).
final myPendingTradesProvider = StreamProvider<List<TradeRequest>>((ref) {
  final uid = ref.watch(userProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(tradeRepositoryProvider).watchMyPendingTrades(uid);
});

/// Trades con propuesta recibida esperando confirmación de User A.
final myProposedTradesProvider = StreamProvider<List<TradeRequest>>((ref) {
  final uid = ref.watch(userProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(tradeRepositoryProvider).watchMyProposedTrades(uid);
});

/// Trades donde el usuario propuso y espera respuesta del creador.
final myWaitingTradesProvider = StreamProvider<List<TradeRequest>>((ref) {
  final uid = ref.watch(userProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(tradeRepositoryProvider).watchMyWaitingTrades(uid);
});

/// Trades completados que el user A todavía no vio (para reveal al reentrar).
final unseenCompletedTradesProvider =
    FutureProvider<List<TradeRequest>>((ref) async {
  final uid = ref.watch(userProvider).value?.uid;
  if (uid == null) return [];
  return ref.read(tradeRepositoryProvider).getUnseenCompletedTrades(uid);
});
