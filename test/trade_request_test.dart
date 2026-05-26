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

      expect(
        _trade({'status': 'pending', 'expiresAt': past}).isExpired,
        isTrue,
      );
      expect(
        _trade({'status': 'proposed', 'expiresAt': past}).isExpired,
        isFalse,
      );
    });

    test('resolves received monster metadata per participant', () {
      final trade = _trade({
        'fromUserId': 'user-a',
        'toUserId': 'user-b',
        'fromMonsterName': 'Chispin',
        'fromReceivedMonsterId': 'goterin',
        'fromReceivedMonsterName': 'Goterin',
        'toReceivedMonsterId': 'chispin',
        'toReceivedMonsterName': 'Chispin',
      });

      expect(trade.receivedMonsterIdForUser('user-a'), 'goterin');
      expect(trade.receivedMonsterNameForUser('user-a'), 'Goterin');
      expect(trade.receivedMonsterIdForUser('user-b'), 'chispin');
      expect(trade.receivedMonsterNameForUser('user-b'), 'Chispin');
      expect(trade.receivedMonsterIdForUser('other'), isNull);
    });

    test('uses legacy received fields for from user reveals', () {
      final trade = _trade({
        'fromUserId': 'user-a',
        'receivedMonsterId': 'legacy-id',
        'receivedMonsterName': 'Legacy Monster',
      });

      expect(trade.receivedMonsterIdForUser('user-a'), 'legacy-id');
      expect(trade.receivedMonsterNameForUser('user-a'), 'Legacy Monster');
    });

    test('tracks reveal seen independently for both participants', () {
      final trade = _trade({
        'fromUserId': 'user-a',
        'toUserId': 'user-b',
        'fromRevealSeen': true,
        'toRevealSeen': false,
      });

      expect(trade.revealSeenForUser('user-a'), isTrue);
      expect(trade.revealSeenForUser('user-b'), isFalse);
      expect(trade.revealSeenForUser('other'), isTrue);
    });

    test('legacy seen marks from user reveal as seen', () {
      final trade = _trade({'fromUserId': 'user-a', 'seen': true});

      expect(trade.revealSeenForUser('user-a'), isTrue);
    });

    test('legacy seen still wins if from reveal flag is false', () {
      final trade = _trade({
        'fromUserId': 'user-a',
        'fromRevealSeen': false,
        'seen': true,
      });

      expect(trade.revealSeenForUser('user-a'), isTrue);
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
