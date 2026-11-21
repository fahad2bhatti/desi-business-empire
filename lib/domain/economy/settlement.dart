import 'dart:math' as math;

import 'command_result.dart';
import 'economy_config.dart';
import 'game_engine.dart';
import 'game_state.dart';

/// What one business earned and spent during a settlement.
class StageSettlement {
  const StageSettlement({
    required this.stageId,
    required this.sold,
    required this.revenuePaisa,
    required this.wagesPaisa,
    required this.rentPaisa,
    required this.stockUsed,
    required this.ranDryAfter,
  });

  final String stageId;
  final int sold;
  final int revenuePaisa;
  final int wagesPaisa;
  final int rentPaisa;

  /// Ingredient kits put into batches (already paid for when bought).
  final int stockUsed;

  /// Set when stock, ready items and batches all ran out; after that the
  /// business stood closed and cost nothing.
  final Duration? ranDryAfter;

  int get netPaisa => revenuePaisa - wagesPaisa - rentPaisa;
}

class Settlement {
  const Settlement({
    required this.state,
    required this.entries,
    required this.away,
    required this.credited,
    required this.stages,
    this.clockWentBack = false,
  });

  /// Already includes the money; the summary screen only shows it.
  final GameState state;
  final List<LedgerEntry> entries;
  final Duration away;
  final Duration credited;
  final Map<String, StageSettlement> stages;
  final bool clockWentBack;

  bool get capped => credited < Duration(seconds: away.inSeconds);
  int get netPaisa => entries.fold(0, (sum, e) => sum + e.deltaPaisa);
}

/// Working copy of one stage while time is stepped.
class _Run {
  _Run(this.def, this.st, this.prices, this.batches, this.batchSeconds);

  final StageDef def;
  StageState st;
  final Map<String, int> prices;
  final Map<String, int> batches;
  final Map<String, int> batchSeconds;
  bool dry = false;
  int sold = 0;
  int revenue = 0;
  int wages = 0;
  int rent = 0;
  int stockUsed = 0;
  int? dryAtSecond;
}

extension Settle on GameEngine {
  /// Settles wages, rent and staff automation from `s.lastSettledAt` to [now]
  /// in whole seconds (leftover milliseconds wait for the next call).
  ///
  /// [foreground]: the app is open, every unlocked business runs.
  /// Otherwise only businesses with a manager, a helper and a cook run, for
  /// at most `offlineCapMinutes`, and only on stock already bought.
  /// Call it exactly once per resume and on the foreground tick, never again
  /// from a "claim" button: the result already holds the money.
  Settlement advanceTo(GameState s, DateTime now, {required bool foreground}) {
    final elapsedMs = now.difference(s.lastSettledAt).inMilliseconds;
    if (elapsedMs < 0) {
      return Settlement(
        state: s,
        entries: const [],
        away: Duration.zero,
        credited: Duration.zero,
        stages: const {},
        clockWentBack: true,
      );
    }
    final seconds = elapsedMs ~/ 1000;
    final away = Duration(milliseconds: elapsedMs);
    if (seconds == 0) {
      return Settlement(
        state: s,
        entries: const [],
        away: away,
        credited: Duration.zero,
        stages: const {},
      );
    }
    final credited = foreground
        ? seconds
        : math.min(seconds, config.offlineCapMinutes * 60);
    final start = s.lastSettledAt;
    final end = start.add(Duration(seconds: seconds));

    final runs = <_Run>[];
    for (final def in config.stages) {
      final st = s.stages[def.id];
      if (st == null || def.lines.isEmpty) continue; // hall events: later phase
      final eligible =
          foreground ||
          (st.staffCount(StaffRole.manager) > 0 &&
              st.staffCount(StaffRole.helper) > 0 &&
              st.staffCount(StaffRole.cook) > 0);
      if (!eligible) continue;
      final stats = {for (final l in def.lines) l.id: lineStats(s, def, l)};
      runs.add(
        _Run(
          def,
          st,
          {for (final e in stats.entries) e.key: e.value.pricePaisa},
          {for (final e in stats.entries) e.key: e.value.batch},
          {for (final e in stats.entries) e.key: e.value.batchSeconds},
        ),
      );
      if (_isDry(st)) {
        runs.last
          ..dry = true
          ..dryAtSecond = 0;
      }
    }

    var cash = s.cashPaisa;
    for (var i = 1; i <= credited; i++) {
      final t = start.add(Duration(seconds: i));
      for (final r in runs) {
        if (r.dry) continue;
        cash = _step(s, r, t, cash);
        if (_isDry(r.st)) {
          r.dry = true;
          r.dryAtSecond = i;
        }
      }
    }

    // Time past the cap is not credited, but food already in the kadhai
    // still finishes.
    var stages = {...s.stages};
    for (final r in runs) {
      stages[r.def.id] = r.st;
    }
    stages = {
      for (final e in stages.entries) e.key: _finishBatches(e.value, end),
    };

    final entries = <LedgerEntry>[];
    final summaries = <String, StageSettlement>{};
    for (final r in runs) {
      final id = r.def.id;
      if (r.revenue > 0) {
        entries.add(
          LedgerEntry(
            type: LedgerType.sale,
            deltaPaisa: r.revenue,
            reason: '$id/auto',
            at: end,
          ),
        );
      }
      if (r.wages > 0) {
        entries.add(
          LedgerEntry(
            type: LedgerType.wages,
            deltaPaisa: -r.wages,
            reason: id,
            at: end,
          ),
        );
      }
      if (r.rent > 0) {
        entries.add(
          LedgerEntry(
            type: LedgerType.rent,
            deltaPaisa: -r.rent,
            reason: id,
            at: end,
          ),
        );
      }
      summaries[id] = StageSettlement(
        stageId: id,
        sold: r.sold,
        revenuePaisa: r.revenue,
        wagesPaisa: r.wages,
        rentPaisa: r.rent,
        stockUsed: r.stockUsed,
        ranDryAfter: r.dryAtSecond == null
            ? null
            : Duration(seconds: r.dryAtSecond!),
      );
    }

    return Settlement(
      state: s.copyWith(
        revision: s.revision + 1,
        cashPaisa: cash,
        stages: stages,
        lastSettledAt: end,
      ),
      entries: entries,
      away: away,
      credited: Duration(seconds: credited),
      stages: summaries,
    );
  }

