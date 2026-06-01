import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/daily_narrative.dart';
import '../../../domain/models/weekly_narrative.dart';
import '../../auth/providers/repository_providers.dart';

// ── Today's daily narrative ───────────────────────────────────────────────────

final todayDailyNarrativeProvider =
    FutureProvider.autoDispose<DailyNarrative?>((ref) async {
  return ref
      .read(narrativeRepositoryProvider)
      .fetchDailyByDate(DateTime.now());
});

// ── Recent daily narratives (history list) ────────────────────────────────────

final recentDailyNarrativesProvider =
    FutureProvider.autoDispose<List<DailyNarrative>>((ref) async {
  return ref
      .read(narrativeRepositoryProvider)
      .fetchDailyRecent(limit: 30);
});

// ── This week's narrative ─────────────────────────────────────────────────────

final thisWeekNarrativeProvider =
    FutureProvider.autoDispose<WeeklyNarrative?>((ref) async {
  final now = DateTime.now();
  // Week starts on Monday
  final monday =
      DateTime(now.year, now.month, now.day - (now.weekday - 1));
  return ref
      .read(narrativeRepositoryProvider)
      .fetchWeeklyByDate(monday);
});

// ── All weekly narratives (history) ──────────────────────────────────────────

final allWeeklyNarrativesProvider =
    FutureProvider.autoDispose<List<WeeklyNarrative>>((ref) async {
  return ref.read(narrativeRepositoryProvider).fetchWeeklyAll();
});
