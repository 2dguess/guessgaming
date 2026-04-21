class Wallet {
  final String userId;
  final int balance;
  final int availableBalance;
  final int lockedBalance;
  final DateTime updatedAt;

  Wallet({
    required this.userId,
    required this.balance,
    required this.availableBalance,
    required this.lockedBalance,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final available = (json['available_balance'] as num?)?.toInt();
    final locked = (json['locked_balance'] as num?)?.toInt();
    final fallbackBalance = (json['balance'] as num?)?.toInt() ?? 0;
    return Wallet(
      userId: json['user_id'] as String,
      balance: fallbackBalance,
      availableBalance: available ?? fallbackBalance,
      lockedBalance: locked ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'balance': balance,
      'available_balance': availableBalance,
      'locked_balance': lockedBalance,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Virtual score available to spend (`wallets.available_balance`).
  int get availableScore => availableBalance;

  Wallet copyWith({
    String? userId,
    int? balance,
    int? availableBalance,
    int? lockedBalance,
    DateTime? updatedAt,
  }) {
    return Wallet(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      availableBalance: availableBalance ?? this.availableBalance,
      lockedBalance: lockedBalance ?? this.lockedBalance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
