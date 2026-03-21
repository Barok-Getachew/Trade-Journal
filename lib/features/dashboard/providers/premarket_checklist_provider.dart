import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Pre-Market Checklist State ────────────────────────────────────────────────

const _kChecklistItems = [
  'Slept well (7+ hours)',
  'Checked macro news & economic calendar',
  'Identified key S/R levels for today',
  'Trade plan written & reviewed',
  'Risk per trade confirmed',
  'Mental state is calm & focused',
];

class PremarketChecklistState {
  final Map<String, bool> checks;
  final String dateKey; // 'yyyy-MM-dd' — used to detect day change

  const PremarketChecklistState({
    required this.checks,
    required this.dateKey,
  });

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  factory PremarketChecklistState.fresh() => PremarketChecklistState(
        checks: {for (final item in _kChecklistItems) item: false},
        dateKey: _todayKey(),
      );

  int get completedCount => checks.values.where((v) => v).length;
  int get totalCount => checks.length;
  bool get allDone => completedCount == totalCount;
  List<String> get items => _kChecklistItems;
}

class PremarketChecklistNotifier
    extends StateNotifier<PremarketChecklistState> {
  PremarketChecklistNotifier() : super(PremarketChecklistState.fresh());

  void toggle(String item) {
    _resetIfNewDay();
    final updated = Map<String, bool>.from(state.checks);
    updated[item] = !(updated[item] ?? false);
    state = PremarketChecklistState(
      checks: updated,
      dateKey: state.dateKey,
    );
  }

  void _resetIfNewDay() {
    final today = PremarketChecklistState._todayKey();
    if (state.dateKey != today) {
      state = PremarketChecklistState.fresh();
    }
  }
}

final premarketChecklistProvider =
    StateNotifierProvider<PremarketChecklistNotifier, PremarketChecklistState>(
  (_) => PremarketChecklistNotifier(),
);
