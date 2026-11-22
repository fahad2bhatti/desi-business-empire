import 'dart:math' as math;

import 'command_result.dart';
import 'game_engine.dart';
import 'game_state.dart';

class Settlement {
  const Settlement({
    required this.state,
    required this.entries,
    required this.away,
    required this.credited,
    required this.earnedPaisa,
    this.clockWentBack = false,
  });

  /// Already includes the money; a summary screen only shows it.
  final GameState state;
  final List<LedgerEntry> entries;
  final Duration away;
  final Duration credited;
  final int earnedPaisa;
  final bool clockWentBack;

  bool get capped => credited < Duration(seconds: away.inSeconds);
}

extension Settle on GameEngine {
  /// Pays income from `s.lastSettledAt` to [now] in whole seconds (leftover
  /// milliseconds wait for the next call). While the app is closed
  /// ([foreground] false) at most `offlineCapMinutes` are paid.
  /// Call it once per resume and on the foreground tick, never again from a
  /// "claim" button: the result already holds the money.
  Settlement advanceTo(GameState s, DateTime now, {required bool foreground}) {
    final elapsedMs = now.difference(s.lastSettledAt).inMilliseconds;
    if (elapsedMs < 0) {
      return Settlement(
        state: s,
        entries: const [],
        away: Duration.zero,
        credited: Duration.zero,
        earnedPaisa: 0,
        clockWentBack: true,
      );
    }
    final away = Duration(milliseconds: elapsedMs);
    final seconds = elapsedMs ~/ 1000;
    if (seconds == 0) {
      return Settlement(
        state: s,
        entries: const [],
        away: away,
        credited: Duration.zero,
        earnedPaisa: 0,
      );
    }
    final credited = foreground
        ? seconds
        : math.min(seconds, config.offlineCapMinutes * 60);
    final earned = incomePerSec(s) * credited;
    final end = s.lastSettledAt.add(Duration(seconds: seconds));

    // Income tax builds up with income; each missed return deadline adds
    // the late penalty and moves the deadline one period on.
    var due = s.taxDuePaisa + earned * incomeTaxPercent(s) ~/ 100;
    var periodStart = taxPeriodStart(s);
    var missed = s.taxMissed;
    final period = config.tax.period;
    for (var i = 0; i < 100 && !end.isBefore(periodStart.add(period)); i++) {
      due += due * config.tax.latePenaltyPercent ~/ 100;
      periodStart = periodStart.add(period);
      missed++;
    }

    return Settlement(
      state: s.copyWith(
        revision: s.revision + 1,
        cashPaisa: s.cashPaisa + earned,
        totalEarnedPaisa: s.totalEarnedPaisa + earned,
        lastSettledAt: end,
        taxDuePaisa: due,
        taxPeriodStart: periodStart,
        taxMissed: missed,
      ),
      entries: [
        if (earned > 0)
          LedgerEntry(
            type: LedgerType.income,
            deltaPaisa: earned,
            reason: 'income',
            at: end,
          ),
      ],
      away: away,
      credited: Duration(seconds: credited),
      earnedPaisa: earned,
    );
  }
}
