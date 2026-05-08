import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/daily_review.dart';

class DailyReviewRepository {
  final SupabaseClient _client;
  DailyReviewRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// Fetch the review for a specific date and account, or null if not completed.
  Future<DailyReview?> fetchForDate(String accountId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final response = await _client
        .from('daily_reviews')
        .select()
        .eq('user_id', _userId)
        .eq('account_id', accountId)
        .eq('review_date', dateStr)
        .maybeSingle();
    if (response == null) return null;
    return DailyReview.fromMap(response as Map<String, dynamic>);
  }

  /// Fetch the N most recent daily reviews for an account.
  Future<List<DailyReview>> fetchRecent(String accountId,
      {int limit = 30}) async {
    final response = await _client
        .from('daily_reviews')
        .select()
        .eq('user_id', _userId)
        .eq('account_id', accountId)
        .order('review_date', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => DailyReview.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch ALL daily reviews for the user across all accounts (global view).
  Future<List<DailyReview>> fetchAllForUser({int limit = 90}) async {
    final response = await _client
        .from('daily_reviews')
        .select()
        .eq('user_id', _userId)
        .order('review_date', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => DailyReview.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch today's review for the user regardless of which account it was saved under.
  Future<DailyReview?> fetchTodayForUser() async {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _client
        .from('daily_reviews')
        .select()
        .eq('user_id', _userId)
        .eq('review_date', dateStr)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return DailyReview.fromMap(response as Map<String, dynamic>);
  }

  /// Upsert a daily review (insert or update by unique (user_id, account_id, review_date)).
  Future<DailyReview> upsert(DailyReview review) async {
    final data = {
      ...review.toMap(),
      'user_id': _userId, // always stamp the real authenticated user
      'updated_at': DateTime.now().toIso8601String(),
    };
    final response = await _client
        .from('daily_reviews')
        .upsert(data, onConflict: 'user_id,account_id,review_date')
        .select()
        .single();
    return DailyReview.fromMap(response as Map<String, dynamic>);
  }

  /// Check if today's review is complete for a given account.
  Future<bool> isTodayReviewed(String accountId) async {
    final today = DateTime.now();
    final review = await fetchForDate(accountId, today);
    return review != null;
  }

  Future<void> delete(String id) async {
    await _client
        .from('daily_reviews')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
