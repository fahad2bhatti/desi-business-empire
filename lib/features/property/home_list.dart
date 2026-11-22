import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/advisor.dart';
import '../common/photos.dart';
import '../common/run_command.dart';
import '../common/visuals.dart';
import '../common/widgets.dart';

/// Where the player lives. Focus: moving to the next home.
class HomeList extends ConsumerWidget {
  const HomeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final p = context.palette;
    final homes = engine.config.homes;
    final current = engine.currentHome(s);
    final next = engine.nextHome(s);
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);

    Widget focus;
    if (next == null) {
      focus = FocusCard(icon: iconFor(current?.id ?? ''), title: S.topHome);
    } else {
      final cost = formatShort(next.pricePaisa);
      final detail = S.bonusBecomes(next.incomeBonusPercent);
      if (next.pricePaisa <= s.cashPaisa &&
          !engine.cardAllows(s, next.pricePaisa)) {
        focus = FocusCard(
          icon: iconFor(next.id),
          photoId: next.id,
          title: S.focusMove(next.name),
          detail: '$cost · ${S.needsCard(engine.cardFor(next.pricePaisa).name)}',
        );
      } else if (next.pricePaisa <= s.cashPaisa) {
        focus = FocusCard(
          icon: iconFor(next.id),
          title: S.focusMove(next.name),
          detail: detail,
          actionLabel: S.moveFor(cost),
          onAction: session.saveFailed
              ? null
              : () => runCommand(
                  context,
                  ref,
                  (st, now) => engine.moveHome(st, now),
                  successText: S.movedTo(next.name),
                ),
        );
      } else {
        final wait = engine.secondsUntil(s, next.pricePaisa);
        focus = FocusCard(
          icon: iconFor(next.id),
          title: S.focusMove(next.name),
          detail: '$cost · $detail',
          progress: s.cashPaisa / next.pricePaisa,
          progressText: wait == null ? S.workToSave : S.readyIn(S.eta(wait)),
        );
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
        Text(S.homeIntro, style: muted),
        const SizedBox(height: AppSpacing.s12),
        if (current != null)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasPhoto(current.id)) PhotoBanner(id: current.id),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Row(
                    children: [
                      if (!hasPhoto(current.id)) ...[
                        SignTile(
                          icon: iconFor(current.id),
                          artId: current.id,
                          size: 52,
                        ),
                        const SizedBox(width: AppSpacing.s12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.yourHome, style: muted),
                            Text(current.name, style: context.text.titleLarge),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${current.incomeBonusPercent}%',
                            style: context.text.titleLarge
                                ?.copyWith(color: p.income)
                                .numbers,
                          ),
                          Text(S.allIncome, style: muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s12),
        focus,
        const SizedBox(height: AppSpacing.s24),
        const SectionTitle(S.homes),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, h) in homes.indexed) ...[
                if (i > 0) const Divider(indent: AppSpacing.s16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s4,
                  ),
                  leading: SignTile(
                    icon: iconFor(h.id),
                    artId: h.id,
                    size: 40,
                    dimmed: i > s.homeLevel,
                  ),
                  title: Text(
                    h.name,
                    style: context.text.titleSmall?.copyWith(
                      color: i > s.homeLevel ? p.inkMuted : p.ink,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (h.incomeBonusPercent > 0)
                        S.lifestyleBonus(h.incomeBonusPercent),
                      if (i > s.homeLevel) formatShort(h.pricePaisa),
                    ].join(' · '),
                    style: muted.numbers,
                  ),
                  trailing: i < s.homeLevel
                      ? Icon(Icons.check, color: p.income)
                      : i == s.homeLevel
                      ? Text(
                          S.youLiveHere,
                          style: context.text.labelLarge?.copyWith(
                            color: p.accentInk,
                          ),
                        )
                      : i > s.homeLevel + 1
                      ? Icon(Icons.lock_outline, color: p.inkMuted, size: 18)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
