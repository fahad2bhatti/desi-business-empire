import 'dart:math' as math;

import '../../core/money.dart';
import 'command_result.dart';
import 'economy_config.dart';
import 'game_state.dart';

/// Effective numbers for one item line after upgrades.
class LineStats {
  const LineStats({
    required this.batch,
    required this.batchSeconds,
    required this.pricePaisa,
  });

  final int batch;
  final int batchSeconds;
  final int pricePaisa;
}

/// Pure rules for every economic command. No Flutter, no database, no wall
/// clock: callers pass `now`. A command either returns [Success] with the
/// new state (revision + 1) and its ledger entries, or [Failure] and the
/// caller keeps the old state.
///
/// Time-based settlement (wages, rent, staff automation, offline) lives in
/// `settlement.dart` as `advanceTo`.
class GameEngine {
  const GameEngine(this.config);

  final EconomyConfig config;

  // ---------- derived values ----------

  double _stageValue(GameState s, String stageId, UpgradeEffect effect, double base) {
    var value = base;
    for (final u in config.upgrades) {
      final level = s.upgradeLevel(u.id);
      if (u.stageId == stageId && u.effect == effect && level > 0) {
        value = u.levels[level - 1].value;
      }
    }
    return value;
  }

  int storage(GameState s, StageDef def) =>
      _stageValue(s, def.id, UpgradeEffect.storage, def.storage.toDouble()).round();

  double customersPerMin(GameState s, StageDef def) =>
      def.customersPerMin * _stageValue(s, def.id, UpgradeEffect.demandMult, 1);

  LineStats lineStats(GameState s, StageDef def, LineDef line) {
    var batch = line.batch;
    var seconds = line.batchSeconds;
    var price = line.pricePaisa;
    for (final u in config.upgrades) {
      final level = s.upgradeLevel(u.id);
      if (u.stageId != def.id || u.lineId != line.id || level == 0) continue;
      final v = u.levels[level - 1].value;
      switch (u.effect) {
        case UpgradeEffect.batch:
          batch = v.round();
        case UpgradeEffect.batchSeconds:
          seconds = v.round();
        case UpgradeEffect.price:
          price = rupees(v.round());
        case UpgradeEffect.priceMult:
        case UpgradeEffect.demandMult:
        case UpgradeEffect.storage:
          break;
      }
    }
    final mult = _stageValue(s, def.id, UpgradeEffect.priceMult, 1);
    return LineStats(batch: batch, batchSeconds: seconds, pricePaisa: (price * mult).round());
  }

  List<UnmetRequirement> missingRequirements(GameState s, String stageId) {
    final def = config.stage(stageId);
    if (def == null) return const [];
    final r = def.requirements;
    final unmet = <UnmetRequirement>[];
    r.sold.forEach((id, need) {
      final have = s.stages[id]?.sold ?? 0;
      if (have < need) {
        unmet.add(UnmetRequirement(kind: RequirementKind.sold, target: id, have: have, need: need));
      }
    });
    r.upgrades.forEach((id, need) {
      final have = s.upgradeLevel(id);
      if (have < need) {
        unmet.add(UnmetRequirement(kind: RequirementKind.upgrade, target: id, have: have, need: need));
      }
    });
    r.staff.forEach((id, roles) {
      roles.forEach((role, need) {
        final have = s.stages[id]?.staffCount(role) ?? 0;
        if (have < need) {
          unmet.add(UnmetRequirement(
              kind: RequirementKind.staff, target: id, role: role, have: have, need: need));
        }
      });
    });
    return unmet;
  }

  /// The state as it looks at [now] (finished batches, arrived customers).
  /// For display only; it is not a command and does not bump the revision.
  GameState observe(GameState s, DateTime now) {
    var out = s;
    for (final id in s.stages.keys) {
      out = out.withStage(id, _refresh(s, config.stage(id)!, now));
    }
    return out;
  }

