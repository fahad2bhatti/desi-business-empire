import 'package:desi_business_empire/domain/leaderboard/leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final noon = DateTime(2026, 11, 23, 12);

  test('a first score is always due', () {
    expect(ScoreRules.dailyDue(null, noon), isTrue);
    expect(ScoreRules.canSendNow(null, noon), isTrue);
  });

  test('only one automatic score per calendar day', () {
    expect(ScoreRules.dailyDue(DateTime(2026, 11, 23, 1), noon), isFalse);
    expect(ScoreRules.dailyDue(DateTime(2026, 11, 22, 23, 59), noon), isTrue);
  });

  test('the manual button waits an hour', () {
    final sent = noon.subtract(const Duration(minutes: 20));
    expect(ScoreRules.cooldownLeft(sent, noon), const Duration(minutes: 40));
    expect(ScoreRules.canSendNow(sent, noon), isFalse);
    final old = noon.subtract(const Duration(hours: 2));
    expect(ScoreRules.canSendNow(old, noon), isTrue);
  });

  test('names are trimmed and must be 2 to 30 characters', () {
    expect(ScoreRules.cleanName('  Chaudhry Group '), 'Chaudhry Group');
    expect(ScoreRules.cleanName('A'), isNull);
    expect(ScoreRules.cleanName(null), isNull);
    expect(ScoreRules.cleanName('x' * 31), isNull);
  });
}
