import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/narrative_provider.dart';

class NarrativeHistoryScreen extends ConsumerWidget {
  const NarrativeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(recentDailyNarrativesProvider);
    final weeklyAsync = ref.watch(allWeeklyNarrativesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Narrative History', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: AppColors.textSecondary),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Daily'), Tab(text: 'Weekly')],
          ),
        ),
        body: TabBarView(children: [
          // ── Daily list ──
          dailyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.loss))),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No daily narratives yet', style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = list[i];
                      final d = n.narrativeDate;
                      final dateStr = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                      return ListTile(
                        tileColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), side: const BorderSide(color: AppColors.border)),
                        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20)),
                        title: Text(dateStr, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(n.pair?.isNotEmpty == true ? n.pair! : 'No instrument', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (n.preSessionComplete) _badge('Pre ✓', AppColors.profit),
                          if (n.postAttachmentComplete) ...[const SizedBox(width: 4), _badge('Post ✓', AppColors.primary)],
                        ]),
                        onTap: () => context.push('/daily-narrative/history/${n.narrativeDate.toIso8601String().substring(0, 10)}'),
                      );
                    },
                  ),
          ),
          // ── Weekly list ──
          weeklyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.loss))),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No weekly narratives yet', style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = list[i];
                      final w = n.weekOf;
                      final wEnd = w.add(const Duration(days: 6));
                      final str = '${w.day}/${w.month} – ${wEnd.day}/${wEnd.month}/${w.year}';
                      return ListTile(
                        tileColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), side: const BorderSide(color: AppColors.border)),
                        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryDim, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calendar_view_week_rounded, color: AppColors.primary, size: 20)),
                        title: Text('Week of $str', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(n.primaryInstrument?.isNotEmpty == true ? n.primaryInstrument! : 'No instrument', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (n.preWeekComplete) _badge('Plan ✓', AppColors.profit),
                          if (n.reflectionComplete) ...[const SizedBox(width: 4), _badge('Refl ✓', AppColors.primary)],
                        ]),
                        onTap: () => context.push('/weekly-narrative-builder/history/${n.weekOf.toIso8601String().substring(0, 10)}'),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  static Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}
