import '../domain/economy/command_result.dart';
import 'strings.dart';

/// Player-facing message for a refused command.
String failureText(Failure f) => switch (f.reason) {
  FailReason.insufficientFunds => S.notEnoughMoney(
    f.neededPaisa ?? 0,
    f.availablePaisa ?? 0,
  ),
  FailReason.alreadyOwned => S.alreadyOwned,
  FailReason.notOwned => S.notOwned,
  FailReason.maxLevel => S.maxLevelReached,
  FailReason.maxOwned => S.maxOwnedReached,
  FailReason.unknownId || FailReason.invalidQuantity => S.somethingWrong,
};
