import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/account.dart';
import '../../auth/providers/repository_providers.dart';

// ── Account list (active accounts for current user) ───────────────────────────

final accountListProvider = FutureProvider<List<Account>>((ref) async {
  return ref.watch(accountRepositoryProvider).fetchAll();
});

// ── Selected account (null = All Accounts) ─────────────────────────────────────

final selectedAccountProvider = StateProvider<Account?>((ref) => null);

// ── Selected account id shortcut ───────────────────────────────────────────────

final selectedAccountIdProvider = Provider<String?>((ref) {
  return ref.watch(selectedAccountProvider)?.id;
});
