import 'dart:math' as math;

import 'command_result.dart';
import 'economy_config.dart';
import 'game_state.dart';

/// Costs past this are treated as unaffordable, so doubles never overflow
/// a 64-bit int.
const maxCostPaisa = 4000000000000000000;

int _money(double v) => v >= maxCostPaisa ? maxCostPaisa : v.round();

/// Pure idle-tycoon rules. No Flutter, no database, no wall clock: callers
/// pass `now`. A command returns [Success] with the new state (revision + 1)
/// and its ledger entries, or [Failure] and the caller keeps the old state.
/// Time-based income lives in `settlement.dart`.
class GameEngine {
  const GameEngine(this.config);

  final EconomyConfig config;

  // ---------- derived values ----------

  /// Product of every milestone reached at [level].
  int milestoneMultiplier(int level) {
    var m = 1;
    for (final ms in config.milestones) {
      if (level >= ms.level) {
        m *= ms.multiplier;
      }
    }
    return m;
  }

  /// The next milestone above [level], or null when none is left.
  Milestone? nextMilestone(int level) {
    for (final ms in config.milestones) {
      if (level < ms.level) {
        return ms;
      }
    }
    return null;
  }

  int businessIncome(BusinessDef b, int level) =>
      level <= 0 ? 0 : b.incomePaisaPerSec * level * milestoneMultiplier(level);

  /// Cost to go from [level] to [level] + 1.
  int upgradeCost(BusinessDef b, int level) => _money(
    b.pricePaisa *
        config.upgradeBase *
        math.pow(config.upgradeGrowth, level - 1).toDouble(),
  );

  /// Price of the next unit when [owned] units are already owned.
  int propertyPrice(PropertyDef p, int owned) => _money(
    p.pricePaisa * math.pow(config.propertyPriceGrowth, owned).toDouble(),
  );

  /// Money back for selling one unit when [owned] units are owned.
  int propertySellValue(PropertyDef p, int owned) => owned <= 0
      ? 0
      : (propertyPrice(p, owned - 1) * config.propertySellRefund).round();

  int businessSellValue(GameState s, String id) =>
      ((s.invested[id] ?? 0) * config.businessSellRefund).round();

  /// Total bonus from vehicles and luxury items, in percent.
  int lifestyleBonusPercent(GameState s) {
    var bonus = 0;
    for (final i in config.lifestyle) {
      if (s.lifestyle.contains(i.id)) {
        bonus += i.incomeBonusPercent;
      }
    }
    return bonus;
  }

  /// The home lived in now, or null when the config has no homes.
  HomeDef? currentHome(GameState s) =>
      s.homeLevel < config.homes.length ? config.homes[s.homeLevel] : null;

  /// The next home to move into, or null at the top of the ladder.
  HomeDef? nextHome(GameState s) => s.homeLevel + 1 < config.homes.length
      ? config.homes[s.homeLevel + 1]
      : null;

  int homeBonusPercent(GameState s) => currentHome(s)?.incomeBonusPercent ?? 0;

  /// Lifestyle items plus the current home, in percent.
  int totalBonusPercent(GameState s) =>
      lifestyleBonusPercent(s) + homeBonusPercent(s);

  int itemSellValue(LifestyleDef i) =>
      (i.pricePaisa * config.lifestyleSellRefund).round();

  /// Businesses plus rent, raised by the lifestyle and home bonus.
  int incomePerSec(GameState s) =>
      baseIncomePerSec(s) * (100 + totalBonusPercent(s)) ~/ 100;

  int baseIncomePerSec(GameState s) {
    var total = 0;
    for (final b in config.businesses) {
      total += businessIncome(b, s.level(b.id));
    }
    for (final p in config.properties) {
      total += p.rentPaisaPerSec * s.owned(p.id);
    }
    return total;
  }

  // ---------- tax ----------

  /// Income tax rate now, from the income per second.
  int incomeTaxPercent(GameState s) =>
      TaxConfig.percentFor(config.tax.incomeSlabs, incomePerSec(s));

  int purchaseTaxPercent(int pricePaisa) =>
      TaxConfig.percentFor(config.tax.purchaseSlabs, pricePaisa);

  /// Tax added to what is due when something costing [pricePaisa] is bought.
  int purchaseTax(int pricePaisa) =>
      pricePaisa * purchaseTaxPercent(pricePaisa) ~/ 100;

