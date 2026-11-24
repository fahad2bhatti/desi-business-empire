import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/prefs.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/advisor.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../../domain/economy/goals.dart';
import '../common/photos.dart';
import '../common/run_command.dart';
import '../common/widgets.dart';
import '../goals/goals_screen.dart';
import '../onboarding/tutorial.dart';

/// Home tab. One focus: the next move. Below it, quiet context.
class EmpireScreen extends ConsumerWidget {
  const EmpireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final goal = nextGoal(engine, s);

    // Say so when net worth earns a better card.
    ref.listen<int>(
      gameControllerProvider.select((a) {
        final st = a.value?.state;
        return st == null ? 0 : engine.config.cards.indexOf(engine.card(st));
      }),
      (before, now) {
        if (before != null && now > before) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(S.cardUpgraded(engine.config.cards[now].name)),
              ),
            );
        }
      },
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s8,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      children: [
        const TutorialCoach(),
        Center(child: Text(S.tabEmpire, style: context.text.headlineSmall)),
        const SizedBox(height: AppSpacing.s16),
        _Hero(
          netWorthPaisa: engine.netWorth(s),
          incomePaisaPerSec: engine.incomePerSec(s),
        ),
        const SizedBox(height: AppSpacing.s20),
        _BankCard(engine: engine, state: s),
        const SizedBox(height: AppSpacing.s20),
        _Overview(engine: engine, state: s),
        const SizedBox(height: AppSpacing.s20),
        NextMoveCard(engine: engine, state: s, blocked: session.saveFailed),
        const SizedBox(height: AppSpacing.s12),
        _WorkButton(
          pay: formatShort(engine.config.workPayPaisa),
          enabled: !session.saveFailed,
          onTap: () =>
              runCommand(context, ref, (state, now) => engine.work(state, now)),
        ),
        if (goal != null &&
            engine.goalStatus(s, goal) == GoalStatus.inProgress) ...[
          const SizedBox(height: AppSpacing.s24),
          SectionTitle(
            S.nextGoal,
            trailing: TextButton(
              onPressed: () => context.go('/goals'),
              child: const Text(S.tabGoals),
            ),
          ),
          GoalCard(
            goal: goal,
            engine: engine,
            state: s,
            blocked: session.saveFailed,
          ),
        ],
      ],
    );
  }
}

/// `Rs 3.69B` -> `Rs 3.69 B`. Empire screen only; other screens keep
/// [formatShort] as it is.
String _short(int paisa) => formatShort(paisa).replaceFirstMapped(
  RegExp(r'(\d)([KMBT])$'),
  (m) => '${m[1]} ${m[2]}',
);

/// Whole rupees in Indian grouping: `Rs 1,84,29,27,711`.
String _indian(int paisa) {
  final digits = (paisa.abs() ~/ paisaPerRupee).toString();
  final String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final head = digits.substring(0, digits.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < head.length; i++) {
      if (i > 0 && (head.length - i) % 2 == 0) buf.write(',');
      buf.write(head[i]);
    }
    grouped = '$buf,${digits.substring(digits.length - 3)}';
  }
  return '${paisa < 0 ? '− ' : ''}Rs $grouped';
}

/// Centred net worth, with income per second in a soft green pill.
class _Hero extends StatelessWidget {
  const _Hero({required this.netWorthPaisa, required this.incomePaisaPerSec});

