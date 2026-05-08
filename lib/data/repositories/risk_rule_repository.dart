import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/risk_rule.dart';

class RiskRuleRepository {
  final SupabaseClient _client;
  RiskRuleRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Fetch risk rules for an account. Returns null if not yet configured.
  Future<RiskRule?> fetchForAccount(String accountId) async {
    if (accountId.isEmpty) return null; // guard: never send '' as a UUID
    final response = await _client
        .from('risk_rules')
        .select()
        .eq('user_id', _userId)
        .eq('account_id', accountId)
        .maybeSingle();
    if (response == null) return null;
    return RiskRule.fromMap(response as Map<String, dynamic>);
  }

  /// Upsert risk rules for an account.
  Future<RiskRule> upsert(RiskRule rule) async {
    final data = {
      ...rule.toMap(),
      'user_id': _userId, // always stamp the real authenticated user
      'updated_at': DateTime.now().toIso8601String(),
    };
    final response = await _client
        .from('risk_rules')
        .upsert(data, onConflict: 'user_id,account_id')
        .select()
        .single();
    return RiskRule.fromMap(response as Map<String, dynamic>);
  }
}
