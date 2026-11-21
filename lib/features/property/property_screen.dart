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
import '../common/widgets.dart';
import 'home_list.dart';
import 'lifestyle_list.dart';

/// Assets tab: Home, Property, Vehicles, Luxury. [initialTab] is one of
/// `home`, `property`, `vehicles`, `luxury`.
class PropertyScreen extends StatelessWidget {
  const PropertyScreen({super.key, this.initialTab});

  final String? initialTab;

  static const _tabs = ['home', 'property', 'vehicles', 'luxury'];

  @override
  Widget build(BuildContext context) {
    final start = _tabs.indexOf(initialTab ?? '');
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: start < 0 ? 0 : start,
      child: const Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: S.tabHome),
              Tab(text: S.property),
              Tab(text: S.tabVehicles),
              Tab(text: S.tabLuxury),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                HomeList(),
                _PropertyList(),
                LifestyleList(kind: 'vehicle'),
                LifestyleList(kind: 'luxury'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyList extends ConsumerWidget {
  const _PropertyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;

    // Focus: the affordable unit with the best rent for its price.
    String? focus;
    var best = 0.0;
    for (final prop in engine.config.properties) {
      final n = s.owned(prop.id);
      if (n >= prop.maxOwned) {
        continue;
      }
      final price = engine.propertyPrice(prop, n);
      final ratio = prop.rentPaisaPerSec / price;
      if (price <= s.cashPaisa && ratio > best) {
        best = ratio;
        focus = prop.id;
      }
    }

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
          style: context.text.bodySmall?.copyWith(
            color: context.palette.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final prop in engine.config.properties) ...[
          _PropertyCard(
            property: prop,
            state: s,
            engine: engine,
            blocked: session.saveFailed,
            focus: prop.id == focus,
          ),
          const SizedBox(height: AppSpacing.s8),
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
    required this.focus,
  });

  final PropertyDef property;
  final GameState state;
  final GameEngine engine;
  final bool blocked;
  final bool focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final prop = property;
    final n = state.owned(prop.id);
    final full = n >= prop.maxOwned;
    final price = engine.propertyPrice(prop, n);
    final canBuy = !full && state.cashPaisa >= price;
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);
    final onBuy = blocked || !canBuy
        ? null
        : () => runCommand(
            context,
            ref,
            (s, now) => engine.buyProperty(s, prop.id, now),
          );
    final buyChild = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(S.buyShort),
        Text(
          formatShort(price),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ).numbers,
        ),
      ],
    );
    final buyStyle = FilledButton.styleFrom(
      minimumSize: const Size(96, 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
    );

    return Card(
      shape: focus
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: p.accent, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s12,
        ),
        child: Row(
          children: [
            SignTile(icon: iconFor(prop.id), dimmed: n == 0),
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
                  Text(
                    n > 0
                        ? S.rentTotal(formatShort(prop.rentPaisaPerSec * n))
                        : S.rentEach(formatShort(prop.rentPaisaPerSec)),
                    style: context.text.bodySmall
                        ?.copyWith(color: p.income)
                        .numbers,
                  ),
                ],
              ),
            ),
            if (full)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: Text(S.allUnitsOwned, style: muted),
              )
            else if (focus)
              FilledButton(style: buyStyle, onPressed: onBuy, child: buyChild)
            else
              FilledButton.tonal(
                style: buyStyle,
                onPressed: onBuy,
                child: buyChild,
              ),
            if (n > 0)
              PopupMenuButton<void>(
                icon: Icon(Icons.more_vert, color: p.inkMuted),
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    enabled: !blocked,
                    onTap: () => _confirmSell(context, ref, n),
                    child: Text(S.sell, style: TextStyle(color: p.danger)),
                  ),
                ],
              )
            else
              const SizedBox(width: AppSpacing.s8),
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
    final ok = await confirmSell(
      context,
      S.sellUnitTitle(property.name),
      S.sellUnitBody(value),
    );
    if (ok && context.mounted) {
      await runCommand(
        context,
        ref,
        (s, now) => engine.sellProperty(s, property.id, now),
        successText: S.sold(property.name, value),
      );
    }
  }
}
