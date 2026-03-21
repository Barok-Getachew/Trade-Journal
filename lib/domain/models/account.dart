import '../enums/account_type.dart';

class Account {
  final String id;
  final String userId;
  final String name;
  final String? broker;
  final String currency;
  final double initialBalance;
  final AccountType accountType;
  final int leverage;
  final double? targetBalance;
  final double? monthlyRTarget;
  final bool isArchived;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    this.broker,
    this.currency = 'USD',
    required this.initialBalance,
    this.accountType = AccountType.live,
    this.leverage = 1,
    this.targetBalance,
    this.monthlyRTarget,
    this.isArchived = false,
    required this.createdAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) => Account(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        broker: map['broker'] as String?,
        currency: map['currency'] as String? ?? 'USD',
        initialBalance: (map['initial_balance'] as num).toDouble(),
        accountType:
            AccountType.fromString(map['account_type'] as String? ?? 'live'),
        leverage: map['leverage'] as int? ?? 1,
        targetBalance: map['target_balance'] != null
            ? (map['target_balance'] as num).toDouble()
            : null,
        monthlyRTarget: map['monthly_r_target'] != null
            ? (map['monthly_r_target'] as num).toDouble()
            : null,
        isArchived: map['is_archived'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'broker': broker,
        'currency': currency,
        'initial_balance': initialBalance,
        'account_type': accountType.name,
        'leverage': leverage,
        'target_balance': targetBalance,
        'monthly_r_target': monthlyRTarget,
        'is_archived': isArchived,
      };

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    String? broker,
    String? currency,
    double? initialBalance,
    AccountType? accountType,
    int? leverage,
    double? targetBalance,
    double? monthlyRTarget,
    bool? isArchived,
    DateTime? createdAt,
  }) =>
      Account(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        broker: broker ?? this.broker,
        currency: currency ?? this.currency,
        initialBalance: initialBalance ?? this.initialBalance,
        accountType: accountType ?? this.accountType,
        leverage: leverage ?? this.leverage,
        targetBalance: targetBalance ?? this.targetBalance,
        monthlyRTarget: monthlyRTarget ?? this.monthlyRTarget,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
}
