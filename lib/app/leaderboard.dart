import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/remote/leaderboard_repository.dart';
import '../domain/leaderboard/leaderboard.dart';
import 'game_controller.dart';
import 'prefs.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => FirestoreLeaderboardRepository(),
);

enum SendOutcome { sent, tooSoon, noName, failed }

/// Sends the player's net worth to the board: once a day on its own, and
/// when the player taps "update my score" (at most once an hour).
class LeaderboardSync {
  LeaderboardSync(this._ref);

  final Ref _ref;

  static const _key = 'scoreSentAt';

  Future<DateTime?> lastSent() async {
    final m = await _ref.read(prefsRepositoryProvider).loadAll();
    return DateTime.tryParse(m[_key] ?? '');
  }

  Future<SendOutcome> send({required bool manual}) async {
    try {
      final now = DateTime.now().toUtc();
      final last = await lastSent();
      final allowed = manual
          ? ScoreRules.canSendNow(last, now)
          : ScoreRules.dailyDue(last, now);
      if (!allowed) {
        return SendOutcome.tooSoon;
      }
      final prefs = await _ref.read(prefsProvider.future);
      final name = ScoreRules.cleanName(prefs.businessName);
      final session = _ref.read(gameControllerProvider).value;
      if (name == null || session == null) {
        return SendOutcome.noName;
      }
      final engine = _ref.read(gameControllerProvider.notifier).engine;
      final worth = engine.netWorth(session.state);
      await _ref
          .read(leaderboardRepositoryProvider)
          .submit(
            name: name,
            netWorthPaisa: worth < 0 ? 0 : worth,
            cardId: engine.card(session.state).id,
          );
      await _ref.read(prefsRepositoryProvider).set(_key, now.toIso8601String());
      return SendOutcome.sent;
    } catch (_) {
      // No internet, Firebase not set up, or the daily quota is used up:
      // the game goes on and tries again next time.
      return SendOutcome.failed;
    }
  }
}

final leaderboardSyncProvider = Provider<LeaderboardSync>(LeaderboardSync.new);

/// When the last score went out; drives the button's countdown.
final lastScoreSentProvider = FutureProvider.autoDispose<DateTime?>(
  (ref) => ref.watch(leaderboardSyncProvider).lastSent(),
);

class LeaderboardView {
  const LeaderboardView({required this.entries, this.me, this.myRank});

  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? me;
  final int? myRank;
}

/// The top list and the player's own place. Kept ten minutes so opening
/// the screen again does not read the whole list again.
final leaderboardProvider = FutureProvider.autoDispose<LeaderboardView>((
  ref,
) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 10), link.close);
  ref.onDispose(timer.cancel);
  try {
    final repo = ref.read(leaderboardRepositoryProvider);
    final entries = await repo.top();
    final me = await repo.me();
    final rank = me == null ? null : await repo.rankOf(me.netWorthPaisa);
    return LeaderboardView(entries: entries, me: me, myRank: rank);
  } catch (_) {
    link.close();
    rethrow;
  }
});
