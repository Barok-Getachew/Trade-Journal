import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/weekly_review.dart';
import '../../domain/models/monthly_review.dart';

class ReviewRepository {
  final SupabaseClient _client;
  ReviewRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ── Weekly ────────────────────────────────────────────────────────────────

  Future<List<WeeklyReview>> fetchWeeklyAll() async {
    final response = await _client
        .from('weekly_reviews')
        .select()
        .eq('user_id', _userId)
        .order('week_start', ascending: false);
    return (response as List)
        .map((e) => WeeklyReview.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<WeeklyReview?> fetchWeeklyByDate(DateTime weekStart) async {
    final response = await _client
        .from('weekly_reviews')
        .select()
        .eq('user_id', _userId)
        .eq('week_start', weekStart.toIso8601String().split('T').first)
        .maybeSingle();
    if (response == null) return null;
    return WeeklyReview.fromMap(response as Map<String, dynamic>);
  }

  Future<WeeklyReview> upsertWeekly(Map<String, dynamic> data) async {
    final response = await _client
        .from('weekly_reviews')
        .upsert({...data, 'user_id': _userId})
        .select()
        .single();
    return WeeklyReview.fromMap(response as Map<String, dynamic>);
  }

  // ── Monthly ───────────────────────────────────────────────────────────────

  Future<List<MonthlyReview>> fetchMonthlyAll() async {
    final response = await _client
        .from('monthly_reviews')
        .select()
        .eq('user_id', _userId)
        .order('year', ascending: false)
        .order('month', ascending: false);
    return (response as List)
        .map((e) => MonthlyReview.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<MonthlyReview?> fetchMonthlyByDate(int month, int year) async {
    final response = await _client
        .from('monthly_reviews')
        .select()
        .eq('user_id', _userId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();
    if (response == null) return null;
    return MonthlyReview.fromMap(response as Map<String, dynamic>);
  }

  Future<MonthlyReview> upsertMonthly(Map<String, dynamic> data) async {
    final response = await _client
        .from('monthly_reviews')
        .upsert({...data, 'user_id': _userId})
        .select()
        .single();
    return MonthlyReview.fromMap(response as Map<String, dynamic>);
  }
}
