import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/prefs.dart';
import '../../app/theme.dart';
import '../../core/labels.dart';
import '../../core/money.dart';
import '../../domain/economy/command_result.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../../widgets/wallet_chip.dart';
import '../common/widgets.dart';
import '../onboarding/tutorial.dart';
import 'next_goal.dart';

/// Money in and out over the last hour, from the ledger.
class ProfitSummary {
  const ProfitSummary({
    this.revenue = 0,
    this.stock = 0,
    this.wages = 0,
    this.rent = 0,
  });

  final int revenue;
  final int stock;
  final int wages;
  final int rent;

  /// Running profit: investments (upgrades, staff, new shops) not counted.
  int get net => revenue - stock - wages - rent;
}

final recentProfitProvider = FutureProvider.autoDispose<ProfitSummary>((
  ref,
) async {
  // Refresh roughly every 15 saves instead of every second.
  ref.watch(
    gameControllerProvider.select((a) => (a.value?.state.revision ?? 0) ~/ 15),
  );
  final since = ref
      .read(clockProvider)
      .nowUtc()
      .subtract(const Duration(hours: 1));
  final rows = await ref.read(saveRepositoryProvider).ledgerSince(since);
  var revenue = 0, stock = 0, wages = 0, rent = 0;
  for (final r in rows) {
    final type = LedgerType.values.asNameMap()[r.type];
    switch (type) {
      case LedgerType.sale || LedgerType.work:
        revenue += r.deltaPaisa;
      case LedgerType.stockPurchase:
        stock -= r.deltaPaisa;
      case LedgerType.wages:
        wages -= r.deltaPaisa;
      case LedgerType.rent:
        rent -= r.deltaPaisa;
      default:
        break;
    }
  }
  return ProfitSummary(
    revenue: revenue,
    stock: stock,
    wages: wages,
    rent: rent,
  );
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final view = engine.observe(
      session.state,
      ref.read(clockProvider).nowUtc(),
    );
    final goal = nextGoal(engine, view);
    final profit =
        ref.watch(recentProfitProvider).value ?? const ProfitSummary();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Salam, Seth sahab',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    Text(
                      ref.watch(prefsProvider).value?.businessName ??
                          'Mera Karobar',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              WalletChip(paisa: view.cashPaisa),
            ],
          ),
          const SizedBox(height: 16),
          TutorialCoach(starterId: engine.config.stages.first.id),
          _ProfitCard(profit: profit),
          const SizedBox(height: 14),
          _GoalCard(goal: goal),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Aap ke karobar',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Game ka paisa, asli nahi',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final def in engine.config.stages) ...[
            _BusinessCard(def: def, state: view, engine: engine),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ProfitCard extends StatelessWidget {
  const _ProfitCard({required this.profit});

  final ProfitSummary profit;

  @override
  Widget build(BuildContext context) {
    Widget line(String label, int paisa) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Text(formatRs(paisa), style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: SectionLabel('Pichle 60 minute ka hisaab'),
                ),
                TextButton(
                  onPressed: () => context.go('/more/wallet'),
                  child: const Text('Tafseel'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${profit.net >= 0 ? '+ ' : ''}${formatRs(profit.net)}',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: profit.net >= 0 ? AppColors.green : AppColors.terra,
              ),
            ),
            const Text(
              'khalis munafa (investment ke ilawa)',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            line('Bikri aur mazdoori', profit.revenue),
            line('Saman khareeda', -profit.stock),
            line('Tankhwah', -profit.wages),
            line('Kiraya', -profit.rent),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final NextGoal goal;

  @override
  Widget build(BuildContext context) {
    final route = goal.route;
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: route == null ? null : () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AGLA GOAL',
                style: TextStyle(
                  color: AppColors.onTealMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                goal.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (goal.have != null && goal.need != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.need == 0
                        ? 1.0
                        : (goal.have! / goal.need!).clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    color: AppColors.amber,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${goal.have! > goal.need! ? goal.need : goal.have} / ${goal.need}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (goal.detail != null) ...[
                const SizedBox(height: 6),
                Text(
                  goal.detail!,
                  style: const TextStyle(
                    color: AppColors.onTealMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.def,
    required this.state,
    required this.engine,
  });

  final StageDef def;
  final GameState state;
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final st = state.stages[def.id];
    if (st == null) return _locked(context);
    final staff = def.staff.keys
        .where((r) => st.staffCount(r) > 0)
        .map((r) => '${roleName(r)} ${st.staffCount(r)}');
    final ready = st.lines.values.fold(0, (sum, l) => sum + l.ready);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/business/${def.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: AppColors.amberInk,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saman ${st.totalStock} · Tayyar $ready · Bika ${st.sold}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      staff.isEmpty ? 'Koi staff nahi' : staff.join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    final unmet = engine.missingRequirements(state, def.id);
    final isNext =
        engine.config.stages
            .where((s) => !state.stages.containsKey(s.id))
            .first
            .id ==
        def.id;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isNext ? () => context.go('/expand/${def.id}') : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.lock_outline, color: AppColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Kholne ki qeemat: ${formatRs(def.unlockCostPaisa)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  if (isNext)
                    for (final u in unmet)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${describeRequirement(u, engine.config)} (${u.have}/${u.need})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  if (isNext && unmet.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Saari shartein poori! Tap kar ke kholein.',
                        style: TextStyle(fontSize: 13, color: AppColors.green),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
