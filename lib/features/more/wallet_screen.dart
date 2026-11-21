import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/local/app_database.dart';
import '../../domain/economy/command_result.dart';
import '../common/widgets.dart';
import '../home/home_screen.dart';

final recentLedgerProvider = FutureProvider.autoDispose<List<LedgerRow>>((ref) {
  ref.watch(
    gameControllerProvider.select((a) => (a.value?.state.revision ?? 0) ~/ 5),
  );
  return ref.read(saveRepositoryProvider).recentLedger(limit: 60);
});

String _typeLabel(String type) => switch (LedgerType.values.asNameMap()[type]) {
  LedgerType.sale => 'Bikri',
  LedgerType.work => 'Mazdoori',
  LedgerType.stockPurchase => 'Saman khareeda',
  LedgerType.upgrade => 'Upgrade',
  LedgerType.hire => 'Staff rakha',
  LedgerType.stageUnlock => 'Naya karobar',
  LedgerType.wages => 'Tankhwah',
  LedgerType.rent => 'Kiraya',
  null => type,
};

String _ago(Duration d) {
  if (d.inMinutes < 1) {
    return 'abhi';
  }
  if (d.inHours < 1) {
    return '${d.inMinutes} min pehle';
  }
  return '${d.inHours} ghante pehle';
}

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final profit =
        ref.watch(recentProfitProvider).value ?? const ProfitSummary();
    final ledger = ref.watch(recentLedgerProvider).value ?? const <LedgerRow>[];
    final now = ref.read(clockProvider).nowUtc();

    Widget line(String k, int v, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            formatRs(v),
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: strong
                  ? AppColors.green
                  : (v < 0 ? AppColors.terra : AppColors.text),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Hisaab kitaab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Maujooda raqam'),
                  const SizedBox(height: 6),
                  Text(
                    formatRs(session.state.cashPaisa),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ye sirf game ka paisa hai. Asli paisa nahi, nikala ya becha nahi ja sakta.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Pichle 60 minute'),
                  const SizedBox(height: 6),
                  line('Bikri aur mazdoori', profit.revenue),
                  line('Saman khareeda', -profit.stock),
                  line('Tankhwah', -profit.wages),
                  line('Kiraya', -profit.rent),
                  const Divider(),
                  line('Khalis munafa', profit.net, strong: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Aakhri len den'),
          const SizedBox(height: 6),
          if (ledger.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Abhi koi len den nahi. Pehle saman lein aur samosay bechein.',
              ),
            ),
          for (final r in ledger)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(_typeLabel(r.type)),
              subtitle: Text(
                '${r.reason} · ${_ago(now.difference(r.at.toUtc()))}',
              ),
              trailing: Text(
                '${r.deltaPaisa > 0 ? '+ ' : ''}${formatRs(r.deltaPaisa)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: r.deltaPaisa >= 0 ? AppColors.green : AppColors.terra,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