  final int netWorthPaisa;
  final int incomePaisaPerSec;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label:
          '${S.netWorth} ${formatShort(netWorthPaisa)}, ${S.perSecond(formatShort(incomePaisaPerSec))}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            S.netWorth,
            style: context.text.titleSmall?.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s4),
          TweenAnimationBuilder<double>(
            tween: Tween(end: netWorthPaisa.toDouble()),
            duration: reduceMotion ? Duration.zero : AppMotion.counter,
            curve: AppMotion.curve,
            builder: (context, value, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _short(value.round()),
                style: context.text.displaySmall
                    ?.copyWith(
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    )
                    .numbers,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: p.income.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s4 + 2,
              ),
              child: Text(
                S.aSecond(_short(incomePaisaPerSec)),
                style: context.text.titleSmall
                    ?.copyWith(color: p.income)
                    .numbers,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The advisor's best move: small label, name, cost and gain, and a white
/// action button on the right. When it cannot be afforded yet, a progress bar
/// takes the button's place.
class NextMoveCard extends ConsumerWidget {
  const NextMoveCard({
    super.key,
    required this.engine,
    required this.state,
    required this.blocked,
  });

  final GameEngine engine;
  final GameState state;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    final move = engine.nextMove(s);
    if (move == null) {
      return const _MoveCard(title: S.allDone);
    }
    final c = engine.config;
    final cost = _short(move.costPaisa);
    final (String title, String action, String? done) = switch (move.kind) {
      MoveKind.claimGoals => (
        S.focusClaim,
        S.actionCollect,
        S.collected(formatShort(move.gainPaisa)),
      ),
      MoveKind.buyBusiness => (
        S.focusBuy(c.business(move.id!)!.name),
        S.actionBuy,
        null,
      ),
      MoveKind.upgradeBusiness => (
        S.focusUpgrade(c.business(move.id!)!.name),
        S.actionUpgrade,
        null,
      ),
      MoveKind.moveHome => (
        S.focusMove(engine.nextHome(s)!.name),
        S.actionMove,
        S.movedTo(engine.nextHome(s)!.name),
      ),
      MoveKind.buyItem => (
        S.focusBuy(c.item(move.id!)!.name),
        S.actionBuy,
        null,
      ),
    };
    final detail = move.kind == MoveKind.claimGoals
        ? S.focusWaiting(_short(move.gainPaisa))
        : '$cost · ${S.aSecond(_short(move.gainPaisa))}';
    final affordable = move.costPaisa <= s.cashPaisa;
    if (!affordable) {
      final wait = engine.secondsUntil(s, move.costPaisa);
      return _MoveCard(
        title: title,
        detail: detail,
        progress: s.cashPaisa / move.costPaisa,
        progressText: wait == null ? S.workToSave : S.readyIn(S.eta(wait)),
      );
    }
    return _MoveCard(
      title: title,
      detail: detail,
      actionLabel: action,
      onAction: blocked
          ? null
          : () => runCommand(
              context,
              ref,
              (st, now) => switch (move.kind) {
                MoveKind.claimGoals => engine.claimAllGoals(st, now),
                MoveKind.buyBusiness => engine.buyBusiness(st, move.id!, now),
                MoveKind.upgradeBusiness => engine.upgradeBusiness(
                  st,
                  move.id!,
                  now,
                ),
                MoveKind.moveHome => engine.moveHome(st, now),
                MoveKind.buyItem => engine.buyItem(st, move.id!, now),
              },
              successText: done,
            ),
    );
  }
}

/// The one accent-filled element on the Empire screen.
class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.title,
    this.detail,
    this.progress,
    this.progressText,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? detail;
  final double? progress;
  final String? progressText;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = p.onAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.nextMove,
              style: context.text.bodySmall?.copyWith(
                color: on.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.titleLarge?.copyWith(
                          color: on,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          detail!,
                          style: context.text.bodySmall
                              ?.copyWith(color: on.withValues(alpha: 0.85))
                              .numbers,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: AppSpacing.s12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: on,
                      foregroundColor: p.accent,
                      minimumSize: const Size(76, 44),
                    ),
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  color: on,
                  backgroundColor: on.withValues(alpha: 0.24),
                  semanticsLabel: title,
                ),
              ),
              if (progressText != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  progressText!,
                  style: context.text.bodySmall?.copyWith(color: on).numbers,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// What the empire is worth, split by kind: a coloured bar, then two columns
/// of soft tiles. Each tile opens the tab where that kind is managed.
class _Overview extends StatelessWidget {
  const _Overview({required this.engine, required this.state});

  final GameEngine engine;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final c = engine.config;

    final worth = <String, int>{for (final cat in c.categories) cat.id: 0};
    for (final id in s.businesses.keys) {
      final b = c.business(id);
      if (b != null) {
        worth[b.categoryId] =
            (worth[b.categoryId] ?? 0) + engine.businessSellValue(s, id);
      }
    }
    var property = 0;
    for (final prop in c.properties) {
      for (var i = s.owned(prop.id); i > 0; i--) {
        property += engine.propertySellValue(prop, i);
      }
    }
    var lifestyle = 0;
    for (final item in c.lifestyle) {
      if (s.lifestyle.contains(item.id)) {
        lifestyle += engine.itemSellValue(item);
      }
    }
    lifestyle +=
        ((engine.currentHome(s)?.pricePaisa ?? 0) * c.lifestyleSellRefund)
            .round();

    final tiles = <_TileData>[
      for (final cat in c.categories)
        _TileData(cat.id, cat.name, worth[cat.id] ?? 0, '/businesses'),
      _TileData('property', S.property, property, '/property?tab=property'),
      _TileData('lifestyle', S.lifestyle, lifestyle, '/property?tab=vehicles'),
    ];
    final total = tiles.fold<int>(0, (a, t) => a + (t.paisa > 0 ? t.paisa : 0));

    final p = context.palette;
    return Column(
      children: [
        SizedBox(
          height: 6,
          child: Row(
            children: [
              for (final (i, t) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  flex: total == 0
                      ? 1
                      : ((t.paisa > 0 ? t.paisa : 0) * 1000 ~/ total).clamp(
                          12,
                          1000,
                        ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.category(t.id),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(child: _CategoryTile(data: tiles[i])),
              const SizedBox(width: AppSpacing.s12),
              if (i + 1 < tiles.length)
                Expanded(child: _CategoryTile(data: tiles[i + 1]))
              else
                const Spacer(),
            ],
          ),
        ],
      ],
    );
  }
}

class _TileData {
  const _TileData(this.id, this.label, this.paisa, this.path);

  final String id;
  final String label;
  final int paisa;
  final String path;
}

/// Soft tile in the category's colour with a strip on its left edge.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.data});

  final _TileData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '${data.label}, ${formatShort(data.paisa)}',
      excludeSemantics: true,
      child: Material(
        color: p.tint(data.id),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(data.path),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 9,
                  child: ColoredBox(color: p.category(data.id)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.label,
                          style: context.text.bodySmall?.copyWith(
                            color: p.inkMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.s4 / 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _short(data.paisa),
                            style: context.text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)
                                .numbers,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neutral tap target. Each tap pops a small "+Rs 25" that floats up.
class _WorkButton extends StatefulWidget {
  const _WorkButton({
    required this.pay,
    required this.enabled,
    required this.onTap,
  });

  final String pay;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_WorkButton> createState() => _WorkButtonState();
}

class _WorkButtonState extends State<_WorkButton> {
  final _pops = <int>[];
  var _next = 0;
  var _pressed = false;

  void _tap() {
    widget.onTap();
    if (MediaQuery.of(context).disableAnimations) {
      return;
    }
    final id = _next++;
    setState(() => _pops.add(id));
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      setState(() => _pops.remove(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: widget.enabled ? _tap : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    PhotoThumb(
                      id: 'samosa',
                      fallback: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: p.surfaceRaised,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.touch_app, color: p.ink),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.work, style: context.text.titleMedium),
                          Text(
                            S.workPay(widget.pay),
                            style: context.text.bodySmall?.copyWith(
                              color: p.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (final id in _pops)
          Positioned(
            right: AppSpacing.s20,
            top: AppSpacing.s16,
            child: IgnorePointer(
              key: ValueKey(id),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: AppMotion.curve,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(0, -32 * t),
                  child: Opacity(opacity: 1 - t, child: child),
                ),
                child: Text(
                  '+${widget.pay}',
                  style: context.text.titleMedium
                      ?.copyWith(color: p.income)
                      .numbers,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Card colours, dark to light, and the digits printed on each card.
({Color top, Color bottom, String last4}) _cardLook(String id) => switch (id) {
  'bronze' => (
    top: const Color(0xFF8A5A33),
    bottom: const Color(0xFF5E3B20),
    last4: '2184',
  ),
  'silver' => (
    top: const Color(0xFF8C96A1),
    bottom: const Color(0xFF5B6570),
    last4: '5530',
  ),
  'gold' => (
    top: const Color(0xFFB8912A),
    bottom: const Color(0xFF7A5D14),
    last4: '9017',
  ),
  'platinum' => (
    top: const Color(0xFF4A5560),
    bottom: const Color(0xFF343D46),
    last4: '7439',
  ),
  'diamond' => (
    top: const Color(0xFF3B86B8),
    bottom: const Color(0xFF245A82),
    last4: '3862',
  ),
  _ => (
    top: const Color(0xFF2C4A72),
    bottom: const Color(0xFF14213A),
    last4: '1001',
  ),
};

/// A bank card drawn in code: soft gradient, two faint circles, the balance
/// and the card number. [compact] is the small version for the card list.
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    this.balancePaisa = 0,
    this.compact = false,
  });

  final CardDef card;
  final int balancePaisa;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final look = _cardLook(card.id);
    const white = Colors.white;
    return AspectRatio(
      aspectRatio: compact ? 1.6 : 1.55,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final k = w / 340;
          return ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 10 : AppRadius.card),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [look.top, look.bottom],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -w * 0.12,
                    top: -w * 0.16,
                    child: _Disc(size: w * 0.62, alpha: 0.07),
                  ),
                  Positioned(
                    right: w * 0.16,
                    bottom: -w * 0.30,
                    child: _Disc(size: w * 0.55, alpha: 0.05),
                  ),
                  if (compact)
                    Center(
                      child: Icon(
                        Icons.diamond_outlined,
                        color: white.withValues(alpha: 0.85),
                        size: 18,
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.all(20 * k),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                S.cardShort(card.name),
                                style: TextStyle(
                                  color: white.withValues(alpha: 0.82),
                                  fontSize: 14 * k,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.diamond_outlined,
                                color: white.withValues(alpha: 0.9),
                                size: 24 * k,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            S.cardBalance,
                            style: TextStyle(
                              color: white.withValues(alpha: 0.7),
                              fontSize: 13 * k,
                            ),
                          ),
                          SizedBox(height: 2 * k),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _indian(balancePaisa),
                              style: TextStyle(
                                color: white,
                                fontSize: 28 * k,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ).numbers,
                            ),
                          ),
                          SizedBox(height: 18 * k),
                          Row(
                            children: [
                              Text(
                                '•••• ${look.last4}',
                                style: TextStyle(
                                  color: white.withValues(alpha: 0.75),
                                  fontSize: 12 * k,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                S.cardExpiry,
                                style: TextStyle(
                                  color: white.withValues(alpha: 0.75),
                                  fontSize: 12 * k,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: alpha),
    ),
  );
}

/// Index of the card on show: the one the player picked if it is unlocked,
/// otherwise the best one they hold.
int _usedCard(List<CardDef> cards, int best, String? pickedId) {
  final i = cards.indexWhere((c) => c.id == pickedId);
  return i < 0 || i > best ? best : i;
}

/// The player's bank card with their cash as the balance. Tap to see every
/// card and pick any unlocked one.
class _BankCard extends ConsumerWidget {
  const _BankCard({required this.engine, required this.state});

  final GameEngine engine;
  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = engine.config.cards;
    final picked = ref.watch(prefsProvider.select((a) => a.value?.cardId));
    final card = cards[_usedCard(
      cards,
      cards.indexOf(engine.card(state)),
      picked,
    )];
    final limit = card.limitPaisa == noCardLimit
        ? S.cardNoLimit
        : S.cardLimit(formatShort(card.limitPaisa));
    return Semantics(
      container: true,
      button: true,
      label:
          '${S.cardShort(card.name)}. ${S.cardBalance} ${formatShort(state.cashPaisa)}. $limit',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _showCards(context, engine, state),
        child: _CardFace(card: card, balancePaisa: state.cashPaisa),
      ),
    );
  }
}

/// Every card from first to last. Unlocked ones can be picked; locked ones
/// show what they need.
void _showCards(BuildContext context, GameEngine engine, GameState s) {
  final p = context.palette;
  final cards = engine.config.cards;
  final best = cards.indexOf(engine.card(s));
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Consumer(
        builder: (context, ref, _) {
          final used = _usedCard(
            cards,
            best,
            ref.watch(prefsProvider.select((a) => a.value?.cardId)),
          );
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              0,
              AppSpacing.s20,
              AppSpacing.s20,
            ),
            children: [
              Text(S.cardsTitle, style: sheet.text.titleLarge),
              const SizedBox(height: AppSpacing.s4),
              Text(
                S.cardsIntro,
                style: sheet.text.bodyMedium?.copyWith(color: p.inkMuted),
              ),
              const SizedBox(height: AppSpacing.s16),
              for (final (i, c) in cards.indexed)
                _CardRow(
                  card: c,
                  locked: i > best,
                  used: i == used,
                  onTap: () {
                    ref.read(prefsProvider.notifier).setCardId(c.id);
                    Navigator.of(sheet).pop();
                  },
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.locked,
    required this.used,
    required this.onTap,
  });

  final CardDef card;
  final bool locked;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final limit = card.limitPaisa == noCardLimit
        ? S.cardNoLimit
        : S.cardLimit(formatShort(card.limitPaisa));
    final status = locked
        ? S.cardNeedsWorth(formatShort(card.netWorthPaisa))
        : used
        ? S.cardInUse
        : S.cardTapToUse;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: locked ? null : onTap,
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: used ? p.accent : p.inkMuted.withValues(alpha: 0.25),
                  width: used ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _CardFace(card: card, compact: true),
                        if (locked)
                          const Icon(Icons.lock_outline, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.cardShort(card.name),
                          style: context.text.titleSmall,
                        ),
                        Text(
                          limit,
                          style: context.text.bodySmall?.copyWith(
                            color: p.inkMuted,
                          ),
                        ),
                        Text(
                          status,
                          style: context.text.bodySmall
                              ?.copyWith(
                                color: used ? p.accentInk : p.inkMuted,
                              )
                              .numbers,
                        ),
                      ],
                    ),
                  ),
                  if (used) Icon(Icons.check_circle, color: p.accent, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