  DateTime taxPeriodStart(GameState s) => s.taxPeriodStart ?? s.lastSettledAt;

  /// When the next return must be filed.
  DateTime taxDeadline(GameState s) =>
      taxPeriodStart(s).add(config.tax.period);

  /// Pays everything due and starts a new tax period.
  CommandResult fileTaxReturn(GameState s, DateTime now) {
    final due = s.taxDuePaisa;
    if (due > s.cashPaisa) {
      return _noFunds(due, s);
    }
    return _ok(
      s.copyWith(
        cashPaisa: s.cashPaisa - due,
        taxDuePaisa: 0,
        taxPaidPaisa: s.taxPaidPaisa + due,
        taxPeriodStart: now,
        taxMissed: 0,
      ),
      [if (due > 0) _entry(LedgerType.tax, -due, 'return', now)],
    );
  }

  /// Cash plus what everything owned would sell for, minus tax due.
  int netWorth(GameState s) {
    var worth = s.cashPaisa - s.taxDuePaisa;
    for (final id in s.businesses.keys) {
      worth += businessSellValue(s, id);
    }
    for (final i in config.lifestyle) {
      if (s.lifestyle.contains(i.id)) {
        worth += itemSellValue(i);
      }
    }
    worth += ((currentHome(s)?.pricePaisa ?? 0) * config.lifestyleSellRefund)
        .round();
    for (final p in config.properties) {
      final n = s.owned(p.id);
      for (var i = n; i > 0; i--) {
        worth += propertySellValue(p, i);
      }
    }
    return worth;
  }

  // ---------- commands ----------

  /// One tap on "Work": always possible, needs nothing.
  CommandResult work(GameState s, DateTime now) {
    final pay = config.workPayPaisa;
    return _ok(s.copyWith(cashPaisa: s.cashPaisa + pay, taps: s.taps + 1), [
      _entry(LedgerType.work, pay, 'work', now),
    ]);
  }

  CommandResult buyBusiness(GameState s, String id, DateTime now) {
    final b = config.business(id);
    if (b == null) {
      return const Failure(FailReason.unknownId);
    }
    if (s.level(id) > 0) {
      return const Failure(FailReason.alreadyOwned);
    }
    final cost = b.pricePaisa;
    if (cost > s.cashPaisa) {
      return _noFunds(cost, s);
    }
    return _ok(
      s.copyWith(
        cashPaisa: s.cashPaisa - cost,
        taxDuePaisa: s.taxDuePaisa + purchaseTax(cost),
        businesses: {...s.businesses, id: 1},
        invested: {...s.invested, id: cost},
      ),
      [_entry(LedgerType.buyBusiness, -cost, id, now)],
    );
  }

  /// Buys up to [times] levels, as many as the cash allows (at least one).
  CommandResult upgradeBusiness(
    GameState s,
    String id,
    DateTime now, {
    int times = 1,
  }) {
    if (times < 1) {
      return const Failure(FailReason.invalidQuantity);
    }
    final b = config.business(id);
    if (b == null) {
      return const Failure(FailReason.unknownId);
    }
    var level = s.level(id);
    if (level == 0) {
      return const Failure(FailReason.notOwned);
    }
    if (level >= config.maxLevel) {
      return const Failure(FailReason.maxLevel);
    }
    final first = upgradeCost(b, level);
    if (first > s.cashPaisa) {
      return _noFunds(first, s);
    }
    var cash = s.cashPaisa;
    var spent = 0;
    for (var i = 0; i < times && level < config.maxLevel; i++) {
      final cost = upgradeCost(b, level);
      if (cost > cash) {
        break;
      }
      cash -= cost;
      spent += cost;
      level++;
    }
    return _ok(
      s.copyWith(
        cashPaisa: cash,
        taxDuePaisa: s.taxDuePaisa + purchaseTax(spent),
        businesses: {...s.businesses, id: level},
        invested: {...s.invested, id: (s.invested[id] ?? 0) + spent},
      ),
      [_entry(LedgerType.upgrade, -spent, '$id L$level', now)],
    );
  }

