/// Estado de un intercambio.
enum TradeStatus { pending, proposed, completed, cancelled, expired }

/// Modelo de un trade en Firestore (`trades/{id}`).
class TradeRequest {
  const TradeRequest({
    required this.id,
    required this.code,
    required this.fromUserId,
    required this.fromOwnedMonsterId,
    required this.fromMonsterName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.fromMonsterImagePath,
    this.toUserId,
    this.toOwnedMonsterId,
    this.toMonsterName,
    this.toMonsterImagePath,
    this.completedAt,
    this.receivedMonsterId,
    this.receivedMonsterName,
  });

  final String id;
  final String code;
  final String fromUserId;
  final String fromOwnedMonsterId;
  final String fromMonsterName;
  final String? fromMonsterImagePath;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? toUserId;
  final String? toOwnedMonsterId;
  final String? toMonsterName;
  final String? toMonsterImagePath;
  final DateTime? completedAt;

  /// Monster catalogId que User A recibió (para reveal al reentrar).
  final String? receivedMonsterId;
  final String? receivedMonsterName;

  bool get isExpired =>
      status == TradeStatus.pending && DateTime.now().isAfter(expiresAt);

  factory TradeRequest.fromFirestore(String docId, Map<String, dynamic> data) {
    return TradeRequest(
      id: docId,
      code: data['code'] as String? ?? '',
      fromUserId: data['fromUserId'] as String? ?? '',
      fromOwnedMonsterId: data['fromOwnedMonsterId'] as String? ?? '',
      fromMonsterName: data['fromMonsterName'] as String? ?? '',
      fromMonsterImagePath: data['fromMonsterImagePath'] as String?,
      status: _parseStatus(data['status']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      expiresAt: _parseDateTime(data['expiresAt']) ?? DateTime.now(),
      toUserId: data['toUserId'] as String?,
      toOwnedMonsterId: data['toOwnedMonsterId'] as String?,
      toMonsterName: data['toMonsterName'] as String?,
      toMonsterImagePath: data['toMonsterImagePath'] as String?,
      completedAt: _parseDateTime(data['completedAt']),
      receivedMonsterId: data['receivedMonsterId'] as String?,
      receivedMonsterName: data['receivedMonsterName'] as String?,
    );
  }

  static TradeStatus _parseStatus(dynamic raw) {
    switch (raw) {
      case 'proposed':
        return TradeStatus.proposed;
      case 'completed':
        return TradeStatus.completed;
      case 'cancelled':
        return TradeStatus.cancelled;
      case 'expired':
        return TradeStatus.expired;
      default:
        return TradeStatus.pending;
    }
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw.runtimeType.toString().contains('Timestamp')) {
      return (raw as dynamic).toDate() as DateTime;
    }
    return null;
  }
}
