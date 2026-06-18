// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProgramsTable extends Programs with TableInfo<$ProgramsTable, Program> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Program> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Program map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Program(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }
}

class Program extends DataClass implements Insertable<Program> {
  final String id;
  final String name;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const Program({
    required this.id,
    required this.name,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      name: Value(name),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory Program.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Program(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  Program copyWith({
    String? id,
    String? name,
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => Program(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  Program copyWithCompanion(ProgramsCompanion data) {
    return Program(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Program(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAtMs, updatedAtMs, schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Program &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class ProgramsCompanion extends UpdateCompanion<Program> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramsCompanion.insert({
    required String id,
    required String name,
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<Program> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDaysTable extends WorkoutDays
    with TableInfo<$WorkoutDaysTable, WorkoutDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES programs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programId,
    name,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDay(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $WorkoutDaysTable createAlias(String alias) {
    return $WorkoutDaysTable(attachedDatabase, alias);
  }
}

class WorkoutDay extends DataClass implements Insertable<WorkoutDay> {
  final String id;
  final String programId;
  final String name;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const WorkoutDay({
    required this.id,
    required this.programId,
    required this.name,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['program_id'] = Variable<String>(programId);
    map['name'] = Variable<String>(name);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  WorkoutDaysCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDaysCompanion(
      id: Value(id),
      programId: Value(programId),
      name: Value(name),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory WorkoutDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDay(
      id: serializer.fromJson<String>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      name: serializer.fromJson<String>(json['name']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'programId': serializer.toJson<String>(programId),
      'name': serializer.toJson<String>(name),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  WorkoutDay copyWith({
    String? id,
    String? programId,
    String? name,
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => WorkoutDay(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    name: name ?? this.name,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  WorkoutDay copyWithCompanion(WorkoutDaysCompanion data) {
    return WorkoutDay(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      name: data.name.present ? data.name.value : this.name,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDay(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('name: $name, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, programId, name, createdAtMs, updatedAtMs, schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDay &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.name == this.name &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class WorkoutDaysCompanion extends UpdateCompanion<WorkoutDay> {
  final Value<String> id;
  final Value<String> programId;
  final Value<String> name;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const WorkoutDaysCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutDaysCompanion.insert({
    required String id,
    required String programId,
    required String name,
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       programId = Value(programId),
       name = Value(name),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<WorkoutDay> custom({
    Expression<String>? id,
    Expression<String>? programId,
    Expression<String>? name,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (name != null) 'name': name,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutDaysCompanion copyWith({
    Value<String>? id,
    Value<String>? programId,
    Value<String>? name,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return WorkoutDaysCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDaysCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('name: $name, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgramWorkoutDaysTable extends ProgramWorkoutDays
    with TableInfo<$ProgramWorkoutDaysTable, ProgramWorkoutDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramWorkoutDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES programs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _workoutDayIdMeta = const VerificationMeta(
    'workoutDayId',
  );
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
    'workout_day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [programId, workoutDayId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'program_workout_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramWorkoutDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
        _workoutDayIdMeta,
        workoutDayId.isAcceptableOrUnknown(
          data['workout_day_id']!,
          _workoutDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutDayIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {programId, workoutDayId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {programId, position},
  ];
  @override
  ProgramWorkoutDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramWorkoutDay(
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      workoutDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_day_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $ProgramWorkoutDaysTable createAlias(String alias) {
    return $ProgramWorkoutDaysTable(attachedDatabase, alias);
  }
}

class ProgramWorkoutDay extends DataClass
    implements Insertable<ProgramWorkoutDay> {
  final String programId;
  final String workoutDayId;
  final int position;
  const ProgramWorkoutDay({
    required this.programId,
    required this.workoutDayId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['program_id'] = Variable<String>(programId);
    map['workout_day_id'] = Variable<String>(workoutDayId);
    map['position'] = Variable<int>(position);
    return map;
  }

  ProgramWorkoutDaysCompanion toCompanion(bool nullToAbsent) {
    return ProgramWorkoutDaysCompanion(
      programId: Value(programId),
      workoutDayId: Value(workoutDayId),
      position: Value(position),
    );
  }

  factory ProgramWorkoutDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramWorkoutDay(
      programId: serializer.fromJson<String>(json['programId']),
      workoutDayId: serializer.fromJson<String>(json['workoutDayId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'programId': serializer.toJson<String>(programId),
      'workoutDayId': serializer.toJson<String>(workoutDayId),
      'position': serializer.toJson<int>(position),
    };
  }

  ProgramWorkoutDay copyWith({
    String? programId,
    String? workoutDayId,
    int? position,
  }) => ProgramWorkoutDay(
    programId: programId ?? this.programId,
    workoutDayId: workoutDayId ?? this.workoutDayId,
    position: position ?? this.position,
  );
  ProgramWorkoutDay copyWithCompanion(ProgramWorkoutDaysCompanion data) {
    return ProgramWorkoutDay(
      programId: data.programId.present ? data.programId.value : this.programId,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramWorkoutDay(')
          ..write('programId: $programId, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(programId, workoutDayId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramWorkoutDay &&
          other.programId == this.programId &&
          other.workoutDayId == this.workoutDayId &&
          other.position == this.position);
}

class ProgramWorkoutDaysCompanion extends UpdateCompanion<ProgramWorkoutDay> {
  final Value<String> programId;
  final Value<String> workoutDayId;
  final Value<int> position;
  final Value<int> rowid;
  const ProgramWorkoutDaysCompanion({
    this.programId = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramWorkoutDaysCompanion.insert({
    required String programId,
    required String workoutDayId,
    required int position,
    this.rowid = const Value.absent(),
  }) : programId = Value(programId),
       workoutDayId = Value(workoutDayId),
       position = Value(position);
  static Insertable<ProgramWorkoutDay> custom({
    Expression<String>? programId,
    Expression<String>? workoutDayId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (programId != null) 'program_id': programId,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramWorkoutDaysCompanion copyWith({
    Value<String>? programId,
    Value<String>? workoutDayId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return ProgramWorkoutDaysCompanion(
      programId: programId ?? this.programId,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramWorkoutDaysCompanion(')
          ..write('programId: $programId, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseGroupsTable extends ExerciseGroups
    with TableInfo<$ExerciseGroupsTable, ExerciseGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutDayIdMeta = const VerificationMeta(
    'workoutDayId',
  );
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
    'workout_day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_days (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindDiscriminatorMeta = const VerificationMeta(
    'kindDiscriminator',
  );
  @override
  late final GeneratedColumn<String> kindDiscriminator =
      GeneratedColumn<String>(
        'kind_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _kindPayloadJsonMeta = const VerificationMeta(
    'kindPayloadJson',
  );
  @override
  late final GeneratedColumn<String> kindPayloadJson = GeneratedColumn<String>(
    'kind_payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleDiscriminatorMeta = const VerificationMeta(
    'roleDiscriminator',
  );
  @override
  late final GeneratedColumn<String> roleDiscriminator =
      GeneratedColumn<String>(
        'role_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('main'),
      );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutDayId,
    position,
    kindDiscriminator,
    kindPayloadJson,
    roleDiscriminator,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
        _workoutDayIdMeta,
        workoutDayId.isAcceptableOrUnknown(
          data['workout_day_id']!,
          _workoutDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutDayIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('kind_discriminator')) {
      context.handle(
        _kindDiscriminatorMeta,
        kindDiscriminator.isAcceptableOrUnknown(
          data['kind_discriminator']!,
          _kindDiscriminatorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kindDiscriminatorMeta);
    }
    if (data.containsKey('kind_payload_json')) {
      context.handle(
        _kindPayloadJsonMeta,
        kindPayloadJson.isAcceptableOrUnknown(
          data['kind_payload_json']!,
          _kindPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kindPayloadJsonMeta);
    }
    if (data.containsKey('role_discriminator')) {
      context.handle(
        _roleDiscriminatorMeta,
        roleDiscriminator.isAcceptableOrUnknown(
          data['role_discriminator']!,
          _roleDiscriminatorMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workoutDayId, position},
  ];
  @override
  ExerciseGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workoutDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_day_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      kindDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind_discriminator'],
      )!,
      kindPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind_payload_json'],
      )!,
      roleDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_discriminator'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $ExerciseGroupsTable createAlias(String alias) {
    return $ExerciseGroupsTable(attachedDatabase, alias);
  }
}

class ExerciseGroup extends DataClass implements Insertable<ExerciseGroup> {
  final String id;
  final String workoutDayId;
  final int position;
  final String kindDiscriminator;
  final String kindPayloadJson;
  final String roleDiscriminator;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const ExerciseGroup({
    required this.id,
    required this.workoutDayId,
    required this.position,
    required this.kindDiscriminator,
    required this.kindPayloadJson,
    required this.roleDiscriminator,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_day_id'] = Variable<String>(workoutDayId);
    map['position'] = Variable<int>(position);
    map['kind_discriminator'] = Variable<String>(kindDiscriminator);
    map['kind_payload_json'] = Variable<String>(kindPayloadJson);
    map['role_discriminator'] = Variable<String>(roleDiscriminator);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  ExerciseGroupsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseGroupsCompanion(
      id: Value(id),
      workoutDayId: Value(workoutDayId),
      position: Value(position),
      kindDiscriminator: Value(kindDiscriminator),
      kindPayloadJson: Value(kindPayloadJson),
      roleDiscriminator: Value(roleDiscriminator),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory ExerciseGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseGroup(
      id: serializer.fromJson<String>(json['id']),
      workoutDayId: serializer.fromJson<String>(json['workoutDayId']),
      position: serializer.fromJson<int>(json['position']),
      kindDiscriminator: serializer.fromJson<String>(json['kindDiscriminator']),
      kindPayloadJson: serializer.fromJson<String>(json['kindPayloadJson']),
      roleDiscriminator: serializer.fromJson<String>(json['roleDiscriminator']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutDayId': serializer.toJson<String>(workoutDayId),
      'position': serializer.toJson<int>(position),
      'kindDiscriminator': serializer.toJson<String>(kindDiscriminator),
      'kindPayloadJson': serializer.toJson<String>(kindPayloadJson),
      'roleDiscriminator': serializer.toJson<String>(roleDiscriminator),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  ExerciseGroup copyWith({
    String? id,
    String? workoutDayId,
    int? position,
    String? kindDiscriminator,
    String? kindPayloadJson,
    String? roleDiscriminator,
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => ExerciseGroup(
    id: id ?? this.id,
    workoutDayId: workoutDayId ?? this.workoutDayId,
    position: position ?? this.position,
    kindDiscriminator: kindDiscriminator ?? this.kindDiscriminator,
    kindPayloadJson: kindPayloadJson ?? this.kindPayloadJson,
    roleDiscriminator: roleDiscriminator ?? this.roleDiscriminator,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  ExerciseGroup copyWithCompanion(ExerciseGroupsCompanion data) {
    return ExerciseGroup(
      id: data.id.present ? data.id.value : this.id,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      position: data.position.present ? data.position.value : this.position,
      kindDiscriminator: data.kindDiscriminator.present
          ? data.kindDiscriminator.value
          : this.kindDiscriminator,
      kindPayloadJson: data.kindPayloadJson.present
          ? data.kindPayloadJson.value
          : this.kindPayloadJson,
      roleDiscriminator: data.roleDiscriminator.present
          ? data.roleDiscriminator.value
          : this.roleDiscriminator,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseGroup(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('position: $position, ')
          ..write('kindDiscriminator: $kindDiscriminator, ')
          ..write('kindPayloadJson: $kindPayloadJson, ')
          ..write('roleDiscriminator: $roleDiscriminator, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutDayId,
    position,
    kindDiscriminator,
    kindPayloadJson,
    roleDiscriminator,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseGroup &&
          other.id == this.id &&
          other.workoutDayId == this.workoutDayId &&
          other.position == this.position &&
          other.kindDiscriminator == this.kindDiscriminator &&
          other.kindPayloadJson == this.kindPayloadJson &&
          other.roleDiscriminator == this.roleDiscriminator &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class ExerciseGroupsCompanion extends UpdateCompanion<ExerciseGroup> {
  final Value<String> id;
  final Value<String> workoutDayId;
  final Value<int> position;
  final Value<String> kindDiscriminator;
  final Value<String> kindPayloadJson;
  final Value<String> roleDiscriminator;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const ExerciseGroupsCompanion({
    this.id = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.position = const Value.absent(),
    this.kindDiscriminator = const Value.absent(),
    this.kindPayloadJson = const Value.absent(),
    this.roleDiscriminator = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseGroupsCompanion.insert({
    required String id,
    required String workoutDayId,
    required int position,
    required String kindDiscriminator,
    required String kindPayloadJson,
    this.roleDiscriminator = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workoutDayId = Value(workoutDayId),
       position = Value(position),
       kindDiscriminator = Value(kindDiscriminator),
       kindPayloadJson = Value(kindPayloadJson),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<ExerciseGroup> custom({
    Expression<String>? id,
    Expression<String>? workoutDayId,
    Expression<int>? position,
    Expression<String>? kindDiscriminator,
    Expression<String>? kindPayloadJson,
    Expression<String>? roleDiscriminator,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (position != null) 'position': position,
      if (kindDiscriminator != null) 'kind_discriminator': kindDiscriminator,
      if (kindPayloadJson != null) 'kind_payload_json': kindPayloadJson,
      if (roleDiscriminator != null) 'role_discriminator': roleDiscriminator,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? workoutDayId,
    Value<int>? position,
    Value<String>? kindDiscriminator,
    Value<String>? kindPayloadJson,
    Value<String>? roleDiscriminator,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return ExerciseGroupsCompanion(
      id: id ?? this.id,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      position: position ?? this.position,
      kindDiscriminator: kindDiscriminator ?? this.kindDiscriminator,
      kindPayloadJson: kindPayloadJson ?? this.kindPayloadJson,
      roleDiscriminator: roleDiscriminator ?? this.roleDiscriminator,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (kindDiscriminator.present) {
      map['kind_discriminator'] = Variable<String>(kindDiscriminator.value);
    }
    if (kindPayloadJson.present) {
      map['kind_payload_json'] = Variable<String>(kindPayloadJson.value);
    }
    if (roleDiscriminator.present) {
      map['role_discriminator'] = Variable<String>(roleDiscriminator.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseGroupsCompanion(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('position: $position, ')
          ..write('kindDiscriminator: $kindDiscriminator, ')
          ..write('kindPayloadJson: $kindPayloadJson, ')
          ..write('roleDiscriminator: $roleDiscriminator, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryExercisesTable extends LibraryExercises
    with TableInfo<$LibraryExercisesTable, LibraryExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameLowerMeta = const VerificationMeta(
    'nameLower',
  );
  @override
  late final GeneratedColumn<String> nameLower = GeneratedColumn<String>(
    'name_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementTypeDiscriminatorMeta =
      const VerificationMeta('measurementTypeDiscriminator');
  @override
  late final GeneratedColumn<String> measurementTypeDiscriminator =
      GeneratedColumn<String>(
        'measurement_type_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _measurementTypePayloadJsonMeta =
      const VerificationMeta('measurementTypePayloadJson');
  @override
  late final GeneratedColumn<String> measurementTypePayloadJson =
      GeneratedColumn<String>(
        'measurement_type_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
  );
  static const VerificationMeta _prominenceMeta = const VerificationMeta(
    'prominence',
  );
  @override
  late final GeneratedColumn<String> prominence = GeneratedColumn<String>(
    'prominence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('common'),
  );
  static const VerificationMeta _primaryMusclesJsonMeta =
      const VerificationMeta('primaryMusclesJson');
  @override
  late final GeneratedColumn<String> primaryMusclesJson =
      GeneratedColumn<String>(
        'primary_muscles_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _secondaryMusclesJsonMeta =
      const VerificationMeta('secondaryMusclesJson');
  @override
  late final GeneratedColumn<String> secondaryMusclesJson =
      GeneratedColumn<String>(
        'secondary_muscles_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cuesMeta = const VerificationMeta('cues');
  @override
  late final GeneratedColumn<String> cues = GeneratedColumn<String>(
    'cues',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMsMeta = const VerificationMeta(
    'archivedAtMs',
  );
  @override
  late final GeneratedColumn<int> archivedAtMs = GeneratedColumn<int>(
    'archived_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameLower,
    measurementTypeDiscriminator,
    measurementTypePayloadJson,
    source,
    prominence,
    primaryMusclesJson,
    secondaryMusclesJson,
    videoUrl,
    cues,
    archivedAtMs,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_lower')) {
      context.handle(
        _nameLowerMeta,
        nameLower.isAcceptableOrUnknown(data['name_lower']!, _nameLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_nameLowerMeta);
    }
    if (data.containsKey('measurement_type_discriminator')) {
      context.handle(
        _measurementTypeDiscriminatorMeta,
        measurementTypeDiscriminator.isAcceptableOrUnknown(
          data['measurement_type_discriminator']!,
          _measurementTypeDiscriminatorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementTypeDiscriminatorMeta);
    }
    if (data.containsKey('measurement_type_payload_json')) {
      context.handle(
        _measurementTypePayloadJsonMeta,
        measurementTypePayloadJson.isAcceptableOrUnknown(
          data['measurement_type_payload_json']!,
          _measurementTypePayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementTypePayloadJsonMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('prominence')) {
      context.handle(
        _prominenceMeta,
        prominence.isAcceptableOrUnknown(data['prominence']!, _prominenceMeta),
      );
    }
    if (data.containsKey('primary_muscles_json')) {
      context.handle(
        _primaryMusclesJsonMeta,
        primaryMusclesJson.isAcceptableOrUnknown(
          data['primary_muscles_json']!,
          _primaryMusclesJsonMeta,
        ),
      );
    }
    if (data.containsKey('secondary_muscles_json')) {
      context.handle(
        _secondaryMusclesJsonMeta,
        secondaryMusclesJson.isAcceptableOrUnknown(
          data['secondary_muscles_json']!,
          _secondaryMusclesJsonMeta,
        ),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('cues')) {
      context.handle(
        _cuesMeta,
        cues.isAcceptableOrUnknown(data['cues']!, _cuesMeta),
      );
    }
    if (data.containsKey('archived_at_ms')) {
      context.handle(
        _archivedAtMsMeta,
        archivedAtMs.isAcceptableOrUnknown(
          data['archived_at_ms']!,
          _archivedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_lower'],
      )!,
      measurementTypeDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_type_discriminator'],
      )!,
      measurementTypePayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_type_payload_json'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      prominence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prominence'],
      )!,
      primaryMusclesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_muscles_json'],
      )!,
      secondaryMusclesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_muscles_json'],
      )!,
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      cues: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cues'],
      ),
      archivedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at_ms'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $LibraryExercisesTable createAlias(String alias) {
    return $LibraryExercisesTable(attachedDatabase, alias);
  }
}

class LibraryExercise extends DataClass implements Insertable<LibraryExercise> {
  final String id;
  final String name;
  final String nameLower;
  final String measurementTypeDiscriminator;
  final String measurementTypePayloadJson;
  final String source;
  final String prominence;
  final String primaryMusclesJson;
  final String secondaryMusclesJson;
  final String? videoUrl;
  final String? cues;
  final int? archivedAtMs;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const LibraryExercise({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.measurementTypeDiscriminator,
    required this.measurementTypePayloadJson,
    required this.source,
    required this.prominence,
    required this.primaryMusclesJson,
    required this.secondaryMusclesJson,
    this.videoUrl,
    this.cues,
    this.archivedAtMs,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['name_lower'] = Variable<String>(nameLower);
    map['measurement_type_discriminator'] = Variable<String>(
      measurementTypeDiscriminator,
    );
    map['measurement_type_payload_json'] = Variable<String>(
      measurementTypePayloadJson,
    );
    map['source'] = Variable<String>(source);
    map['prominence'] = Variable<String>(prominence);
    map['primary_muscles_json'] = Variable<String>(primaryMusclesJson);
    map['secondary_muscles_json'] = Variable<String>(secondaryMusclesJson);
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || cues != null) {
      map['cues'] = Variable<String>(cues);
    }
    if (!nullToAbsent || archivedAtMs != null) {
      map['archived_at_ms'] = Variable<int>(archivedAtMs);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  LibraryExercisesCompanion toCompanion(bool nullToAbsent) {
    return LibraryExercisesCompanion(
      id: Value(id),
      name: Value(name),
      nameLower: Value(nameLower),
      measurementTypeDiscriminator: Value(measurementTypeDiscriminator),
      measurementTypePayloadJson: Value(measurementTypePayloadJson),
      source: Value(source),
      prominence: Value(prominence),
      primaryMusclesJson: Value(primaryMusclesJson),
      secondaryMusclesJson: Value(secondaryMusclesJson),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      cues: cues == null && nullToAbsent ? const Value.absent() : Value(cues),
      archivedAtMs: archivedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAtMs),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory LibraryExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryExercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameLower: serializer.fromJson<String>(json['nameLower']),
      measurementTypeDiscriminator: serializer.fromJson<String>(
        json['measurementTypeDiscriminator'],
      ),
      measurementTypePayloadJson: serializer.fromJson<String>(
        json['measurementTypePayloadJson'],
      ),
      source: serializer.fromJson<String>(json['source']),
      prominence: serializer.fromJson<String>(json['prominence']),
      primaryMusclesJson: serializer.fromJson<String>(
        json['primaryMusclesJson'],
      ),
      secondaryMusclesJson: serializer.fromJson<String>(
        json['secondaryMusclesJson'],
      ),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      cues: serializer.fromJson<String?>(json['cues']),
      archivedAtMs: serializer.fromJson<int?>(json['archivedAtMs']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'nameLower': serializer.toJson<String>(nameLower),
      'measurementTypeDiscriminator': serializer.toJson<String>(
        measurementTypeDiscriminator,
      ),
      'measurementTypePayloadJson': serializer.toJson<String>(
        measurementTypePayloadJson,
      ),
      'source': serializer.toJson<String>(source),
      'prominence': serializer.toJson<String>(prominence),
      'primaryMusclesJson': serializer.toJson<String>(primaryMusclesJson),
      'secondaryMusclesJson': serializer.toJson<String>(secondaryMusclesJson),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'cues': serializer.toJson<String?>(cues),
      'archivedAtMs': serializer.toJson<int?>(archivedAtMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  LibraryExercise copyWith({
    String? id,
    String? name,
    String? nameLower,
    String? measurementTypeDiscriminator,
    String? measurementTypePayloadJson,
    String? source,
    String? prominence,
    String? primaryMusclesJson,
    String? secondaryMusclesJson,
    Value<String?> videoUrl = const Value.absent(),
    Value<String?> cues = const Value.absent(),
    Value<int?> archivedAtMs = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => LibraryExercise(
    id: id ?? this.id,
    name: name ?? this.name,
    nameLower: nameLower ?? this.nameLower,
    measurementTypeDiscriminator:
        measurementTypeDiscriminator ?? this.measurementTypeDiscriminator,
    measurementTypePayloadJson:
        measurementTypePayloadJson ?? this.measurementTypePayloadJson,
    source: source ?? this.source,
    prominence: prominence ?? this.prominence,
    primaryMusclesJson: primaryMusclesJson ?? this.primaryMusclesJson,
    secondaryMusclesJson: secondaryMusclesJson ?? this.secondaryMusclesJson,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    cues: cues.present ? cues.value : this.cues,
    archivedAtMs: archivedAtMs.present ? archivedAtMs.value : this.archivedAtMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  LibraryExercise copyWithCompanion(LibraryExercisesCompanion data) {
    return LibraryExercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameLower: data.nameLower.present ? data.nameLower.value : this.nameLower,
      measurementTypeDiscriminator: data.measurementTypeDiscriminator.present
          ? data.measurementTypeDiscriminator.value
          : this.measurementTypeDiscriminator,
      measurementTypePayloadJson: data.measurementTypePayloadJson.present
          ? data.measurementTypePayloadJson.value
          : this.measurementTypePayloadJson,
      source: data.source.present ? data.source.value : this.source,
      prominence: data.prominence.present
          ? data.prominence.value
          : this.prominence,
      primaryMusclesJson: data.primaryMusclesJson.present
          ? data.primaryMusclesJson.value
          : this.primaryMusclesJson,
      secondaryMusclesJson: data.secondaryMusclesJson.present
          ? data.secondaryMusclesJson.value
          : this.secondaryMusclesJson,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      cues: data.cues.present ? data.cues.value : this.cues,
      archivedAtMs: data.archivedAtMs.present
          ? data.archivedAtMs.value
          : this.archivedAtMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryExercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLower: $nameLower, ')
          ..write(
            'measurementTypeDiscriminator: $measurementTypeDiscriminator, ',
          )
          ..write('measurementTypePayloadJson: $measurementTypePayloadJson, ')
          ..write('source: $source, ')
          ..write('prominence: $prominence, ')
          ..write('primaryMusclesJson: $primaryMusclesJson, ')
          ..write('secondaryMusclesJson: $secondaryMusclesJson, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('cues: $cues, ')
          ..write('archivedAtMs: $archivedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    nameLower,
    measurementTypeDiscriminator,
    measurementTypePayloadJson,
    source,
    prominence,
    primaryMusclesJson,
    secondaryMusclesJson,
    videoUrl,
    cues,
    archivedAtMs,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryExercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameLower == this.nameLower &&
          other.measurementTypeDiscriminator ==
              this.measurementTypeDiscriminator &&
          other.measurementTypePayloadJson == this.measurementTypePayloadJson &&
          other.source == this.source &&
          other.prominence == this.prominence &&
          other.primaryMusclesJson == this.primaryMusclesJson &&
          other.secondaryMusclesJson == this.secondaryMusclesJson &&
          other.videoUrl == this.videoUrl &&
          other.cues == this.cues &&
          other.archivedAtMs == this.archivedAtMs &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class LibraryExercisesCompanion extends UpdateCompanion<LibraryExercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> nameLower;
  final Value<String> measurementTypeDiscriminator;
  final Value<String> measurementTypePayloadJson;
  final Value<String> source;
  final Value<String> prominence;
  final Value<String> primaryMusclesJson;
  final Value<String> secondaryMusclesJson;
  final Value<String?> videoUrl;
  final Value<String?> cues;
  final Value<int?> archivedAtMs;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const LibraryExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameLower = const Value.absent(),
    this.measurementTypeDiscriminator = const Value.absent(),
    this.measurementTypePayloadJson = const Value.absent(),
    this.source = const Value.absent(),
    this.prominence = const Value.absent(),
    this.primaryMusclesJson = const Value.absent(),
    this.secondaryMusclesJson = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.cues = const Value.absent(),
    this.archivedAtMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryExercisesCompanion.insert({
    required String id,
    required String name,
    required String nameLower,
    required String measurementTypeDiscriminator,
    required String measurementTypePayloadJson,
    this.source = const Value.absent(),
    this.prominence = const Value.absent(),
    this.primaryMusclesJson = const Value.absent(),
    this.secondaryMusclesJson = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.cues = const Value.absent(),
    this.archivedAtMs = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       nameLower = Value(nameLower),
       measurementTypeDiscriminator = Value(measurementTypeDiscriminator),
       measurementTypePayloadJson = Value(measurementTypePayloadJson),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<LibraryExercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? nameLower,
    Expression<String>? measurementTypeDiscriminator,
    Expression<String>? measurementTypePayloadJson,
    Expression<String>? source,
    Expression<String>? prominence,
    Expression<String>? primaryMusclesJson,
    Expression<String>? secondaryMusclesJson,
    Expression<String>? videoUrl,
    Expression<String>? cues,
    Expression<int>? archivedAtMs,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameLower != null) 'name_lower': nameLower,
      if (measurementTypeDiscriminator != null)
        'measurement_type_discriminator': measurementTypeDiscriminator,
      if (measurementTypePayloadJson != null)
        'measurement_type_payload_json': measurementTypePayloadJson,
      if (source != null) 'source': source,
      if (prominence != null) 'prominence': prominence,
      if (primaryMusclesJson != null)
        'primary_muscles_json': primaryMusclesJson,
      if (secondaryMusclesJson != null)
        'secondary_muscles_json': secondaryMusclesJson,
      if (videoUrl != null) 'video_url': videoUrl,
      if (cues != null) 'cues': cues,
      if (archivedAtMs != null) 'archived_at_ms': archivedAtMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? nameLower,
    Value<String>? measurementTypeDiscriminator,
    Value<String>? measurementTypePayloadJson,
    Value<String>? source,
    Value<String>? prominence,
    Value<String>? primaryMusclesJson,
    Value<String>? secondaryMusclesJson,
    Value<String?>? videoUrl,
    Value<String?>? cues,
    Value<int?>? archivedAtMs,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return LibraryExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLower: nameLower ?? this.nameLower,
      measurementTypeDiscriminator:
          measurementTypeDiscriminator ?? this.measurementTypeDiscriminator,
      measurementTypePayloadJson:
          measurementTypePayloadJson ?? this.measurementTypePayloadJson,
      source: source ?? this.source,
      prominence: prominence ?? this.prominence,
      primaryMusclesJson: primaryMusclesJson ?? this.primaryMusclesJson,
      secondaryMusclesJson: secondaryMusclesJson ?? this.secondaryMusclesJson,
      videoUrl: videoUrl ?? this.videoUrl,
      cues: cues ?? this.cues,
      archivedAtMs: archivedAtMs ?? this.archivedAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameLower.present) {
      map['name_lower'] = Variable<String>(nameLower.value);
    }
    if (measurementTypeDiscriminator.present) {
      map['measurement_type_discriminator'] = Variable<String>(
        measurementTypeDiscriminator.value,
      );
    }
    if (measurementTypePayloadJson.present) {
      map['measurement_type_payload_json'] = Variable<String>(
        measurementTypePayloadJson.value,
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (prominence.present) {
      map['prominence'] = Variable<String>(prominence.value);
    }
    if (primaryMusclesJson.present) {
      map['primary_muscles_json'] = Variable<String>(primaryMusclesJson.value);
    }
    if (secondaryMusclesJson.present) {
      map['secondary_muscles_json'] = Variable<String>(
        secondaryMusclesJson.value,
      );
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (cues.present) {
      map['cues'] = Variable<String>(cues.value);
    }
    if (archivedAtMs.present) {
      map['archived_at_ms'] = Variable<int>(archivedAtMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLower: $nameLower, ')
          ..write(
            'measurementTypeDiscriminator: $measurementTypeDiscriminator, ',
          )
          ..write('measurementTypePayloadJson: $measurementTypePayloadJson, ')
          ..write('source: $source, ')
          ..write('prominence: $prominence, ')
          ..write('primaryMusclesJson: $primaryMusclesJson, ')
          ..write('secondaryMusclesJson: $secondaryMusclesJson, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('cues: $cues, ')
          ..write('archivedAtMs: $archivedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseGroupIdMeta = const VerificationMeta(
    'exerciseGroupId',
  );
  @override
  late final GeneratedColumn<String> exerciseGroupId = GeneratedColumn<String>(
    'exercise_group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercise_groups (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementTypeDiscriminatorMeta =
      const VerificationMeta('measurementTypeDiscriminator');
  @override
  late final GeneratedColumn<String> measurementTypeDiscriminator =
      GeneratedColumn<String>(
        'measurement_type_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _measurementTypePayloadJsonMeta =
      const VerificationMeta('measurementTypePayloadJson');
  @override
  late final GeneratedColumn<String> measurementTypePayloadJson =
      GeneratedColumn<String>(
        'measurement_type_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedRestSecondsMeta =
      const VerificationMeta('plannedRestSeconds');
  @override
  late final GeneratedColumn<int> plannedRestSeconds = GeneratedColumn<int>(
    'planned_rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _libraryExerciseIdMeta = const VerificationMeta(
    'libraryExerciseId',
  );
  @override
  late final GeneratedColumn<String> libraryExerciseId =
      GeneratedColumn<String>(
        'library_exercise_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES library_exercises (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseGroupId,
    position,
    name,
    measurementTypeDiscriminator,
    measurementTypePayloadJson,
    notes,
    videoUrl,
    plannedRestSeconds,
    libraryExerciseId,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exercise_group_id')) {
      context.handle(
        _exerciseGroupIdMeta,
        exerciseGroupId.isAcceptableOrUnknown(
          data['exercise_group_id']!,
          _exerciseGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseGroupIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('measurement_type_discriminator')) {
      context.handle(
        _measurementTypeDiscriminatorMeta,
        measurementTypeDiscriminator.isAcceptableOrUnknown(
          data['measurement_type_discriminator']!,
          _measurementTypeDiscriminatorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementTypeDiscriminatorMeta);
    }
    if (data.containsKey('measurement_type_payload_json')) {
      context.handle(
        _measurementTypePayloadJsonMeta,
        measurementTypePayloadJson.isAcceptableOrUnknown(
          data['measurement_type_payload_json']!,
          _measurementTypePayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementTypePayloadJsonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('planned_rest_seconds')) {
      context.handle(
        _plannedRestSecondsMeta,
        plannedRestSeconds.isAcceptableOrUnknown(
          data['planned_rest_seconds']!,
          _plannedRestSecondsMeta,
        ),
      );
    }
    if (data.containsKey('library_exercise_id')) {
      context.handle(
        _libraryExerciseIdMeta,
        libraryExerciseId.isAcceptableOrUnknown(
          data['library_exercise_id']!,
          _libraryExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {exerciseGroupId, position},
  ];
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      exerciseGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_group_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      measurementTypeDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_type_discriminator'],
      )!,
      measurementTypePayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_type_payload_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      plannedRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_rest_seconds'],
      ),
      libraryExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_exercise_id'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String exerciseGroupId;
  final int position;
  final String name;
  final String measurementTypeDiscriminator;
  final String measurementTypePayloadJson;
  final String? notes;
  final String? videoUrl;
  final int? plannedRestSeconds;
  final String? libraryExerciseId;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const Exercise({
    required this.id,
    required this.exerciseGroupId,
    required this.position,
    required this.name,
    required this.measurementTypeDiscriminator,
    required this.measurementTypePayloadJson,
    this.notes,
    this.videoUrl,
    this.plannedRestSeconds,
    this.libraryExerciseId,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exercise_group_id'] = Variable<String>(exerciseGroupId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['measurement_type_discriminator'] = Variable<String>(
      measurementTypeDiscriminator,
    );
    map['measurement_type_payload_json'] = Variable<String>(
      measurementTypePayloadJson,
    );
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || plannedRestSeconds != null) {
      map['planned_rest_seconds'] = Variable<int>(plannedRestSeconds);
    }
    if (!nullToAbsent || libraryExerciseId != null) {
      map['library_exercise_id'] = Variable<String>(libraryExerciseId);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      exerciseGroupId: Value(exerciseGroupId),
      position: Value(position),
      name: Value(name),
      measurementTypeDiscriminator: Value(measurementTypeDiscriminator),
      measurementTypePayloadJson: Value(measurementTypePayloadJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      plannedRestSeconds: plannedRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedRestSeconds),
      libraryExerciseId: libraryExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(libraryExerciseId),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      exerciseGroupId: serializer.fromJson<String>(json['exerciseGroupId']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      measurementTypeDiscriminator: serializer.fromJson<String>(
        json['measurementTypeDiscriminator'],
      ),
      measurementTypePayloadJson: serializer.fromJson<String>(
        json['measurementTypePayloadJson'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      plannedRestSeconds: serializer.fromJson<int?>(json['plannedRestSeconds']),
      libraryExerciseId: serializer.fromJson<String?>(
        json['libraryExerciseId'],
      ),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exerciseGroupId': serializer.toJson<String>(exerciseGroupId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'measurementTypeDiscriminator': serializer.toJson<String>(
        measurementTypeDiscriminator,
      ),
      'measurementTypePayloadJson': serializer.toJson<String>(
        measurementTypePayloadJson,
      ),
      'notes': serializer.toJson<String?>(notes),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'plannedRestSeconds': serializer.toJson<int?>(plannedRestSeconds),
      'libraryExerciseId': serializer.toJson<String?>(libraryExerciseId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  Exercise copyWith({
    String? id,
    String? exerciseGroupId,
    int? position,
    String? name,
    String? measurementTypeDiscriminator,
    String? measurementTypePayloadJson,
    Value<String?> notes = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    Value<int?> plannedRestSeconds = const Value.absent(),
    Value<String?> libraryExerciseId = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => Exercise(
    id: id ?? this.id,
    exerciseGroupId: exerciseGroupId ?? this.exerciseGroupId,
    position: position ?? this.position,
    name: name ?? this.name,
    measurementTypeDiscriminator:
        measurementTypeDiscriminator ?? this.measurementTypeDiscriminator,
    measurementTypePayloadJson:
        measurementTypePayloadJson ?? this.measurementTypePayloadJson,
    notes: notes.present ? notes.value : this.notes,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    plannedRestSeconds: plannedRestSeconds.present
        ? plannedRestSeconds.value
        : this.plannedRestSeconds,
    libraryExerciseId: libraryExerciseId.present
        ? libraryExerciseId.value
        : this.libraryExerciseId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      exerciseGroupId: data.exerciseGroupId.present
          ? data.exerciseGroupId.value
          : this.exerciseGroupId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      measurementTypeDiscriminator: data.measurementTypeDiscriminator.present
          ? data.measurementTypeDiscriminator.value
          : this.measurementTypeDiscriminator,
      measurementTypePayloadJson: data.measurementTypePayloadJson.present
          ? data.measurementTypePayloadJson.value
          : this.measurementTypePayloadJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      plannedRestSeconds: data.plannedRestSeconds.present
          ? data.plannedRestSeconds.value
          : this.plannedRestSeconds,
      libraryExerciseId: data.libraryExerciseId.present
          ? data.libraryExerciseId.value
          : this.libraryExerciseId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('exerciseGroupId: $exerciseGroupId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write(
            'measurementTypeDiscriminator: $measurementTypeDiscriminator, ',
          )
          ..write('measurementTypePayloadJson: $measurementTypePayloadJson, ')
          ..write('notes: $notes, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('plannedRestSeconds: $plannedRestSeconds, ')
          ..write('libraryExerciseId: $libraryExerciseId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseGroupId,
    position,
    name,
    measurementTypeDiscriminator,
    measurementTypePayloadJson,
    notes,
    videoUrl,
    plannedRestSeconds,
    libraryExerciseId,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.exerciseGroupId == this.exerciseGroupId &&
          other.position == this.position &&
          other.name == this.name &&
          other.measurementTypeDiscriminator ==
              this.measurementTypeDiscriminator &&
          other.measurementTypePayloadJson == this.measurementTypePayloadJson &&
          other.notes == this.notes &&
          other.videoUrl == this.videoUrl &&
          other.plannedRestSeconds == this.plannedRestSeconds &&
          other.libraryExerciseId == this.libraryExerciseId &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> exerciseGroupId;
  final Value<int> position;
  final Value<String> name;
  final Value<String> measurementTypeDiscriminator;
  final Value<String> measurementTypePayloadJson;
  final Value<String?> notes;
  final Value<String?> videoUrl;
  final Value<int?> plannedRestSeconds;
  final Value<String?> libraryExerciseId;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.exerciseGroupId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.measurementTypeDiscriminator = const Value.absent(),
    this.measurementTypePayloadJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.plannedRestSeconds = const Value.absent(),
    this.libraryExerciseId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String exerciseGroupId,
    required int position,
    required String name,
    required String measurementTypeDiscriminator,
    required String measurementTypePayloadJson,
    this.notes = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.plannedRestSeconds = const Value.absent(),
    this.libraryExerciseId = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       exerciseGroupId = Value(exerciseGroupId),
       position = Value(position),
       name = Value(name),
       measurementTypeDiscriminator = Value(measurementTypeDiscriminator),
       measurementTypePayloadJson = Value(measurementTypePayloadJson),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? exerciseGroupId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? measurementTypeDiscriminator,
    Expression<String>? measurementTypePayloadJson,
    Expression<String>? notes,
    Expression<String>? videoUrl,
    Expression<int>? plannedRestSeconds,
    Expression<String>? libraryExerciseId,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseGroupId != null) 'exercise_group_id': exerciseGroupId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (measurementTypeDiscriminator != null)
        'measurement_type_discriminator': measurementTypeDiscriminator,
      if (measurementTypePayloadJson != null)
        'measurement_type_payload_json': measurementTypePayloadJson,
      if (notes != null) 'notes': notes,
      if (videoUrl != null) 'video_url': videoUrl,
      if (plannedRestSeconds != null)
        'planned_rest_seconds': plannedRestSeconds,
      if (libraryExerciseId != null) 'library_exercise_id': libraryExerciseId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? exerciseGroupId,
    Value<int>? position,
    Value<String>? name,
    Value<String>? measurementTypeDiscriminator,
    Value<String>? measurementTypePayloadJson,
    Value<String?>? notes,
    Value<String?>? videoUrl,
    Value<int?>? plannedRestSeconds,
    Value<String?>? libraryExerciseId,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      exerciseGroupId: exerciseGroupId ?? this.exerciseGroupId,
      position: position ?? this.position,
      name: name ?? this.name,
      measurementTypeDiscriminator:
          measurementTypeDiscriminator ?? this.measurementTypeDiscriminator,
      measurementTypePayloadJson:
          measurementTypePayloadJson ?? this.measurementTypePayloadJson,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      plannedRestSeconds: plannedRestSeconds ?? this.plannedRestSeconds,
      libraryExerciseId: libraryExerciseId ?? this.libraryExerciseId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exerciseGroupId.present) {
      map['exercise_group_id'] = Variable<String>(exerciseGroupId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (measurementTypeDiscriminator.present) {
      map['measurement_type_discriminator'] = Variable<String>(
        measurementTypeDiscriminator.value,
      );
    }
    if (measurementTypePayloadJson.present) {
      map['measurement_type_payload_json'] = Variable<String>(
        measurementTypePayloadJson.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (plannedRestSeconds.present) {
      map['planned_rest_seconds'] = Variable<int>(plannedRestSeconds.value);
    }
    if (libraryExerciseId.present) {
      map['library_exercise_id'] = Variable<String>(libraryExerciseId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('exerciseGroupId: $exerciseGroupId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write(
            'measurementTypeDiscriminator: $measurementTypeDiscriminator, ',
          )
          ..write('measurementTypePayloadJson: $measurementTypePayloadJson, ')
          ..write('notes: $notes, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('plannedRestSeconds: $plannedRestSeconds, ')
          ..write('libraryExerciseId: $libraryExerciseId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedValuesDiscriminatorMeta =
      const VerificationMeta('plannedValuesDiscriminator');
  @override
  late final GeneratedColumn<String> plannedValuesDiscriminator =
      GeneratedColumn<String>(
        'planned_values_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _plannedValuesPayloadJsonMeta =
      const VerificationMeta('plannedValuesPayloadJson');
  @override
  late final GeneratedColumn<String> plannedValuesPayloadJson =
      GeneratedColumn<String>(
        'planned_values_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    position,
    plannedValuesDiscriminator,
    plannedValuesPayloadJson,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('planned_values_discriminator')) {
      context.handle(
        _plannedValuesDiscriminatorMeta,
        plannedValuesDiscriminator.isAcceptableOrUnknown(
          data['planned_values_discriminator']!,
          _plannedValuesDiscriminatorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedValuesDiscriminatorMeta);
    }
    if (data.containsKey('planned_values_payload_json')) {
      context.handle(
        _plannedValuesPayloadJsonMeta,
        plannedValuesPayloadJson.isAcceptableOrUnknown(
          data['planned_values_payload_json']!,
          _plannedValuesPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedValuesPayloadJsonMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {exerciseId, position},
  ];
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      plannedValuesDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_values_discriminator'],
      )!,
      plannedValuesPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_values_payload_json'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final String id;
  final String exerciseId;
  final int position;
  final String plannedValuesDiscriminator;
  final String plannedValuesPayloadJson;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.position,
    required this.plannedValuesDiscriminator,
    required this.plannedValuesPayloadJson,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    map['planned_values_discriminator'] = Variable<String>(
      plannedValuesDiscriminator,
    );
    map['planned_values_payload_json'] = Variable<String>(
      plannedValuesPayloadJson,
    );
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      position: Value(position),
      plannedValuesDiscriminator: Value(plannedValuesDiscriminator),
      plannedValuesPayloadJson: Value(plannedValuesPayloadJson),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory WorkoutSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<String>(json['id']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      plannedValuesDiscriminator: serializer.fromJson<String>(
        json['plannedValuesDiscriminator'],
      ),
      plannedValuesPayloadJson: serializer.fromJson<String>(
        json['plannedValuesPayloadJson'],
      ),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'plannedValuesDiscriminator': serializer.toJson<String>(
        plannedValuesDiscriminator,
      ),
      'plannedValuesPayloadJson': serializer.toJson<String>(
        plannedValuesPayloadJson,
      ),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    int? position,
    String? plannedValuesDiscriminator,
    String? plannedValuesPayloadJson,
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => WorkoutSet(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    plannedValuesDiscriminator:
        plannedValuesDiscriminator ?? this.plannedValuesDiscriminator,
    plannedValuesPayloadJson:
        plannedValuesPayloadJson ?? this.plannedValuesPayloadJson,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      plannedValuesDiscriminator: data.plannedValuesDiscriminator.present
          ? data.plannedValuesDiscriminator.value
          : this.plannedValuesDiscriminator,
      plannedValuesPayloadJson: data.plannedValuesPayloadJson.present
          ? data.plannedValuesPayloadJson.value
          : this.plannedValuesPayloadJson,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('plannedValuesDiscriminator: $plannedValuesDiscriminator, ')
          ..write('plannedValuesPayloadJson: $plannedValuesPayloadJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    position,
    plannedValuesDiscriminator,
    plannedValuesPayloadJson,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.plannedValuesDiscriminator == this.plannedValuesDiscriminator &&
          other.plannedValuesPayloadJson == this.plannedValuesPayloadJson &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<String> id;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<String> plannedValuesDiscriminator;
  final Value<String> plannedValuesPayloadJson;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.plannedValuesDiscriminator = const Value.absent(),
    this.plannedValuesPayloadJson = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    required String id,
    required String exerciseId,
    required int position,
    required String plannedValuesDiscriminator,
    required String plannedValuesPayloadJson,
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       exerciseId = Value(exerciseId),
       position = Value(position),
       plannedValuesDiscriminator = Value(plannedValuesDiscriminator),
       plannedValuesPayloadJson = Value(plannedValuesPayloadJson),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<WorkoutSet> custom({
    Expression<String>? id,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<String>? plannedValuesDiscriminator,
    Expression<String>? plannedValuesPayloadJson,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (plannedValuesDiscriminator != null)
        'planned_values_discriminator': plannedValuesDiscriminator,
      if (plannedValuesPayloadJson != null)
        'planned_values_payload_json': plannedValuesPayloadJson,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<String>? plannedValuesDiscriminator,
    Value<String>? plannedValuesPayloadJson,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      plannedValuesDiscriminator:
          plannedValuesDiscriminator ?? this.plannedValuesDiscriminator,
      plannedValuesPayloadJson:
          plannedValuesPayloadJson ?? this.plannedValuesPayloadJson,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (plannedValuesDiscriminator.present) {
      map['planned_values_discriminator'] = Variable<String>(
        plannedValuesDiscriminator.value,
      );
    }
    if (plannedValuesPayloadJson.present) {
      map['planned_values_payload_json'] = Variable<String>(
        plannedValuesPayloadJson.value,
      );
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('plannedValuesDiscriminator: $plannedValuesDiscriminator, ')
          ..write('plannedValuesPayloadJson: $plannedValuesPayloadJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutDayIdMeta = const VerificationMeta(
    'workoutDayId',
  );
  @override
  late final GeneratedColumn<String> workoutDayId = GeneratedColumn<String>(
    'workout_day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotJsonMeta = const VerificationMeta(
    'snapshotJson',
  );
  @override
  late final GeneratedColumn<String> snapshotJson = GeneratedColumn<String>(
    'snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotHashMeta = const VerificationMeta(
    'snapshotHash',
  );
  @override
  late final GeneratedColumn<String> snapshotHash = GeneratedColumn<String>(
    'snapshot_hash',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMsMeta = const VerificationMeta(
    'endedAtMs',
  );
  @override
  late final GeneratedColumn<int> endedAtMs = GeneratedColumn<int>(
    'ended_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _isDeloadMeta = const VerificationMeta(
    'isDeload',
  );
  @override
  late final GeneratedColumn<bool> isDeload = GeneratedColumn<bool>(
    'is_deload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deload" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutDayId,
    snapshotJson,
    snapshotHash,
    startedAtMs,
    endedAtMs,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
    isDeload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_day_id')) {
      context.handle(
        _workoutDayIdMeta,
        workoutDayId.isAcceptableOrUnknown(
          data['workout_day_id']!,
          _workoutDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutDayIdMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('snapshot_hash')) {
      context.handle(
        _snapshotHashMeta,
        snapshotHash.isAcceptableOrUnknown(
          data['snapshot_hash']!,
          _snapshotHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotHashMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('ended_at_ms')) {
      context.handle(
        _endedAtMsMeta,
        endedAtMs.isAcceptableOrUnknown(data['ended_at_ms']!, _endedAtMsMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    if (data.containsKey('is_deload')) {
      context.handle(
        _isDeloadMeta,
        isDeload.isAcceptableOrUnknown(data['is_deload']!, _isDeloadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workoutDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_day_id'],
      )!,
      snapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
      snapshotHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_hash'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      endedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_ms'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      isDeload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deload'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String workoutDayId;
  final String snapshotJson;
  final String snapshotHash;
  final int startedAtMs;
  final int? endedAtMs;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  final bool isDeload;
  const Session({
    required this.id,
    required this.workoutDayId,
    required this.snapshotJson,
    required this.snapshotHash,
    required this.startedAtMs,
    this.endedAtMs,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
    required this.isDeload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_day_id'] = Variable<String>(workoutDayId);
    map['snapshot_json'] = Variable<String>(snapshotJson);
    map['snapshot_hash'] = Variable<String>(snapshotHash);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || endedAtMs != null) {
      map['ended_at_ms'] = Variable<int>(endedAtMs);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['is_deload'] = Variable<bool>(isDeload);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      workoutDayId: Value(workoutDayId),
      snapshotJson: Value(snapshotJson),
      snapshotHash: Value(snapshotHash),
      startedAtMs: Value(startedAtMs),
      endedAtMs: endedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMs),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
      isDeload: Value(isDeload),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      workoutDayId: serializer.fromJson<String>(json['workoutDayId']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      snapshotHash: serializer.fromJson<String>(json['snapshotHash']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      endedAtMs: serializer.fromJson<int?>(json['endedAtMs']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      isDeload: serializer.fromJson<bool>(json['isDeload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutDayId': serializer.toJson<String>(workoutDayId),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'snapshotHash': serializer.toJson<String>(snapshotHash),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'endedAtMs': serializer.toJson<int?>(endedAtMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'isDeload': serializer.toJson<bool>(isDeload),
    };
  }

  Session copyWith({
    String? id,
    String? workoutDayId,
    String? snapshotJson,
    String? snapshotHash,
    int? startedAtMs,
    Value<int?> endedAtMs = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
    bool? isDeload,
  }) => Session(
    id: id ?? this.id,
    workoutDayId: workoutDayId ?? this.workoutDayId,
    snapshotJson: snapshotJson ?? this.snapshotJson,
    snapshotHash: snapshotHash ?? this.snapshotHash,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    endedAtMs: endedAtMs.present ? endedAtMs.value : this.endedAtMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    isDeload: isDeload ?? this.isDeload,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      workoutDayId: data.workoutDayId.present
          ? data.workoutDayId.value
          : this.workoutDayId,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      snapshotHash: data.snapshotHash.present
          ? data.snapshotHash.value
          : this.snapshotHash,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      endedAtMs: data.endedAtMs.present ? data.endedAtMs.value : this.endedAtMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      isDeload: data.isDeload.present ? data.isDeload.value : this.isDeload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('snapshotHash: $snapshotHash, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('isDeload: $isDeload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutDayId,
    snapshotJson,
    snapshotHash,
    startedAtMs,
    endedAtMs,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
    isDeload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.workoutDayId == this.workoutDayId &&
          other.snapshotJson == this.snapshotJson &&
          other.snapshotHash == this.snapshotHash &&
          other.startedAtMs == this.startedAtMs &&
          other.endedAtMs == this.endedAtMs &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion &&
          other.isDeload == this.isDeload);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> workoutDayId;
  final Value<String> snapshotJson;
  final Value<String> snapshotHash;
  final Value<int> startedAtMs;
  final Value<int?> endedAtMs;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<bool> isDeload;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.workoutDayId = const Value.absent(),
    this.snapshotJson = const Value.absent(),
    this.snapshotHash = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.isDeload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String workoutDayId,
    required String snapshotJson,
    required String snapshotHash,
    required int startedAtMs,
    this.endedAtMs = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.isDeload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workoutDayId = Value(workoutDayId),
       snapshotJson = Value(snapshotJson),
       snapshotHash = Value(snapshotHash),
       startedAtMs = Value(startedAtMs),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? workoutDayId,
    Expression<String>? snapshotJson,
    Expression<String>? snapshotHash,
    Expression<int>? startedAtMs,
    Expression<int>? endedAtMs,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<bool>? isDeload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutDayId != null) 'workout_day_id': workoutDayId,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (snapshotHash != null) 'snapshot_hash': snapshotHash,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (endedAtMs != null) 'ended_at_ms': endedAtMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (isDeload != null) 'is_deload': isDeload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? workoutDayId,
    Value<String>? snapshotJson,
    Value<String>? snapshotHash,
    Value<int>? startedAtMs,
    Value<int?>? endedAtMs,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<bool>? isDeload,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      snapshotHash: snapshotHash ?? this.snapshotHash,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      isDeload: isDeload ?? this.isDeload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutDayId.present) {
      map['workout_day_id'] = Variable<String>(workoutDayId.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = Variable<String>(snapshotJson.value);
    }
    if (snapshotHash.present) {
      map['snapshot_hash'] = Variable<String>(snapshotHash.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (endedAtMs.present) {
      map['ended_at_ms'] = Variable<int>(endedAtMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (isDeload.present) {
      map['is_deload'] = Variable<bool>(isDeload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('workoutDayId: $workoutDayId, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('snapshotHash: $snapshotHash, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('isDeload: $isDeload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedExerciseIdInSnapshotMeta =
      const VerificationMeta('plannedExerciseIdInSnapshot');
  @override
  late final GeneratedColumn<String> plannedExerciseIdInSnapshot =
      GeneratedColumn<String>(
        'planned_exercise_id_in_snapshot',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 36,
          maxTextLength: 36,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _stateDiscriminatorMeta =
      const VerificationMeta('stateDiscriminator');
  @override
  late final GeneratedColumn<String> stateDiscriminator =
      GeneratedColumn<String>(
        'state_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _substitutePayloadJsonMeta =
      const VerificationMeta('substitutePayloadJson');
  @override
  late final GeneratedColumn<String> substitutePayloadJson =
      GeneratedColumn<String>(
        'substitute_payload_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _supersetTagMeta = const VerificationMeta(
    'supersetTag',
  );
  @override
  late final GeneratedColumn<String> supersetTag = GeneratedColumn<String>(
    'superset_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    position,
    plannedExerciseIdInSnapshot,
    stateDiscriminator,
    substitutePayloadJson,
    supersetTag,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('planned_exercise_id_in_snapshot')) {
      context.handle(
        _plannedExerciseIdInSnapshotMeta,
        plannedExerciseIdInSnapshot.isAcceptableOrUnknown(
          data['planned_exercise_id_in_snapshot']!,
          _plannedExerciseIdInSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedExerciseIdInSnapshotMeta);
    }
    if (data.containsKey('state_discriminator')) {
      context.handle(
        _stateDiscriminatorMeta,
        stateDiscriminator.isAcceptableOrUnknown(
          data['state_discriminator']!,
          _stateDiscriminatorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stateDiscriminatorMeta);
    }
    if (data.containsKey('substitute_payload_json')) {
      context.handle(
        _substitutePayloadJsonMeta,
        substitutePayloadJson.isAcceptableOrUnknown(
          data['substitute_payload_json']!,
          _substitutePayloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('superset_tag')) {
      context.handle(
        _supersetTagMeta,
        supersetTag.isAcceptableOrUnknown(
          data['superset_tag']!,
          _supersetTagMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, position},
  ];
  @override
  SessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      plannedExerciseIdInSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_exercise_id_in_snapshot'],
      )!,
      stateDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_discriminator'],
      )!,
      substitutePayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substitute_payload_json'],
      ),
      supersetTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}superset_tag'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }
}

class SessionExercise extends DataClass implements Insertable<SessionExercise> {
  final String id;
  final String sessionId;
  final int position;
  final String plannedExerciseIdInSnapshot;
  final String stateDiscriminator;
  final String? substitutePayloadJson;
  final String? supersetTag;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const SessionExercise({
    required this.id,
    required this.sessionId,
    required this.position,
    required this.plannedExerciseIdInSnapshot,
    required this.stateDiscriminator,
    this.substitutePayloadJson,
    this.supersetTag,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['position'] = Variable<int>(position);
    map['planned_exercise_id_in_snapshot'] = Variable<String>(
      plannedExerciseIdInSnapshot,
    );
    map['state_discriminator'] = Variable<String>(stateDiscriminator);
    if (!nullToAbsent || substitutePayloadJson != null) {
      map['substitute_payload_json'] = Variable<String>(substitutePayloadJson);
    }
    if (!nullToAbsent || supersetTag != null) {
      map['superset_tag'] = Variable<String>(supersetTag);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      position: Value(position),
      plannedExerciseIdInSnapshot: Value(plannedExerciseIdInSnapshot),
      stateDiscriminator: Value(stateDiscriminator),
      substitutePayloadJson: substitutePayloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(substitutePayloadJson),
      supersetTag: supersetTag == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetTag),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory SessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExercise(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      position: serializer.fromJson<int>(json['position']),
      plannedExerciseIdInSnapshot: serializer.fromJson<String>(
        json['plannedExerciseIdInSnapshot'],
      ),
      stateDiscriminator: serializer.fromJson<String>(
        json['stateDiscriminator'],
      ),
      substitutePayloadJson: serializer.fromJson<String?>(
        json['substitutePayloadJson'],
      ),
      supersetTag: serializer.fromJson<String?>(json['supersetTag']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'position': serializer.toJson<int>(position),
      'plannedExerciseIdInSnapshot': serializer.toJson<String>(
        plannedExerciseIdInSnapshot,
      ),
      'stateDiscriminator': serializer.toJson<String>(stateDiscriminator),
      'substitutePayloadJson': serializer.toJson<String?>(
        substitutePayloadJson,
      ),
      'supersetTag': serializer.toJson<String?>(supersetTag),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  SessionExercise copyWith({
    String? id,
    String? sessionId,
    int? position,
    String? plannedExerciseIdInSnapshot,
    String? stateDiscriminator,
    Value<String?> substitutePayloadJson = const Value.absent(),
    Value<String?> supersetTag = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => SessionExercise(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    position: position ?? this.position,
    plannedExerciseIdInSnapshot:
        plannedExerciseIdInSnapshot ?? this.plannedExerciseIdInSnapshot,
    stateDiscriminator: stateDiscriminator ?? this.stateDiscriminator,
    substitutePayloadJson: substitutePayloadJson.present
        ? substitutePayloadJson.value
        : this.substitutePayloadJson,
    supersetTag: supersetTag.present ? supersetTag.value : this.supersetTag,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  SessionExercise copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      position: data.position.present ? data.position.value : this.position,
      plannedExerciseIdInSnapshot: data.plannedExerciseIdInSnapshot.present
          ? data.plannedExerciseIdInSnapshot.value
          : this.plannedExerciseIdInSnapshot,
      stateDiscriminator: data.stateDiscriminator.present
          ? data.stateDiscriminator.value
          : this.stateDiscriminator,
      substitutePayloadJson: data.substitutePayloadJson.present
          ? data.substitutePayloadJson.value
          : this.substitutePayloadJson,
      supersetTag: data.supersetTag.present
          ? data.supersetTag.value
          : this.supersetTag,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercise(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('plannedExerciseIdInSnapshot: $plannedExerciseIdInSnapshot, ')
          ..write('stateDiscriminator: $stateDiscriminator, ')
          ..write('substitutePayloadJson: $substitutePayloadJson, ')
          ..write('supersetTag: $supersetTag, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    position,
    plannedExerciseIdInSnapshot,
    stateDiscriminator,
    substitutePayloadJson,
    supersetTag,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExercise &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.position == this.position &&
          other.plannedExerciseIdInSnapshot ==
              this.plannedExerciseIdInSnapshot &&
          other.stateDiscriminator == this.stateDiscriminator &&
          other.substitutePayloadJson == this.substitutePayloadJson &&
          other.supersetTag == this.supersetTag &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExercise> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> position;
  final Value<String> plannedExerciseIdInSnapshot;
  final Value<String> stateDiscriminator;
  final Value<String?> substitutePayloadJson;
  final Value<String?> supersetTag;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const SessionExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.position = const Value.absent(),
    this.plannedExerciseIdInSnapshot = const Value.absent(),
    this.stateDiscriminator = const Value.absent(),
    this.substitutePayloadJson = const Value.absent(),
    this.supersetTag = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    required String id,
    required String sessionId,
    required int position,
    required String plannedExerciseIdInSnapshot,
    required String stateDiscriminator,
    this.substitutePayloadJson = const Value.absent(),
    this.supersetTag = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       position = Value(position),
       plannedExerciseIdInSnapshot = Value(plannedExerciseIdInSnapshot),
       stateDiscriminator = Value(stateDiscriminator),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<SessionExercise> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? position,
    Expression<String>? plannedExerciseIdInSnapshot,
    Expression<String>? stateDiscriminator,
    Expression<String>? substitutePayloadJson,
    Expression<String>? supersetTag,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (position != null) 'position': position,
      if (plannedExerciseIdInSnapshot != null)
        'planned_exercise_id_in_snapshot': plannedExerciseIdInSnapshot,
      if (stateDiscriminator != null) 'state_discriminator': stateDiscriminator,
      if (substitutePayloadJson != null)
        'substitute_payload_json': substitutePayloadJson,
      if (supersetTag != null) 'superset_tag': supersetTag,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? position,
    Value<String>? plannedExerciseIdInSnapshot,
    Value<String>? stateDiscriminator,
    Value<String?>? substitutePayloadJson,
    Value<String?>? supersetTag,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return SessionExercisesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      position: position ?? this.position,
      plannedExerciseIdInSnapshot:
          plannedExerciseIdInSnapshot ?? this.plannedExerciseIdInSnapshot,
      stateDiscriminator: stateDiscriminator ?? this.stateDiscriminator,
      substitutePayloadJson:
          substitutePayloadJson ?? this.substitutePayloadJson,
      supersetTag: supersetTag ?? this.supersetTag,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (plannedExerciseIdInSnapshot.present) {
      map['planned_exercise_id_in_snapshot'] = Variable<String>(
        plannedExerciseIdInSnapshot.value,
      );
    }
    if (stateDiscriminator.present) {
      map['state_discriminator'] = Variable<String>(stateDiscriminator.value);
    }
    if (substitutePayloadJson.present) {
      map['substitute_payload_json'] = Variable<String>(
        substitutePayloadJson.value,
      );
    }
    if (supersetTag.present) {
      map['superset_tag'] = Variable<String>(supersetTag.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('plannedExerciseIdInSnapshot: $plannedExerciseIdInSnapshot, ')
          ..write('stateDiscriminator: $stateDiscriminator, ')
          ..write('substitutePayloadJson: $substitutePayloadJson, ')
          ..write('supersetTag: $supersetTag, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExecutedSetsTable extends ExecutedSets
    with TableInfo<$ExecutedSetsTable, ExecutedSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExecutedSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionExerciseIdMeta = const VerificationMeta(
    'sessionExerciseId',
  );
  @override
  late final GeneratedColumn<String> sessionExerciseId =
      GeneratedColumn<String>(
        'session_exercise_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES session_exercises (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementTypeDiscriminatorMeta =
      const VerificationMeta('measurementTypeDiscriminator');
  @override
  late final GeneratedColumn<String> measurementTypeDiscriminator =
      GeneratedColumn<String>(
        'measurement_type_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _actualValuesDiscriminatorMeta =
      const VerificationMeta('actualValuesDiscriminator');
  @override
  late final GeneratedColumn<String> actualValuesDiscriminator =
      GeneratedColumn<String>(
        'actual_values_discriminator',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _actualValuesPayloadJsonMeta =
      const VerificationMeta('actualValuesPayloadJson');
  @override
  late final GeneratedColumn<String> actualValuesPayloadJson =
      GeneratedColumn<String>(
        'actual_values_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _plannedSetIdInSnapshotMeta =
      const VerificationMeta('plannedSetIdInSnapshot');
  @override
  late final GeneratedColumn<String> plannedSetIdInSnapshot =
      GeneratedColumn<String>(
        'planned_set_id_in_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _completedAtMsMeta = const VerificationMeta(
    'completedAtMs',
  );
  @override
  late final GeneratedColumn<int> completedAtMs = GeneratedColumn<int>(
    'completed_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionExerciseId,
    position,
    measurementTypeDiscriminator,
    actualValuesDiscriminator,
    actualValuesPayloadJson,
    plannedSetIdInSnapshot,
    completedAtMs,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'executed_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExecutedSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_exercise_id')) {
      context.handle(
        _sessionExerciseIdMeta,
        sessionExerciseId.isAcceptableOrUnknown(
          data['session_exercise_id']!,
          _sessionExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionExerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('measurement_type_discriminator')) {
      context.handle(
        _measurementTypeDiscriminatorMeta,
        measurementTypeDiscriminator.isAcceptableOrUnknown(
          data['measurement_type_discriminator']!,
          _measurementTypeDiscriminatorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementTypeDiscriminatorMeta);
    }
    if (data.containsKey('actual_values_discriminator')) {
      context.handle(
        _actualValuesDiscriminatorMeta,
        actualValuesDiscriminator.isAcceptableOrUnknown(
          data['actual_values_discriminator']!,
          _actualValuesDiscriminatorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualValuesDiscriminatorMeta);
    }
    if (data.containsKey('actual_values_payload_json')) {
      context.handle(
        _actualValuesPayloadJsonMeta,
        actualValuesPayloadJson.isAcceptableOrUnknown(
          data['actual_values_payload_json']!,
          _actualValuesPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualValuesPayloadJsonMeta);
    }
    if (data.containsKey('planned_set_id_in_snapshot')) {
      context.handle(
        _plannedSetIdInSnapshotMeta,
        plannedSetIdInSnapshot.isAcceptableOrUnknown(
          data['planned_set_id_in_snapshot']!,
          _plannedSetIdInSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('completed_at_ms')) {
      context.handle(
        _completedAtMsMeta,
        completedAtMs.isAcceptableOrUnknown(
          data['completed_at_ms']!,
          _completedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMsMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionExerciseId, position},
  ];
  @override
  ExecutedSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExecutedSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      measurementTypeDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_type_discriminator'],
      )!,
      actualValuesDiscriminator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_values_discriminator'],
      )!,
      actualValuesPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_values_payload_json'],
      )!,
      plannedSetIdInSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_set_id_in_snapshot'],
      ),
      completedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_ms'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $ExecutedSetsTable createAlias(String alias) {
    return $ExecutedSetsTable(attachedDatabase, alias);
  }
}

class ExecutedSet extends DataClass implements Insertable<ExecutedSet> {
  final String id;
  final String sessionExerciseId;
  final int position;
  final String measurementTypeDiscriminator;
  final String actualValuesDiscriminator;
  final String actualValuesPayloadJson;
  final String? plannedSetIdInSnapshot;
  final int completedAtMs;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const ExecutedSet({
    required this.id,
    required this.sessionExerciseId,
    required this.position,
    required this.measurementTypeDiscriminator,
    required this.actualValuesDiscriminator,
    required this.actualValuesPayloadJson,
    this.plannedSetIdInSnapshot,
    required this.completedAtMs,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_exercise_id'] = Variable<String>(sessionExerciseId);
    map['position'] = Variable<int>(position);
    map['measurement_type_discriminator'] = Variable<String>(
      measurementTypeDiscriminator,
    );
    map['actual_values_discriminator'] = Variable<String>(
      actualValuesDiscriminator,
    );
    map['actual_values_payload_json'] = Variable<String>(
      actualValuesPayloadJson,
    );
    if (!nullToAbsent || plannedSetIdInSnapshot != null) {
      map['planned_set_id_in_snapshot'] = Variable<String>(
        plannedSetIdInSnapshot,
      );
    }
    map['completed_at_ms'] = Variable<int>(completedAtMs);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  ExecutedSetsCompanion toCompanion(bool nullToAbsent) {
    return ExecutedSetsCompanion(
      id: Value(id),
      sessionExerciseId: Value(sessionExerciseId),
      position: Value(position),
      measurementTypeDiscriminator: Value(measurementTypeDiscriminator),
      actualValuesDiscriminator: Value(actualValuesDiscriminator),
      actualValuesPayloadJson: Value(actualValuesPayloadJson),
      plannedSetIdInSnapshot: plannedSetIdInSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedSetIdInSnapshot),
      completedAtMs: Value(completedAtMs),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory ExecutedSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExecutedSet(
      id: serializer.fromJson<String>(json['id']),
      sessionExerciseId: serializer.fromJson<String>(json['sessionExerciseId']),
      position: serializer.fromJson<int>(json['position']),
      measurementTypeDiscriminator: serializer.fromJson<String>(
        json['measurementTypeDiscriminator'],
      ),
      actualValuesDiscriminator: serializer.fromJson<String>(
        json['actualValuesDiscriminator'],
      ),
      actualValuesPayloadJson: serializer.fromJson<String>(
        json['actualValuesPayloadJson'],
      ),
      plannedSetIdInSnapshot: serializer.fromJson<String?>(
        json['plannedSetIdInSnapshot'],
      ),
      completedAtMs: serializer.fromJson<int>(json['completedAtMs']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionExerciseId': serializer.toJson<String>(sessionExerciseId),
      'position': serializer.toJson<int>(position),
      'measurementTypeDiscriminator': serializer.toJson<String>(
        measurementTypeDiscriminator,
      ),
      'actualValuesDiscriminator': serializer.toJson<String>(
        actualValuesDiscriminator,
      ),
      'actualValuesPayloadJson': serializer.toJson<String>(
        actualValuesPayloadJson,
      ),
      'plannedSetIdInSnapshot': serializer.toJson<String?>(
        plannedSetIdInSnapshot,
      ),
      'completedAtMs': serializer.toJson<int>(completedAtMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  ExecutedSet copyWith({
    String? id,
    String? sessionExerciseId,
    int? position,
    String? measurementTypeDiscriminator,
    String? actualValuesDiscriminator,
    String? actualValuesPayloadJson,
    Value<String?> plannedSetIdInSnapshot = const Value.absent(),
    int? completedAtMs,
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => ExecutedSet(
    id: id ?? this.id,
    sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
    position: position ?? this.position,
    measurementTypeDiscriminator:
        measurementTypeDiscriminator ?? this.measurementTypeDiscriminator,
    actualValuesDiscriminator:
        actualValuesDiscriminator ?? this.actualValuesDiscriminator,
    actualValuesPayloadJson:
        actualValuesPayloadJson ?? this.actualValuesPayloadJson,
    plannedSetIdInSnapshot: plannedSetIdInSnapshot.present
        ? plannedSetIdInSnapshot.value
        : this.plannedSetIdInSnapshot,
    completedAtMs: completedAtMs ?? this.completedAtMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  ExecutedSet copyWithCompanion(ExecutedSetsCompanion data) {
    return ExecutedSet(
      id: data.id.present ? data.id.value : this.id,
      sessionExerciseId: data.sessionExerciseId.present
          ? data.sessionExerciseId.value
          : this.sessionExerciseId,
      position: data.position.present ? data.position.value : this.position,
      measurementTypeDiscriminator: data.measurementTypeDiscriminator.present
          ? data.measurementTypeDiscriminator.value
          : this.measurementTypeDiscriminator,
      actualValuesDiscriminator: data.actualValuesDiscriminator.present
          ? data.actualValuesDiscriminator.value
          : this.actualValuesDiscriminator,
      actualValuesPayloadJson: data.actualValuesPayloadJson.present
          ? data.actualValuesPayloadJson.value
          : this.actualValuesPayloadJson,
      plannedSetIdInSnapshot: data.plannedSetIdInSnapshot.present
          ? data.plannedSetIdInSnapshot.value
          : this.plannedSetIdInSnapshot,
      completedAtMs: data.completedAtMs.present
          ? data.completedAtMs.value
          : this.completedAtMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExecutedSet(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('position: $position, ')
          ..write(
            'measurementTypeDiscriminator: $measurementTypeDiscriminator, ',
          )
          ..write('actualValuesDiscriminator: $actualValuesDiscriminator, ')
          ..write('actualValuesPayloadJson: $actualValuesPayloadJson, ')
          ..write('plannedSetIdInSnapshot: $plannedSetIdInSnapshot, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionExerciseId,
    position,
    measurementTypeDiscriminator,
    actualValuesDiscriminator,
    actualValuesPayloadJson,
    plannedSetIdInSnapshot,
    completedAtMs,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExecutedSet &&
          other.id == this.id &&
          other.sessionExerciseId == this.sessionExerciseId &&
          other.position == this.position &&
          other.measurementTypeDiscriminator ==
              this.measurementTypeDiscriminator &&
          other.actualValuesDiscriminator == this.actualValuesDiscriminator &&
          other.actualValuesPayloadJson == this.actualValuesPayloadJson &&
          other.plannedSetIdInSnapshot == this.plannedSetIdInSnapshot &&
          other.completedAtMs == this.completedAtMs &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class ExecutedSetsCompanion extends UpdateCompanion<ExecutedSet> {
  final Value<String> id;
  final Value<String> sessionExerciseId;
  final Value<int> position;
  final Value<String> measurementTypeDiscriminator;
  final Value<String> actualValuesDiscriminator;
  final Value<String> actualValuesPayloadJson;
  final Value<String?> plannedSetIdInSnapshot;
  final Value<int> completedAtMs;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const ExecutedSetsCompanion({
    this.id = const Value.absent(),
    this.sessionExerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.measurementTypeDiscriminator = const Value.absent(),
    this.actualValuesDiscriminator = const Value.absent(),
    this.actualValuesPayloadJson = const Value.absent(),
    this.plannedSetIdInSnapshot = const Value.absent(),
    this.completedAtMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExecutedSetsCompanion.insert({
    required String id,
    required String sessionExerciseId,
    required int position,
    required String measurementTypeDiscriminator,
    required String actualValuesDiscriminator,
    required String actualValuesPayloadJson,
    this.plannedSetIdInSnapshot = const Value.absent(),
    required int completedAtMs,
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionExerciseId = Value(sessionExerciseId),
       position = Value(position),
       measurementTypeDiscriminator = Value(measurementTypeDiscriminator),
       actualValuesDiscriminator = Value(actualValuesDiscriminator),
       actualValuesPayloadJson = Value(actualValuesPayloadJson),
       completedAtMs = Value(completedAtMs),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<ExecutedSet> custom({
    Expression<String>? id,
    Expression<String>? sessionExerciseId,
    Expression<int>? position,
    Expression<String>? measurementTypeDiscriminator,
    Expression<String>? actualValuesDiscriminator,
    Expression<String>? actualValuesPayloadJson,
    Expression<String>? plannedSetIdInSnapshot,
    Expression<int>? completedAtMs,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionExerciseId != null) 'session_exercise_id': sessionExerciseId,
      if (position != null) 'position': position,
      if (measurementTypeDiscriminator != null)
        'measurement_type_discriminator': measurementTypeDiscriminator,
      if (actualValuesDiscriminator != null)
        'actual_values_discriminator': actualValuesDiscriminator,
      if (actualValuesPayloadJson != null)
        'actual_values_payload_json': actualValuesPayloadJson,
      if (plannedSetIdInSnapshot != null)
        'planned_set_id_in_snapshot': plannedSetIdInSnapshot,
      if (completedAtMs != null) 'completed_at_ms': completedAtMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExecutedSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionExerciseId,
    Value<int>? position,
    Value<String>? measurementTypeDiscriminator,
    Value<String>? actualValuesDiscriminator,
    Value<String>? actualValuesPayloadJson,
    Value<String?>? plannedSetIdInSnapshot,
    Value<int>? completedAtMs,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return ExecutedSetsCompanion(
      id: id ?? this.id,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      position: position ?? this.position,
      measurementTypeDiscriminator:
          measurementTypeDiscriminator ?? this.measurementTypeDiscriminator,
      actualValuesDiscriminator:
          actualValuesDiscriminator ?? this.actualValuesDiscriminator,
      actualValuesPayloadJson:
          actualValuesPayloadJson ?? this.actualValuesPayloadJson,
      plannedSetIdInSnapshot:
          plannedSetIdInSnapshot ?? this.plannedSetIdInSnapshot,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionExerciseId.present) {
      map['session_exercise_id'] = Variable<String>(sessionExerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (measurementTypeDiscriminator.present) {
      map['measurement_type_discriminator'] = Variable<String>(
        measurementTypeDiscriminator.value,
      );
    }
    if (actualValuesDiscriminator.present) {
      map['actual_values_discriminator'] = Variable<String>(
        actualValuesDiscriminator.value,
      );
    }
    if (actualValuesPayloadJson.present) {
      map['actual_values_payload_json'] = Variable<String>(
        actualValuesPayloadJson.value,
      );
    }
    if (plannedSetIdInSnapshot.present) {
      map['planned_set_id_in_snapshot'] = Variable<String>(
        plannedSetIdInSnapshot.value,
      );
    }
    if (completedAtMs.present) {
      map['completed_at_ms'] = Variable<int>(completedAtMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExecutedSetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('position: $position, ')
          ..write(
            'measurementTypeDiscriminator: $measurementTypeDiscriminator, ',
          )
          ..write('actualValuesDiscriminator: $actualValuesDiscriminator, ')
          ..write('actualValuesPayloadJson: $actualValuesPayloadJson, ')
          ..write('plannedSetIdInSnapshot: $plannedSetIdInSnapshot, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionNotesTable extends SessionNotes
    with TableInfo<$SessionNotesTable, SessionNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    body,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $SessionNotesTable createAlias(String alias) {
    return $SessionNotesTable(attachedDatabase, alias);
  }
}

class SessionNote extends DataClass implements Insertable<SessionNote> {
  final String id;
  final String sessionId;
  final String body;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const SessionNote({
    required this.id,
    required this.sessionId,
    required this.body,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['body'] = Variable<String>(body);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  SessionNotesCompanion toCompanion(bool nullToAbsent) {
    return SessionNotesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      body: Value(body),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory SessionNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionNote(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      body: serializer.fromJson<String>(json['body']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'body': serializer.toJson<String>(body),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  SessionNote copyWith({
    String? id,
    String? sessionId,
    String? body,
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => SessionNote(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    body: body ?? this.body,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  SessionNote copyWithCompanion(SessionNotesCompanion data) {
    return SessionNote(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      body: data.body.present ? data.body.value : this.body,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionNote(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, body, createdAtMs, updatedAtMs, schemaVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionNote &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.body == this.body &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class SessionNotesCompanion extends UpdateCompanion<SessionNote> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> body;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const SessionNotesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionNotesCompanion.insert({
    required String id,
    required String sessionId,
    required String body,
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       body = Value(body),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<SessionNote> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? body,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (body != null) 'body': body,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? body,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return SessionNotesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      body: body ?? this.body,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionNotesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtraWorkItemsTable extends ExtraWorkItems
    with TableInfo<$ExtraWorkItemsTable, ExtraWorkItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtraWorkItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    position,
    body,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extra_work_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtraWorkItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, position},
  ];
  @override
  ExtraWorkItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtraWorkItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $ExtraWorkItemsTable createAlias(String alias) {
    return $ExtraWorkItemsTable(attachedDatabase, alias);
  }
}

class ExtraWorkItem extends DataClass implements Insertable<ExtraWorkItem> {
  final String id;
  final String sessionId;
  final int position;
  final String body;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;
  const ExtraWorkItem({
    required this.id,
    required this.sessionId,
    required this.position,
    required this.body,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['position'] = Variable<int>(position);
    map['body'] = Variable<String>(body);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  ExtraWorkItemsCompanion toCompanion(bool nullToAbsent) {
    return ExtraWorkItemsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      position: Value(position),
      body: Value(body),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory ExtraWorkItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtraWorkItem(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      position: serializer.fromJson<int>(json['position']),
      body: serializer.fromJson<String>(json['body']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'position': serializer.toJson<int>(position),
      'body': serializer.toJson<String>(body),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  ExtraWorkItem copyWith({
    String? id,
    String? sessionId,
    int? position,
    String? body,
    int? createdAtMs,
    int? updatedAtMs,
    int? schemaVersion,
  }) => ExtraWorkItem(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    position: position ?? this.position,
    body: body ?? this.body,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  ExtraWorkItem copyWithCompanion(ExtraWorkItemsCompanion data) {
    return ExtraWorkItem(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      position: data.position.present ? data.position.value : this.position,
      body: data.body.present ? data.body.value : this.body,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtraWorkItem(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    position,
    body,
    createdAtMs,
    updatedAtMs,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtraWorkItem &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.position == this.position &&
          other.body == this.body &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.schemaVersion == this.schemaVersion);
}

class ExtraWorkItemsCompanion extends UpdateCompanion<ExtraWorkItem> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> position;
  final Value<String> body;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const ExtraWorkItemsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.position = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtraWorkItemsCompanion.insert({
    required String id,
    required String sessionId,
    required int position,
    required String body,
    required int createdAtMs,
    required int updatedAtMs,
    required int schemaVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       position = Value(position),
       body = Value(body),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs),
       schemaVersion = Value(schemaVersion);
  static Insertable<ExtraWorkItem> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? position,
    Expression<String>? body,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (position != null) 'position': position,
      if (body != null) 'body': body,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtraWorkItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? position,
    Value<String>? body,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return ExtraWorkItemsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      position: position ?? this.position,
      body: body ?? this.body,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtraWorkItemsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('position: $position, ')
          ..write('body: $body, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $WorkoutDaysTable workoutDays = $WorkoutDaysTable(this);
  late final $ProgramWorkoutDaysTable programWorkoutDays =
      $ProgramWorkoutDaysTable(this);
  late final $ExerciseGroupsTable exerciseGroups = $ExerciseGroupsTable(this);
  late final $LibraryExercisesTable libraryExercises = $LibraryExercisesTable(
    this,
  );
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionExercisesTable sessionExercises = $SessionExercisesTable(
    this,
  );
  late final $ExecutedSetsTable executedSets = $ExecutedSetsTable(this);
  late final $SessionNotesTable sessionNotes = $SessionNotesTable(this);
  late final $ExtraWorkItemsTable extraWorkItems = $ExtraWorkItemsTable(this);
  late final Index workoutDaysProgramId = Index(
    'workout_days_program_id',
    'CREATE INDEX workout_days_program_id ON workout_days (program_id)',
  );
  late final Index sessionsWorkoutDayId = Index(
    'sessions_workout_day_id',
    'CREATE INDEX sessions_workout_day_id ON sessions (workout_day_id)',
  );
  late final Index sessionExercisesSessionState = Index(
    'session_exercises_session_state',
    'CREATE INDEX session_exercises_session_state ON session_exercises (session_id, state_discriminator)',
  );
  late final Index sessionNotesSessionId = Index(
    'session_notes_session_id',
    'CREATE INDEX session_notes_session_id ON session_notes (session_id)',
  );
  late final Index libraryExercisesNameLower = Index(
    'library_exercises_name_lower',
    'CREATE INDEX library_exercises_name_lower ON library_exercises (name_lower)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    programs,
    workoutDays,
    programWorkoutDays,
    exerciseGroups,
    libraryExercises,
    exercises,
    workoutSets,
    sessions,
    sessionExercises,
    executedSets,
    sessionNotes,
    extraWorkItems,
    workoutDaysProgramId,
    sessionsWorkoutDayId,
    sessionExercisesSessionState,
    sessionNotesSessionId,
    libraryExercisesNameLower,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'programs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_days', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'programs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('program_workout_days', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('program_workout_days', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercise_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercises', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('executed_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('extra_work_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProgramsTableCreateCompanionBuilder =
    ProgramsCompanion Function({
      required String id,
      required String name,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$ProgramsTableUpdateCompanionBuilder =
    ProgramsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$ProgramsTableReferences
    extends BaseReferences<_$AppDatabase, $ProgramsTable, Program> {
  $$ProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutDaysTable, List<WorkoutDay>>
  _workoutDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutDays,
    aliasName: $_aliasNameGenerator(db.programs.id, db.workoutDays.programId),
  );

  $$WorkoutDaysTableProcessedTableManager get workoutDaysRefs {
    final manager = $$WorkoutDaysTableTableManager(
      $_db,
      $_db.workoutDays,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProgramWorkoutDaysTable, List<ProgramWorkoutDay>>
  _programWorkoutDaysRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.programWorkoutDays,
        aliasName: $_aliasNameGenerator(
          db.programs.id,
          db.programWorkoutDays.programId,
        ),
      );

  $$ProgramWorkoutDaysTableProcessedTableManager get programWorkoutDaysRefs {
    final manager = $$ProgramWorkoutDaysTableTableManager(
      $_db,
      $_db.programWorkoutDays,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _programWorkoutDaysRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workoutDaysRefs(
    Expression<bool> Function($$WorkoutDaysTableFilterComposer f) f,
  ) {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> programWorkoutDaysRefs(
    Expression<bool> Function($$ProgramWorkoutDaysTableFilterComposer f) f,
  ) {
    final $$ProgramWorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programWorkoutDays,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramWorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.programWorkoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  Expression<T> workoutDaysRefs<T extends Object>(
    Expression<T> Function($$WorkoutDaysTableAnnotationComposer a) f,
  ) {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> programWorkoutDaysRefs<T extends Object>(
    Expression<T> Function($$ProgramWorkoutDaysTableAnnotationComposer a) f,
  ) {
    final $$ProgramWorkoutDaysTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.programWorkoutDays,
          getReferencedColumn: (t) => t.programId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProgramWorkoutDaysTableAnnotationComposer(
                $db: $db,
                $table: $db.programWorkoutDays,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          Program,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (Program, $$ProgramsTableReferences),
          Program,
          PrefetchHooks Function({
            bool workoutDaysRefs,
            bool programWorkoutDaysRefs,
          })
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                name: name,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                name: name,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workoutDaysRefs = false, programWorkoutDaysRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutDaysRefs) db.workoutDays,
                    if (programWorkoutDaysRefs) db.programWorkoutDays,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutDaysRefs)
                        await $_getPrefetchedData<
                          Program,
                          $ProgramsTable,
                          WorkoutDay
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramsTableReferences
                              ._workoutDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramsTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutDaysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (programWorkoutDaysRefs)
                        await $_getPrefetchedData<
                          Program,
                          $ProgramsTable,
                          ProgramWorkoutDay
                        >(
                          currentTable: table,
                          referencedTable: $$ProgramsTableReferences
                              ._programWorkoutDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProgramsTableReferences(
                                db,
                                table,
                                p0,
                              ).programWorkoutDaysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      Program,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (Program, $$ProgramsTableReferences),
      Program,
      PrefetchHooks Function({
        bool workoutDaysRefs,
        bool programWorkoutDaysRefs,
      })
    >;
typedef $$WorkoutDaysTableCreateCompanionBuilder =
    WorkoutDaysCompanion Function({
      required String id,
      required String programId,
      required String name,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$WorkoutDaysTableUpdateCompanionBuilder =
    WorkoutDaysCompanion Function({
      Value<String> id,
      Value<String> programId,
      Value<String> name,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$WorkoutDaysTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutDaysTable, WorkoutDay> {
  $$WorkoutDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProgramsTable _programIdTable(_$AppDatabase db) =>
      db.programs.createAlias(
        $_aliasNameGenerator(db.workoutDays.programId, db.programs.id),
      );

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<String>('program_id')!;

    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProgramWorkoutDaysTable, List<ProgramWorkoutDay>>
  _programWorkoutDaysRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.programWorkoutDays,
        aliasName: $_aliasNameGenerator(
          db.workoutDays.id,
          db.programWorkoutDays.workoutDayId,
        ),
      );

  $$ProgramWorkoutDaysTableProcessedTableManager get programWorkoutDaysRefs {
    final manager = $$ProgramWorkoutDaysTableTableManager(
      $_db,
      $_db.programWorkoutDays,
    ).filter((f) => f.workoutDayId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _programWorkoutDaysRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExerciseGroupsTable, List<ExerciseGroup>>
  _exerciseGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseGroups,
    aliasName: $_aliasNameGenerator(
      db.workoutDays.id,
      db.exerciseGroups.workoutDayId,
    ),
  );

  $$ExerciseGroupsTableProcessedTableManager get exerciseGroupsRefs {
    final manager = $$ExerciseGroupsTableTableManager(
      $_db,
      $_db.exerciseGroups,
    ).filter((f) => f.workoutDayId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exerciseGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutDaysTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> programWorkoutDaysRefs(
    Expression<bool> Function($$ProgramWorkoutDaysTableFilterComposer f) f,
  ) {
    final $$ProgramWorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programWorkoutDays,
      getReferencedColumn: (t) => t.workoutDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramWorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.programWorkoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseGroupsRefs(
    Expression<bool> Function($$ExerciseGroupsTableFilterComposer f) f,
  ) {
    final $$ExerciseGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseGroups,
      getReferencedColumn: (t) => t.workoutDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseGroupsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> programWorkoutDaysRefs<T extends Object>(
    Expression<T> Function($$ProgramWorkoutDaysTableAnnotationComposer a) f,
  ) {
    final $$ProgramWorkoutDaysTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.programWorkoutDays,
          getReferencedColumn: (t) => t.workoutDayId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProgramWorkoutDaysTableAnnotationComposer(
                $db: $db,
                $table: $db.programWorkoutDays,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> exerciseGroupsRefs<T extends Object>(
    Expression<T> Function($$ExerciseGroupsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseGroups,
      getReferencedColumn: (t) => t.workoutDayId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutDaysTable,
          WorkoutDay,
          $$WorkoutDaysTableFilterComposer,
          $$WorkoutDaysTableOrderingComposer,
          $$WorkoutDaysTableAnnotationComposer,
          $$WorkoutDaysTableCreateCompanionBuilder,
          $$WorkoutDaysTableUpdateCompanionBuilder,
          (WorkoutDay, $$WorkoutDaysTableReferences),
          WorkoutDay,
          PrefetchHooks Function({
            bool programId,
            bool programWorkoutDaysRefs,
            bool exerciseGroupsRefs,
          })
        > {
  $$WorkoutDaysTableTableManager(_$AppDatabase db, $WorkoutDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutDaysCompanion(
                id: id,
                programId: programId,
                name: name,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String programId,
                required String name,
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => WorkoutDaysCompanion.insert(
                id: id,
                programId: programId,
                name: name,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                programId = false,
                programWorkoutDaysRefs = false,
                exerciseGroupsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (programWorkoutDaysRefs) db.programWorkoutDays,
                    if (exerciseGroupsRefs) db.exerciseGroups,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (programId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.programId,
                                    referencedTable:
                                        $$WorkoutDaysTableReferences
                                            ._programIdTable(db),
                                    referencedColumn:
                                        $$WorkoutDaysTableReferences
                                            ._programIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (programWorkoutDaysRefs)
                        await $_getPrefetchedData<
                          WorkoutDay,
                          $WorkoutDaysTable,
                          ProgramWorkoutDay
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutDaysTableReferences
                              ._programWorkoutDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).programWorkoutDaysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseGroupsRefs)
                        await $_getPrefetchedData<
                          WorkoutDay,
                          $WorkoutDaysTable,
                          ExerciseGroup
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutDaysTableReferences
                              ._exerciseGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutDaysTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutDayId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutDaysTable,
      WorkoutDay,
      $$WorkoutDaysTableFilterComposer,
      $$WorkoutDaysTableOrderingComposer,
      $$WorkoutDaysTableAnnotationComposer,
      $$WorkoutDaysTableCreateCompanionBuilder,
      $$WorkoutDaysTableUpdateCompanionBuilder,
      (WorkoutDay, $$WorkoutDaysTableReferences),
      WorkoutDay,
      PrefetchHooks Function({
        bool programId,
        bool programWorkoutDaysRefs,
        bool exerciseGroupsRefs,
      })
    >;
typedef $$ProgramWorkoutDaysTableCreateCompanionBuilder =
    ProgramWorkoutDaysCompanion Function({
      required String programId,
      required String workoutDayId,
      required int position,
      Value<int> rowid,
    });
typedef $$ProgramWorkoutDaysTableUpdateCompanionBuilder =
    ProgramWorkoutDaysCompanion Function({
      Value<String> programId,
      Value<String> workoutDayId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$ProgramWorkoutDaysTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProgramWorkoutDaysTable,
          ProgramWorkoutDay
        > {
  $$ProgramWorkoutDaysTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProgramsTable _programIdTable(_$AppDatabase db) =>
      db.programs.createAlias(
        $_aliasNameGenerator(db.programWorkoutDays.programId, db.programs.id),
      );

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<String>('program_id')!;

    final manager = $$ProgramsTableTableManager(
      $_db,
      $_db.programs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WorkoutDaysTable _workoutDayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias(
        $_aliasNameGenerator(
          db.programWorkoutDays.workoutDayId,
          db.workoutDays.id,
        ),
      );

  $$WorkoutDaysTableProcessedTableManager get workoutDayId {
    final $_column = $_itemColumn<String>('workout_day_id')!;

    final manager = $$WorkoutDaysTableTableManager(
      $_db,
      $_db.workoutDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgramWorkoutDaysTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramWorkoutDaysTable> {
  $$ProgramWorkoutDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableFilterComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutDaysTableFilterComposer get workoutDayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutDayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramWorkoutDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramWorkoutDaysTable> {
  $$ProgramWorkoutDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutDaysTableOrderingComposer get workoutDayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutDayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableOrderingComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramWorkoutDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramWorkoutDaysTable> {
  $$ProgramWorkoutDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.programs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutDaysTableAnnotationComposer get workoutDayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutDayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgramWorkoutDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramWorkoutDaysTable,
          ProgramWorkoutDay,
          $$ProgramWorkoutDaysTableFilterComposer,
          $$ProgramWorkoutDaysTableOrderingComposer,
          $$ProgramWorkoutDaysTableAnnotationComposer,
          $$ProgramWorkoutDaysTableCreateCompanionBuilder,
          $$ProgramWorkoutDaysTableUpdateCompanionBuilder,
          (ProgramWorkoutDay, $$ProgramWorkoutDaysTableReferences),
          ProgramWorkoutDay,
          PrefetchHooks Function({bool programId, bool workoutDayId})
        > {
  $$ProgramWorkoutDaysTableTableManager(
    _$AppDatabase db,
    $ProgramWorkoutDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramWorkoutDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramWorkoutDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramWorkoutDaysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> programId = const Value.absent(),
                Value<String> workoutDayId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramWorkoutDaysCompanion(
                programId: programId,
                workoutDayId: workoutDayId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String programId,
                required String workoutDayId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => ProgramWorkoutDaysCompanion.insert(
                programId: programId,
                workoutDayId: workoutDayId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProgramWorkoutDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programId = false, workoutDayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programId,
                                referencedTable:
                                    $$ProgramWorkoutDaysTableReferences
                                        ._programIdTable(db),
                                referencedColumn:
                                    $$ProgramWorkoutDaysTableReferences
                                        ._programIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (workoutDayId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutDayId,
                                referencedTable:
                                    $$ProgramWorkoutDaysTableReferences
                                        ._workoutDayIdTable(db),
                                referencedColumn:
                                    $$ProgramWorkoutDaysTableReferences
                                        ._workoutDayIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgramWorkoutDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramWorkoutDaysTable,
      ProgramWorkoutDay,
      $$ProgramWorkoutDaysTableFilterComposer,
      $$ProgramWorkoutDaysTableOrderingComposer,
      $$ProgramWorkoutDaysTableAnnotationComposer,
      $$ProgramWorkoutDaysTableCreateCompanionBuilder,
      $$ProgramWorkoutDaysTableUpdateCompanionBuilder,
      (ProgramWorkoutDay, $$ProgramWorkoutDaysTableReferences),
      ProgramWorkoutDay,
      PrefetchHooks Function({bool programId, bool workoutDayId})
    >;
typedef $$ExerciseGroupsTableCreateCompanionBuilder =
    ExerciseGroupsCompanion Function({
      required String id,
      required String workoutDayId,
      required int position,
      required String kindDiscriminator,
      required String kindPayloadJson,
      Value<String> roleDiscriminator,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$ExerciseGroupsTableUpdateCompanionBuilder =
    ExerciseGroupsCompanion Function({
      Value<String> id,
      Value<String> workoutDayId,
      Value<int> position,
      Value<String> kindDiscriminator,
      Value<String> kindPayloadJson,
      Value<String> roleDiscriminator,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$ExerciseGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $ExerciseGroupsTable, ExerciseGroup> {
  $$ExerciseGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutDaysTable _workoutDayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias(
        $_aliasNameGenerator(db.exerciseGroups.workoutDayId, db.workoutDays.id),
      );

  $$WorkoutDaysTableProcessedTableManager get workoutDayId {
    final $_column = $_itemColumn<String>('workout_day_id')!;

    final manager = $$WorkoutDaysTableTableManager(
      $_db,
      $_db.workoutDays,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutDayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExercisesTable, List<Exercise>>
  _exercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exercises,
    aliasName: $_aliasNameGenerator(
      db.exerciseGroups.id,
      db.exercises.exerciseGroupId,
    ),
  );

  $$ExercisesTableProcessedTableManager get exercisesRefs {
    final manager = $$ExercisesTableTableManager($_db, $_db.exercises).filter(
      (f) => f.exerciseGroupId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_exercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExerciseGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseGroupsTable> {
  $$ExerciseGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kindDiscriminator => $composableBuilder(
    column: $table.kindDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kindPayloadJson => $composableBuilder(
    column: $table.kindPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleDiscriminator => $composableBuilder(
    column: $table.roleDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutDaysTableFilterComposer get workoutDayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutDayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableFilterComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> exercisesRefs(
    Expression<bool> Function($$ExercisesTableFilterComposer f) f,
  ) {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.exerciseGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExerciseGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseGroupsTable> {
  $$ExerciseGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kindDiscriminator => $composableBuilder(
    column: $table.kindDiscriminator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kindPayloadJson => $composableBuilder(
    column: $table.kindPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleDiscriminator => $composableBuilder(
    column: $table.roleDiscriminator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutDaysTableOrderingComposer get workoutDayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutDayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableOrderingComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseGroupsTable> {
  $$ExerciseGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get kindDiscriminator => $composableBuilder(
    column: $table.kindDiscriminator,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kindPayloadJson => $composableBuilder(
    column: $table.kindPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roleDiscriminator => $composableBuilder(
    column: $table.roleDiscriminator,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$WorkoutDaysTableAnnotationComposer get workoutDayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutDayId,
      referencedTable: $db.workoutDays,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> exercisesRefs<T extends Object>(
    Expression<T> Function($$ExercisesTableAnnotationComposer a) f,
  ) {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.exerciseGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExerciseGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseGroupsTable,
          ExerciseGroup,
          $$ExerciseGroupsTableFilterComposer,
          $$ExerciseGroupsTableOrderingComposer,
          $$ExerciseGroupsTableAnnotationComposer,
          $$ExerciseGroupsTableCreateCompanionBuilder,
          $$ExerciseGroupsTableUpdateCompanionBuilder,
          (ExerciseGroup, $$ExerciseGroupsTableReferences),
          ExerciseGroup,
          PrefetchHooks Function({bool workoutDayId, bool exercisesRefs})
        > {
  $$ExerciseGroupsTableTableManager(
    _$AppDatabase db,
    $ExerciseGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workoutDayId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> kindDiscriminator = const Value.absent(),
                Value<String> kindPayloadJson = const Value.absent(),
                Value<String> roleDiscriminator = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseGroupsCompanion(
                id: id,
                workoutDayId: workoutDayId,
                position: position,
                kindDiscriminator: kindDiscriminator,
                kindPayloadJson: kindPayloadJson,
                roleDiscriminator: roleDiscriminator,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workoutDayId,
                required int position,
                required String kindDiscriminator,
                required String kindPayloadJson,
                Value<String> roleDiscriminator = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseGroupsCompanion.insert(
                id: id,
                workoutDayId: workoutDayId,
                position: position,
                kindDiscriminator: kindDiscriminator,
                kindPayloadJson: kindPayloadJson,
                roleDiscriminator: roleDiscriminator,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workoutDayId = false, exercisesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (exercisesRefs) db.exercises],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workoutDayId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workoutDayId,
                                    referencedTable:
                                        $$ExerciseGroupsTableReferences
                                            ._workoutDayIdTable(db),
                                    referencedColumn:
                                        $$ExerciseGroupsTableReferences
                                            ._workoutDayIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exercisesRefs)
                        await $_getPrefetchedData<
                          ExerciseGroup,
                          $ExerciseGroupsTable,
                          Exercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExerciseGroupsTableReferences
                              ._exercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExerciseGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).exercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseGroupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExerciseGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseGroupsTable,
      ExerciseGroup,
      $$ExerciseGroupsTableFilterComposer,
      $$ExerciseGroupsTableOrderingComposer,
      $$ExerciseGroupsTableAnnotationComposer,
      $$ExerciseGroupsTableCreateCompanionBuilder,
      $$ExerciseGroupsTableUpdateCompanionBuilder,
      (ExerciseGroup, $$ExerciseGroupsTableReferences),
      ExerciseGroup,
      PrefetchHooks Function({bool workoutDayId, bool exercisesRefs})
    >;
typedef $$LibraryExercisesTableCreateCompanionBuilder =
    LibraryExercisesCompanion Function({
      required String id,
      required String name,
      required String nameLower,
      required String measurementTypeDiscriminator,
      required String measurementTypePayloadJson,
      Value<String> source,
      Value<String> prominence,
      Value<String> primaryMusclesJson,
      Value<String> secondaryMusclesJson,
      Value<String?> videoUrl,
      Value<String?> cues,
      Value<int?> archivedAtMs,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$LibraryExercisesTableUpdateCompanionBuilder =
    LibraryExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> nameLower,
      Value<String> measurementTypeDiscriminator,
      Value<String> measurementTypePayloadJson,
      Value<String> source,
      Value<String> prominence,
      Value<String> primaryMusclesJson,
      Value<String> secondaryMusclesJson,
      Value<String?> videoUrl,
      Value<String?> cues,
      Value<int?> archivedAtMs,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$LibraryExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $LibraryExercisesTable, LibraryExercise> {
  $$LibraryExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ExercisesTable, List<Exercise>>
  _exercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exercises,
    aliasName: $_aliasNameGenerator(
      db.libraryExercises.id,
      db.exercises.libraryExerciseId,
    ),
  );

  $$ExercisesTableProcessedTableManager get exercisesRefs {
    final manager = $$ExercisesTableTableManager($_db, $_db.exercises).filter(
      (f) => f.libraryExerciseId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_exercisesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryExercisesTable> {
  $$LibraryExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameLower => $composableBuilder(
    column: $table.nameLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementTypeDiscriminator => $composableBuilder(
    column: $table.measurementTypeDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementTypePayloadJson => $composableBuilder(
    column: $table.measurementTypePayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prominence => $composableBuilder(
    column: $table.prominence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryMusclesJson => $composableBuilder(
    column: $table.primaryMusclesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryMusclesJson => $composableBuilder(
    column: $table.secondaryMusclesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cues => $composableBuilder(
    column: $table.cues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAtMs => $composableBuilder(
    column: $table.archivedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exercisesRefs(
    Expression<bool> Function($$ExercisesTableFilterComposer f) f,
  ) {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.libraryExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryExercisesTable> {
  $$LibraryExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameLower => $composableBuilder(
    column: $table.nameLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementTypeDiscriminator =>
      $composableBuilder(
        column: $table.measurementTypeDiscriminator,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get measurementTypePayloadJson => $composableBuilder(
    column: $table.measurementTypePayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prominence => $composableBuilder(
    column: $table.prominence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryMusclesJson => $composableBuilder(
    column: $table.primaryMusclesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryMusclesJson => $composableBuilder(
    column: $table.secondaryMusclesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cues => $composableBuilder(
    column: $table.cues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAtMs => $composableBuilder(
    column: $table.archivedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryExercisesTable> {
  $$LibraryExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameLower =>
      $composableBuilder(column: $table.nameLower, builder: (column) => column);

  GeneratedColumn<String> get measurementTypeDiscriminator =>
      $composableBuilder(
        column: $table.measurementTypeDiscriminator,
        builder: (column) => column,
      );

  GeneratedColumn<String> get measurementTypePayloadJson => $composableBuilder(
    column: $table.measurementTypePayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get prominence => $composableBuilder(
    column: $table.prominence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryMusclesJson => $composableBuilder(
    column: $table.primaryMusclesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryMusclesJson => $composableBuilder(
    column: $table.secondaryMusclesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get cues =>
      $composableBuilder(column: $table.cues, builder: (column) => column);

  GeneratedColumn<int> get archivedAtMs => $composableBuilder(
    column: $table.archivedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  Expression<T> exercisesRefs<T extends Object>(
    Expression<T> Function($$ExercisesTableAnnotationComposer a) f,
  ) {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.libraryExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryExercisesTable,
          LibraryExercise,
          $$LibraryExercisesTableFilterComposer,
          $$LibraryExercisesTableOrderingComposer,
          $$LibraryExercisesTableAnnotationComposer,
          $$LibraryExercisesTableCreateCompanionBuilder,
          $$LibraryExercisesTableUpdateCompanionBuilder,
          (LibraryExercise, $$LibraryExercisesTableReferences),
          LibraryExercise,
          PrefetchHooks Function({bool exercisesRefs})
        > {
  $$LibraryExercisesTableTableManager(
    _$AppDatabase db,
    $LibraryExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameLower = const Value.absent(),
                Value<String> measurementTypeDiscriminator =
                    const Value.absent(),
                Value<String> measurementTypePayloadJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> prominence = const Value.absent(),
                Value<String> primaryMusclesJson = const Value.absent(),
                Value<String> secondaryMusclesJson = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> cues = const Value.absent(),
                Value<int?> archivedAtMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryExercisesCompanion(
                id: id,
                name: name,
                nameLower: nameLower,
                measurementTypeDiscriminator: measurementTypeDiscriminator,
                measurementTypePayloadJson: measurementTypePayloadJson,
                source: source,
                prominence: prominence,
                primaryMusclesJson: primaryMusclesJson,
                secondaryMusclesJson: secondaryMusclesJson,
                videoUrl: videoUrl,
                cues: cues,
                archivedAtMs: archivedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String nameLower,
                required String measurementTypeDiscriminator,
                required String measurementTypePayloadJson,
                Value<String> source = const Value.absent(),
                Value<String> prominence = const Value.absent(),
                Value<String> primaryMusclesJson = const Value.absent(),
                Value<String> secondaryMusclesJson = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> cues = const Value.absent(),
                Value<int?> archivedAtMs = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => LibraryExercisesCompanion.insert(
                id: id,
                name: name,
                nameLower: nameLower,
                measurementTypeDiscriminator: measurementTypeDiscriminator,
                measurementTypePayloadJson: measurementTypePayloadJson,
                source: source,
                prominence: prominence,
                primaryMusclesJson: primaryMusclesJson,
                secondaryMusclesJson: secondaryMusclesJson,
                videoUrl: videoUrl,
                cues: cues,
                archivedAtMs: archivedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LibraryExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (exercisesRefs) db.exercises],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exercisesRefs)
                    await $_getPrefetchedData<
                      LibraryExercise,
                      $LibraryExercisesTable,
                      Exercise
                    >(
                      currentTable: table,
                      referencedTable: $$LibraryExercisesTableReferences
                          ._exercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LibraryExercisesTableReferences(
                            db,
                            table,
                            p0,
                          ).exercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.libraryExerciseId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LibraryExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryExercisesTable,
      LibraryExercise,
      $$LibraryExercisesTableFilterComposer,
      $$LibraryExercisesTableOrderingComposer,
      $$LibraryExercisesTableAnnotationComposer,
      $$LibraryExercisesTableCreateCompanionBuilder,
      $$LibraryExercisesTableUpdateCompanionBuilder,
      (LibraryExercise, $$LibraryExercisesTableReferences),
      LibraryExercise,
      PrefetchHooks Function({bool exercisesRefs})
    >;
typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      required String id,
      required String exerciseGroupId,
      required int position,
      required String name,
      required String measurementTypeDiscriminator,
      required String measurementTypePayloadJson,
      Value<String?> notes,
      Value<String?> videoUrl,
      Value<int?> plannedRestSeconds,
      Value<String?> libraryExerciseId,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<String> id,
      Value<String> exerciseGroupId,
      Value<int> position,
      Value<String> name,
      Value<String> measurementTypeDiscriminator,
      Value<String> measurementTypePayloadJson,
      Value<String?> notes,
      Value<String?> videoUrl,
      Value<int?> plannedRestSeconds,
      Value<String?> libraryExerciseId,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExerciseGroupsTable _exerciseGroupIdTable(_$AppDatabase db) =>
      db.exerciseGroups.createAlias(
        $_aliasNameGenerator(
          db.exercises.exerciseGroupId,
          db.exerciseGroups.id,
        ),
      );

  $$ExerciseGroupsTableProcessedTableManager get exerciseGroupId {
    final $_column = $_itemColumn<String>('exercise_group_id')!;

    final manager = $$ExerciseGroupsTableTableManager(
      $_db,
      $_db.exerciseGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LibraryExercisesTable _libraryExerciseIdTable(_$AppDatabase db) =>
      db.libraryExercises.createAlias(
        $_aliasNameGenerator(
          db.exercises.libraryExerciseId,
          db.libraryExercises.id,
        ),
      );

  $$LibraryExercisesTableProcessedTableManager? get libraryExerciseId {
    final $_column = $_itemColumn<String>('library_exercise_id');
    if ($_column == null) return null;
    final manager = $$LibraryExercisesTableTableManager(
      $_db,
      $_db.libraryExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
  _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSets,
    aliasName: $_aliasNameGenerator(db.exercises.id, db.workoutSets.exerciseId),
  );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementTypeDiscriminator => $composableBuilder(
    column: $table.measurementTypeDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementTypePayloadJson => $composableBuilder(
    column: $table.measurementTypePayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedRestSeconds => $composableBuilder(
    column: $table.plannedRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$ExerciseGroupsTableFilterComposer get exerciseGroupId {
    final $$ExerciseGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseGroupId,
      referencedTable: $db.exerciseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseGroupsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryExercisesTableFilterComposer get libraryExerciseId {
    final $$LibraryExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryExerciseId,
      referencedTable: $db.libraryExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryExercisesTableFilterComposer(
            $db: $db,
            $table: $db.libraryExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutSetsRefs(
    Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementTypeDiscriminator =>
      $composableBuilder(
        column: $table.measurementTypeDiscriminator,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get measurementTypePayloadJson => $composableBuilder(
    column: $table.measurementTypePayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedRestSeconds => $composableBuilder(
    column: $table.plannedRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExerciseGroupsTableOrderingComposer get exerciseGroupId {
    final $$ExerciseGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseGroupId,
      referencedTable: $db.exerciseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.exerciseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryExercisesTableOrderingComposer get libraryExerciseId {
    final $$LibraryExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryExerciseId,
      referencedTable: $db.libraryExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.libraryExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get measurementTypeDiscriminator =>
      $composableBuilder(
        column: $table.measurementTypeDiscriminator,
        builder: (column) => column,
      );

  GeneratedColumn<String> get measurementTypePayloadJson => $composableBuilder(
    column: $table.measurementTypePayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<int> get plannedRestSeconds => $composableBuilder(
    column: $table.plannedRestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$ExerciseGroupsTableAnnotationComposer get exerciseGroupId {
    final $$ExerciseGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseGroupId,
      referencedTable: $db.exerciseGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryExercisesTableAnnotationComposer get libraryExerciseId {
    final $$LibraryExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryExerciseId,
      referencedTable: $db.libraryExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutSetsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({
            bool exerciseGroupId,
            bool libraryExerciseId,
            bool workoutSetsRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> exerciseGroupId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> measurementTypeDiscriminator =
                    const Value.absent(),
                Value<String> measurementTypePayloadJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<int?> plannedRestSeconds = const Value.absent(),
                Value<String?> libraryExerciseId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                exerciseGroupId: exerciseGroupId,
                position: position,
                name: name,
                measurementTypeDiscriminator: measurementTypeDiscriminator,
                measurementTypePayloadJson: measurementTypePayloadJson,
                notes: notes,
                videoUrl: videoUrl,
                plannedRestSeconds: plannedRestSeconds,
                libraryExerciseId: libraryExerciseId,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String exerciseGroupId,
                required int position,
                required String name,
                required String measurementTypeDiscriminator,
                required String measurementTypePayloadJson,
                Value<String?> notes = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<int?> plannedRestSeconds = const Value.absent(),
                Value<String?> libraryExerciseId = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                exerciseGroupId: exerciseGroupId,
                position: position,
                name: name,
                measurementTypeDiscriminator: measurementTypeDiscriminator,
                measurementTypePayloadJson: measurementTypePayloadJson,
                notes: notes,
                videoUrl: videoUrl,
                plannedRestSeconds: plannedRestSeconds,
                libraryExerciseId: libraryExerciseId,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                exerciseGroupId = false,
                libraryExerciseId = false,
                workoutSetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutSetsRefs) db.workoutSets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (exerciseGroupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exerciseGroupId,
                                    referencedTable: $$ExercisesTableReferences
                                        ._exerciseGroupIdTable(db),
                                    referencedColumn: $$ExercisesTableReferences
                                        ._exerciseGroupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (libraryExerciseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.libraryExerciseId,
                                    referencedTable: $$ExercisesTableReferences
                                        ._libraryExerciseIdTable(db),
                                    referencedColumn: $$ExercisesTableReferences
                                        ._libraryExerciseIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutSetsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          WorkoutSet
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._workoutSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({
        bool exerciseGroupId,
        bool libraryExerciseId,
        bool workoutSetsRefs,
      })
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder =
    WorkoutSetsCompanion Function({
      required String id,
      required String exerciseId,
      required int position,
      required String plannedValuesDiscriminator,
      required String plannedValuesPayloadJson,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$WorkoutSetsTableUpdateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<String> id,
      Value<String> exerciseId,
      Value<int> position,
      Value<String> plannedValuesDiscriminator,
      Value<String> plannedValuesPayloadJson,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.workoutSets.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedValuesDiscriminator => $composableBuilder(
    column: $table.plannedValuesDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedValuesPayloadJson => $composableBuilder(
    column: $table.plannedValuesPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedValuesDiscriminator => $composableBuilder(
    column: $table.plannedValuesDiscriminator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedValuesPayloadJson => $composableBuilder(
    column: $table.plannedValuesPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get plannedValuesDiscriminator => $composableBuilder(
    column: $table.plannedValuesDiscriminator,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plannedValuesPayloadJson => $composableBuilder(
    column: $table.plannedValuesPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetsTable,
          WorkoutSet,
          $$WorkoutSetsTableFilterComposer,
          $$WorkoutSetsTableOrderingComposer,
          $$WorkoutSetsTableAnnotationComposer,
          $$WorkoutSetsTableCreateCompanionBuilder,
          $$WorkoutSetsTableUpdateCompanionBuilder,
          (WorkoutSet, $$WorkoutSetsTableReferences),
          WorkoutSet,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> plannedValuesDiscriminator = const Value.absent(),
                Value<String> plannedValuesPayloadJson = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion(
                id: id,
                exerciseId: exerciseId,
                position: position,
                plannedValuesDiscriminator: plannedValuesDiscriminator,
                plannedValuesPayloadJson: plannedValuesPayloadJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String exerciseId,
                required int position,
                required String plannedValuesDiscriminator,
                required String plannedValuesPayloadJson,
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                position: position,
                plannedValuesDiscriminator: plannedValuesDiscriminator,
                plannedValuesPayloadJson: plannedValuesPayloadJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$WorkoutSetsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$WorkoutSetsTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetsTable,
      WorkoutSet,
      $$WorkoutSetsTableFilterComposer,
      $$WorkoutSetsTableOrderingComposer,
      $$WorkoutSetsTableAnnotationComposer,
      $$WorkoutSetsTableCreateCompanionBuilder,
      $$WorkoutSetsTableUpdateCompanionBuilder,
      (WorkoutSet, $$WorkoutSetsTableReferences),
      WorkoutSet,
      PrefetchHooks Function({bool exerciseId})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String workoutDayId,
      required String snapshotJson,
      required String snapshotHash,
      required int startedAtMs,
      Value<int?> endedAtMs,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<bool> isDeload,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> workoutDayId,
      Value<String> snapshotJson,
      Value<String> snapshotHash,
      Value<int> startedAtMs,
      Value<int?> endedAtMs,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<bool> isDeload,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
  _sessionExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionExercises,
    aliasName: $_aliasNameGenerator(
      db.sessions.id,
      db.sessionExercises.sessionId,
    ),
  );

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionNotesTable, List<SessionNote>>
  _sessionNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionNotes,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.sessionNotes.sessionId),
  );

  $$SessionNotesTableProcessedTableManager get sessionNotesRefs {
    final manager = $$SessionNotesTableTableManager(
      $_db,
      $_db.sessionNotes,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExtraWorkItemsTable, List<ExtraWorkItem>>
  _extraWorkItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.extraWorkItems,
    aliasName: $_aliasNameGenerator(
      db.sessions.id,
      db.extraWorkItems.sessionId,
    ),
  );

  $$ExtraWorkItemsTableProcessedTableManager get extraWorkItemsRefs {
    final manager = $$ExtraWorkItemsTableTableManager(
      $_db,
      $_db.extraWorkItems,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_extraWorkItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutDayId => $composableBuilder(
    column: $table.workoutDayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotHash => $composableBuilder(
    column: $table.snapshotHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeload => $composableBuilder(
    column: $table.isDeload,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionExercisesRefs(
    Expression<bool> Function($$SessionExercisesTableFilterComposer f) f,
  ) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionNotesRefs(
    Expression<bool> Function($$SessionNotesTableFilterComposer f) f,
  ) {
    final $$SessionNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionNotes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionNotesTableFilterComposer(
            $db: $db,
            $table: $db.sessionNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> extraWorkItemsRefs(
    Expression<bool> Function($$ExtraWorkItemsTableFilterComposer f) f,
  ) {
    final $$ExtraWorkItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extraWorkItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtraWorkItemsTableFilterComposer(
            $db: $db,
            $table: $db.extraWorkItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutDayId => $composableBuilder(
    column: $table.workoutDayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotHash => $composableBuilder(
    column: $table.snapshotHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeload => $composableBuilder(
    column: $table.isDeload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutDayId => $composableBuilder(
    column: $table.workoutDayId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshotHash => $composableBuilder(
    column: $table.snapshotHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMs =>
      $composableBuilder(column: $table.endedAtMs, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeload =>
      $composableBuilder(column: $table.isDeload, builder: (column) => column);

  Expression<T> sessionExercisesRefs<T extends Object>(
    Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionNotesRefs<T extends Object>(
    Expression<T> Function($$SessionNotesTableAnnotationComposer a) f,
  ) {
    final $$SessionNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionNotes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> extraWorkItemsRefs<T extends Object>(
    Expression<T> Function($$ExtraWorkItemsTableAnnotationComposer a) f,
  ) {
    final $$ExtraWorkItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extraWorkItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtraWorkItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.extraWorkItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool sessionExercisesRefs,
            bool sessionNotesRefs,
            bool extraWorkItemsRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workoutDayId = const Value.absent(),
                Value<String> snapshotJson = const Value.absent(),
                Value<String> snapshotHash = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<bool> isDeload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                workoutDayId: workoutDayId,
                snapshotJson: snapshotJson,
                snapshotHash: snapshotHash,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                isDeload: isDeload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workoutDayId,
                required String snapshotJson,
                required String snapshotHash,
                required int startedAtMs,
                Value<int?> endedAtMs = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<bool> isDeload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                workoutDayId: workoutDayId,
                snapshotJson: snapshotJson,
                snapshotHash: snapshotHash,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                isDeload: isDeload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionExercisesRefs = false,
                sessionNotesRefs = false,
                extraWorkItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionExercisesRefs) db.sessionExercises,
                    if (sessionNotesRefs) db.sessionNotes,
                    if (extraWorkItemsRefs) db.extraWorkItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionExercisesRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          SessionExercise
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._sessionExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionNotesRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          SessionNote
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._sessionNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (extraWorkItemsRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          ExtraWorkItem
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._extraWorkItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).extraWorkItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool sessionExercisesRefs,
        bool sessionNotesRefs,
        bool extraWorkItemsRefs,
      })
    >;
typedef $$SessionExercisesTableCreateCompanionBuilder =
    SessionExercisesCompanion Function({
      required String id,
      required String sessionId,
      required int position,
      required String plannedExerciseIdInSnapshot,
      required String stateDiscriminator,
      Value<String?> substitutePayloadJson,
      Value<String?> supersetTag,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$SessionExercisesTableUpdateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> position,
      Value<String> plannedExerciseIdInSnapshot,
      Value<String> stateDiscriminator,
      Value<String?> substitutePayloadJson,
      Value<String?> supersetTag,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$SessionExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionExercisesTable, SessionExercise> {
  $$SessionExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.sessionExercises.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExecutedSetsTable, List<ExecutedSet>>
  _executedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.executedSets,
    aliasName: $_aliasNameGenerator(
      db.sessionExercises.id,
      db.executedSets.sessionExerciseId,
    ),
  );

  $$ExecutedSetsTableProcessedTableManager get executedSetsRefs {
    final manager = $$ExecutedSetsTableTableManager($_db, $_db.executedSets)
        .filter(
          (f) => f.sessionExerciseId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_executedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedExerciseIdInSnapshot => $composableBuilder(
    column: $table.plannedExerciseIdInSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateDiscriminator => $composableBuilder(
    column: $table.stateDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get substitutePayloadJson => $composableBuilder(
    column: $table.substitutePayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersetTag => $composableBuilder(
    column: $table.supersetTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> executedSetsRefs(
    Expression<bool> Function($$ExecutedSetsTableFilterComposer f) f,
  ) {
    final $$ExecutedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.executedSets,
      getReferencedColumn: (t) => t.sessionExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExecutedSetsTableFilterComposer(
            $db: $db,
            $table: $db.executedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedExerciseIdInSnapshot => $composableBuilder(
    column: $table.plannedExerciseIdInSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateDiscriminator => $composableBuilder(
    column: $table.stateDiscriminator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get substitutePayloadJson => $composableBuilder(
    column: $table.substitutePayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersetTag => $composableBuilder(
    column: $table.supersetTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get plannedExerciseIdInSnapshot => $composableBuilder(
    column: $table.plannedExerciseIdInSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stateDiscriminator => $composableBuilder(
    column: $table.stateDiscriminator,
    builder: (column) => column,
  );

  GeneratedColumn<String> get substitutePayloadJson => $composableBuilder(
    column: $table.substitutePayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supersetTag => $composableBuilder(
    column: $table.supersetTag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> executedSetsRefs<T extends Object>(
    Expression<T> Function($$ExecutedSetsTableAnnotationComposer a) f,
  ) {
    final $$ExecutedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.executedSets,
      getReferencedColumn: (t) => t.sessionExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExecutedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.executedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionExercisesTable,
          SessionExercise,
          $$SessionExercisesTableFilterComposer,
          $$SessionExercisesTableOrderingComposer,
          $$SessionExercisesTableAnnotationComposer,
          $$SessionExercisesTableCreateCompanionBuilder,
          $$SessionExercisesTableUpdateCompanionBuilder,
          (SessionExercise, $$SessionExercisesTableReferences),
          SessionExercise,
          PrefetchHooks Function({bool sessionId, bool executedSetsRefs})
        > {
  $$SessionExercisesTableTableManager(
    _$AppDatabase db,
    $SessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> plannedExerciseIdInSnapshot =
                    const Value.absent(),
                Value<String> stateDiscriminator = const Value.absent(),
                Value<String?> substitutePayloadJson = const Value.absent(),
                Value<String?> supersetTag = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionExercisesCompanion(
                id: id,
                sessionId: sessionId,
                position: position,
                plannedExerciseIdInSnapshot: plannedExerciseIdInSnapshot,
                stateDiscriminator: stateDiscriminator,
                substitutePayloadJson: substitutePayloadJson,
                supersetTag: supersetTag,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int position,
                required String plannedExerciseIdInSnapshot,
                required String stateDiscriminator,
                Value<String?> substitutePayloadJson = const Value.absent(),
                Value<String?> supersetTag = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => SessionExercisesCompanion.insert(
                id: id,
                sessionId: sessionId,
                position: position,
                plannedExerciseIdInSnapshot: plannedExerciseIdInSnapshot,
                stateDiscriminator: stateDiscriminator,
                substitutePayloadJson: substitutePayloadJson,
                supersetTag: supersetTag,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, executedSetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (executedSetsRefs) db.executedSets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sessionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sessionId,
                                    referencedTable:
                                        $$SessionExercisesTableReferences
                                            ._sessionIdTable(db),
                                    referencedColumn:
                                        $$SessionExercisesTableReferences
                                            ._sessionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (executedSetsRefs)
                        await $_getPrefetchedData<
                          SessionExercise,
                          $SessionExercisesTable,
                          ExecutedSet
                        >(
                          currentTable: table,
                          referencedTable: $$SessionExercisesTableReferences
                              ._executedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).executedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionExerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionExercisesTable,
      SessionExercise,
      $$SessionExercisesTableFilterComposer,
      $$SessionExercisesTableOrderingComposer,
      $$SessionExercisesTableAnnotationComposer,
      $$SessionExercisesTableCreateCompanionBuilder,
      $$SessionExercisesTableUpdateCompanionBuilder,
      (SessionExercise, $$SessionExercisesTableReferences),
      SessionExercise,
      PrefetchHooks Function({bool sessionId, bool executedSetsRefs})
    >;
typedef $$ExecutedSetsTableCreateCompanionBuilder =
    ExecutedSetsCompanion Function({
      required String id,
      required String sessionExerciseId,
      required int position,
      required String measurementTypeDiscriminator,
      required String actualValuesDiscriminator,
      required String actualValuesPayloadJson,
      Value<String?> plannedSetIdInSnapshot,
      required int completedAtMs,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$ExecutedSetsTableUpdateCompanionBuilder =
    ExecutedSetsCompanion Function({
      Value<String> id,
      Value<String> sessionExerciseId,
      Value<int> position,
      Value<String> measurementTypeDiscriminator,
      Value<String> actualValuesDiscriminator,
      Value<String> actualValuesPayloadJson,
      Value<String?> plannedSetIdInSnapshot,
      Value<int> completedAtMs,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$ExecutedSetsTableReferences
    extends BaseReferences<_$AppDatabase, $ExecutedSetsTable, ExecutedSet> {
  $$ExecutedSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionExercisesTable _sessionExerciseIdTable(_$AppDatabase db) =>
      db.sessionExercises.createAlias(
        $_aliasNameGenerator(
          db.executedSets.sessionExerciseId,
          db.sessionExercises.id,
        ),
      );

  $$SessionExercisesTableProcessedTableManager get sessionExerciseId {
    final $_column = $_itemColumn<String>('session_exercise_id')!;

    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExecutedSetsTableFilterComposer
    extends Composer<_$AppDatabase, $ExecutedSetsTable> {
  $$ExecutedSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementTypeDiscriminator => $composableBuilder(
    column: $table.measurementTypeDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualValuesDiscriminator => $composableBuilder(
    column: $table.actualValuesDiscriminator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualValuesPayloadJson => $composableBuilder(
    column: $table.actualValuesPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedSetIdInSnapshot => $composableBuilder(
    column: $table.plannedSetIdInSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionExercisesTableFilterComposer get sessionExerciseId {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExecutedSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExecutedSetsTable> {
  $$ExecutedSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementTypeDiscriminator =>
      $composableBuilder(
        column: $table.measurementTypeDiscriminator,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get actualValuesDiscriminator => $composableBuilder(
    column: $table.actualValuesDiscriminator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualValuesPayloadJson => $composableBuilder(
    column: $table.actualValuesPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedSetIdInSnapshot => $composableBuilder(
    column: $table.plannedSetIdInSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionExercisesTableOrderingComposer get sessionExerciseId {
    final $$SessionExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExecutedSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExecutedSetsTable> {
  $$ExecutedSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get measurementTypeDiscriminator =>
      $composableBuilder(
        column: $table.measurementTypeDiscriminator,
        builder: (column) => column,
      );

  GeneratedColumn<String> get actualValuesDiscriminator => $composableBuilder(
    column: $table.actualValuesDiscriminator,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actualValuesPayloadJson => $composableBuilder(
    column: $table.actualValuesPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plannedSetIdInSnapshot => $composableBuilder(
    column: $table.plannedSetIdInSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$SessionExercisesTableAnnotationComposer get sessionExerciseId {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExecutedSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExecutedSetsTable,
          ExecutedSet,
          $$ExecutedSetsTableFilterComposer,
          $$ExecutedSetsTableOrderingComposer,
          $$ExecutedSetsTableAnnotationComposer,
          $$ExecutedSetsTableCreateCompanionBuilder,
          $$ExecutedSetsTableUpdateCompanionBuilder,
          (ExecutedSet, $$ExecutedSetsTableReferences),
          ExecutedSet,
          PrefetchHooks Function({bool sessionExerciseId})
        > {
  $$ExecutedSetsTableTableManager(_$AppDatabase db, $ExecutedSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExecutedSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExecutedSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExecutedSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionExerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> measurementTypeDiscriminator =
                    const Value.absent(),
                Value<String> actualValuesDiscriminator = const Value.absent(),
                Value<String> actualValuesPayloadJson = const Value.absent(),
                Value<String?> plannedSetIdInSnapshot = const Value.absent(),
                Value<int> completedAtMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExecutedSetsCompanion(
                id: id,
                sessionExerciseId: sessionExerciseId,
                position: position,
                measurementTypeDiscriminator: measurementTypeDiscriminator,
                actualValuesDiscriminator: actualValuesDiscriminator,
                actualValuesPayloadJson: actualValuesPayloadJson,
                plannedSetIdInSnapshot: plannedSetIdInSnapshot,
                completedAtMs: completedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionExerciseId,
                required int position,
                required String measurementTypeDiscriminator,
                required String actualValuesDiscriminator,
                required String actualValuesPayloadJson,
                Value<String?> plannedSetIdInSnapshot = const Value.absent(),
                required int completedAtMs,
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => ExecutedSetsCompanion.insert(
                id: id,
                sessionExerciseId: sessionExerciseId,
                position: position,
                measurementTypeDiscriminator: measurementTypeDiscriminator,
                actualValuesDiscriminator: actualValuesDiscriminator,
                actualValuesPayloadJson: actualValuesPayloadJson,
                plannedSetIdInSnapshot: plannedSetIdInSnapshot,
                completedAtMs: completedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExecutedSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionExerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionExerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionExerciseId,
                                referencedTable: $$ExecutedSetsTableReferences
                                    ._sessionExerciseIdTable(db),
                                referencedColumn: $$ExecutedSetsTableReferences
                                    ._sessionExerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExecutedSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExecutedSetsTable,
      ExecutedSet,
      $$ExecutedSetsTableFilterComposer,
      $$ExecutedSetsTableOrderingComposer,
      $$ExecutedSetsTableAnnotationComposer,
      $$ExecutedSetsTableCreateCompanionBuilder,
      $$ExecutedSetsTableUpdateCompanionBuilder,
      (ExecutedSet, $$ExecutedSetsTableReferences),
      ExecutedSet,
      PrefetchHooks Function({bool sessionExerciseId})
    >;
typedef $$SessionNotesTableCreateCompanionBuilder =
    SessionNotesCompanion Function({
      required String id,
      required String sessionId,
      required String body,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$SessionNotesTableUpdateCompanionBuilder =
    SessionNotesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> body,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$SessionNotesTableReferences
    extends BaseReferences<_$AppDatabase, $SessionNotesTable, SessionNote> {
  $$SessionNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.sessionNotes.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionNotesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionNotesTable> {
  $$SessionNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionNotesTable> {
  $$SessionNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionNotesTable> {
  $$SessionNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionNotesTable,
          SessionNote,
          $$SessionNotesTableFilterComposer,
          $$SessionNotesTableOrderingComposer,
          $$SessionNotesTableAnnotationComposer,
          $$SessionNotesTableCreateCompanionBuilder,
          $$SessionNotesTableUpdateCompanionBuilder,
          (SessionNote, $$SessionNotesTableReferences),
          SessionNote,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionNotesTableTableManager(_$AppDatabase db, $SessionNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionNotesCompanion(
                id: id,
                sessionId: sessionId,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String body,
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => SessionNotesCompanion.insert(
                id: id,
                sessionId: sessionId,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$SessionNotesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$SessionNotesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionNotesTable,
      SessionNote,
      $$SessionNotesTableFilterComposer,
      $$SessionNotesTableOrderingComposer,
      $$SessionNotesTableAnnotationComposer,
      $$SessionNotesTableCreateCompanionBuilder,
      $$SessionNotesTableUpdateCompanionBuilder,
      (SessionNote, $$SessionNotesTableReferences),
      SessionNote,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$ExtraWorkItemsTableCreateCompanionBuilder =
    ExtraWorkItemsCompanion Function({
      required String id,
      required String sessionId,
      required int position,
      required String body,
      required int createdAtMs,
      required int updatedAtMs,
      required int schemaVersion,
      Value<int> rowid,
    });
typedef $$ExtraWorkItemsTableUpdateCompanionBuilder =
    ExtraWorkItemsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<int> position,
      Value<String> body,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$ExtraWorkItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ExtraWorkItemsTable, ExtraWorkItem> {
  $$ExtraWorkItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.extraWorkItems.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExtraWorkItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ExtraWorkItemsTable> {
  $$ExtraWorkItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraWorkItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtraWorkItemsTable> {
  $$ExtraWorkItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraWorkItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtraWorkItemsTable> {
  $$ExtraWorkItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraWorkItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtraWorkItemsTable,
          ExtraWorkItem,
          $$ExtraWorkItemsTableFilterComposer,
          $$ExtraWorkItemsTableOrderingComposer,
          $$ExtraWorkItemsTableAnnotationComposer,
          $$ExtraWorkItemsTableCreateCompanionBuilder,
          $$ExtraWorkItemsTableUpdateCompanionBuilder,
          (ExtraWorkItem, $$ExtraWorkItemsTableReferences),
          ExtraWorkItem,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ExtraWorkItemsTableTableManager(
    _$AppDatabase db,
    $ExtraWorkItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtraWorkItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtraWorkItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtraWorkItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtraWorkItemsCompanion(
                id: id,
                sessionId: sessionId,
                position: position,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int position,
                required String body,
                required int createdAtMs,
                required int updatedAtMs,
                required int schemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => ExtraWorkItemsCompanion.insert(
                id: id,
                sessionId: sessionId,
                position: position,
                body: body,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExtraWorkItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$ExtraWorkItemsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn:
                                    $$ExtraWorkItemsTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExtraWorkItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtraWorkItemsTable,
      ExtraWorkItem,
      $$ExtraWorkItemsTableFilterComposer,
      $$ExtraWorkItemsTableOrderingComposer,
      $$ExtraWorkItemsTableAnnotationComposer,
      $$ExtraWorkItemsTableCreateCompanionBuilder,
      $$ExtraWorkItemsTableUpdateCompanionBuilder,
      (ExtraWorkItem, $$ExtraWorkItemsTableReferences),
      ExtraWorkItem,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db, _db.workoutDays);
  $$ProgramWorkoutDaysTableTableManager get programWorkoutDays =>
      $$ProgramWorkoutDaysTableTableManager(_db, _db.programWorkoutDays);
  $$ExerciseGroupsTableTableManager get exerciseGroups =>
      $$ExerciseGroupsTableTableManager(_db, _db.exerciseGroups);
  $$LibraryExercisesTableTableManager get libraryExercises =>
      $$LibraryExercisesTableTableManager(_db, _db.libraryExercises);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(_db, _db.sessionExercises);
  $$ExecutedSetsTableTableManager get executedSets =>
      $$ExecutedSetsTableTableManager(_db, _db.executedSets);
  $$SessionNotesTableTableManager get sessionNotes =>
      $$SessionNotesTableTableManager(_db, _db.sessionNotes);
  $$ExtraWorkItemsTableTableManager get extraWorkItems =>
      $$ExtraWorkItemsTableTableManager(_db, _db.extraWorkItems);
}
