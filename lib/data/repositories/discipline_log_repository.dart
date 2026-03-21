import 'package:supabase_flutter/supabase_flutter.dart';

class DisciplineLog {
  final String id;
  final String userId;
  final String accountId;
  final DateTime logDate;
  final String violationType;
  final String? details;
  final String? tradeId;
  final DateTime createdAt;

  const DisciplineLog({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.logDate,
    required this.violationType,
    this.details,
    this.tradeId,
    required this.createdAt,
  });

  factory DisciplineLog.fromMap(Map<String, dynamic> map) => DisciplineLog(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        accountId: map['account_id'] as String,
        logDate: DateTime.parse(map['log_date'] as String),
        violationType: map['violation_type'] as String,
        details: map['details'] as String?,
        tradeId: map['trade_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'account_id': accountId,
        'log_date': logDate.toIso8601String().substring(0, 10),
        'violation_type': violationType,
        'details': details,
        'trade_id': tradeId,
      };
}

class DisciplineLogRepository {
  final SupabaseClient _client;
  DisciplineLogRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Append a new discipline violation entry.
  Future<DisciplineLog> log({
    required String accountId,
    required String violationType,
    String? details,
    String? tradeId,
  }) async {
    final data = {
      'user_id': _userId,
      'account_id': accountId,
      'log_date': DateTime.now().toIso8601String().substring(0, 10),
      'violation_type': violationType,
      'details': details,
      'trade_id': tradeId,
    };
    final response =
        await _client.from('discipline_logs').insert(data).select().single();
    return DisciplineLog.fromMap(response as Map<String, dynamic>);
  }

  /// Fetch recent logs for an account.
  Future<List<DisciplineLog>> fetchForAccount(
    String accountId, {
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    var q = _client
        .from('discipline_logs')
        .select()
        .eq('user_id', _userId)
        .eq('account_id', accountId);

    if (from != null) {
      q = q.gte('log_date', from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      q = q.lte('log_date', to.toIso8601String().substring(0, 10));
    }

    final response = await q.order('created_at', ascending: false).limit(limit);
    return (response as List)
        .map((e) => DisciplineLog.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Count violations this month for discipline score calculation.
  Future<int> countThisMonth(String accountId) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final logs = await fetchForAccount(accountId, from: from);
    return logs.length;
  }
}
