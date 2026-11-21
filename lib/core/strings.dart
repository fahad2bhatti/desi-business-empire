import 'money.dart';

/// Every player-facing string, in English. Kept in one file so a Roman Urdu
/// set can be added later without touching the screens.
abstract final class S {
  // ---------- general ----------
  static const appName = 'Desi Business Empire';
  static String walletLabel(String amount, String income) =>
      'Cash $amount virtual PKR, earning $income a second';
  static const notRealMoney =
      'Game money only. It is not real and cannot be withdrawn or sold.';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const tryAgain = 'Try again';
  static String perSecond(String amount) => '+$amount/s';

  // ---------- tabs ----------
  static const tabEmpire = 'Empire';
  static const tabBusinesses = 'Businesses';
  static const tabProperty = 'Property';
  static const tabMore = 'More';

  // ---------- save / load ----------
  static const saveProblem =
      'Saving failed. Buying and selling are paused until it works again.';
  static const saveFailedToast =
      'Could not save. Tap "Try again" in the banner.';
  static const restoredFromBackup =
      'Your last save was damaged, so it was restored from a backup.';
  static const loadFailedTitle = 'The game could not load';
  static const corruptTitle = 'Your save cannot be read';
  static const corruptBody =
      'Your save and both backups are damaged. Starting a new game erases your old progress.';
  static const startNewGame = 'Start a new game';
  static const sureTitle = 'Erase all progress?';
  static const sureBody = 'This cannot be undone.';
  static const keepIt = 'Keep it';
  static const eraseAndStart = 'Erase and start over';

  // ---------- empire ----------
  static const netWorth = 'Net worth';
  static const work = 'Work';
  static String workPay(String pay) => 'Tap to earn $pay';
  static const businessesOwned = 'Businesses';
  static const propertiesOwned = 'Property units';
  static const lifetimeEarned = 'Earned so far';
  static const nextBuy = 'Next to buy';
  static String saveUpFor(String name) => 'Save up for $name';
  static String earnsPerSecond(String amount) => 'Earns $amount every second';
  static const everythingBought = 'You own every business. Keep upgrading.';
  static const quickActions = 'Quick actions';
  static const upgradeBest = 'Best upgrade';
  static String upgradeBestDetail(String name, String cost, String gain) =>
      '$name for $cost, $gain more a second';
  static const nothingToUpgrade = 'Buy a business to start upgrading';

  // ---------- businesses ----------
  static String level(int n, int max) => 'Level $n / $max';
  static String nextBonus(int level, int mult) =>
      'x$mult income at level $level';
  static const allBonuses = 'All bonuses reached';
  static String buyFor(String price) => 'Buy · $price';
  static String upgradeFor(String price) => 'Upgrade · $price';
  static const upgradeMax = 'Upgrade max';
  static const maxed = 'Max level';
  static String plusIncome(String amount) => '+$amount/s';
  static String earnsAtLevel1(String amount) => 'Earns $amount/s at level 1';
  static const sell = 'Sell';
  static String sellTitle(String name) => 'Sell $name?';
  static String sellBody(String value) =>
      'You get $value back, half of everything you spent on it. It stops earning right away.';
  static const keep = 'Keep';
  static String sold(String name, String value) => '$name sold for $value';
  static String locked(String progress) => '$progress of the price saved';

  // ---------- property ----------
  static const propertyIntro =
      'Property pays rent every second. Each unit costs more than the last.';
  static String ownedUnits(int n, int max) => 'Owned $n / $max';
  static String rentEach(String amount) => '$amount/s rent each';
  static String rentTotal(String amount) => '$amount/s total';
  static const allUnitsOwned = 'All units owned';
  static String sellUnitTitle(String name) => 'Sell one $name?';
  static String sellUnitBody(String value) =>
      'You get $value back for one unit.';

