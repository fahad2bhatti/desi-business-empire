import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../data/local/app_database.dart';
import '../../domain/economy/command_result.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../common/run_command.dart';
import '../common/widgets.dart';

/// Buys, sells, rewards and tax. Refreshes when something is bought or sold
/// (cash moves by a command), not on every income tick.
final transactionsProvider = FutureProvider.autoDispose<List<LedgerRow>>((ref) {
  ref.watch(
    gameControllerProvider.select((a) => (a.value?.state.revision ?? 0) ~/ 5),
  );
  return ref.read(saveRepositoryProvider).transactions();
});

String _typeLabel(String type) => switch (LedgerType.values.asNameMap()[type]) {
  LedgerType.work => S.entryWork,
  LedgerType.buyBusiness => S.entryBuyBusiness,
  LedgerType.upgrade => S.entryUpgrade,
  LedgerType.sellBusiness => S.entrySellBusiness,
  LedgerType.buyProperty => S.entryBuyProperty,
  LedgerType.sellProperty => S.entrySellProperty,
  LedgerType.income => S.entryIncome,
  LedgerType.goalReward => S.entryGoal,
  LedgerType.buyItem => S.entryBuyItem,
  LedgerType.sellItem => S.entrySellItem,
  LedgerType.moveHome => S.entryMoveHome,
  LedgerType.tax => S.entryTax,
  null => type,
};

/// `samosa L3` -> `Samosa Thela L3`, `plot #2` -> `Small Plot #2`.
String _reasonLabel(EconomyConfig c, String reason) {
  final space = reason.indexOf(' ');
  final id = space < 0 ? reason : reason.substring(0, space);
  final rest = space < 0 ? '' : reason.substring(space);
  final name =
      c.business(id)?.name ??
      c.property(id)?.name ??
      c.item(id)?.name ??
      _homeName(c, id);
  return name == null ? reason : '$name$rest';
}

String? _homeName(EconomyConfig c, String id) {
  for (final h in c.homes) {
    if (h.id == id) {
      return h.name;
    }
  }
  return null;
}

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final ledger = ref.watch(transactionsProvider).value ?? const <LedgerRow>[];
    final now = ref.read(clockProvider).nowUtc();
    final s = session.state;
    final p = context.palette;
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);

    return Scaffold(
      appBar: AppBar(title: const Text(S.accounts)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s32,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: S.cash,
                  value: formatShort(s.cashPaisa),
                  icon: Icons.payments,
                  color: p.inkMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: StatTile(
                  label: S.incomeNow,
                  value: S.perSecond(formatShort(engine.incomePerSec(s))),
                  icon: Icons.bolt,
                  color: p.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: S.netWorth,
                  value: formatShort(engine.netWorth(s)),
                  icon: Icons.account_balance,
                  color: p.inkMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: StatTile(
                  label: S.lifetimeEarned,
                  value: formatShort(s.totalEarnedPaisa),
                  icon: Icons.trending_up,
                  color: p.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(S.notRealMoney, style: muted),
          const SizedBox(height: AppSpacing.s24),
          const SectionTitle(S.tax),
          _TaxCard(engine: engine, state: s, now: now, blocked: session.saveFailed),
          const SizedBox(height: AppSpacing.s24),
          const SectionTitle(S.transactions),
          if (ledger.isEmpty)
            Text(S.noTransactions, style: context.text.bodyMedium)
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, r) in ledger.indexed) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      dense: true,
                      title: Text(_typeLabel(r.type)),
                      subtitle: Text(
                        '${_reasonLabel(engine.config, r.reason)} · ${S.ago(now.difference(r.at.toUtc()))}',
                        style: muted,
                      ),
                      trailing: Text(
                        '${r.deltaPaisa > 0 ? '+' : ''}${formatShort(r.deltaPaisa)}',
                        style: context.text.bodyMedium
                            ?.copyWith(
                              color: r.deltaPaisa < 0 ? p.danger : p.income,
                            )
                            .numbers,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What is due, when the next return is due, and the button to file it.
class _TaxCard extends ConsumerWidget {
  const _TaxCard({
    required this.engine,
    required this.state,
    required this.now,
    required this.blocked,
  });

  final GameEngine engine;
  final GameState state;
  final DateTime now;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tax = engine.config.tax;
    final s = state;
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);
    final left = engine.taxDeadline(s).difference(now).inSeconds;
    final overdue = s.taxMissed > 0;
    final canPay = !blocked && s.taxDuePaisa <= s.cashPaisa;
    final due = formatShort(s.taxDuePaisa);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.taxDue, style: muted),
                      Text(
                        due,
                        style: context.text.headlineSmall?.copyWith(
                          color: overdue ? p.danger : p.ink,
                        ).numbers,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: canPay
                      ? () => runCommand(
                          context,
                          ref,
                          (st, t) => engine.fileTaxReturn(st, t),
                          successText: S.taxFiled(due),
                        )
                      : null,
                  child: const Text(S.fileReturn),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              overdue
                  ? S.taxOverdue(s.taxMissed, tax.latePenaltyPercent)
                  : S.taxDueIn(S.eta(left < 0 ? 0 : left)),
              style: context.text.bodyMedium?.copyWith(
                color: overdue ? p.danger : p.ink,
              ),
            ),
            Text(S.taxIncomeRate(engine.incomeTaxPercent(s)), style: muted),
            Text(
              '${S.taxPaid}: ${formatShort(s.taxPaidPaisa)}',
              style: muted?.numbers,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(S.taxExplain(tax.periodHours), style: muted),
          ],
        ),
      ),
    );
  }
}
