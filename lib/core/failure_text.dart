import '../domain/economy/command_result.dart';
import 'money.dart';

/// Roman Urdu message for a refused command.
String failureText(Failure f, DateTime now) => switch (f.reason) {
  FailReason.insufficientFunds =>
    'Paise kam hain: ${formatRs(f.neededPaisa ?? 0)} chahiye, aap ke paas ${formatRs(f.availablePaisa ?? 0)} hain',
  FailReason.storageFull => 'Jagah nahi: saman ki peti bhari hai',
  FailReason.noStock => 'Saman nahi hai: pehle "Saman lo" dabayein',
  FailReason.batchInProgress => 'Kadhai pehle se chal rahi hai',
  FailReason.nothingReady => 'Tayyar samosa nahi: pehle "Tal do" dabayein',
  FailReason.noCustomer => 'Abhi koi customer nahi',
  FailReason.cooldown =>
    'Thora aaram: ${f.retryAt == null ? 1 : f.retryAt!.difference(now).inSeconds + 1} sec baad',
  FailReason.maxLevel => 'Ye upgrade poora ho chuka hai',
  FailReason.maxStaff => 'Is kaam ke liye mazeed log nahi rakh sakte',
  FailReason.requirementsNotMet => 'Shartein abhi poori nahi',
  FailReason.stageLocked => 'Ye karobar abhi band hai',
  FailReason.alreadyUnlocked => 'Ye pehle se khula hai',
  FailReason.unknownId || FailReason.invalidQuantity => 'Kuch ghalat ho gaya',
};