  CommandResult sellBusiness(GameState s, String id, DateTime now) {
    if (config.business(id) == null) {
      return const Failure(FailReason.unknownId);
    }
    if (s.level(id) == 0) {
      return const Failure(FailReason.notOwned);
    }
    final value = businessSellValue(s, id);
    return _ok(
      s.copyWith(
        cashPaisa: s.cashPaisa + value,
        businesses: {...s.businesses}..remove(id),
        invested: {...s.invested}..remove(id),
      ),
      [_entry(LedgerType.sellBusiness, value, id, now)],
    );
  }

  CommandResult buyProperty(GameState s, String id, DateTime now) {
    final p = config.property(id);
    if (p == null) {
      return const Failure(FailReason.unknownId);
    }
    final n = s.owned(id);
    if (n >= p.maxOwned) {
      return const Failure(FailReason.maxOwned);
    }
    final cost = propertyPrice(p, n);
    if (cost > s.cashPaisa) {
      return _noFunds(cost, s);
    }
    return _ok(
      s.copyWith(
        cashPaisa: s.cashPaisa - cost,
        taxDuePaisa: s.taxDuePaisa + purchaseTax(cost),
        properties: {...s.properties, id: n + 1},
      ),
      [_entry(LedgerType.buyProperty, -cost, '$id #${n + 1}', now)],
    );
  }

  CommandResult sellProperty(GameState s, String id, DateTime now) {
    final p = config.property(id);
    if (p == null) {
      return const Failure(FailReason.unknownId);
    }
    final n = s.owned(id);
    if (n == 0) {
      return const Failure(FailReason.notOwned);
    }
    final value = propertySellValue(p, n);
    final props = {...s.properties};
    if (n == 1) {
      props.remove(id);
    } else {
      props[id] = n - 1;
    }
    return _ok(s.copyWith(cashPaisa: s.cashPaisa + value, properties: props), [
      _entry(LedgerType.sellProperty, value, '$id #$n', now),
    ]);
  }

  CommandResult buyItem(GameState s, String id, DateTime now) {
    final item = config.item(id);
    if (item == null) {
      return const Failure(FailReason.unknownId);
    }
    if (s.lifestyle.contains(id)) {
      return const Failure(FailReason.alreadyOwned);
    }
    if (item.pricePaisa > s.cashPaisa) {
      return _noFunds(item.pricePaisa, s);
    }
    return _ok(
      s.copyWith(
        cashPaisa: s.cashPaisa - item.pricePaisa,
        taxDuePaisa: s.taxDuePaisa + purchaseTax(item.pricePaisa),
        lifestyle: {...s.lifestyle, id},
      ),
      [_entry(LedgerType.buyItem, -item.pricePaisa, id, now)],
    );
  }

  CommandResult sellItem(GameState s, String id, DateTime now) {
    final item = config.item(id);
    if (item == null) {
      return const Failure(FailReason.unknownId);
    }
    if (!s.lifestyle.contains(id)) {
      return const Failure(FailReason.notOwned);
    }
    final value = itemSellValue(item);
    return _ok(
      s.copyWith(
        cashPaisa: s.cashPaisa + value,
        lifestyle: {...s.lifestyle}..remove(id),
      ),
      [_entry(LedgerType.sellItem, value, id, now)],
    );
  }

  /// Moves one step up the home ladder. The old home is left behind.
  CommandResult moveHome(GameState s, DateTime now) {
    final next = nextHome(s);
    if (next == null) {
      return const Failure(FailReason.maxLevel);
    }
    if (next.pricePaisa > s.cashPaisa) {
      return _noFunds(next.pricePaisa, s);
    }
    return _ok(
      s.copyWith(
        cashPaisa: s.cashPaisa - next.pricePaisa,
        taxDuePaisa: s.taxDuePaisa + purchaseTax(next.pricePaisa),
        homeLevel: s.homeLevel + 1,
      ),
      [_entry(LedgerType.moveHome, -next.pricePaisa, next.id, now)],
    );
  }

  // ---------- helpers ----------

  Success _ok(GameState s, List<LedgerEntry> entries) =>
      Success(s.copyWith(revision: s.revision + 1), entries);

  Failure _noFunds(int cost, GameState s) => Failure(
    FailReason.insufficientFunds,
    neededPaisa: cost,
    availablePaisa: s.cashPaisa,
  );

  LedgerEntry _entry(LedgerType type, int delta, String reason, DateTime at) =>
      LedgerEntry(type: type, deltaPaisa: delta, reason: reason, at: at);
}
