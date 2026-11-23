import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/advisor.dart';
import '../../domain/economy/economy_config.dart';
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
          detail:
              '$cost · ${S.needsCard(engine.cardFor(next.pricePaisa).name)}',
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
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
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
        for (final (i, h) in homes.indexed) ...[
          _HomeRow(
            home: h,
            thumb: SignTile(
              icon: iconFor(h.id),
              artId: h.id,
              size: 64,
              dimmed: i > s.homeLevel,
            ),
            owned: i < s.homeLevel,
            current: i == s.homeLevel,
            locked: i > s.homeLevel + 1,
            future: i > s.homeLevel,
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

/// One home as its own soft card: big picture, name, bonus and a bold price.
class _HomeRow extends StatelessWidget {
  const _HomeRow({
    required this.home,
    required this.thumb,
    required this.owned,
    required this.current,
    required this.locked,
    required this.future,
  });

  final HomeDef home;
  final Widget thumb;
  final bool owned;
  final bool current;
  final bool locked;
  final bool future;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dim = future ? p.inkMuted : p.ink;
    final Widget end;
    if (owned) {
      end = _RoundBadge(
        color: p.income,
        child: Icon(Icons.check_rounded, color: p.income, size: 22),
      );
    } else if (current) {
      end = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(p.accent.withValues(alpha: 0.12), p.surface),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Text(
          S.youLiveHere,
          style: context.text.labelLarge?.copyWith(color: p.accentInk),
        ),
      );
    } else if (locked) {
      end = _RoundBadge(
        color: p.inkMuted,
        child: Icon(Icons.lock_outline_rounded, color: p.inkMuted, size: 22),
      );
    } else {
      end = const SizedBox.shrink();
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          children: [
            thumb,
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    home.name,
                    style: context.text.titleMedium?.copyWith(
                      color: dim,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (home.incomeBonusPercent > 0)
                    Text(
                      S.lifestyleBonus(home.incomeBonusPercent),
                      style: context.text.bodySmall?.copyWith(
                        color: future ? p.inkMuted : p.income,
                      ),
                    ),
                  if (future) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      formatShort(home.pricePaisa),
                      style: context.text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700, color: p.ink)
                          .numbers,
                    ),
                  ],
                ],
              ),
            ),
            end,
          ],
        ),
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Color.alphaBlend(
        color.withValues(alpha: 0.12),
        context.palette.surface,
      ),
    ),
    child: child,
  );
}