  // ---------- commands ----------

  CommandResult buyStock(GameState s, String stageId, String lineId, int qty, DateTime now) {
    if (qty <= 0) return const Failure(FailReason.invalidQuantity);
    final def = config.stage(stageId);
    final line = def?.line(lineId);
    if (def == null || line == null) return const Failure(FailReason.unknownId);
    if (!s.stages.containsKey(stageId)) return const Failure(FailReason.stageLocked);
    final st = _refresh(s, def, now);
    if (st.totalStock + qty > storage(s, def)) return const Failure(FailReason.storageFull);
    final cost = line.costPaisa * qty;
    if (cost > s.cashPaisa) return _noFunds(cost, s);
    final ls = st.lines[lineId]!;
    return _ok(
      s.copyWith(cashPaisa: s.cashPaisa - cost)
          .withStage(stageId, st.withLine(lineId, ls.copyWith(stock: ls.stock + qty))),
      [_entry(LedgerType.stockPurchase, -cost, '$stageId/$lineId x$qty', now)],
    );
  }

  /// Puts up to one batch of stock in the kadhai.
  CommandResult startBatch(GameState s, String stageId, String lineId, DateTime now) {
    final def = config.stage(stageId);
    final line = def?.line(lineId);
    if (def == null || line == null) return const Failure(FailReason.unknownId);
    if (!s.stages.containsKey(stageId)) return const Failure(FailReason.stageLocked);
    final st = _refresh(s, def, now);
    final ls = st.lines[lineId]!;
    if (ls.isCooking) return const Failure(FailReason.batchInProgress);
    if (ls.stock == 0) return const Failure(FailReason.noStock);
    final stats = lineStats(s, def, line);
    final size = math.min(stats.batch, ls.stock);
    final endsAt = now.add(Duration(seconds: stats.batchSeconds));
    return _ok(s.withStage(stageId, st.withLine(lineId, ls.startBatch(size, endsAt))), const []);
  }

  /// Sells one ready item to the first waiting customer.
  CommandResult serve(GameState s, String stageId, String lineId, DateTime now) {
    final def = config.stage(stageId);
    final line = def?.line(lineId);
    if (def == null || line == null) return const Failure(FailReason.unknownId);
    if (!s.stages.containsKey(stageId)) return const Failure(FailReason.stageLocked);
    final st = _refresh(s, def, now);
    if (st.queue < 1) return const Failure(FailReason.noCustomer);
    final ls = st.lines[lineId]!;
    if (ls.ready < 1) return const Failure(FailReason.nothingReady);
    final price = lineStats(s, def, line).pricePaisa;
    final next = st
        .copyWith(queue: st.queue - 1, sold: st.sold + 1)
        .withLine(lineId, ls.copyWith(ready: ls.ready - 1));
    return _ok(
      s.copyWith(cashPaisa: s.cashPaisa + price).withStage(stageId, next),
      [_entry(LedgerType.sale, price, '$stageId/$lineId', now)],
    );
  }

  CommandResult buyUpgrade(GameState s, String upgradeId, DateTime now) {
    final u = config.upgrade(upgradeId);
    if (u == null) return const Failure(FailReason.unknownId);
    if (!s.stages.containsKey(u.stageId)) return const Failure(FailReason.stageLocked);
    final level = s.upgradeLevel(upgradeId);
    if (level >= u.levels.length) return const Failure(FailReason.maxLevel);
    final cost = u.levels[level].costPaisa;
    if (cost > s.cashPaisa) return _noFunds(cost, s);
    return _ok(
      s.copyWith(cashPaisa: s.cashPaisa - cost, upgrades: {...s.upgrades, upgradeId: level + 1}),
      [_entry(LedgerType.upgrade, -cost, '$upgradeId L${level + 1}', now)],
    );
  }

