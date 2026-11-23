/// One row of the online leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.netWorthPaisa,
    required this.cardId,
  });

  /// The player's anonymous account id.
  final String id;
  final String name;
  final int netWorthPaisa;
  final String cardId;
}

/// When a score may be sent. The server enforces the same one-hour gap, so
/// a broken or hacked client cannot use up the free quota.
abstract final class ScoreRules {
  static const cooldown = Duration(hours: 1);
  static const minNameLength = 2;
  static const maxNameLength = 30;

  /// True when no score went out today (the phone's calendar day).
  static bool dailyDue(DateTime? lastSent, DateTime now) {
    if (lastSent == null) {
      return true;
    }
    final a = lastSent.toLocal();
    final b = now.toLocal();
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  /// Time left before the manual "update my score" button works again.
  static Duration cooldownLeft(DateTime? lastSent, DateTime now) {
    if (lastSent == null) {
      return Duration.zero;
    }
    final left = cooldown - now.difference(lastSent);
    return left.isNegative ? Duration.zero : left;
  }

  static bool canSendNow(DateTime? lastSent, DateTime now) =>
      cooldownLeft(lastSent, now) == Duration.zero;

  /// The empire name as shown on the board, or null if it is unusable.
  static String? cleanName(String? raw) {
    final t = (raw ?? '').trim();
    if (t.length < minNameLength || t.length > maxNameLength) {
      return null;
    }
    return t;
  }
}
