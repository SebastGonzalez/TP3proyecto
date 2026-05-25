import 'package:flutter_test/flutter_test.dart';
import 'package:prueba1/monsters/domain/trade_request.dart';

void main() {
  group('TradeRequest parsing', () {
    test('maps known Firestore status strings to enum values', () {
      expect(_trade({'status': 'pending'}).status, TradeStatus.pending);
      expect(_trade({'status': 'proposed'}).status, TradeStatus.proposed);
      expect(_trade({'status': 'completed'}).status, TradeStatus.completed);
      expect(_trade({'status': 'cancelled'}).status, TradeStatus.cancelled);
      expect(_trade({'status': 'expired'}).status, TradeStatus.expired);
    });

    test('unknown or missing statuses default to pending', () {
      expect(_trade({}).status, TradeStatus.pending);
      expect(_trade({'status': 'unknown'}).status, TradeStatus.pending);
    });

    test('isExpired only applies to pending trades past expiresAt', () {
      final past = DateTime.now().subtract(const Duration(minutes: 1));

      expect(_trade({'status': 'pending', 'expiresAt': past}).isExpired, isTrue);
      expect(
        _trade({'status': 'proposed', 'expiresAt': past}).isExpired,
        isFalse,
      );
    });
  });
}

TradeRequest _trade(Map<String, dynamic> overrides) {
  final now = DateTime.now();
  return TradeRequest.fromFirestore('trade-id', {
    'code': 'ABC123',
    'fromUserId': 'from-user',
    'fromOwnedMonsterId': 'owned-id',
    'fromMonsterName': 'Chispin',
    'createdAt': now,
    'expiresAt': now.add(const Duration(minutes: 10)),
    ...overrides,
  });
}
