import 'economy_config.dart';

/// Returns every problem found; an empty list means the config is usable.
List<String> validateConfig(EconomyConfig c) {
  final errors = <String>[];
  void check(bool ok, String message) {
    if (!ok) {
      errors.add(message);
    }
  }

  check(c.startCashPaisa >= 0, 'startCash is negative');
  check(c.offlineCapMinutes > 0, 'offlineCapMinutes must be > 0');
  check(c.workPayPaisa > 0, 'workPay must be > 0');
  check(c.maxLevel >= 1, 'maxLevel must be >= 1');
  check(c.upgradeBase > 0, 'upgradeCost.base must be > 0');
  check(c.upgradeGrowth >= 1, 'upgradeCost.growth must be >= 1');
  check(
    c.businessSellRefund > 0 && c.businessSellRefund <= 1,
    'businessSellRefund must be in (0, 1]',
  );
  check(
    c.propertySellRefund > 0 && c.propertySellRefund <= 1,
    'propertySellRefund must be in (0, 1]',
  );
  check(c.propertyPriceGrowth >= 1, 'propertyPriceGrowth must be >= 1');

  var lastLevel = 0;
  for (final m in c.milestones) {
    check(m.level > lastLevel, 'milestone levels must ascend (at ${m.level})');
    check(m.level <= c.maxLevel, 'milestone ${m.level} is above maxLevel');
    check(m.multiplier >= 1, 'milestone ${m.level} multiplier must be >= 1');
    lastLevel = m.level;
  }

  final categoryIds = <String>{};
  for (final cat in c.categories) {
    check(categoryIds.add(cat.id), 'category ${cat.id}: duplicate id');
  }

  final ids = <String>{};
  for (final b in c.businesses) {
    final where = 'business ${b.id}';
    check(ids.add(b.id), '$where: duplicate id');
    check(
      categoryIds.contains(b.categoryId),
      '$where: unknown category ${b.categoryId}',
    );
    check(b.pricePaisa > 0, '$where: price must be > 0');
    check(b.incomePaisaPerSec > 0, '$where: income must be > 0');
  }
  check(c.businesses.isNotEmpty, 'no businesses');

  for (final p in c.properties) {
    final where = 'property ${p.id}';
    check(ids.add(p.id), '$where: duplicate id');
    check(p.pricePaisa > 0, '$where: price must be > 0');
    check(p.rentPaisaPerSec > 0, '$where: rent must be > 0');
    check(p.maxOwned >= 1, '$where: maxOwned must be >= 1');
  }
  return errors;
}
