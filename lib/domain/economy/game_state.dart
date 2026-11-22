import 'economy_config.dart';

/// The whole save. Immutable: every command returns a new instance.
class GameState {
  const GameState({
    required this.revision,
    required this.cashPaisa,
    required this.lastSettledAt,
    this.businesses = const {},
    this.invested = const {},
    this.properties = const {},
    this.totalEarnedPaisa = 0,
    this.taps = 0,
    this.claimedGoals = const {},
    this.lifestyle = const {},
    this.homeLevel = 0,
    this.taxDuePaisa = 0,
    this.taxPaidPaisa = 0,
    this.taxPeriodStart,
    this.taxMissed = 0,
  });

  factory GameState.newGame(EconomyConfig config, DateTime now) => GameState(
    revision: 0,
    cashPaisa: config.startCashPaisa,
    lastSettledAt: now,
    taxPeriodStart: now,
  );

  /// Increases by one with every successful command or settlement.
  final int revision;
  final int cashPaisa;

  /// Time up to which income has been paid.
  final DateTime lastSettledAt;

  /// businessId -> level (only owned businesses are present).
  final Map<String, int> businesses;

  /// businessId -> everything spent on it (price plus upgrades), for selling.
  final Map<String, int> invested;

  /// propertyId -> units owned (only owned properties are present).
  final Map<String, int> properties;

  /// Lifetime income from businesses and property.
  final int totalEarnedPaisa;

  /// Times "Work" was tapped.
  final int taps;

  /// Goals whose reward has been collected.
  final Set<String> claimedGoals;

  /// Vehicles and luxury items owned.
  final Set<String> lifestyle;

  /// Index into the config's homes: where the player lives now.
  final int homeLevel;

  /// Tax built up since the last return, not paid yet.
  final int taxDuePaisa;

  /// Lifetime tax paid.
  final int taxPaidPaisa;

  /// When the current tax period began (the last return, or the start).
  /// Null in saves from before tax; treat as [lastSettledAt].
  final DateTime? taxPeriodStart;

  /// Return deadlines missed since the last return.
  final int taxMissed;

  int level(String businessId) => businesses[businessId] ?? 0;
  int owned(String propertyId) => properties[propertyId] ?? 0;

  GameState copyWith({
    int? revision,
    int? cashPaisa,
    DateTime? lastSettledAt,
    Map<String, int>? businesses,
    Map<String, int>? invested,
    Map<String, int>? properties,
    int? totalEarnedPaisa,
    int? taps,
    Set<String>? claimedGoals,
    Set<String>? lifestyle,
    int? homeLevel,
    int? taxDuePaisa,
    int? taxPaidPaisa,
    DateTime? taxPeriodStart,
    int? taxMissed,
  }) => GameState(
    revision: revision ?? this.revision,
    cashPaisa: cashPaisa ?? this.cashPaisa,
    lastSettledAt: lastSettledAt ?? this.lastSettledAt,
    businesses: businesses ?? this.businesses,
    invested: invested ?? this.invested,
    properties: properties ?? this.properties,
    totalEarnedPaisa: totalEarnedPaisa ?? this.totalEarnedPaisa,
    taps: taps ?? this.taps,
    claimedGoals: claimedGoals ?? this.claimedGoals,
    lifestyle: lifestyle ?? this.lifestyle,
    homeLevel: homeLevel ?? this.homeLevel,
    taxDuePaisa: taxDuePaisa ?? this.taxDuePaisa,
    taxPaidPaisa: taxPaidPaisa ?? this.taxPaidPaisa,
    taxPeriodStart: taxPeriodStart ?? this.taxPeriodStart,
    taxMissed: taxMissed ?? this.taxMissed,
  );
}
