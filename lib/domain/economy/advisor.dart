import 'game_engine.dart';
import 'game_state.dart';
import 'goals.dart';

enum MoveKind { claimGoals, buyBusiness, upgradeBusiness, moveHome, buyItem }

/// One suggested action: what it costs and how much income it adds.
class Move {
  const Move(
    this.kind, {
    this.id,
    required this.costPaisa,
    required this.gainPaisa,
  });

  final MoveKind kind;

  /// Business or item id; null for goals and homes.
  final String? id;
  final int costPaisa;

  /// Income per second it adds, or the reward for [MoveKind.claimGoals].
  final int gainPaisa;

  /// Seconds of the new income needed to earn the cost back.
  double get payback =>
      gainPaisa <= 0 ? double.infinity : costPaisa / gainPaisa;
}

extension Advisor on GameEngine {
  /// Every move that would raise income right now, cheapest unowned first.
  List<Move> candidateMoves(GameState s) {
    final moves = <Move>[];
    for (final b in config.businesses) {
      final level = s.level(b.id);
      if (level == 0) {
        moves.add(
          Move(
            MoveKind.buyBusiness,
            id: b.id,
            costPaisa: b.pricePaisa,
            gainPaisa: businessIncome(b, 1),
          ),
        );
      } else if (level < config.maxLevel) {
        moves.add(
          Move(
            MoveKind.upgradeBusiness,
            id: b.id,
            costPaisa: upgradeCost(b, level),
            gainPaisa: businessIncome(b, level + 1) - businessIncome(b, level),
          ),
        );
      }
    }
    final base = baseIncomePerSec(s);
    final home = nextHome(s);
    if (home != null) {
      final delta = home.incomeBonusPercent - homeBonusPercent(s);
      moves.add(
        Move(
          MoveKind.moveHome,
          costPaisa: home.pricePaisa,
          gainPaisa: base * delta ~/ 100,
        ),
      );
    }
    for (final i in config.lifestyle) {
      if (!s.lifestyle.contains(i.id)) {
        moves.add(
          Move(
            MoveKind.buyItem,
            id: i.id,
            costPaisa: i.pricePaisa,
            gainPaisa: base * i.incomeBonusPercent ~/ 100,
          ),
        );
      }
    }
    return moves;
  }

  /// The single best thing to do now. Rewards waiting come first; then the
  /// affordable move that pays itself back fastest; when nothing is
  /// affordable, the cheapest move to save up for. Null when nothing is left.
  Move? nextMove(GameState s) {
    final reward = claimableRewardPaisa(s);
    if (reward > 0) {
      return Move(MoveKind.claimGoals, costPaisa: 0, gainPaisa: reward);
    }
    var moves = candidateMoves(s).where((m) => m.gainPaisa > 0).toList();
    if (moves.isEmpty) {
      return null;
    }
    // Moves above the bank card's limit cannot be bought yet.
    final allowed = moves.where((m) => cardAllows(s, m.costPaisa)).toList();
    if (allowed.isNotEmpty) {
      moves = allowed;
    }
    final affordable = moves.where((m) => m.costPaisa <= s.cashPaisa).toList();
    if (affordable.isNotEmpty) {
      affordable.sort((a, b) => a.payback.compareTo(b.payback));
      return affordable.first;
    }
    moves.sort((a, b) => a.costPaisa.compareTo(b.costPaisa));
    return moves.first;
  }

  /// The affordable business move in one category that pays back fastest:
  /// the only one that gets the focus button on the Businesses tab.
  String? bestBusinessIn(GameState s, String categoryId) {
    Move? best;
    for (final m in candidateMoves(s)) {
      if (m.kind != MoveKind.buyBusiness &&
          m.kind != MoveKind.upgradeBusiness) {
        continue;
      }
      if (config.business(m.id!)!.categoryId != categoryId ||
          m.costPaisa > s.cashPaisa ||
          !cardAllows(s, m.costPaisa)) {
        continue;
      }
      if (best == null || m.payback < best.payback) {
        best = m;
      }
    }
    return best?.id;
  }

  /// Whole seconds until [costPaisa] is affordable at the current income,
  /// or null when there is no income yet.
  int? secondsUntil(GameState s, int costPaisa) {
    final missing = costPaisa - s.cashPaisa;
    if (missing <= 0) {
      return 0;
    }
    final income = incomePerSec(s);
    return income <= 0 ? null : (missing + income - 1) ~/ income;
  }
}
