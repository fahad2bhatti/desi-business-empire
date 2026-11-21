import 'economy_config.dart';

/// One item line inside a business (e.g. samosa at the stall).
class LineState {
  const LineState({
    this.stock = 0,
    this.ready = 0,
    this.batchSize = 0,
    this.batchEndsAt,
  });

  /// Raw ingredient kits bought, one kit makes one item.
  final int stock;

  /// Finished items waiting to be sold.
  final int ready;

  /// Items in the kadhai right now (0 when idle).
  final int batchSize;
  final DateTime? batchEndsAt;

  bool get isCooking => batchEndsAt != null;

  LineState copyWith({int? stock, int? ready}) => LineState(
        stock: stock ?? this.stock,
        ready: ready ?? this.ready,
        batchSize: batchSize,
        batchEndsAt: batchEndsAt,
      );

  LineState startBatch(int size, DateTime endsAt) => LineState(
        stock: stock - size,
        ready: ready,
        batchSize: size,
        batchEndsAt: endsAt,
      );

  LineState finishBatch() =>
      LineState(stock: stock, ready: ready + batchSize);
}

/// One unlocked business (stall, takeaway, ...).
class StageState {
  const StageState({
    required this.customersUpdatedAt,
    this.sold = 0,
    this.queue = 0,
    this.queueCarry = 0,
    this.serveCarry = 0,
    this.costCarry = 0,
    this.staff = const {},
    this.lines = const {},
  });

  factory StageState.opened(StageDef def, DateTime now) => StageState(
        customersUpdatedAt: now,
        lines: {for (final l in def.lines) l.id: const LineState()},
      );

  /// Items sold here, all lines together.
  final int sold;

  /// Customers waiting to be served.
  final int queue;

  /// Remainder of customer arrivals not yet whole (see GameEngine).
  final int queueCarry;
  final DateTime customersUpdatedAt;

  /// Remainder of helper serving not yet a whole customer (milli-customers).
  final int serveCarry;

  /// Remainder of rent + wages not yet a whole paisa (paisa x ms / 60000).
  final int costCarry;

  /// role -> count.
  final Map<String, int> staff;

  /// lineId -> state.
  final Map<String, LineState> lines;

  int staffCount(String role) => staff[role] ?? 0;

  int get totalStock => lines.values.fold(0, (sum, l) => sum + l.stock);

  StageState copyWith({
    int? sold,
    int? queue,
    int? queueCarry,
    DateTime? customersUpdatedAt,
    int? serveCarry,
    int? costCarry,
    Map<String, int>? staff,
    Map<String, LineState>? lines,
  }) =>
      StageState(
        sold: sold ?? this.sold,
        queue: queue ?? this.queue,
        queueCarry: queueCarry ?? this.queueCarry,
        customersUpdatedAt: customersUpdatedAt ?? this.customersUpdatedAt,
        serveCarry: serveCarry ?? this.serveCarry,
        costCarry: costCarry ?? this.costCarry,
        staff: staff ?? this.staff,
        lines: lines ?? this.lines,
      );

  StageState withLine(String id, LineState line) =>
      copyWith(lines: {...lines, id: line});
}

/// The whole save. Immutable: every command returns a new instance.
class GameState {
  const GameState({
    required this.revision,
    required this.cashPaisa,
    required this.upgrades,
    required this.stages,
    required this.lastSettledAt,
    this.workReadyAt,
  });

  factory GameState.newGame(EconomyConfig config, DateTime now) {
    final first = config.stages.first;
    return GameState(
      revision: 0,
      cashPaisa: config.startCashPaisa,
      upgrades: const {},
      stages: {first.id: StageState.opened(first, now)},
      lastSettledAt: now,
    );
  }

  /// Increases by one with every successful command.
  final int revision;
  final int cashPaisa;

  /// upgradeId -> level bought (missing = 0).
  final Map<String, int> upgrades;

  /// Only unlocked stages are present.
  final Map<String, StageState> stages;

  /// Time up to which wages, rent and automation have been settled.
  final DateTime lastSettledAt;

  /// When the free recovery action can be used again.
  final DateTime? workReadyAt;

  int upgradeLevel(String id) => upgrades[id] ?? 0;

  GameState copyWith({
    int? revision,
    int? cashPaisa,
    Map<String, int>? upgrades,
    Map<String, StageState>? stages,
    DateTime? lastSettledAt,
    DateTime? workReadyAt,
  }) =>
      GameState(
        revision: revision ?? this.revision,
        cashPaisa: cashPaisa ?? this.cashPaisa,
        upgrades: upgrades ?? this.upgrades,
        stages: stages ?? this.stages,
        lastSettledAt: lastSettledAt ?? this.lastSettledAt,
        workReadyAt: workReadyAt ?? this.workReadyAt,
      );

  GameState withStage(String id, StageState stage) =>
      copyWith(stages: {...stages, id: stage});
}
