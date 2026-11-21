import 'economy_config.dart';

/// Returns every problem found; an empty list means the config is usable.
/// Run in tests so a bad balance file never reaches a build.
List<String> validateConfig(EconomyConfig c) {
  final errors = <String>[];
  void check(bool ok, String message) {
    if (!ok) errors.add(message);
  }

  check(c.startCashPaisa >= 0, 'startCash is negative');
  check(c.offlineCapMinutes > 0, 'offlineCapMinutes must be > 0');
  check(c.maxQueue > 0, 'maxQueue must be > 0');
  check(c.recoveryPayPaisa > 0, 'recovery pay must be > 0');
  check(c.recoveryCooldown > Duration.zero, 'recovery cooldown must be > 0');
  check(c.stages.isNotEmpty, 'no stages');
  if (c.stages.isNotEmpty) {
    check(c.stages.first.unlockCostPaisa == 0, 'first stage must be free');
  }

  final seenStages = <String>{};
  for (final s in c.stages) {
    final where = 'stage ${s.id}';
    check(seenStages.add(s.id), '$where: duplicate id');
    check(s.unlockCostPaisa >= 0, '$where: negative unlockCost');
    check(s.rentPaisaPerMin >= 0, '$where: negative rent');

    // Requirements may only point at stages that come earlier (no cycles).
    final earlier = seenStages.difference({s.id});
    for (final id in s.requirements.sold.keys) {
      check(earlier.contains(id), '$where: sold requirement on unknown/later stage $id');
    }
    for (final e in s.requirements.staff.entries) {
      check(earlier.contains(e.key), '$where: staff requirement on unknown/later stage ${e.key}');
      for (final role in e.value.keys) {
        check(StaffRole.all.contains(role), '$where: unknown role $role');
      }
    }
    for (final id in s.requirements.upgrades.keys) {
      final u = c.upgrade(id);
      check(u != null, '$where: requirement on unknown upgrade $id');
      if (u != null) {
        check(earlier.contains(u.stageId), '$where: upgrade $id belongs to a later stage');
        check(s.requirements.upgrades[id]! <= u.levels.length, '$where: upgrade $id level too high');
      }
    }

    if (s.lines.isEmpty) continue; // e.g. the hall (event based), balanced later
    check(s.customersPerMin > 0, '$where: customersPerMin must be > 0');
    check(s.storage > 0, '$where: storage must be > 0');
    final lineIds = <String>{};
    var shares = 0.0;
    for (final l in s.lines) {
      final lw = '$where line ${l.id}';
      check(lineIds.add(l.id), '$lw: duplicate id');
      check(l.costPaisa >= 0, '$lw: negative cost');
      check(l.pricePaisa > l.costPaisa, '$lw: price must be above cost');
      check(l.batch > 0, '$lw: batch must be > 0');
      check(l.batchSeconds > 0, '$lw: batchSeconds must be > 0');
      check(l.share > 0, '$lw: share must be > 0');
      shares += l.share;
    }
    check((shares - 1).abs() < 0.001, '$where: line shares add up to $shares, not 1');
    for (final role in StaffRole.all) {
      final d = s.staff[role];
      check(d != null, '$where: missing staff role $role');
      if (d == null) continue;
      check(d.hirePaisa >= 0 && d.wagePaisaPerMin >= 0, '$where $role: negative money');
      check(d.max >= 1, '$where $role: max must be >= 1');
    }
    check((s.staff[StaffRole.helper]?.servePerMin ?? 0) > 0, '$where: helper must serve > 0');
  }

  final seenUpgrades = <String>{};
  for (final u in c.upgrades) {
    final where = 'upgrade ${u.id}';
    check(seenUpgrades.add(u.id), '$where: duplicate id');
    final s = c.stage(u.stageId);
    check(s != null, '$where: unknown stage ${u.stageId}');
    check(u.levels.isNotEmpty, '$where: no levels');
    if (lineEffects.contains(u.effect)) {
      check(u.lineId != null && s?.line(u.lineId!) != null, '$where: needs a valid line');
    } else {
      check(u.lineId == null, '$where: stage-wide effect must not name a line');
    }
    for (final l in u.levels) {
      check(l.costPaisa > 0, '$where: level cost must be > 0');
      check(l.value > 0, '$where: level value must be > 0');
    }
  }
  return errors;
}
