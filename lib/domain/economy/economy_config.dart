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

class Milestone {
  const Milestone({required this.level, required this.multiplier});

  final int level;
  final int multiplier;
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

  BusinessDef? business(String id) {
    for (final b in businesses) {
      if (b.id == id) {
        return b;
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
    );
  }

  static EconomyConfig parse(String source) =>
      EconomyConfig.fromJson(jsonDecode(source) as Map<String, Object?>);
}
