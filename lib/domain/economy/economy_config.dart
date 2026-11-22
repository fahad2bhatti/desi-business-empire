import 'dart:convert';

import '../../core/money.dart';

int _int(Object? v) => (v as num).toInt();
double _double(Object? v) => (v as num).toDouble();

class CategoryDef {
  const CategoryDef({required this.id, required this.name});

  final String id;
  final String name;
}

/// A business the player buys once and then levels up. It earns on its own.
class BusinessDef {
  const BusinessDef({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.pricePaisa,
    required this.incomePaisaPerSec,
  });

  final String id;
  final String name;
  final String categoryId;
  final int pricePaisa;

  /// Income at level 1; level n earns n times this, times milestone bonuses.
  final int incomePaisaPerSec;
}

/// Property: bought in units, each unit pays rent. Every unit costs more.
class PropertyDef {
  const PropertyDef({
    required this.id,
    required this.name,
    required this.area,
    required this.pricePaisa,
    required this.rentPaisaPerSec,
    required this.maxOwned,
  });

  final String id;
  final String name;
  final String area;
  final int pricePaisa;
  final int rentPaisaPerSec;
  final int maxOwned;
}

/// A vehicle or luxury item, owned once. Adds a permanent bonus to all
/// income.
class LifestyleDef {
  const LifestyleDef({
    required this.id,
    required this.name,
    required this.kind,
    required this.group,
    required this.pricePaisa,
    required this.incomeBonusPercent,
  });

  final String id;
  final String name;

  /// `vehicle` or `luxury`.
  final String kind;

  /// The section it is shown in: `road`, `heli`, `plane`, `luxury`, or one
  /// of the luxury sub-sections `watches`, `jewellery`, `art` and `yachts`.
  final String group;
  final int pricePaisa;
  final int incomeBonusPercent;
}

/// A place to live. The player moves up one home at a time; the current
/// home adds its bonus to all income. The first home is free.
class HomeDef {
  const HomeDef({
    required this.id,
    required this.name,
    required this.pricePaisa,
    required this.incomeBonusPercent,
  });

  final String id;
  final String name;
  final int pricePaisa;
  final int incomeBonusPercent;
}

class Milestone {
  const Milestone({required this.level, required this.multiplier});

  final int level;
  final int multiplier;
}

enum GoalType {
  taps,
  businessesOwned,
  businessLevel,
  totalLevels,
  propertyUnits,
  incomePerSecond,
  netWorth,
  lifestyleOwned,
  homeLevel,
}

/// Money goal types keep their target in paisa; the rest are counts.
const moneyGoalTypes = {GoalType.incomePerSecond, GoalType.netWorth};

/// Something to achieve for a one-time cash reward.
class GoalDef {
  const GoalDef({
    required this.id,
    required this.type,
    required this.target,
    required this.rewardPaisa,
    this.businessId,
  });

  final String id;
  final GoalType type;

  /// A count, a level, or paisa for money goals.
  final int target;
  final int rewardPaisa;

  /// Only for [GoalType.businessLevel].
  final String? businessId;
}

class EconomyConfig {
  const EconomyConfig({
    required this.version,
    required this.startCashPaisa,
    required this.offlineCapMinutes,
    required this.workPayPaisa,
    required this.maxLevel,
    required this.upgradeBase,
    required this.upgradeGrowth,
    required this.milestones,
    required this.businessSellRefund,
    required this.propertyPriceGrowth,
    required this.propertySellRefund,
    required this.categories,
    required this.businesses,
    required this.properties,
    required this.goals,
    required this.lifestyle,
    required this.lifestyleSellRefund,
    this.homes = const [],
  });

  final int version;
  final int startCashPaisa;
  final int offlineCapMinutes;

  /// Paid for one tap on "Work".
  final int workPayPaisa;
  final int maxLevel;

  /// Upgrade from level n to n+1 costs price x base x growth^(n-1).
  final double upgradeBase;
  final double upgradeGrowth;

  /// Ascending by level.
  final List<Milestone> milestones;

  /// Share of everything spent on a business returned when it is sold.
  final double businessSellRefund;
  final double propertyPriceGrowth;

  /// Share of the last unit's price returned when one unit is sold.
  final double propertySellRefund;
  final List<CategoryDef> categories;

  /// Cheapest first within each category.
  final List<BusinessDef> businesses;
  final List<PropertyDef> properties;