  // ---------- offline ----------
  static const whileAway = 'While you were away';
  static String awayFor(String d) => 'You were away for $d.';
  static String creditedUpTo(String d) =>
      'Your businesses earned for the first $d.';
  static const earned = 'Earned';
  static const alreadyAdded = 'Already added to your cash.';
  static const collect = 'Nice';
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) {
      return '$m min';
    }
    return m == 0 ? '$h h' : '$h h $m min';
  }

  // ---------- onboarding ----------
  static const welcomeTitle = 'Build your empire';
  static const welcomeBody =
      'Start with nothing but your hands. Work for your first samosa thela, let it earn while you rest, '
      'upgrade it, and grow into shops, companies and property across the city.';
  static const businessNameLabel = 'Name your empire';
  static const businessNameHelp =
      'Any name works. You can change it later in More.';
  static const defaultEmpireName = 'Chaudhry Group';
  static const nameTooShort = 'Use at least 2 characters';
  static const nameTooLong = 'Use at most 30 characters';
  static const start = 'Start';
  static const tutorialStep1 = 'Step 1 of 3 · Work';
  static const tutorialBody1 =
      'Tap Work on the Empire tab to earn your first rupees.';
  static const tutorialStep2 = 'Step 2 of 3 · Your first business';
  static const tutorialBody2 =
      'Open Businesses and buy the Samosa Thela. It earns on its own, even while you are away.';
  static const tutorialStep3 = 'Step 3 of 3 · Upgrade';
  static const tutorialBody3 =
      'Upgrade the thela. Every level adds income, and big levels double it.';
  static const openBusinesses = 'Open Businesses';
  static const skipTutorial = 'Skip';
  static const tutorialDone = 'Tutorial complete. Now grow your empire.';

  // ---------- more ----------
  static const moreTitle = 'More';
  static const accounts = 'Accounts';
  static const accountsSubtitle = 'Cash and recent entries';
  static const empireName = 'Empire name';
  static const defaultName = 'My Empire';
  static const sound = 'Sound';
  static const soundSubtitle = 'Sounds arrive in a later update';
  static const vibration = 'Vibration';
  static const vibrationSubtitle = 'A light tap when an action works';
  static const replayTutorial = 'Replay tutorial';
  static const privacy = 'Privacy';
  static const privacyBody =
      'All data stays on this phone. No account, ads or tracking.';
  static const saveStatus = 'Save';
  static String saveOk(int revision) => 'Saved · revision $revision';
  static const resetGame = 'Reset game';
  static const resetSubtitle = 'Erases all progress';
  static const resetTitle = 'Reset the game?';
  static const resetBody =
      'Cash, businesses and property will all be erased. This cannot be undone.';
  static const reset = 'Reset';
  static const resetAgainTitle = 'Are you sure?';
  static const resetAgainBody = 'All progress will be erased for good.';
  static const eraseEverything = 'Erase everything';

  // ---------- accounts ----------
  static const cash = 'Cash';
  static const incomeNow = 'Income now';
  static const recentEntries = 'Recent entries';
  static const noEntries = 'No entries yet. Tap Work to get started.';
  static const entryWork = 'Work';
  static const entryBuyBusiness = 'Bought business';
  static const entryUpgrade = 'Upgrade';
  static const entrySellBusiness = 'Sold business';
  static const entryBuyProperty = 'Bought property';
  static const entrySellProperty = 'Sold property';
  static const entryIncome = 'Income';
  static String ago(Duration d) {
    if (d.inMinutes < 1) {
      return 'just now';
    }
    if (d.inHours < 1) {
      return '${d.inMinutes} min ago';
    }
    return '${d.inHours} h ago';
  }

  // ---------- refusals ----------
  static String notEnoughMoney(int needed, int available) =>
      'Not enough cash: ${formatShort(needed)} needed, you have ${formatShort(available)}';
  static const alreadyOwned = 'You already own this';
  static const notOwned = 'You do not own this';
  static const maxLevelReached = 'Already at max level';
  static const maxOwnedReached = 'You own every unit';
  static const somethingWrong = 'Something went wrong';
}
