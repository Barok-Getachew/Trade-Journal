import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/daily_narrative.dart';
import '../../domain/models/weekly_narrative.dart';

class NarrativeRepository {
  final SupabaseClient _client;
  NarrativeRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ── Daily ─────────────────────────────────────────────────────────────────

  Future<DailyNarrative?> fetchDailyByDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final response = await _client
        .from('daily_narratives')
        .select()
        .eq('user_id', _userId)
        .eq('narrative_date', dateStr)
        .maybeSingle();
    if (response == null) return null;
    return DailyNarrative.fromMap(response as Map<String, dynamic>);
  }

  Future<DailyNarrative> upsertDaily(Map<String, dynamic> data) async {
    final response = await _client
        .from('daily_narratives')
        .upsert({...data, 'user_id': _userId},
            onConflict: 'user_id,narrative_date')
        .select()
        .single();
    return DailyNarrative.fromMap(response as Map<String, dynamic>);
  }

  Future<List<DailyNarrative>> fetchDailyRecent({int limit = 30}) async {
    final response = await _client
        .from('daily_narratives')
        .select()
        .eq('user_id', _userId)
        .order('narrative_date', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => DailyNarrative.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ── Weekly ────────────────────────────────────────────────────────────────

  Future<WeeklyNarrative?> fetchWeeklyByDate(DateTime weekOf) async {
    final dateStr = weekOf.toIso8601String().substring(0, 10);
    final response = await _client
        .from('weekly_narratives')
        .select()
        .eq('user_id', _userId)
        .eq('week_of', dateStr)
        .maybeSingle();
    if (response == null) return null;
    return WeeklyNarrative.fromMap(response as Map<String, dynamic>);
  }

  Future<WeeklyNarrative> upsertWeekly(Map<String, dynamic> data) async {
    final response = await _client
        .from('weekly_narratives')
        .upsert({...data, 'user_id': _userId},
            onConflict: 'user_id,week_of')
        .select()
        .single();
    return WeeklyNarrative.fromMap(response as Map<String, dynamic>);
  }

  Future<List<WeeklyNarrative>> fetchWeeklyAll() async {
    final response = await _client
        .from('weekly_narratives')
        .select()
        .eq('user_id', _userId)
        .order('week_of', ascending: false);
    return (response as List)
        .map((e) => WeeklyNarrative.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
