import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/trade_repository.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/repositories/daily_review_repository.dart';
import '../../../data/repositories/risk_rule_repository.dart';
import '../../../data/repositories/discipline_log_repository.dart';
import '../../auth/providers/auth_provider.dart';

// ── Repository providers ──────────────────────────────────────────────────────

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return TradeRepository(ref.watch(supabaseClientProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(supabaseClientProvider));
});

final strategyRepositoryProvider = Provider<StrategyRepository>((ref) {
  return StrategyRepository(ref.watch(supabaseClientProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(supabaseClientProvider));
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref.watch(supabaseClientProvider));
});

final dailyReviewRepositoryProvider = Provider<DailyReviewRepository>((ref) {
  return DailyReviewRepository(ref.watch(supabaseClientProvider));
});

final riskRuleRepositoryProvider = Provider<RiskRuleRepository>((ref) {
  return RiskRuleRepository(ref.watch(supabaseClientProvider));
});

final disciplineLogRepositoryProvider =
    Provider<DisciplineLogRepository>((ref) {
  return DisciplineLogRepository(ref.watch(supabaseClientProvider));
});
