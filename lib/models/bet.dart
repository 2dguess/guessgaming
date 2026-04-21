class Bet {
  final String betId;
  final String userId;
  final int digit;
  final int amount;
  final String status;
  final DateTime createdAt;
  /// `12:01` morning draw or `16:30` afternoon (Myanmar betting window).
  final String? drawSlot;
  /// Yangon calendar date for this draw.
  final String? drawDate;

  Bet({
    required this.betId,
    required this.userId,
    required this.digit,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.drawSlot,
    this.drawDate,
  });

  factory Bet.fromJson(Map<String, dynamic> json) {
    return Bet(
      betId: json['bet_id'] as String,
      userId: json['user_id'] as String,
      digit: json['digit'] as int,
      amount: json['amount'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      drawSlot: json['draw_slot'] as String?,
      drawDate: json['draw_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bet_id': betId,
      'user_id': userId,
      'digit': digit,
      'amount': amount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (drawSlot != null) 'draw_slot': drawSlot,
      if (drawDate != null) 'draw_date': drawDate,
    };
  }

  bool get isPending => status == 'pending';
  bool get isWin => status == 'win';
  bool get isLose => status == 'lose';

  /// Server credits this multiplier × stake on a win (virtual score).
  static const int winScoreMultiplier = 80;

  /// Virtual score credited when [isWin] (matches payout RPCs).
  int get winRewardScore => amount * winScoreMultiplier;
}

class TrendingDigit {
  final int digit;
  /// Distinct users who picked this digit (within the trending window).
  final int peopleCount;

  TrendingDigit({
    required this.digit,
    required this.peopleCount,
  });

  factory TrendingDigit.fromJson(Map<String, dynamic> json) {
    final rawPeople = json['people_count'] ?? json['bet_count'];
    return TrendingDigit(
      digit: (json['digit'] as num).toInt(),
      peopleCount: (rawPeople as num).toInt(),
    );
  }
}
