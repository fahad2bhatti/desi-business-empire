import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../data/local/app_database.dart';
import '../../domain/economy/command_result.dart';
import '../common/widgets.dart';

final recentLedgerProvider = FutureProvider.autoDispose<List<LedgerRow>>((ref) {
  ref.watch(
    gameControllerProvider.select((a) => (a.value?.state.revision ?? 0) ~/ 5),
  );
  return ref.read(saveRepositoryProvider).recentLedger(limit: 60);
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
  null => type,
};

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final ledger = ref.watch(recentLedgerProvider).value ?? const <LedgerRow>[];
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
          const SectionTitle(S.recentEntries),
          if (ledger.isEmpty)
            Text(S.noEntries, style: context.text.bodyMedium)
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
                        '${r.reason} · ${S.ago(now.difference(r.at.toUtc()))}',
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
