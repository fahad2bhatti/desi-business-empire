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

  /// A short wait: 45s, 12 min, 3 h 5 min, 2 days.
  static String eta(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final d = Duration(seconds: seconds);
    if (d.inHours < 1) {
      return '${d.inMinutes} min';
    }
    if (d.inDays < 1) {
      return duration(d);
    }
    return d.inDays == 1 ? '1 day' : '${d.inDays} days';
  }

  // ---------- tabs ----------
  static const tabEmpire = 'Empire';
  static const tabBusinesses = 'Businesses';
  static const tabProperty = 'Assets';
  static const property = 'Property';
  static const lifestyle = 'Lifestyle';
  static const tabHome = 'Home';
  static const tabVehicles = 'Vehicles';
  static const tabCars = 'Cars';
  static const tabBikes = 'Bikes';
  static const tabHelis = 'Helicopters';
  static const tabPlanes = 'Planes';
  static const tabLuxury = 'Luxury';
  static const watches = 'Watches';
  static const jewellery = 'Jewellery';
  static const yachts = 'Yachts';
  static const artCollection = 'Art Collection';
  static const tabMore = 'More';
  static const tabGoals = 'Goals';

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

  // ---------- next move (the focus card) ----------
  static const focusClaim = 'Collect your rewards';
  static String focusBuy(String name) => 'Buy $name';
  static String focusUpgrade(String name) => 'Upgrade $name';
  static String focusMove(String name) => 'Move to $name';
  static String focusGain(String gain, String payback) =>
      '+$gain/s income · pays back in $payback';
  static String focusWaiting(String amount) => '$amount waiting for you';
  static String readyIn(String wait) =>
      'Ready in $wait. Work to get there faster.';
  static const workToSave = 'Tap Work to save up for it.';
  static const allDone = 'You own everything. Enjoy the empire.';
  static const yourEmpire = 'Your empire';
  static String rowBusinesses(int owned, int total) => '$owned of $total owned';
  static String rowProperty(int units, String rent) =>
      units == 0 ? 'No property yet' : '$units units · $rent/s rent';
  static String rowVehicles(int owned, int total) =>
      owned == 0 ? 'No vehicles yet' : '$owned of $total owned';
  static String rowHome(String name, int percent) =>
      percent == 0 ? name : '$name · +$percent% income';

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
  static const buyShort = 'Buy';
  static const upgradeShort = 'Upgrade';
  static String categorySummary(String income, int owned, int total) =>
      'Earns $income/s · $owned of $total owned';
  static String levelIncome(int level) => 'Level $level · ';

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

  // ---------- lifestyle ----------
  static const lifestyleIntro =
      'Vehicles and luxuries raise all your income for good.';
  static String lifestyleBonus(int percent) => '+$percent% on all income';
  static String totalBonus(int percent) => 'Lifestyle bonus: +$percent% income';
  static const owned = 'Owned';
  static String sellItemTitle(String name) => 'Sell your $name?';
  static String sellItemBody(String value, int percent) =>
      'You get $value back and lose its +$percent% income bonus.';
  static const kindVehicle = 'Vehicle';
  static const kindLuxury = 'Luxury';
  static String categoryInfo(int owned, int total, int percent) =>
      '$owned of $total owned · +$percent% income';
  static String sectionBonus(String what, int percent) =>
      'Your $what add +$percent% to all income';
  static String ownedOf(int n, int total) => '$n of $total';

  // ---------- home ----------
  static const yourHome = 'Your home';
  static const allIncome = 'all income';
  static const homes = 'Homes';
  static const homeIntro =
      'A better home raises all your income. Move up one step at a time.';
  static String bonusBecomes(int percent) => 'Bonus becomes +$percent%';
  static String moveFor(String price) => 'Move · $price';
  static const youLiveHere = 'You live here';
  static const topHome = 'You live in the best home there is.';
  static String movedTo(String name) => 'Welcome to your $name';

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
  static const accountsSubtitle = 'Cash, tax and every buy and sell';
  static const empireName = 'Empire name';
  static const defaultName = 'My Empire';
  static const sound = 'Sound';
  static const soundSubtitle = 'Sounds arrive in a later update';
  static const vibration = 'Vibration';
  static const vibrationSubtitle = 'A light tap when an action works';
  static const replayTutorial = 'Replay tutorial';
  static const appearance = 'Appearance';
  static const themeDark = 'Dark';
  static const themeLight = 'Light';
  static const themeSystem = 'Phone';
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
  static const entryGoal = 'Goal reward';
  static const entryBuyItem = 'Bought lifestyle item';
  static const entrySellItem = 'Sold lifestyle item';
  static const entryMoveHome = 'Moved home';
  static const entryTax = 'Tax return';
  static const transactions = 'Buys, sells and tax';
  static const noTransactions = 'Nothing bought or sold yet.';
  static String ago(Duration d) {
    if (d.inMinutes < 1) {
      return 'just now';
    }
    if (d.inHours < 1) {
      return '${d.inMinutes} min ago';
    }
    if (d.inDays < 1) {
      return '${d.inHours} h ago';
    }
    return d.inDays == 1 ? '1 day ago' : '${d.inDays} days ago';
  }

  // ---------- tax ----------
  // ---------- bank card ----------
  static const bankCard = 'Bank card';
  static String cardShort(String card) => '$card card';
  static String needsCard(String card) => 'Needs the $card card';
  static String cardNext(String card, String need, String have) =>
      '$card card at $need (now $have)';
  static const cardTop = 'Top card reached';
  static const cardsTitle = 'Bank cards';
  static const cardsIntro =
      'Your card follows your net worth. A better card lets you buy bigger things.';
  static const cardYours = 'Your card';
  static String cardNeedsWorth(String worth) => 'Needs a net worth of $worth';
  static const cardUnlocked = 'Unlocked';
  static const cardStart = 'Where everyone starts';
  static String cardUpgraded(String card) => 'Card upgraded: $card';
  static String cardLimit(String limit) => 'Buy anything up to $limit';
  static const cardNoLimit = 'No limit on what you can buy';

  static const tax = 'Tax';
  static const taxDue = 'Tax due';
  static const taxPaid = 'Tax paid so far';
  static String taxIncomeRate(int percent) => 'Income tax now: $percent%';
  static String taxDueIn(String wait) => 'Return due in $wait';
  static String taxOverdue(int missed, int penalty) =>
      'Overdue · $missed missed · +$penalty% late fee each time';
  static String taxExplain(int hours) =>
      'Tax builds up on income and on every purchase. File a return at least every $hours hours or a late fee is added.';
  static const fileReturn = 'File return';
  static String taxFiled(String amount) => 'Return filed. Paid $amount.';
  static const taxReminderTitle = 'Tax return due';
  static String taxReminder(String due, String wait) =>
      '$due due · file within $wait';
  static String taxReminderOverdue(String due) =>
      '$due due · overdue, late fees are adding up';

  // ---------- goals ----------
  static String goalTaps(int n) => 'Tap Work $n times';
  static String goalOwn(int n) =>
      n == 1 ? 'Buy your first business' : 'Own $n businesses';
  static String goalLevel(String business, int level) =>
      'Get $business to level $level';
  static String goalTotalLevels(int n) => 'Reach $n business levels in total';
  static String goalUnits(int n) =>
      n == 1 ? 'Buy your first property' : 'Own $n property units';
  static String goalIncome(String amount) => 'Earn $amount every second';
  static String goalWorth(String amount) => 'Reach a net worth of $amount';
  static String goalLifestyle(int n) => n == 1
      ? 'Buy your first vehicle or luxury'
      : 'Own $n vehicles or luxuries';
  static String goalHome(String name) => 'Move into a $name';
  static const goalsIntro = 'Finish goals to collect cash rewards.';
  static const readyToClaim = 'Ready to collect';
  static const inProgress = 'In progress';
  static const completed = 'Completed';
  static String claimFor(String reward) => 'Collect $reward';
  static String reward(String amount) => 'Reward $amount';
  static String collected(String amount) => 'Collected $amount';
  static String goalsDone(int done, int total) => '$done of $total done';
  static const nextGoal = 'Next goal';
  static const allGoalsDone = 'Every goal is complete.';
  static String goalsReady(int n) =>
      n == 1 ? '1 reward ready' : '$n rewards ready';
  static String collectAll(String reward) => 'Collect all · $reward';

  // ---------- refusals ----------
  static String notEnoughMoney(int needed, int available) =>
      'Not enough cash: ${formatShort(needed)} needed, you have ${formatShort(available)}';
  static const alreadyOwned = 'You already own this';
  static const goalNotReached = 'Goal not reached yet';
  static const alreadyClaimed = 'Reward already collected';
  static const notOwned = 'You do not own this';
  static const maxLevelReached = 'Already at max level';
  static const maxOwnedReached = 'You own every unit';
  static const somethingWrong = 'Something went wrong';
}
