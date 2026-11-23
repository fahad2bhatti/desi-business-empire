import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/leaderboard.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/leaderboard/leaderboard.dart';

/// Top empires by net worth, and where the player stands.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(leaderboardProvider);
    final p = context.palette;
    final cards = {
      for (final c
          in ref.read(gameControllerProvider.notifier).engine.config.cards)
        c.id: c.name,
    };
    final myId = ref.read(leaderboardRepositoryProvider).myId;

    return Scaffold(
      appBar: AppBar(title: const Text(S.leaderboard)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider);
          await ref
              .read(leaderboardProvider.future)
              .catchError((_) => const LeaderboardView(entries: []));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            Text(
              S.leaderboardIntro,
              style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s16),
            const _UpdateCard(),
            const SizedBox(height: AppSpacing.s16),
            ...switch (board) {
              AsyncData(:final value) => _rows(context, value, cards, myId),
              AsyncError() => [
                Text(S.leaderboardOffline, style: context.text.bodyMedium),
                const SizedBox(height: AppSpacing.s12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(leaderboardProvider),
                  child: const Text(S.tryAgain),
                ),
              ],
              _ => const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.s24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(
    BuildContext context,
    LeaderboardView view,
    Map<String, String> cards,
    String? myId,
  ) {
    final p = context.palette;
    if (view.entries.isEmpty) {
      return [Text(S.leaderboardEmpty, style: context.text.bodyMedium)];
    }
    return [
      if (view.myRank != null && view.me != null) ...[
        Text(
          S.leaderboardYourRank(view.myRank!),
          style: context.text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.s12),
      ],
      for (final (i, e) in view.entries.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: e.id == myId
                    ? p.accent
                    : p.inkMuted.withValues(alpha: 0.2),
                width: e.id == myId ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${i + 1}',
                    style: context.text.titleMedium
                        ?.copyWith(color: i < 3 ? p.accent : p.inkMuted)
                        .numbers,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                      Text(
                        S.cardShort(cards[e.cardId] ?? ''),
                        style: context.text.bodySmall?.copyWith(
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatShort(e.netWorthPaisa),
                  style: context.text.titleSmall?.numbers,
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

/// Shows the daily rule and the "update my score" button with its wait.
class _UpdateCard extends ConsumerStatefulWidget {
  const _UpdateCard();

  @override
  ConsumerState<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends ConsumerState<_UpdateCard> {
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    final outcome = await ref.read(leaderboardSyncProvider).send(manual: true);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ref.invalidate(lastScoreSentProvider);
    if (outcome == SendOutcome.sent) {
      ref.invalidate(leaderboardProvider);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (outcome) {
            SendOutcome.sent => S.scoreSent,
            SendOutcome.tooSoon => S.scoreTooSoon,
            SendOutcome.noName => S.scoreNoName,
            SendOutcome.failed => S.leaderboardOffline,
          }),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = ref.watch(lastScoreSentProvider).value;
    final left = ScoreRules.cooldownLeft(last, DateTime.now().toUtc());
    final ready = left == Duration.zero && !_busy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                left == Duration.zero
                    ? S.scoreReady
                    : S.scoreWait(left.inMinutes + 1),
                style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            FilledButton(
              onPressed: ready ? _send : null,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(S.scoreUpdate),
            ),
          ],
        ),
      ),
    );
  }
}
