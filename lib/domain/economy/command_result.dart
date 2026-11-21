import 'game_state.dart';

enum LedgerType {
  stockPurchase,
  sale,
  upgrade,
  hire,
  stageUnlock,
  work,
  wages,
  rent,
}

/// One money movement. The repository stores these with the new state in
/// the same database transaction.
class LedgerEntry {
  const LedgerEntry({
    required this.type,
    required this.deltaPaisa,
    required this.reason,
    required this.at,
  });

  final LedgerType type;

  /// Positive = money in, negative = money out.
  final int deltaPaisa;

  /// Short machine-readable reason, e.g. `stall/samosa x10`.
  final String reason;
  final DateTime at;
}

enum FailReason {
  unknownId,
  invalidQuantity,
  stageLocked,
  alreadyUnlocked,
  insufficientFunds,
  storageFull,
  noStock,
  batchInProgress,
  nothingReady,
  noCustomer,
  maxLevel,
  maxStaff,
  requirementsNotMet,
  cooldown,
}

enum RequirementKind { sold, upgrade, staff }

/// One unmet condition, so the UI can show "312 / 300" instead of only a
/// disabled button.
class UnmetRequirement {
  const UnmetRequirement({
    required this.kind,
    required this.target,
    required this.have,
    required this.need,
    this.role,
  });

  final RequirementKind kind;

  /// Stage id (sold, staff) or upgrade id.
  final String target;
  final String? role;
  final int have;
  final int need;
}

sealed class CommandResult {
  const CommandResult();
}

final class Success extends CommandResult {
  const Success(this.state, this.entries);

  final GameState state;
  final List<LedgerEntry> entries;
}

final class Failure extends CommandResult {
  const Failure(
    this.reason, {
    this.neededPaisa,
    this.availablePaisa,
    this.retryAt,
    this.unmet = const [],
  });

  final FailReason reason;

  /// Set for [FailReason.insufficientFunds].
  final int? neededPaisa;
  final int? availablePaisa;

  /// Set for [FailReason.cooldown].
  final DateTime? retryAt;

  /// Set for [FailReason.requirementsNotMet].
  final List<UnmetRequirement> unmet;
}
