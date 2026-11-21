// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SaveSlotsTable extends SaveSlots
    with TableInfo<$SaveSlotsTable, SaveSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaveSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configVersionMeta = const VerificationMeta(
    'configVersion',
  );
  @override
  late final GeneratedColumn<int> configVersion = GeneratedColumn<int>(
    'config_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    slot,
    schemaVersion,
    configVersion,
    revision,
    data,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'save_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaveSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('config_version')) {
      context.handle(
        _configVersionMeta,
        configVersion.isAcceptableOrUnknown(
          data['config_version']!,
          _configVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configVersionMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slot};
  @override
  SaveSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaveSlot(
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      configVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}config_version'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SaveSlotsTable createAlias(String alias) {
    return $SaveSlotsTable(attachedDatabase, alias);
  }
}

class SaveSlot extends DataClass implements Insertable<SaveSlot> {
  final String slot;
  final int schemaVersion;
  final int configVersion;
  final int revision;
  final String data;
  final DateTime savedAt;
  const SaveSlot({
    required this.slot,
    required this.schemaVersion,
    required this.configVersion,
    required this.revision,
    required this.data,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot'] = Variable<String>(slot);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['config_version'] = Variable<int>(configVersion);
    map['revision'] = Variable<int>(revision);
    map['data'] = Variable<String>(data);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SaveSlotsCompanion toCompanion(bool nullToAbsent) {
    return SaveSlotsCompanion(
      slot: Value(slot),
      schemaVersion: Value(schemaVersion),
      configVersion: Value(configVersion),
      revision: Value(revision),
      data: Value(data),
      savedAt: Value(savedAt),
    );
  }

  factory SaveSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaveSlot(
      slot: serializer.fromJson<String>(json['slot']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      configVersion: serializer.fromJson<int>(json['configVersion']),
      revision: serializer.fromJson<int>(json['revision']),
      data: serializer.fromJson<String>(json['data']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slot': serializer.toJson<String>(slot),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'configVersion': serializer.toJson<int>(configVersion),
      'revision': serializer.toJson<int>(revision),
      'data': serializer.toJson<String>(data),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SaveSlot copyWith({
    String? slot,
    int? schemaVersion,
    int? configVersion,
    int? revision,
    String? data,
    DateTime? savedAt,
  }) => SaveSlot(
    slot: slot ?? this.slot,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    configVersion: configVersion ?? this.configVersion,
    revision: revision ?? this.revision,
    data: data ?? this.data,
    savedAt: savedAt ?? this.savedAt,
  );
  SaveSlot copyWithCompanion(SaveSlotsCompanion data) {
    return SaveSlot(
      slot: data.slot.present ? data.slot.value : this.slot,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      configVersion: data.configVersion.present
          ? data.configVersion.value
          : this.configVersion,
      revision: data.revision.present ? data.revision.value : this.revision,
      data: data.data.present ? data.data.value : this.data,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaveSlot(')
          ..write('slot: $slot, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('configVersion: $configVersion, ')
          ..write('revision: $revision, ')
          ..write('data: $data, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(slot, schemaVersion, configVersion, revision, data, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaveSlot &&
          other.slot == this.slot &&
          other.schemaVersion == this.schemaVersion &&
          other.configVersion == this.configVersion &&
          other.revision == this.revision &&
          other.data == this.data &&
          other.savedAt == this.savedAt);
}

class SaveSlotsCompanion extends UpdateCompanion<SaveSlot> {
  final Value<String> slot;
  final Value<int> schemaVersion;
  final Value<int> configVersion;
  final Value<int> revision;
  final Value<String> data;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SaveSlotsCompanion({
    this.slot = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.configVersion = const Value.absent(),
    this.revision = const Value.absent(),
    this.data = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaveSlotsCompanion.insert({
    required String slot,
    required int schemaVersion,
    required int configVersion,
    required int revision,
    required String data,
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : slot = Value(slot),
       schemaVersion = Value(schemaVersion),
       configVersion = Value(configVersion),
       revision = Value(revision),
       data = Value(data),
       savedAt = Value(savedAt);
  static Insertable<SaveSlot> custom({
    Expression<String>? slot,
    Expression<int>? schemaVersion,
    Expression<int>? configVersion,
    Expression<int>? revision,
    Expression<String>? data,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slot != null) 'slot': slot,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (configVersion != null) 'config_version': configVersion,
      if (revision != null) 'revision': revision,
      if (data != null) 'data': data,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaveSlotsCompanion copyWith({
    Value<String>? slot,
    Value<int>? schemaVersion,
    Value<int>? configVersion,
    Value<int>? revision,
    Value<String>? data,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SaveSlotsCompanion(
      slot: slot ?? this.slot,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      configVersion: configVersion ?? this.configVersion,
      revision: revision ?? this.revision,
      data: data ?? this.data,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (configVersion.present) {
      map['config_version'] = Variable<int>(configVersion.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaveSlotsCompanion(')
          ..write('slot: $slot, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('configVersion: $configVersion, ')
          ..write('revision: $revision, ')
          ..write('data: $data, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerRowsTable extends LedgerRows
    with TableInfo<$LedgerRowsTable, LedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idxMeta = const VerificationMeta('idx');
  @override
  late final GeneratedColumn<int> idx = GeneratedColumn<int>(
    'idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deltaPaisaMeta = const VerificationMeta(
    'deltaPaisa',
  );
  @override
  late final GeneratedColumn<int> deltaPaisa = GeneratedColumn<int>(
    'delta_paisa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    revision,
    idx,
    type,
    deltaPaisa,
    reason,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('idx')) {
      context.handle(
        _idxMeta,
        idx.isAcceptableOrUnknown(data['idx']!, _idxMeta),
      );
    } else if (isInserting) {
      context.missing(_idxMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('delta_paisa')) {
      context.handle(
        _deltaPaisaMeta,
        deltaPaisa.isAcceptableOrUnknown(data['delta_paisa']!, _deltaPaisaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaPaisaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {revision, idx};
  @override
  LedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerRow(
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      idx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idx'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      deltaPaisa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta_paisa'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $LedgerRowsTable createAlias(String alias) {
    return $LedgerRowsTable(attachedDatabase, alias);
  }
}

class LedgerRow extends DataClass implements Insertable<LedgerRow> {
  final int revision;
  final int idx;
  final String type;
  final int deltaPaisa;
  final String reason;
  final DateTime at;
  const LedgerRow({
    required this.revision,
    required this.idx,
    required this.type,
    required this.deltaPaisa,
    required this.reason,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['revision'] = Variable<int>(revision);
    map['idx'] = Variable<int>(idx);
    map['type'] = Variable<String>(type);
    map['delta_paisa'] = Variable<int>(deltaPaisa);
    map['reason'] = Variable<String>(reason);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  LedgerRowsCompanion toCompanion(bool nullToAbsent) {
    return LedgerRowsCompanion(
      revision: Value(revision),
      idx: Value(idx),
      type: Value(type),
      deltaPaisa: Value(deltaPaisa),
      reason: Value(reason),
      at: Value(at),
    );
  }

  factory LedgerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerRow(
      revision: serializer.fromJson<int>(json['revision']),
      idx: serializer.fromJson<int>(json['idx']),
      type: serializer.fromJson<String>(json['type']),
      deltaPaisa: serializer.fromJson<int>(json['deltaPaisa']),
      reason: serializer.fromJson<String>(json['reason']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'revision': serializer.toJson<int>(revision),
      'idx': serializer.toJson<int>(idx),
      'type': serializer.toJson<String>(type),
      'deltaPaisa': serializer.toJson<int>(deltaPaisa),
      'reason': serializer.toJson<String>(reason),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  LedgerRow copyWith({
    int? revision,
    int? idx,
    String? type,
    int? deltaPaisa,
    String? reason,
    DateTime? at,
  }) => LedgerRow(
    revision: revision ?? this.revision,
    idx: idx ?? this.idx,
    type: type ?? this.type,
    deltaPaisa: deltaPaisa ?? this.deltaPaisa,
    reason: reason ?? this.reason,
    at: at ?? this.at,
  );
  LedgerRow copyWithCompanion(LedgerRowsCompanion data) {
    return LedgerRow(
      revision: data.revision.present ? data.revision.value : this.revision,
      idx: data.idx.present ? data.idx.value : this.idx,
      type: data.type.present ? data.type.value : this.type,
      deltaPaisa: data.deltaPaisa.present
          ? data.deltaPaisa.value
          : this.deltaPaisa,
      reason: data.reason.present ? data.reason.value : this.reason,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerRow(')
          ..write('revision: $revision, ')
          ..write('idx: $idx, ')
          ..write('type: $type, ')
          ..write('deltaPaisa: $deltaPaisa, ')
          ..write('reason: $reason, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(revision, idx, type, deltaPaisa, reason, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerRow &&
          other.revision == this.revision &&
          other.idx == this.idx &&
          other.type == this.type &&
          other.deltaPaisa == this.deltaPaisa &&
          other.reason == this.reason &&
          other.at == this.at);
}

class LedgerRowsCompanion extends UpdateCompanion<LedgerRow> {
  final Value<int> revision;
  final Value<int> idx;
  final Value<String> type;
  final Value<int> deltaPaisa;
  final Value<String> reason;
  final Value<DateTime> at;
  final Value<int> rowid;
  const LedgerRowsCompanion({
    this.revision = const Value.absent(),
    this.idx = const Value.absent(),
    this.type = const Value.absent(),
    this.deltaPaisa = const Value.absent(),
    this.reason = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerRowsCompanion.insert({
    required int revision,
    required int idx,
    required String type,
    required int deltaPaisa,
    required String reason,
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : revision = Value(revision),
       idx = Value(idx),
       type = Value(type),
       deltaPaisa = Value(deltaPaisa),
       reason = Value(reason),
       at = Value(at);
  static Insertable<LedgerRow> custom({
    Expression<int>? revision,
    Expression<int>? idx,
    Expression<String>? type,
    Expression<int>? deltaPaisa,
    Expression<String>? reason,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (revision != null) 'revision': revision,
      if (idx != null) 'idx': idx,
      if (type != null) 'type': type,
      if (deltaPaisa != null) 'delta_paisa': deltaPaisa,
      if (reason != null) 'reason': reason,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerRowsCompanion copyWith({
    Value<int>? revision,
    Value<int>? idx,
    Value<String>? type,
    Value<int>? deltaPaisa,
    Value<String>? reason,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return LedgerRowsCompanion(
      revision: revision ?? this.revision,
      idx: idx ?? this.idx,
      type: type ?? this.type,
      deltaPaisa: deltaPaisa ?? this.deltaPaisa,
      reason: reason ?? this.reason,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (idx.present) {
      map['idx'] = Variable<int>(idx.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (deltaPaisa.present) {
      map['delta_paisa'] = Variable<int>(deltaPaisa.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerRowsCompanion(')
          ..write('revision: $revision, ')
          ..write('idx: $idx, ')
          ..write('type: $type, ')
          ..write('deltaPaisa: $deltaPaisa, ')
          ..write('reason: $reason, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SaveSlotsTable saveSlots = $SaveSlotsTable(this);
  late final $LedgerRowsTable ledgerRows = $LedgerRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [saveSlots, ledgerRows];
}

typedef $$SaveSlotsTableCreateCompanionBuilder = SaveSlotsCompanion Function({
  required String slot,
  required int schemaVersion,
  required int configVersion,
  required int revision,
  required String data,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SaveSlotsTableUpdateCompanionBuilder = SaveSlotsCompanion Function({
  Value<String> slot,
  Value<int> schemaVersion,
  Value<int> configVersion,
  Value<int> revision,
  Value<String> data,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SaveSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $SaveSlotsTable> {
  $$SaveSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get configVersion => $composableBuilder(
    column: $table.configVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SaveSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaveSlotsTable> {
  $$SaveSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get configVersion => $composableBuilder(
    column: $table.configVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SaveSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaveSlotsTable> {
  $$SaveSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get configVersion => $composableBuilder(
    column: $table.configVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SaveSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaveSlotsTable,
          SaveSlot,
          $$SaveSlotsTableFilterComposer,
          $$SaveSlotsTableOrderingComposer,
          $$SaveSlotsTableAnnotationComposer,
          $$SaveSlotsTableCreateCompanionBuilder,
          $$SaveSlotsTableUpdateCompanionBuilder,
          (SaveSlot, BaseReferences<_$AppDatabase, $SaveSlotsTable, SaveSlot>),
          SaveSlot,
          PrefetchHooks Function()
        > {
  $$SaveSlotsTableTableManager(_$AppDatabase db, $SaveSlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaveSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaveSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaveSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slot = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> configVersion = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaveSlotsCompanion(
                slot: slot,
                schemaVersion: schemaVersion,
                configVersion: configVersion,
                revision: revision,
                data: data,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slot,
                required int schemaVersion,
                required int configVersion,
                required int revision,
                required String data,
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SaveSlotsCompanion.insert(
                slot: slot,
                schemaVersion: schemaVersion,
                configVersion: configVersion,
                revision: revision,
                data: data,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SaveSlotsTable, SaveSlot>(table),
                  BaseReferences<_$AppDatabase, $SaveSlotsTable, SaveSlot>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SaveSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaveSlotsTable,
      SaveSlot,
      $$SaveSlotsTableFilterComposer,
      $$SaveSlotsTableOrderingComposer,
      $$SaveSlotsTableAnnotationComposer,
      $$SaveSlotsTableCreateCompanionBuilder,
      $$SaveSlotsTableUpdateCompanionBuilder,
      (SaveSlot, BaseReferences<_$AppDatabase, $SaveSlotsTable, SaveSlot>),
      SaveSlot,
      PrefetchHooks Function()
    >;
typedef $$LedgerRowsTableCreateCompanionBuilder = LedgerRowsCompanion Function({
  required int revision,
  required int idx,
  required String type,
  required int deltaPaisa,
  required String reason,
  required DateTime at,
  Value<int> rowid,
});
typedef $$LedgerRowsTableUpdateCompanionBuilder = LedgerRowsCompanion Function({
  Value<int> revision,
  Value<int> idx,
  Value<String> type,
  Value<int> deltaPaisa,
  Value<String> reason,
  Value<DateTime> at,
  Value<int> rowid,
});

class $$LedgerRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerRowsTable> {
  $$LedgerRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deltaPaisa => $composableBuilder(
    column: $table.deltaPaisa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LedgerRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerRowsTable> {
  $$LedgerRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deltaPaisa => $composableBuilder(
    column: $table.deltaPaisa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerRowsTable> {
  $$LedgerRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get idx =>
      $composableBuilder(column: $table.idx, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get deltaPaisa => $composableBuilder(
    column: $table.deltaPaisa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$LedgerRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerRowsTable,
          LedgerRow,
          $$LedgerRowsTableFilterComposer,
          $$LedgerRowsTableOrderingComposer,
          $$LedgerRowsTableAnnotationComposer,
          $$LedgerRowsTableCreateCompanionBuilder,
          $$LedgerRowsTableUpdateCompanionBuilder,
          (
            LedgerRow,
            BaseReferences<_$AppDatabase, $LedgerRowsTable, LedgerRow>,
          ),
          LedgerRow,
          PrefetchHooks Function()
        > {
  $$LedgerRowsTableTableManager(_$AppDatabase db, $LedgerRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> revision = const Value.absent(),
                Value<int> idx = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> deltaPaisa = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerRowsCompanion(
                revision: revision,
                idx: idx,
                type: type,
                deltaPaisa: deltaPaisa,
                reason: reason,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int revision,
                required int idx,
                required String type,
                required int deltaPaisa,
                required String reason,
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => LedgerRowsCompanion.insert(
                revision: revision,
                idx: idx,
                type: type,
                deltaPaisa: deltaPaisa,
                reason: reason,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerRowsTable, LedgerRow>(table),
                  BaseReferences<_$AppDatabase, $LedgerRowsTable, LedgerRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerRowsTable,
      LedgerRow,
      $$LedgerRowsTableFilterComposer,
      $$LedgerRowsTableOrderingComposer,
      $$LedgerRowsTableAnnotationComposer,
      $$LedgerRowsTableCreateCompanionBuilder,
      $$LedgerRowsTableUpdateCompanionBuilder,
      (LedgerRow, BaseReferences<_$AppDatabase, $LedgerRowsTable, LedgerRow>),
      LedgerRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SaveSlotsTableTableManager get saveSlots =>
      $$SaveSlotsTableTableManager(_db, _db.saveSlots);
  $$LedgerRowsTableTableManager get ledgerRows =>
      $$LedgerRowsTableTableManager(_db, _db.ledgerRows);
}
