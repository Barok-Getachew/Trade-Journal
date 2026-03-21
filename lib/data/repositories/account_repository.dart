import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/account.dart';
import '../../domain/models/strategy.dart';

class AccountRepository {
  final SupabaseClient _client;
  AccountRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Fetch all accounts. Archived ones excluded by default.
  Future<List<Account>> fetchAll({bool includeArchived = false}) async {
    var q = _client.from('accounts').select().eq('user_id', _userId);
    if (!includeArchived) q = q.eq('is_archived', false);
    final response = await q.order('created_at');
    return (response as List)
        .map((e) => Account.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Account> insert(Map<String, dynamic> data) async {
    final response = await _client
        .from('accounts')
        .insert({...data, 'user_id': _userId})
        .select()
        .single();
    return Account.fromMap(response as Map<String, dynamic>);
  }

  Future<Account> update(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('accounts')
        .update(data)
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return Account.fromMap(response as Map<String, dynamic>);
  }

  Future<void> archive(String id) async {
    await _client
        .from('accounts')
        .update({'is_archived': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> unarchive(String id) async {
    await _client
        .from('accounts')
        .update({'is_archived': false})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) async {
    await _client.from('accounts').delete().eq('id', id).eq('user_id', _userId);
  }
}

class StrategyRepository {
  final SupabaseClient _client;
  StrategyRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Strategy>> fetchAll() async {
    final response = await _client
        .from('strategies')
        .select()
        .eq('user_id', _userId)
        .order('name');
    return (response as List)
        .map((e) => Strategy.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Strategy> insert(String name, {String? description}) async {
    final response = await _client
        .from('strategies')
        .insert({'user_id': _userId, 'name': name, 'description': description})
        .select()
        .single();
    return Strategy.fromMap(response as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client
        .from('strategies')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