  /// In display order within each type.
  final List<GoalDef> goals;

  /// Cheapest first.
  final List<LifestyleDef> lifestyle;

  /// Share of the price returned when an item is sold.
  final double lifestyleSellRefund;

  /// Cheapest first; index 0 is where every player starts.
  final List<HomeDef> homes;

  BusinessDef? business(String id) {
    for (final b in businesses) {
      if (b.id == id) {
        return b;
      }
    }
    return null;
  }

  LifestyleDef? item(String id) {
    for (final i in lifestyle) {
      if (i.id == id) {
        return i;
      }
    }
    return null;
  }

  GoalDef? goal(String id) {
    for (final g in goals) {
      if (g.id == id) {
        return g;
      }
    }
    return null;
  }

  PropertyDef? property(String id) {
    for (final p in properties) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  factory EconomyConfig.fromJson(Map<String, Object?> j) {
    final upgrade = j['upgradeCost'] as Map<String, Object?>;
    return EconomyConfig(
      version: _int(j['version']),
      startCashPaisa: rupees(_int(j['startCash'])),
      offlineCapMinutes: _int(j['offlineCapMinutes']),
      workPayPaisa: rupees(_int(j['workPay'])),
      maxLevel: _int(j['maxLevel']),
      upgradeBase: _double(upgrade['base']),
      upgradeGrowth: _double(upgrade['growth']),
      milestones: [
        for (final m in (j['milestones'] as List).cast<Map<String, Object?>>())
          Milestone(level: _int(m['level']), multiplier: _int(m['multiplier'])),
      ],
      businessSellRefund: _double(j['businessSellRefund']),
      propertyPriceGrowth: _double(j['propertyPriceGrowth']),
      propertySellRefund: _double(j['propertySellRefund']),
      categories: [
        for (final c in (j['categories'] as List).cast<Map<String, Object?>>())
          CategoryDef(id: c['id'] as String, name: c['name'] as String),
      ],
      businesses: [
        for (final b in (j['businesses'] as List).cast<Map<String, Object?>>())
          BusinessDef(
            id: b['id'] as String,
            name: b['name'] as String,
            categoryId: b['category'] as String,
            pricePaisa: rupees(_int(b['price'])),
            incomePaisaPerSec: rupees(_int(b['incomePerSecond'])),
          ),
      ],
      properties: [
        for (final p in (j['properties'] as List).cast<Map<String, Object?>>())
          PropertyDef(
            id: p['id'] as String,
            name: p['name'] as String,
            area: p['area'] as String,
            pricePaisa: rupees(_int(p['price'])),
            rentPaisaPerSec: rupees(_int(p['rentPerSecond'])),
            maxOwned: _int(p['maxOwned']),
          ),
      ],
      lifestyle: [
        for (final i in ((j['lifestyle'] ?? const []) as List).cast<Map<String, Object?>>())
          LifestyleDef(
            id: i['id'] as String,
            name: i['name'] as String,
            kind: i['kind'] as String,
            group: (i['group'] ?? i['kind']) as String,
            pricePaisa: rupees(_int(i['price'])),
            incomeBonusPercent: _int(i['incomeBonusPercent']),
          ),
      ],
      lifestyleSellRefund: _double(j['lifestyleSellRefund'] ?? 0.6),
      homes: [
        for (final h in ((j['homes'] ?? const []) as List).cast<Map<String, Object?>>())
          HomeDef(
            id: h['id'] as String,
            name: h['name'] as String,
            pricePaisa: rupees(_int(h['price'])),
            incomeBonusPercent: _int(h['incomeBonusPercent']),
          ),
      ],
      goals: [
        for (final g in ((j['goals'] ?? const []) as List).cast<Map<String, Object?>>())
          _goal(g),
      ],
    );
  }

  static GoalDef _goal(Map<String, Object?> g) {
    final type = GoalType.values.byName(g['type'] as String);
    final target = _int(g['target']);
    return GoalDef(
      id: g['id'] as String,
      type: type,
      target: moneyGoalTypes.contains(type) ? rupees(target) : target,
      rewardPaisa: rupees(_int(g['reward'])),
      businessId: g['business'] as String?,
    );
  }

  static EconomyConfig parse(String source) =>
      EconomyConfig.fromJson(jsonDecode(source) as Map<String, Object?>);
}
