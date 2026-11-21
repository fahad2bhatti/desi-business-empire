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
  });

  factory GameState.newGame(EconomyConfig config, DateTime now) => GameState(
    revision: 0,
    cashPaisa: config.startCashPaisa,
    lastSettledAt: now,
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
  }) => GameState(
    revision: revision ?? this.revision,
    cashPaisa: cashPaisa ?? this.cashPaisa,
    lastSettledAt: lastSettledAt ?? this.lastSettledAt,
    businesses: businesses ?? this.businesses,
    invested: invested ?? this.invested,
    properties: properties ?? this.properties,
    totalEarnedPaisa: totalEarnedPaisa ?? this.totalEarnedPaisa,
    taps: taps ?? this.taps,
  );
}
