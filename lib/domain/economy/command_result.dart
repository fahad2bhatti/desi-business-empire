import 'game_state.dart';

enum LedgerType {
  work,
  buyBusiness,
  upgrade,
  sellBusiness,
  buyProperty,
  sellProperty,
  income,
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

  /// Short machine-readable reason, e.g. `samosa L2`.
  final String reason;
  final DateTime at;
}

enum FailReason {
  unknownId,
  invalidQuantity,
  insufficientFunds,
  alreadyOwned,
  notOwned,
  maxLevel,
  maxOwned,
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
  const Failure(this.reason, {this.neededPaisa, this.availablePaisa});

  final FailReason reason;

  /// Set for [FailReason.insufficientFunds].
  final int? neededPaisa;
  final int? availablePaisa;
}
