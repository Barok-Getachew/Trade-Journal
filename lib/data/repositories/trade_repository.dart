import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/trade.dart';

class TradeRepository {
  final SupabaseClient _client;

  TradeRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<List<Trade>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? strategyId,
    String? symbol,
    bool? rulesFollowed,
    String? accountId,
  }) async {
    // Build filter step-by-step using PostgrestFilterBuilder
    var q = _client.from('trades').select().eq('user_id', _userId);
    if (accountId != null) q = q.eq('account_id', accountId);
    if (from != null) q = q.gte('entry_at', from.toIso8601String());
    if (to != null) q = q.lte('entry_at', to.toIso8601String());
    if (strategyId != null) q = q.eq('strategy_id', strategyId);
    if (symbol != null) q = q.eq('symbol', symbol.toUpperCase());
    if (rulesFollowed != null) q = q.eq('rules_followed', rulesFollowed);

    final response = await q.order('entry_at', ascending: false);
    return (response as List)
        .map((e) => Trade.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Trade?> fetchById(String id) async {
    final response = await _client
        .from('trades')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return Trade.fromMap(response as Map<String, dynamic>);
  }

  Future<Trade> insert(Map<String, dynamic> data) async {
    final response = await _client
        .from('trades')
        .insert({...data, 'user_id': _userId})
        .select()
        .single();
    return Trade.fromMap(response as Map<String, dynamic>);
  }

  Future<Trade> update(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('trades')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return Trade.fromMap(response as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.from('trades').delete().eq('id', id).eq('user_id', _userId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<Trade>> fetchForWeek(DateTime weekStart, DateTime weekEnd,
      {String? accountId}) {
    return fetchAll(from: weekStart, to: weekEnd, accountId: accountId);
  }

  Future<List<Trade>> fetchForMonth(int month, int year, {String? accountId}) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    return fetchAll(from: from, to: to, accountId: accountId);
  }

  Future<List<String>> fetchDistinctSymbols({String? accountId}) async {
    var q = _client.from('trades').select('symbol').eq('user_id', _userId);
    if (accountId != null) q = q.eq('account_id', accountId);
    final response = await q;
    final symbols =
        (response as List).map((e) => e['symbol'] as String).toSet().toList();
    symbols.sort();
    return symbols;
  }

  Future<void> updateScreenshotUrl(String tradeId, String url) async {
    await _client
        .from('trades')
        .update({'screenshot_url': url})
        .eq('id', tradeId)
        .eq('user_id', _userId);
  }
}
