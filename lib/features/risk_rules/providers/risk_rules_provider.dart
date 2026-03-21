import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/risk_rule.dart';
import '../../auth/providers/repository_providers.dart';

// ── Risk rules for a specific account ────────────────────────────────────────

final riskRulesProvider =
    FutureProvider.family<RiskRule?, String>((ref, accountId) async {
  return ref.read(riskRuleRepositoryProvider).fetchForAccount(accountId);
});
