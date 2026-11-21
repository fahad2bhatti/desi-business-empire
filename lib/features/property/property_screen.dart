import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../common/run_command.dart';
import '../common/visuals.dart';

class PropertyScreen extends ConsumerWidget {
  const PropertyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s32,
      ),
      children: [
        Text(
          S.propertyIntro,
          style: context.text.bodyMedium?.copyWith(
            color: context.palette.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        for (final prop in engine.config.properties) ...[
          _PropertyCard(
            property: prop,
            state: session.state,
            engine: engine,
            blocked: session.saveFailed,
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  const _PropertyCard({
    required this.property,
    required this.state,
    required this.engine,
    required this.blocked,
  });

  final PropertyDef property;
  final GameState state;
  final GameEngine engine;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final prop = property;
    final n = state.owned(prop.id);
    final full = n >= prop.maxOwned;
    final price = engine.propertyPrice(prop, n);
    final canBuy = !full && state.cashPaisa >= price;
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SignTile(
                  icon: iconFor(prop.id),
                  color: p.property,
                  dimmed: n == 0,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prop.name, style: context.text.titleMedium),
                      Text(
                        '${prop.area} · ${S.ownedUnits(n, prop.maxOwned)}',
                        style: muted.numbers,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      S.rentEach(formatShort(prop.rentPaisaPerSec)),
                      style: context.text.bodySmall
                          ?.copyWith(color: p.income)
                          .numbers,
                    ),
                    if (n > 0)
                      Text(
                        S.rentTotal(formatShort(prop.rentPaisaPerSec * n)),
                        style: context.text.titleSmall
                            ?.copyWith(color: p.income)
                            .numbers,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.income,
                      foregroundColor: p.onIncome,
                    ),
                    onPressed: blocked || !canBuy
                        ? null
                        : () => runCommand(
                            context,
                            ref,
                            (s, now) => engine.buyProperty(s, prop.id, now),
                          ),
                    child: Text(
                      full ? S.allUnitsOwned : S.buyFor(formatShort(price)),
                    ),
                  ),
                ),
                if (n > 0) ...[
                  const SizedBox(width: AppSpacing.s8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: p.danger),
                    onPressed: blocked
                        ? null
                        : () => _confirmSell(context, ref, n),
                    child: const Text(S.sell),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSell(
    BuildContext context,
    WidgetRef ref,
    int owned,
  ) async {
    final value = formatShort(engine.propertySellValue(property, owned));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.sellUnitTitle(property.name)),
        content: Text(S.sellUnitBody(value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.keep),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.background,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.sell),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
      await runCommand(
        context,
        ref,
        (s, now) => engine.sellProperty(s, property.id, now),
        successText: S.sold(property.name, value),
      );
    }
  }
}
