import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/daily_review.dart';
import '../../auth/providers/repository_providers.dart';
import '../../accounts/providers/account_provider.dart';

// ── Daily review for today (per selected account) ─────────────────────────────

final todayReviewProvider =
    FutureProvider.autoDispose<DailyReview?>((ref) async {
  final account = ref.watch(selectedAccountProvider);
  if (account == null) return null;
  return ref
      .read(dailyReviewRepositoryProvider)
      .fetchForDate(account.id, DateTime.now());
});

// ── Whether today's review is pending (traded today but not reviewed) ─────────

final dailyReviewPendingProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final account = ref.watch(selectedAccountProvider);
  if (account == null) return false;
  final review = await ref
      .read(dailyReviewRepositoryProvider)
      .fetchForDate(account.id, DateTime.now());
  // Only pending if review is null — trade existence checked in the gate widget
  return review == null;
});

// ── Recent daily reviews for an account ───────────────────────────────────────

final recentDailyReviewsProvider =
    FutureProvider.family<List<DailyReview>, String>((ref, accountId) async {
  return ref
      .read(dailyReviewRepositoryProvider)
      .fetchRecent(accountId, limit: 30);
});