  /// One second of one running business. Returns the new cash.
  int _step(GameState s, _Run r, DateTime t, int cash) {
    var st = r.st;
    final cooks = st.staffCount(StaffRole.cook);
    final lines = <String, LineState>{};
    for (final e in st.lines.entries) {
      var l = e.value;
      if (l.isCooking && !t.isBefore(l.batchEndsAt!)) l = l.finishBatch();
      if (cooks > 0 && !l.isCooking && l.stock > 0) {
        final size = math.min(r.batches[e.key]!, l.stock);
        l = l.startBatch(
          size,
          t.add(Duration(seconds: r.batchSeconds[e.key]!)),
        );
        r.stockUsed += size;
      }
      lines[e.key] = l;
    }

    // Customers who arrived during this second.
    var queue = st.queue;
    var queueCarry = st.queueCarry;
    var updatedAt = st.customersUpdatedAt;
    final ms = t.difference(updatedAt).inMilliseconds;
    if (ms > 0) {
      final total =
          queueCarry + ms * (customersPerMin(s, r.def) * 1000).round();
      queue = math.min(config.maxQueue, queue + total ~/ GameEngine.carryUnit);
      queueCarry = total % GameEngine.carryUnit;
      updatedAt = t;
    }

    // Helpers serve, taking lines in turn so every item sells.
    final helperDef = r.def.staff[StaffRole.helper]!;
    var serveCarry =
        st.serveCarry +
        st.staffCount(StaffRole.helper) * helperDef.servePerMin * 1000 * 1000;
    var serves = serveCarry ~/ GameEngine.carryUnit;
    serveCarry %= GameEngine.carryUnit;
    final ids = r.def.lines.map((l) => l.id).toList();
    var sold = st.sold;
    while (serves > 0 && queue > 0) {
      String? pick;
      for (var k = 0; k < ids.length; k++) {
        final id = ids[(sold + k) % ids.length];
        if (lines[id]!.ready > 0) {
          pick = id;
          break;
        }
      }
      if (pick == null) break;
      final l = lines[pick]!;
      lines[pick] = l.copyWith(ready: l.ready - 1);
      queue--;
      serves--;
      sold++;
      r.sold++;
      r.revenue += r.prices[pick]!;
      cash += r.prices[pick]!;
    }

    // Rent and wages for this second, never below zero cash.
    final wagePerMin = r.def.staff.entries.fold<int>(
      0,
      (sum, e) => sum + e.value.wagePaisaPerMin * st.staffCount(e.key),
    );
    final perMin = r.def.rentPaisaPerMin + wagePerMin;
    var costCarry = st.costCarry + perMin * 1000;
    var charge = costCarry ~/ 60000;
    costCarry %= 60000;
    if (charge > cash) charge = cash; // unpaid remainder is forgiven
    if (charge > 0) {
      final rentPart = charge * r.def.rentPaisaPerMin ~/ perMin;
      r.rent += rentPart;
      r.wages += charge - rentPart;
      cash -= charge;
    }

    st = st.copyWith(
      lines: lines,
      queue: queue,
      queueCarry: queueCarry,
      customersUpdatedAt: updatedAt,
      serveCarry: serveCarry,
      costCarry: costCarry,
      sold: sold,
    );
    r.st = st;
    return cash;
  }

  bool _isDry(StageState st) => st.lines.values.every(
    (l) => l.stock == 0 && l.ready == 0 && !l.isCooking,
  );

  StageState _finishBatches(StageState st, DateTime end) => st.copyWith(
    lines: {
      for (final e in st.lines.entries)
        e.key: (e.value.isCooking && !end.isBefore(e.value.batchEndsAt!))
            ? e.value.finishBatch()
            : e.value,
    },
  );
}