  CommandResult hire(GameState s, String stageId, String role, DateTime now) {
    final def = config.stage(stageId);
    final staffDef = def?.staff[role];
    if (def == null || staffDef == null) return const Failure(FailReason.unknownId);
    final st = s.stages[stageId];
    if (st == null) return const Failure(FailReason.stageLocked);
    final count = st.staffCount(role);
    if (count >= staffDef.max) return const Failure(FailReason.maxStaff);
    if (st.sold < staffDef.requiresSold) {
      return Failure(FailReason.requirementsNotMet, unmet: [
        UnmetRequirement(
            kind: RequirementKind.sold, target: stageId, have: st.sold, need: staffDef.requiresSold),
      ]);
    }
    final cost = staffDef.hirePaisa;
    if (cost > s.cashPaisa) return _noFunds(cost, s);
    return _ok(
      s.copyWith(cashPaisa: s.cashPaisa - cost)
          .withStage(stageId, st.copyWith(staff: {...st.staff, role: count + 1})),
      [_entry(LedgerType.hire, -cost, '$stageId/$role #${count + 1}', now)],
    );
  }

  CommandResult unlockStage(GameState s, String stageId, DateTime now) {
    final def = config.stage(stageId);
    if (def == null) return const Failure(FailReason.unknownId);
    if (s.stages.containsKey(stageId)) return const Failure(FailReason.alreadyUnlocked);
    final unmet = missingRequirements(s, stageId);
    if (unmet.isNotEmpty) return Failure(FailReason.requirementsNotMet, unmet: unmet);
    final cost = def.unlockCostPaisa;
    if (cost > s.cashPaisa) return _noFunds(cost, s);
    return _ok(
      s.copyWith(cashPaisa: s.cashPaisa - cost).withStage(stageId, StageState.opened(def, now)),
      [_entry(LedgerType.stageUnlock, -cost, stageId, now)],
    );
  }

  /// Free recovery action: always possible, needs no stock or money.
  CommandResult doWork(GameState s, DateTime now) {
    final readyAt = s.workReadyAt;
    if (readyAt != null && now.isBefore(readyAt)) {
      return Failure(FailReason.cooldown, retryAt: readyAt);
    }
    final pay = config.recoveryPayPaisa;
    return _ok(
      s.copyWith(cashPaisa: s.cashPaisa + pay, workReadyAt: now.add(config.recoveryCooldown)),
      [_entry(LedgerType.work, pay, 'work', now)],
    );
  }

  // ---------- helpers ----------

  static const carryUnit = 60000 * 1000; // ms per minute x milli-customers

  /// Finishes batches whose time is up and adds customers who arrived.
  StageState _refresh(GameState s, StageDef def, DateTime now) {
    final st = s.stages[def.id]!;
    final lines = {
      for (final e in st.lines.entries)
        e.key: (e.value.batchEndsAt != null && !now.isBefore(e.value.batchEndsAt!))
            ? e.value.finishBatch()
            : e.value,
    };
    final elapsedMs = now.difference(st.customersUpdatedAt).inMilliseconds;
    if (elapsedMs <= 0) return st.copyWith(lines: lines); // clock went back: no arrivals
    final perMinMilli = (customersPerMin(s, def) * 1000).round();
    final total = st.queueCarry + elapsedMs * perMinMilli;
    return st.copyWith(
      lines: lines,
      queue: math.min(config.maxQueue, st.queue + total ~/ carryUnit),
      queueCarry: total % carryUnit,
      customersUpdatedAt: now,
    );
  }

  Success _ok(GameState s, List<LedgerEntry> entries) =>
      Success(s.copyWith(revision: s.revision + 1), entries);

  Failure _noFunds(int cost, GameState s) =>
      Failure(FailReason.insufficientFunds, neededPaisa: cost, availablePaisa: s.cashPaisa);

  LedgerEntry _entry(LedgerType type, int delta, String reason, DateTime at) =>
      LedgerEntry(type: type, deltaPaisa: delta, reason: reason, at: at);
}
