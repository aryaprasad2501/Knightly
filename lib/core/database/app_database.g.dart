// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting({required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value), updatedAt: Value(updatedAt));
  }

  factory AppSetting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value, updatedAt: updatedAt ?? this.updatedAt);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, ProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, uuid, name, createdAt, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<ProjectRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectRow extends DataClass implements Insertable<ProjectRow> {
  final int id;

  /// Stable id across devices and backups (see `newUuid`).
  final String uuid;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the project is in the Recycle Bin. Its missions keep the link
  /// (shown without a project meanwhile), so restoring reconnects them.
  final DateTime? deletedAt;
  const ProjectRow({
    required this.id,
    required this.uuid,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory ProjectRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ProjectRow copyWith({
    int? id,
    String? uuid,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ProjectRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ProjectRow copyWithCompanion(ProjectsCompanion data) {
    return ProjectRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, name, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ProjectRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES projects (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMinuteMeta = const VerificationMeta('dueMinute');
  @override
  late final GeneratedColumn<int> dueMinute = GeneratedColumn<int>(
    'due_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta('recurrence');
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextTaskIdMeta = const VerificationMeta('nextTaskId');
  @override
  late final GeneratedColumn<int> nextTaskId = GeneratedColumn<int>(
    'next_task_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    title,
    notes,
    priority,
    projectId,
    dueDate,
    dueMinute,
    recurrence,
    nextTaskId,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<TaskRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta, priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta, projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta, dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('due_minute')) {
      context.handle(_dueMinuteMeta, dueMinute.isAcceptableOrUnknown(data['due_minute']!, _dueMinuteMeta));
    }
    if (data.containsKey('recurrence')) {
      context.handle(_recurrenceMeta, recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta));
    }
    if (data.containsKey('next_task_id')) {
      context.handle(
        _nextTaskIdMeta,
        nextTaskId.isAcceptableOrUnknown(data['next_task_id']!, _nextTaskIdMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      priority: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      projectId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}project_id']),
      dueDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}due_date']),
      dueMinute: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}due_minute']),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      ),
      nextTaskId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}next_task_id']),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final int id;

  /// Stable id across devices and backups (see `newUuid`).
  final String uuid;
  final String title;
  final String notes;

  /// `TaskPriority.storageValue`.
  final int priority;

  /// Deleting a project keeps its missions (they become unassigned).
  final int? projectId;

  /// Local calendar date, `yyyy-MM-dd` (see `CalendarDate`).
  final String? dueDate;

  /// Minutes after midnight; only set together with [dueDate].
  final int? dueMinute;

  /// `Recurrence.encode()` text.
  final String? recurrence;

  /// For a completed (or skipped) occurrence of a repeating mission: the
  /// occurrence created at that moment, so undo / restore can remove it again.
  final int? nextTaskId;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the mission is in the Recycle Bin.
  final DateTime? deletedAt;
  const TaskRow({
    required this.id,
    required this.uuid,
    required this.title,
    required this.notes,
    required this.priority,
    this.projectId,
    this.dueDate,
    this.dueMinute,
    this.recurrence,
    this.nextTaskId,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || dueMinute != null) {
      map['due_minute'] = Variable<int>(dueMinute);
    }
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<String>(recurrence);
    }
    if (!nullToAbsent || nextTaskId != null) {
      map['next_task_id'] = Variable<int>(nextTaskId);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      uuid: Value(uuid),
      title: Value(title),
      notes: Value(notes),
      priority: Value(priority),
      projectId: projectId == null && nullToAbsent ? const Value.absent() : Value(projectId),
      dueDate: dueDate == null && nullToAbsent ? const Value.absent() : Value(dueDate),
      dueMinute: dueMinute == null && nullToAbsent ? const Value.absent() : Value(dueMinute),
      recurrence: recurrence == null && nullToAbsent ? const Value.absent() : Value(recurrence),
      nextTaskId: nextTaskId == null && nullToAbsent ? const Value.absent() : Value(nextTaskId),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory TaskRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      priority: serializer.fromJson<int>(json['priority']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      dueMinute: serializer.fromJson<int?>(json['dueMinute']),
      recurrence: serializer.fromJson<String?>(json['recurrence']),
      nextTaskId: serializer.fromJson<int?>(json['nextTaskId']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'priority': serializer.toJson<int>(priority),
      'projectId': serializer.toJson<int?>(projectId),
      'dueDate': serializer.toJson<String?>(dueDate),
      'dueMinute': serializer.toJson<int?>(dueMinute),
      'recurrence': serializer.toJson<String?>(recurrence),
      'nextTaskId': serializer.toJson<int?>(nextTaskId),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TaskRow copyWith({
    int? id,
    String? uuid,
    String? title,
    String? notes,
    int? priority,
    Value<int?> projectId = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    Value<int?> dueMinute = const Value.absent(),
    Value<String?> recurrence = const Value.absent(),
    Value<int?> nextTaskId = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    priority: priority ?? this.priority,
    projectId: projectId.present ? projectId.value : this.projectId,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueMinute: dueMinute.present ? dueMinute.value : this.dueMinute,
    recurrence: recurrence.present ? recurrence.value : this.recurrence,
    nextTaskId: nextTaskId.present ? nextTaskId.value : this.nextTaskId,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      priority: data.priority.present ? data.priority.value : this.priority,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueMinute: data.dueMinute.present ? data.dueMinute.value : this.dueMinute,
      recurrence: data.recurrence.present ? data.recurrence.value : this.recurrence,
      nextTaskId: data.nextTaskId.present ? data.nextTaskId.value : this.nextTaskId,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority, ')
          ..write('projectId: $projectId, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinute: $dueMinute, ')
          ..write('recurrence: $recurrence, ')
          ..write('nextTaskId: $nextTaskId, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    title,
    notes,
    priority,
    projectId,
    dueDate,
    dueMinute,
    recurrence,
    nextTaskId,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.priority == this.priority &&
          other.projectId == this.projectId &&
          other.dueDate == this.dueDate &&
          other.dueMinute == this.dueMinute &&
          other.recurrence == this.recurrence &&
          other.nextTaskId == this.nextTaskId &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> title;
  final Value<String> notes;
  final Value<int> priority;
  final Value<int?> projectId;
  final Value<String?> dueDate;
  final Value<int?> dueMinute;
  final Value<String?> recurrence;
  final Value<int?> nextTaskId;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.projectId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueMinute = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.nextTaskId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.priority = const Value.absent(),
    this.projectId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueMinute = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.nextTaskId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<TaskRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? priority,
    Expression<int>? projectId,
    Expression<String>? dueDate,
    Expression<int>? dueMinute,
    Expression<String>? recurrence,
    Expression<int>? nextTaskId,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (priority != null) 'priority': priority,
      if (projectId != null) 'project_id': projectId,
      if (dueDate != null) 'due_date': dueDate,
      if (dueMinute != null) 'due_minute': dueMinute,
      if (recurrence != null) 'recurrence': recurrence,
      if (nextTaskId != null) 'next_task_id': nextTaskId,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? title,
    Value<String>? notes,
    Value<int>? priority,
    Value<int?>? projectId,
    Value<String?>? dueDate,
    Value<int?>? dueMinute,
    Value<String?>? recurrence,
    Value<int?>? nextTaskId,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      dueDate: dueDate ?? this.dueDate,
      dueMinute: dueMinute ?? this.dueMinute,
      recurrence: recurrence ?? this.recurrence,
      nextTaskId: nextTaskId ?? this.nextTaskId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (dueMinute.present) {
      map['due_minute'] = Variable<int>(dueMinute.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (nextTaskId.present) {
      map['next_task_id'] = Variable<int>(nextTaskId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('priority: $priority, ')
          ..write('projectId: $projectId, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinute: $dueMinute, ')
          ..write('recurrence: $recurrence, ')
          ..write('nextTaskId: $nextTaskId, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scheduleMeta = const VerificationMeta('schedule');
  @override
  late final GeneratedColumn<String> schedule = GeneratedColumn<String>(
    'schedule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    kind,
    schedule,
    target,
    startDate,
    createdAt,
    updatedAt,
    archivedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<HabitRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('schedule')) {
      context.handle(_scheduleMeta, schedule.isAcceptableOrUnknown(data['schedule']!, _scheduleMeta));
    } else if (isInserting) {
      context.missing(_scheduleMeta);
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta, target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta, startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      schedule: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}schedule'])!,
      target: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}target'])!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class HabitRow extends DataClass implements Insertable<HabitRow> {
  final int id;

  /// Stable id across devices and backups (see `newUuid`).
  final String uuid;
  final String name;

  /// `HabitKind.storageValue`.
  final int kind;

  /// `HabitSchedule.encode()` text.
  final String schedule;

  /// Check-ins needed per day.
  final int target;

  /// `yyyy-MM-dd`; days before it are never counted.
  final String startDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  /// Set when the habit is in the Recycle Bin. Its check-ins are kept, so
  /// restoring brings the full history back.
  final DateTime? deletedAt;
  const HabitRow({
    required this.id,
    required this.uuid,
    required this.name,
    required this.kind,
    required this.schedule,
    required this.target,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<int>(kind);
    map['schedule'] = Variable<String>(schedule);
    map['target'] = Variable<int>(target);
    map['start_date'] = Variable<String>(startDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      kind: Value(kind),
      schedule: Value(schedule),
      target: Value(target),
      startDate: Value(startDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent ? const Value.absent() : Value(archivedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory HabitRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<int>(json['kind']),
      schedule: serializer.fromJson<String>(json['schedule']),
      target: serializer.fromJson<int>(json['target']),
      startDate: serializer.fromJson<String>(json['startDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<int>(kind),
      'schedule': serializer.toJson<String>(schedule),
      'target': serializer.toJson<int>(target),
      'startDate': serializer.toJson<String>(startDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  HabitRow copyWith({
    int? id,
    String? uuid,
    String? name,
    int? kind,
    String? schedule,
    int? target,
    String? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => HabitRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    schedule: schedule ?? this.schedule,
    target: target ?? this.target,
    startDate: startDate ?? this.startDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  HabitRow copyWithCompanion(HabitsCompanion data) {
    return HabitRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      schedule: data.schedule.present ? data.schedule.value : this.schedule,
      target: data.target.present ? data.target.value : this.target,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('schedule: $schedule, ')
          ..write('target: $target, ')
          ..write('startDate: $startDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    kind,
    schedule,
    target,
    startDate,
    createdAt,
    updatedAt,
    archivedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.schedule == this.schedule &&
          other.target == this.target &&
          other.startDate == this.startDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt &&
          other.deletedAt == this.deletedAt);
}

class HabitsCompanion extends UpdateCompanion<HabitRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> kind;
  final Value<String> schedule;
  final Value<int> target;
  final Value<String> startDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> deletedAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.schedule = const Value.absent(),
    this.target = const Value.absent(),
    this.startDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String name,
    this.kind = const Value.absent(),
    required String schedule,
    this.target = const Value.absent(),
    required String startDate,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name),
       schedule = Value(schedule),
       startDate = Value(startDate);
  static Insertable<HabitRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? kind,
    Expression<String>? schedule,
    Expression<int>? target,
    Expression<String>? startDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (schedule != null) 'schedule': schedule,
      if (target != null) 'target': target,
      if (startDate != null) 'start_date': startDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<int>? kind,
    Value<String>? schedule,
    Value<int>? target,
    Value<String>? startDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      schedule: schedule ?? this.schedule,
      target: target ?? this.target,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (schedule.present) {
      map['schedule'] = Variable<String>(schedule.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('schedule: $schedule, ')
          ..write('target: $target, ')
          ..write('startDate: $startDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $HabitCheckInsTable extends HabitCheckIns with TableInfo<$HabitCheckInsTable, HabitCheckInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitCheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES habits (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [habitId, date, count, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_check_ins';
  @override
  VerificationContext validateIntegrity(Insertable<HabitCheckInRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta, habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('count')) {
      context.handle(_countMeta, count.isAcceptableOrUnknown(data['count']!, _countMeta));
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId, date};
  @override
  HabitCheckInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitCheckInRow(
      habitId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}habit_id'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      count: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}count'])!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitCheckInsTable createAlias(String alias) {
    return $HabitCheckInsTable(attachedDatabase, alias);
  }
}

class HabitCheckInRow extends DataClass implements Insertable<HabitCheckInRow> {
  /// Permanently deleting a habit deletes its history; moving it to the
  /// Recycle Bin does not.
  final int habitId;

  /// `yyyy-MM-dd`.
  final String date;
  final int count;
  final DateTime updatedAt;
  const HabitCheckInRow({
    required this.habitId,
    required this.date,
    required this.count,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<int>(habitId);
    map['date'] = Variable<String>(date);
    map['count'] = Variable<int>(count);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitCheckInsCompanion toCompanion(bool nullToAbsent) {
    return HabitCheckInsCompanion(
      habitId: Value(habitId),
      date: Value(date),
      count: Value(count),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitCheckInRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitCheckInRow(
      habitId: serializer.fromJson<int>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      count: serializer.fromJson<int>(json['count']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<int>(habitId),
      'date': serializer.toJson<String>(date),
      'count': serializer.toJson<int>(count),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitCheckInRow copyWith({int? habitId, String? date, int? count, DateTime? updatedAt}) => HabitCheckInRow(
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    count: count ?? this.count,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitCheckInRow copyWithCompanion(HabitCheckInsCompanion data) {
    return HabitCheckInRow(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      count: data.count.present ? data.count.value : this.count,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitCheckInRow(')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitId, date, count, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitCheckInRow &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.count == this.count &&
          other.updatedAt == this.updatedAt);
}

class HabitCheckInsCompanion extends UpdateCompanion<HabitCheckInRow> {
  final Value<int> habitId;
  final Value<String> date;
  final Value<int> count;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitCheckInsCompanion({
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.count = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitCheckInsCompanion.insert({
    required int habitId,
    required String date,
    required int count,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId),
       date = Value(date),
       count = Value(count);
  static Insertable<HabitCheckInRow> custom({
    Expression<int>? habitId,
    Expression<String>? date,
    Expression<int>? count,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (count != null) 'count': count,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitCheckInsCompanion copyWith({
    Value<int>? habitId,
    Value<String>? date,
    Value<int>? count,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitCheckInsCompanion(
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      count: count ?? this.count,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitCheckInsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta('startMinute');
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta('recurrence');
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    title,
    notes,
    kind,
    startDate,
    startMinute,
    durationMinutes,
    recurrence,
    reminderMinutes,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<EventRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta, startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(data['start_minute']!, _startMinuteMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(data['duration_minutes']!, _durationMinutesMeta),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(_recurrenceMeta, recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta));
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(data['reminder_minutes']!, _reminderMinutesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      ),
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final int id;
  final String uuid;
  final String title;
  final String notes;

  /// `EventKind.storageValue`: 0 fixed, 1 flexible.
  final int kind;

  /// First (or only) occurrence, `yyyy-MM-dd`.
  final String startDate;

  /// Minutes after midnight; null = all day (fixed) or any time (flexible).
  final int? startMinute;

  /// Length in minutes; null for all-day and untimed events.
  final int? durationMinutes;

  /// `Recurrence.encode()` text; null = happens once.
  final String? recurrence;

  /// Minutes before the start to remind; null = no reminder. Stored now,
  /// delivered once notifications exist.
  final int? reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the event (the whole series) is in the Recycle Bin.
  final DateTime? deletedAt;
  const EventRow({
    required this.id,
    required this.uuid,
    required this.title,
    required this.notes,
    required this.kind,
    required this.startDate,
    this.startMinute,
    this.durationMinutes,
    this.recurrence,
    this.reminderMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    map['kind'] = Variable<int>(kind);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<String>(recurrence);
    }
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      title: Value(title),
      notes: Value(notes),
      kind: Value(kind),
      startDate: Value(startDate),
      startMinute: startMinute == null && nullToAbsent ? const Value.absent() : Value(startMinute),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      recurrence: recurrence == null && nullToAbsent ? const Value.absent() : Value(recurrence),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory EventRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      kind: serializer.fromJson<int>(json['kind']),
      startDate: serializer.fromJson<String>(json['startDate']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      recurrence: serializer.fromJson<String?>(json['recurrence']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'kind': serializer.toJson<int>(kind),
      'startDate': serializer.toJson<String>(startDate),
      'startMinute': serializer.toJson<int?>(startMinute),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'recurrence': serializer.toJson<String?>(recurrence),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  EventRow copyWith({
    int? id,
    String? uuid,
    String? title,
    String? notes,
    int? kind,
    String? startDate,
    Value<int?> startMinute = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> recurrence = const Value.absent(),
    Value<int?> reminderMinutes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => EventRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    kind: kind ?? this.kind,
    startDate: startDate ?? this.startDate,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    durationMinutes: durationMinutes.present ? durationMinutes.value : this.durationMinutes,
    recurrence: recurrence.present ? recurrence.value : this.recurrence,
    reminderMinutes: reminderMinutes.present ? reminderMinutes.value : this.reminderMinutes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  EventRow copyWithCompanion(EventsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      kind: data.kind.present ? data.kind.value : this.kind,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      startMinute: data.startMinute.present ? data.startMinute.value : this.startMinute,
      durationMinutes: data.durationMinutes.present ? data.durationMinutes.value : this.durationMinutes,
      recurrence: data.recurrence.present ? data.recurrence.value : this.recurrence,
      reminderMinutes: data.reminderMinutes.present ? data.reminderMinutes.value : this.reminderMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('kind: $kind, ')
          ..write('startDate: $startDate, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('recurrence: $recurrence, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    title,
    notes,
    kind,
    startDate,
    startMinute,
    durationMinutes,
    recurrence,
    reminderMinutes,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.kind == this.kind &&
          other.startDate == this.startDate &&
          other.startMinute == this.startMinute &&
          other.durationMinutes == this.durationMinutes &&
          other.recurrence == this.recurrence &&
          other.reminderMinutes == this.reminderMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class EventsCompanion extends UpdateCompanion<EventRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> title;
  final Value<String> notes;
  final Value<int> kind;
  final Value<String> startDate;
  final Value<int?> startMinute;
  final Value<int?> durationMinutes;
  final Value<String?> recurrence;
  final Value<int?> reminderMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.kind = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.kind = const Value.absent(),
    required String startDate,
    this.startMinute = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       startDate = Value(startDate);
  static Insertable<EventRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<int>? kind,
    Expression<String>? startDate,
    Expression<int>? startMinute,
    Expression<int>? durationMinutes,
    Expression<String>? recurrence,
    Expression<int>? reminderMinutes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (kind != null) 'kind': kind,
      if (startDate != null) 'start_date': startDate,
      if (startMinute != null) 'start_minute': startMinute,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (recurrence != null) 'recurrence': recurrence,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  EventsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? title,
    Value<String>? notes,
    Value<int>? kind,
    Value<String>? startDate,
    Value<int?>? startMinute,
    Value<int?>? durationMinutes,
    Value<String?>? recurrence,
    Value<int?>? reminderMinutes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      kind: kind ?? this.kind,
      startDate: startDate ?? this.startDate,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recurrence: recurrence ?? this.recurrence,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('kind: $kind, ')
          ..write('startDate: $startDate, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('recurrence: $recurrence, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $EventExceptionsTable extends EventExceptions with TableInfo<$EventExceptionsTable, EventExceptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventExceptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES events (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta('skipped');
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("skipped" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movedDateMeta = const VerificationMeta('movedDate');
  @override
  late final GeneratedColumn<String> movedDate = GeneratedColumn<String>(
    'moved_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movedMinuteMeta = const VerificationMeta('movedMinute');
  @override
  late final GeneratedColumn<int> movedMinute = GeneratedColumn<int>(
    'moved_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, date, skipped, doneAt, movedDate, movedMinute, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_exceptions';
  @override
  VerificationContext validateIntegrity(Insertable<EventExceptionRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta, eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('skipped')) {
      context.handle(_skippedMeta, skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta));
    }
    if (data.containsKey('done_at')) {
      context.handle(_doneAtMeta, doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta));
    }
    if (data.containsKey('moved_date')) {
      context.handle(_movedDateMeta, movedDate.isAcceptableOrUnknown(data['moved_date']!, _movedDateMeta));
    }
    if (data.containsKey('moved_minute')) {
      context.handle(
        _movedMinuteMeta,
        movedMinute.isAcceptableOrUnknown(data['moved_minute']!, _movedMinuteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, date};
  @override
  EventExceptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventExceptionRow(
      eventId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}event_id'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      skipped: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}skipped'])!,
      doneAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}done_at']),
      movedDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}moved_date']),
      movedMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moved_minute'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EventExceptionsTable createAlias(String alias) {
    return $EventExceptionsTable(attachedDatabase, alias);
  }
}

class EventExceptionRow extends DataClass implements Insertable<EventExceptionRow> {
  /// Permanently deleting an event deletes its occurrence history.
  final int eventId;

  /// The occurrence's original date, `yyyy-MM-dd`.
  final String date;
  final bool skipped;
  final DateTime? doneAt;

  /// Where the occurrence was moved to, if rescheduled.
  final String? movedDate;
  final int? movedMinute;
  final DateTime updatedAt;
  const EventExceptionRow({
    required this.eventId,
    required this.date,
    required this.skipped,
    this.doneAt,
    this.movedDate,
    this.movedMinute,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<int>(eventId);
    map['date'] = Variable<String>(date);
    map['skipped'] = Variable<bool>(skipped);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    if (!nullToAbsent || movedDate != null) {
      map['moved_date'] = Variable<String>(movedDate);
    }
    if (!nullToAbsent || movedMinute != null) {
      map['moved_minute'] = Variable<int>(movedMinute);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EventExceptionsCompanion toCompanion(bool nullToAbsent) {
    return EventExceptionsCompanion(
      eventId: Value(eventId),
      date: Value(date),
      skipped: Value(skipped),
      doneAt: doneAt == null && nullToAbsent ? const Value.absent() : Value(doneAt),
      movedDate: movedDate == null && nullToAbsent ? const Value.absent() : Value(movedDate),
      movedMinute: movedMinute == null && nullToAbsent ? const Value.absent() : Value(movedMinute),
      updatedAt: Value(updatedAt),
    );
  }

  factory EventExceptionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventExceptionRow(
      eventId: serializer.fromJson<int>(json['eventId']),
      date: serializer.fromJson<String>(json['date']),
      skipped: serializer.fromJson<bool>(json['skipped']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
      movedDate: serializer.fromJson<String?>(json['movedDate']),
      movedMinute: serializer.fromJson<int?>(json['movedMinute']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<int>(eventId),
      'date': serializer.toJson<String>(date),
      'skipped': serializer.toJson<bool>(skipped),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
      'movedDate': serializer.toJson<String?>(movedDate),
      'movedMinute': serializer.toJson<int?>(movedMinute),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EventExceptionRow copyWith({
    int? eventId,
    String? date,
    bool? skipped,
    Value<DateTime?> doneAt = const Value.absent(),
    Value<String?> movedDate = const Value.absent(),
    Value<int?> movedMinute = const Value.absent(),
    DateTime? updatedAt,
  }) => EventExceptionRow(
    eventId: eventId ?? this.eventId,
    date: date ?? this.date,
    skipped: skipped ?? this.skipped,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    movedDate: movedDate.present ? movedDate.value : this.movedDate,
    movedMinute: movedMinute.present ? movedMinute.value : this.movedMinute,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EventExceptionRow copyWithCompanion(EventExceptionsCompanion data) {
    return EventExceptionRow(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      date: data.date.present ? data.date.value : this.date,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      movedDate: data.movedDate.present ? data.movedDate.value : this.movedDate,
      movedMinute: data.movedMinute.present ? data.movedMinute.value : this.movedMinute,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventExceptionRow(')
          ..write('eventId: $eventId, ')
          ..write('date: $date, ')
          ..write('skipped: $skipped, ')
          ..write('doneAt: $doneAt, ')
          ..write('movedDate: $movedDate, ')
          ..write('movedMinute: $movedMinute, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, date, skipped, doneAt, movedDate, movedMinute, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventExceptionRow &&
          other.eventId == this.eventId &&
          other.date == this.date &&
          other.skipped == this.skipped &&
          other.doneAt == this.doneAt &&
          other.movedDate == this.movedDate &&
          other.movedMinute == this.movedMinute &&
          other.updatedAt == this.updatedAt);
}

class EventExceptionsCompanion extends UpdateCompanion<EventExceptionRow> {
  final Value<int> eventId;
  final Value<String> date;
  final Value<bool> skipped;
  final Value<DateTime?> doneAt;
  final Value<String?> movedDate;
  final Value<int?> movedMinute;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EventExceptionsCompanion({
    this.eventId = const Value.absent(),
    this.date = const Value.absent(),
    this.skipped = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.movedDate = const Value.absent(),
    this.movedMinute = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventExceptionsCompanion.insert({
    required int eventId,
    required String date,
    this.skipped = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.movedDate = const Value.absent(),
    this.movedMinute = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       date = Value(date);
  static Insertable<EventExceptionRow> custom({
    Expression<int>? eventId,
    Expression<String>? date,
    Expression<bool>? skipped,
    Expression<DateTime>? doneAt,
    Expression<String>? movedDate,
    Expression<int>? movedMinute,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (date != null) 'date': date,
      if (skipped != null) 'skipped': skipped,
      if (doneAt != null) 'done_at': doneAt,
      if (movedDate != null) 'moved_date': movedDate,
      if (movedMinute != null) 'moved_minute': movedMinute,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventExceptionsCompanion copyWith({
    Value<int>? eventId,
    Value<String>? date,
    Value<bool>? skipped,
    Value<DateTime?>? doneAt,
    Value<String?>? movedDate,
    Value<int?>? movedMinute,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventExceptionsCompanion(
      eventId: eventId ?? this.eventId,
      date: date ?? this.date,
      skipped: skipped ?? this.skipped,
      doneAt: doneAt ?? this.doneAt,
      movedDate: movedDate ?? this.movedDate,
      movedMinute: movedMinute ?? this.movedMinute,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (movedDate.present) {
      map['moved_date'] = Variable<String>(movedDate.value);
    }
    if (movedMinute.present) {
      map['moved_minute'] = Variable<int>(movedMinute.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventExceptionsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('date: $date, ')
          ..write('skipped: $skipped, ')
          ..write('doneAt: $doneAt, ')
          ..write('movedDate: $movedDate, ')
          ..write('movedMinute: $movedMinute, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, RoutineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta('timeOfDay');
  @override
  late final GeneratedColumn<int> timeOfDay = GeneratedColumn<int>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scheduleMeta = const VerificationMeta('schedule');
  @override
  late final GeneratedColumn<String> schedule = GeneratedColumn<String>(
    'schedule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta('startMinute');
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    timeOfDay,
    schedule,
    startMinute,
    reminderMinutes,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(_timeOfDayMeta, timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta));
    }
    if (data.containsKey('schedule')) {
      context.handle(_scheduleMeta, schedule.isAcceptableOrUnknown(data['schedule']!, _scheduleMeta));
    } else if (isInserting) {
      context.missing(_scheduleMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(data['start_minute']!, _startMinuteMeta),
      );
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(data['reminder_minutes']!, _reminderMinutesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      timeOfDay: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}time_of_day'])!,
      schedule: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}schedule'])!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class RoutineRow extends DataClass implements Insertable<RoutineRow> {
  final int id;
  final String uuid;
  final String name;

  /// `RoutineTimeOfDay.storageValue`: 0 any time, 1 morning, 2 afternoon, 3 evening.
  final int timeOfDay;

  /// `HabitSchedule.encode()` text: which days it is expected.
  final String schedule;

  /// Optional planned start, minutes after midnight (shown in Calendar).
  final int? startMinute;

  /// Minutes before the start to remind; null = none. Stored now, delivered
  /// once notifications exist.
  final int? reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when the routine is in the Recycle Bin (steps and runs are kept).
  final DateTime? deletedAt;
  const RoutineRow({
    required this.id,
    required this.uuid,
    required this.name,
    required this.timeOfDay,
    required this.schedule,
    this.startMinute,
    this.reminderMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['time_of_day'] = Variable<int>(timeOfDay);
    map['schedule'] = Variable<String>(schedule);
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      timeOfDay: Value(timeOfDay),
      schedule: Value(schedule),
      startMinute: startMinute == null && nullToAbsent ? const Value.absent() : Value(startMinute),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory RoutineRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      timeOfDay: serializer.fromJson<int>(json['timeOfDay']),
      schedule: serializer.fromJson<String>(json['schedule']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'timeOfDay': serializer.toJson<int>(timeOfDay),
      'schedule': serializer.toJson<String>(schedule),
      'startMinute': serializer.toJson<int?>(startMinute),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  RoutineRow copyWith({
    int? id,
    String? uuid,
    String? name,
    int? timeOfDay,
    String? schedule,
    Value<int?> startMinute = const Value.absent(),
    Value<int?> reminderMinutes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => RoutineRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    schedule: schedule ?? this.schedule,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    reminderMinutes: reminderMinutes.present ? reminderMinutes.value : this.reminderMinutes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  RoutineRow copyWithCompanion(RoutinesCompanion data) {
    return RoutineRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      schedule: data.schedule.present ? data.schedule.value : this.schedule,
      startMinute: data.startMinute.present ? data.startMinute.value : this.startMinute,
      reminderMinutes: data.reminderMinutes.present ? data.reminderMinutes.value : this.reminderMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('schedule: $schedule, ')
          ..write('startMinute: $startMinute, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    timeOfDay,
    schedule,
    startMinute,
    reminderMinutes,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.timeOfDay == this.timeOfDay &&
          other.schedule == this.schedule &&
          other.startMinute == this.startMinute &&
          other.reminderMinutes == this.reminderMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RoutinesCompanion extends UpdateCompanion<RoutineRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> timeOfDay;
  final Value<String> schedule;
  final Value<int?> startMinute;
  final Value<int?> reminderMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.schedule = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  RoutinesCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String name,
    this.timeOfDay = const Value.absent(),
    required String schedule,
    this.startMinute = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name),
       schedule = Value(schedule);
  static Insertable<RoutineRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? timeOfDay,
    Expression<String>? schedule,
    Expression<int>? startMinute,
    Expression<int>? reminderMinutes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (schedule != null) 'schedule': schedule,
      if (startMinute != null) 'start_minute': startMinute,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  RoutinesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<int>? timeOfDay,
    Value<String>? schedule,
    Value<int?>? startMinute,
    Value<int?>? reminderMinutes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
  }) {
    return RoutinesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      schedule: schedule ?? this.schedule,
      startMinute: startMinute ?? this.startMinute,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<int>(timeOfDay.value);
    }
    if (schedule.present) {
      map['schedule'] = Variable<String>(schedule.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('schedule: $schedule, ')
          ..write('startMinute: $startMinute, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $RoutineStepsTable extends RoutineSteps with TableInfo<$RoutineStepsTable, RoutineStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES routines (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 80),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, uuid, routineId, position, title, durationSeconds, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_steps';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineStepRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta, routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(data['duration_seconds']!, _durationSecondsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineStepRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      routineId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}routine_id'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RoutineStepsTable createAlias(String alias) {
    return $RoutineStepsTable(attachedDatabase, alias);
  }
}

class RoutineStepRow extends DataClass implements Insertable<RoutineStepRow> {
  final int id;
  final String uuid;

  /// Permanently deleting a routine deletes its steps.
  final int routineId;
  final int position;
  final String title;

  /// Optional timer length in seconds.
  final int? durationSeconds;
  final DateTime updatedAt;
  const RoutineStepRow({
    required this.id,
    required this.uuid,
    required this.routineId,
    required this.position,
    required this.title,
    this.durationSeconds,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['routine_id'] = Variable<int>(routineId);
    map['position'] = Variable<int>(position);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RoutineStepsCompanion toCompanion(bool nullToAbsent) {
    return RoutineStepsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      routineId: Value(routineId),
      position: Value(position),
      title: Value(title),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      updatedAt: Value(updatedAt),
    );
  }

  factory RoutineStepRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineStepRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      routineId: serializer.fromJson<int>(json['routineId']),
      position: serializer.fromJson<int>(json['position']),
      title: serializer.fromJson<String>(json['title']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'routineId': serializer.toJson<int>(routineId),
      'position': serializer.toJson<int>(position),
      'title': serializer.toJson<String>(title),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RoutineStepRow copyWith({
    int? id,
    String? uuid,
    int? routineId,
    int? position,
    String? title,
    Value<int?> durationSeconds = const Value.absent(),
    DateTime? updatedAt,
  }) => RoutineStepRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    routineId: routineId ?? this.routineId,
    position: position ?? this.position,
    title: title ?? this.title,
    durationSeconds: durationSeconds.present ? durationSeconds.value : this.durationSeconds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RoutineStepRow copyWithCompanion(RoutineStepsCompanion data) {
    return RoutineStepRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      position: data.position.present ? data.position.value : this.position,
      title: data.title.present ? data.title.value : this.title,
      durationSeconds: data.durationSeconds.present ? data.durationSeconds.value : this.durationSeconds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineStepRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('routineId: $routineId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, routineId, position, title, durationSeconds, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineStepRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.routineId == this.routineId &&
          other.position == this.position &&
          other.title == this.title &&
          other.durationSeconds == this.durationSeconds &&
          other.updatedAt == this.updatedAt);
}

class RoutineStepsCompanion extends UpdateCompanion<RoutineStepRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> routineId;
  final Value<int> position;
  final Value<String> title;
  final Value<int?> durationSeconds;
  final Value<DateTime> updatedAt;
  const RoutineStepsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.routineId = const Value.absent(),
    this.position = const Value.absent(),
    this.title = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RoutineStepsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required int routineId,
    required int position,
    required String title,
    this.durationSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : routineId = Value(routineId),
       position = Value(position),
       title = Value(title);
  static Insertable<RoutineStepRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? routineId,
    Expression<int>? position,
    Expression<String>? title,
    Expression<int>? durationSeconds,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (routineId != null) 'routine_id': routineId,
      if (position != null) 'position': position,
      if (title != null) 'title': title,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RoutineStepsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? routineId,
    Value<int>? position,
    Value<String>? title,
    Value<int?>? durationSeconds,
    Value<DateTime>? updatedAt,
  }) {
    return RoutineStepsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      routineId: routineId ?? this.routineId,
      position: position ?? this.position,
      title: title ?? this.title,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineStepsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('routineId: $routineId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RoutineRunsTable extends RoutineRuns with TableInfo<$RoutineRunsTable, RoutineRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES routines (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsDoneMeta = const VerificationMeta('stepsDone');
  @override
  late final GeneratedColumn<int> stepsDone = GeneratedColumn<int>(
    'steps_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stepsTotalMeta = const VerificationMeta('stepsTotal');
  @override
  late final GeneratedColumn<int> stepsTotal = GeneratedColumn<int>(
    'steps_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    routineId,
    date,
    startedAt,
    finishedAt,
    stepsDone,
    stepsTotal,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_runs';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineRunRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta, routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('steps_done')) {
      context.handle(_stepsDoneMeta, stepsDone.isAcceptableOrUnknown(data['steps_done']!, _stepsDoneMeta));
    }
    if (data.containsKey('steps_total')) {
      context.handle(
        _stepsTotalMeta,
        stepsTotal.isAcceptableOrUnknown(data['steps_total']!, _stepsTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsTotalMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineRunRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      routineId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}routine_id'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      stepsDone: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}steps_done'])!,
      stepsTotal: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}steps_total'])!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RoutineRunsTable createAlias(String alias) {
    return $RoutineRunsTable(attachedDatabase, alias);
  }
}

class RoutineRunRow extends DataClass implements Insertable<RoutineRunRow> {
  final int id;
  final String uuid;

  /// Permanently deleting a routine deletes its run history.
  final int routineId;

  /// The day it counts for, `yyyy-MM-dd`.
  final String date;
  final DateTime startedAt;

  /// Set when every step was done (or the run was finished early).
  final DateTime? finishedAt;
  final int stepsDone;
  final int stepsTotal;
  final DateTime updatedAt;
  const RoutineRunRow({
    required this.id,
    required this.uuid,
    required this.routineId,
    required this.date,
    required this.startedAt,
    this.finishedAt,
    required this.stepsDone,
    required this.stepsTotal,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['routine_id'] = Variable<int>(routineId);
    map['date'] = Variable<String>(date);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['steps_done'] = Variable<int>(stepsDone);
    map['steps_total'] = Variable<int>(stepsTotal);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RoutineRunsCompanion toCompanion(bool nullToAbsent) {
    return RoutineRunsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      routineId: Value(routineId),
      date: Value(date),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent ? const Value.absent() : Value(finishedAt),
      stepsDone: Value(stepsDone),
      stepsTotal: Value(stepsTotal),
      updatedAt: Value(updatedAt),
    );
  }

  factory RoutineRunRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineRunRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      routineId: serializer.fromJson<int>(json['routineId']),
      date: serializer.fromJson<String>(json['date']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      stepsDone: serializer.fromJson<int>(json['stepsDone']),
      stepsTotal: serializer.fromJson<int>(json['stepsTotal']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'routineId': serializer.toJson<int>(routineId),
      'date': serializer.toJson<String>(date),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'stepsDone': serializer.toJson<int>(stepsDone),
      'stepsTotal': serializer.toJson<int>(stepsTotal),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RoutineRunRow copyWith({
    int? id,
    String? uuid,
    int? routineId,
    String? date,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    int? stepsDone,
    int? stepsTotal,
    DateTime? updatedAt,
  }) => RoutineRunRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    routineId: routineId ?? this.routineId,
    date: date ?? this.date,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    stepsDone: stepsDone ?? this.stepsDone,
    stepsTotal: stepsTotal ?? this.stepsTotal,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RoutineRunRow copyWithCompanion(RoutineRunsCompanion data) {
    return RoutineRunRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      date: data.date.present ? data.date.value : this.date,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
      stepsDone: data.stepsDone.present ? data.stepsDone.value : this.stepsDone,
      stepsTotal: data.stepsTotal.present ? data.stepsTotal.value : this.stepsTotal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineRunRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('routineId: $routineId, ')
          ..write('date: $date, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('stepsDone: $stepsDone, ')
          ..write('stepsTotal: $stepsTotal, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, routineId, date, startedAt, finishedAt, stepsDone, stepsTotal, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineRunRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.routineId == this.routineId &&
          other.date == this.date &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.stepsDone == this.stepsDone &&
          other.stepsTotal == this.stepsTotal &&
          other.updatedAt == this.updatedAt);
}

class RoutineRunsCompanion extends UpdateCompanion<RoutineRunRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> routineId;
  final Value<String> date;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> stepsDone;
  final Value<int> stepsTotal;
  final Value<DateTime> updatedAt;
  const RoutineRunsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.routineId = const Value.absent(),
    this.date = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.stepsDone = const Value.absent(),
    this.stepsTotal = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RoutineRunsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required int routineId,
    required String date,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.stepsDone = const Value.absent(),
    required int stepsTotal,
    this.updatedAt = const Value.absent(),
  }) : routineId = Value(routineId),
       date = Value(date),
       startedAt = Value(startedAt),
       stepsTotal = Value(stepsTotal);
  static Insertable<RoutineRunRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? routineId,
    Expression<String>? date,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? stepsDone,
    Expression<int>? stepsTotal,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (routineId != null) 'routine_id': routineId,
      if (date != null) 'date': date,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (stepsDone != null) 'steps_done': stepsDone,
      if (stepsTotal != null) 'steps_total': stepsTotal,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RoutineRunsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? routineId,
    Value<String>? date,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? stepsDone,
    Value<int>? stepsTotal,
    Value<DateTime>? updatedAt,
  }) {
    return RoutineRunsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      routineId: routineId ?? this.routineId,
      date: date ?? this.date,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      stepsDone: stepsDone ?? this.stepsDone,
      stepsTotal: stepsTotal ?? this.stepsTotal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (stepsDone.present) {
      map['steps_done'] = Variable<int>(stepsDone.value);
    }
    if (stepsTotal.present) {
      map['steps_total'] = Variable<int>(stepsTotal.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineRunsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('routineId: $routineId, ')
          ..write('date: $date, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('stepsDone: $stepsDone, ')
          ..write('stepsTotal: $stepsTotal, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WaterLogsTable extends WaterLogs with TableInfo<$WaterLogsTable, WaterLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta('loggedAt');
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMlMeta = const VerificationMeta('amountMl');
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, uuid, date, loggedAt, amountMl, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WaterLogRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(_loggedAtMeta, loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta));
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('amount_ml')) {
      context.handle(_amountMlMeta, amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta));
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterLogRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      amountMl: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}amount_ml'])!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WaterLogsTable createAlias(String alias) {
    return $WaterLogsTable(attachedDatabase, alias);
  }
}

class WaterLogRow extends DataClass implements Insertable<WaterLogRow> {
  final int id;
  final String uuid;

  /// The calendar day it counts toward, `yyyy-MM-dd`.
  final String date;

  /// When it was logged.
  final DateTime loggedAt;

  /// Millilitres, 1–5000.
  final int amountMl;
  final DateTime updatedAt;
  const WaterLogRow({
    required this.id,
    required this.uuid,
    required this.date,
    required this.loggedAt,
    required this.amountMl,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['date'] = Variable<String>(date);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['amount_ml'] = Variable<int>(amountMl);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WaterLogsCompanion toCompanion(bool nullToAbsent) {
    return WaterLogsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      date: Value(date),
      loggedAt: Value(loggedAt),
      amountMl: Value(amountMl),
      updatedAt: Value(updatedAt),
    );
  }

  factory WaterLogRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterLogRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      date: serializer.fromJson<String>(json['date']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'date': serializer.toJson<String>(date),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'amountMl': serializer.toJson<int>(amountMl),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WaterLogRow copyWith({
    int? id,
    String? uuid,
    String? date,
    DateTime? loggedAt,
    int? amountMl,
    DateTime? updatedAt,
  }) => WaterLogRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    date: date ?? this.date,
    loggedAt: loggedAt ?? this.loggedAt,
    amountMl: amountMl ?? this.amountMl,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WaterLogRow copyWithCompanion(WaterLogsCompanion data) {
    return WaterLogRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      date: data.date.present ? data.date.value : this.date,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('date: $date, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('amountMl: $amountMl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, date, loggedAt, amountMl, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterLogRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.date == this.date &&
          other.loggedAt == this.loggedAt &&
          other.amountMl == this.amountMl &&
          other.updatedAt == this.updatedAt);
}

class WaterLogsCompanion extends UpdateCompanion<WaterLogRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> date;
  final Value<DateTime> loggedAt;
  final Value<int> amountMl;
  final Value<DateTime> updatedAt;
  const WaterLogsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.date = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WaterLogsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String date,
    required DateTime loggedAt,
    required int amountMl,
    this.updatedAt = const Value.absent(),
  }) : date = Value(date),
       loggedAt = Value(loggedAt),
       amountMl = Value(amountMl);
  static Insertable<WaterLogRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? date,
    Expression<DateTime>? loggedAt,
    Expression<int>? amountMl,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (date != null) 'date': date,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (amountMl != null) 'amount_ml': amountMl,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WaterLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? date,
    Value<DateTime>? loggedAt,
    Value<int>? amountMl,
    Value<DateTime>? updatedAt,
  }) {
    return WaterLogsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      date: date ?? this.date,
      loggedAt: loggedAt ?? this.loggedAt,
      amountMl: amountMl ?? this.amountMl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('date: $date, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('amountMl: $amountMl, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SleepLogsTable extends SleepLogs with TableInfo<$SleepLogsTable, SleepLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: newUuid,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _bedtimeMeta = const VerificationMeta('bedtime');
  @override
  late final GeneratedColumn<DateTime> bedtime = GeneratedColumn<DateTime>(
    'bedtime',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wakeTimeMeta = const VerificationMeta('wakeTime');
  @override
  late final GeneratedColumn<DateTime> wakeTime = GeneratedColumn<DateTime>(
    'wake_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta('quality');
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, uuid, date, bedtime, wakeTime, quality, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_logs';
  @override
  VerificationContext validateIntegrity(Insertable<SleepLogRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(_uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bedtime')) {
      context.handle(_bedtimeMeta, bedtime.isAcceptableOrUnknown(data['bedtime']!, _bedtimeMeta));
    } else if (isInserting) {
      context.missing(_bedtimeMeta);
    }
    if (data.containsKey('wake_time')) {
      context.handle(_wakeTimeMeta, wakeTime.isAcceptableOrUnknown(data['wake_time']!, _wakeTimeMeta));
    } else if (isInserting) {
      context.missing(_wakeTimeMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta, quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SleepLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepLogRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      uuid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      bedtime: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}bedtime'])!,
      wakeTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}wake_time'],
      )!,
      quality: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}quality']),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SleepLogsTable createAlias(String alias) {
    return $SleepLogsTable(attachedDatabase, alias);
  }
}

class SleepLogRow extends DataClass implements Insertable<SleepLogRow> {
  final int id;
  final String uuid;

  /// The morning the night ended, `yyyy-MM-dd`. Unique: one entry per night.
  final String date;
  final DateTime bedtime;
  final DateTime wakeTime;

  /// 1 (poor) – 5 (great); null when not rated.
  final int? quality;
  final DateTime updatedAt;
  const SleepLogRow({
    required this.id,
    required this.uuid,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    this.quality,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['date'] = Variable<String>(date);
    map['bedtime'] = Variable<DateTime>(bedtime);
    map['wake_time'] = Variable<DateTime>(wakeTime);
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<int>(quality);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SleepLogsCompanion toCompanion(bool nullToAbsent) {
    return SleepLogsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      date: Value(date),
      bedtime: Value(bedtime),
      wakeTime: Value(wakeTime),
      quality: quality == null && nullToAbsent ? const Value.absent() : Value(quality),
      updatedAt: Value(updatedAt),
    );
  }

  factory SleepLogRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepLogRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      date: serializer.fromJson<String>(json['date']),
      bedtime: serializer.fromJson<DateTime>(json['bedtime']),
      wakeTime: serializer.fromJson<DateTime>(json['wakeTime']),
      quality: serializer.fromJson<int?>(json['quality']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'date': serializer.toJson<String>(date),
      'bedtime': serializer.toJson<DateTime>(bedtime),
      'wakeTime': serializer.toJson<DateTime>(wakeTime),
      'quality': serializer.toJson<int?>(quality),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SleepLogRow copyWith({
    int? id,
    String? uuid,
    String? date,
    DateTime? bedtime,
    DateTime? wakeTime,
    Value<int?> quality = const Value.absent(),
    DateTime? updatedAt,
  }) => SleepLogRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    date: date ?? this.date,
    bedtime: bedtime ?? this.bedtime,
    wakeTime: wakeTime ?? this.wakeTime,
    quality: quality.present ? quality.value : this.quality,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SleepLogRow copyWithCompanion(SleepLogsCompanion data) {
    return SleepLogRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      date: data.date.present ? data.date.value : this.date,
      bedtime: data.bedtime.present ? data.bedtime.value : this.bedtime,
      wakeTime: data.wakeTime.present ? data.wakeTime.value : this.wakeTime,
      quality: data.quality.present ? data.quality.value : this.quality,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepLogRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('date: $date, ')
          ..write('bedtime: $bedtime, ')
          ..write('wakeTime: $wakeTime, ')
          ..write('quality: $quality, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, date, bedtime, wakeTime, quality, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepLogRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.date == this.date &&
          other.bedtime == this.bedtime &&
          other.wakeTime == this.wakeTime &&
          other.quality == this.quality &&
          other.updatedAt == this.updatedAt);
}

class SleepLogsCompanion extends UpdateCompanion<SleepLogRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> date;
  final Value<DateTime> bedtime;
  final Value<DateTime> wakeTime;
  final Value<int?> quality;
  final Value<DateTime> updatedAt;
  const SleepLogsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.date = const Value.absent(),
    this.bedtime = const Value.absent(),
    this.wakeTime = const Value.absent(),
    this.quality = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SleepLogsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String date,
    required DateTime bedtime,
    required DateTime wakeTime,
    this.quality = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date),
       bedtime = Value(bedtime),
       wakeTime = Value(wakeTime);
  static Insertable<SleepLogRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? date,
    Expression<DateTime>? bedtime,
    Expression<DateTime>? wakeTime,
    Expression<int>? quality,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (date != null) 'date': date,
      if (bedtime != null) 'bedtime': bedtime,
      if (wakeTime != null) 'wake_time': wakeTime,
      if (quality != null) 'quality': quality,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SleepLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? date,
    Value<DateTime>? bedtime,
    Value<DateTime>? wakeTime,
    Value<int?>? quality,
    Value<DateTime>? updatedAt,
  }) {
    return SleepLogsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      date: date ?? this.date,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (bedtime.present) {
      map['bedtime'] = Variable<DateTime>(bedtime.value);
    }
    if (wakeTime.present) {
      map['wake_time'] = Variable<DateTime>(wakeTime.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepLogsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('date: $date, ')
          ..write('bedtime: $bedtime, ')
          ..write('wakeTime: $wakeTime, ')
          ..write('quality: $quality, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitCheckInsTable habitCheckIns = $HabitCheckInsTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $EventExceptionsTable eventExceptions = $EventExceptionsTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $RoutineStepsTable routineSteps = $RoutineStepsTable(this);
  late final $RoutineRunsTable routineRuns = $RoutineRunsTable(this);
  late final $WaterLogsTable waterLogs = $WaterLogsTable(this);
  late final $SleepLogsTable sleepLogs = $SleepLogsTable(this);
  late final Index tasksDueDate = Index('tasks_due_date', 'CREATE INDEX tasks_due_date ON tasks (due_date)');
  late final Index tasksCompletedAt = Index(
    'tasks_completed_at',
    'CREATE INDEX tasks_completed_at ON tasks (completed_at)',
  );
  late final Index tasksDeletedAt = Index(
    'tasks_deleted_at',
    'CREATE INDEX tasks_deleted_at ON tasks (deleted_at)',
  );
  late final Index habitCheckInsDate = Index(
    'habit_check_ins_date',
    'CREATE INDEX habit_check_ins_date ON habit_check_ins (date)',
  );
  late final Index eventsStartDate = Index(
    'events_start_date',
    'CREATE INDEX events_start_date ON events (start_date)',
  );
  late final Index routineStepsRoutine = Index(
    'routine_steps_routine',
    'CREATE INDEX routine_steps_routine ON routine_steps (routine_id)',
  );
  late final Index routineRunsDate = Index(
    'routine_runs_date',
    'CREATE INDEX routine_runs_date ON routine_runs (date)',
  );
  late final Index waterLogsDate = Index(
    'water_logs_date',
    'CREATE INDEX water_logs_date ON water_logs (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    projects,
    tasks,
    habits,
    habitCheckIns,
    events,
    eventExceptions,
    routines,
    routineSteps,
    routineRuns,
    waterLogs,
    sleepLogs,
    tasksDueDate,
    tasksCompletedAt,
    tasksDeletedAt,
    habitCheckInsDate,
    eventsStartDate,
    routineStepsRoutine,
    routineRunsDate,
    waterLogsDate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('habits', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('habit_check_ins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('events', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('event_exceptions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('routines', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('routine_steps', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('routines', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('routine_runs', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required String name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$ProjectsTableReferences extends BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<TaskRow>> _tasksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.tasks,
        aliasName: $_aliasNameGenerator(db.projects.id, db.tasks.projectId),
      );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> tasksRefs(Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          ProjectRow,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (ProjectRow, $$ProjectsTableReferences),
          ProjectRow,
          PrefetchHooks Function({bool tasksRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                uuid: uuid,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$ProjectsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<ProjectRow, $ProjectsTable, TaskRow>(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences._tasksRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProjectsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      ProjectRow,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (ProjectRow, $$ProjectsTableReferences),
      ProjectRow,
      PrefetchHooks Function({bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required String title,
      Value<String> notes,
      Value<int> priority,
      Value<int?> projectId,
      Value<String?> dueDate,
      Value<int?> dueMinute,
      Value<String?> recurrence,
      Value<int?> nextTaskId,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> title,
      Value<String> notes,
      Value<int> priority,
      Value<int?> projectId,
      Value<String?> dueDate,
      Value<int?> dueMinute,
      Value<String?> recurrence,
      Value<int?> nextTaskId,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$TasksTableReferences extends BaseReferences<_$AppDatabase, $TasksTable, TaskRow> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias($_aliasNameGenerator(db.tasks.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<int>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager($_db, $_db.projects).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueMinute =>
      $composableBuilder(column: $table.dueMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextTaskId =>
      $composableBuilder(column: $table.nextTaskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueMinute =>
      $composableBuilder(column: $table.dueMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextTaskId =>
      $composableBuilder(column: $table.nextTaskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueMinute =>
      $composableBuilder(column: $table.dueMinute, builder: (column) => column);

  GeneratedColumn<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => column);

  GeneratedColumn<int> get nextTaskId =>
      $composableBuilder(column: $table.nextTaskId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, $$TasksTableReferences),
          TaskRow,
          PrefetchHooks Function({bool projectId})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> dueMinute = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> nextTaskId = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                uuid: uuid,
                title: title,
                notes: notes,
                priority: priority,
                projectId: projectId,
                dueDate: dueDate,
                dueMinute: dueMinute,
                recurrence: recurrence,
                nextTaskId: nextTaskId,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String title,
                Value<String> notes = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<int?> dueMinute = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> nextTaskId = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                uuid: uuid,
                title: title,
                notes: notes,
                priority: priority,
                projectId: projectId,
                dueDate: dueDate,
                dueMinute: dueMinute,
                recurrence: recurrence,
                nextTaskId: nextTaskId,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$TasksTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({projectId = false}) {
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
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable: $$TasksTableReferences._projectIdTable(db),
                                referencedColumn: $$TasksTableReferences._projectIdTable(db).id,
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

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, $$TasksTableReferences),
      TaskRow,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required String name,
      Value<int> kind,
      required String schedule,
      Value<int> target,
      required String startDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> name,
      Value<int> kind,
      Value<String> schedule,
      Value<int> target,
      Value<String> startDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> deletedAt,
    });

final class $$HabitsTableReferences extends BaseReferences<_$AppDatabase, $HabitsTable, HabitRow> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitCheckInsTable, List<HabitCheckInRow>> _habitCheckInsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.habitCheckIns,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitCheckIns.habitId),
  );

  $$HabitCheckInsTableProcessedTableManager get habitCheckInsRefs {
    final manager = $$HabitCheckInsTableTableManager(
      $_db,
      $_db.habitCheckIns,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitCheckInsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$HabitsTableFilterComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> habitCheckInsRefs(Expression<bool> Function($$HabitCheckInsTableFilterComposer f) f) {
    final $$HabitCheckInsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCheckIns,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitCheckInsTableFilterComposer(
            $db: $db,
            $table: $db.habitCheckIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$HabitsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => column);

  GeneratedColumn<int> get target => $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> habitCheckInsRefs<T extends Object>(
    Expression<T> Function($$HabitCheckInsTableAnnotationComposer a) f,
  ) {
    final $$HabitCheckInsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitCheckIns,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitCheckInsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitCheckIns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitRow,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitRow, $$HabitsTableReferences),
          HabitRow,
          PrefetchHooks Function({bool habitCheckInsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<String> schedule = const Value.absent(),
                Value<int> target = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                uuid: uuid,
                name: name,
                kind: kind,
                schedule: schedule,
                target: target,
                startDate: startDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String name,
                Value<int> kind = const Value.absent(),
                required String schedule,
                Value<int> target = const Value.absent(),
                required String startDate,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                kind: kind,
                schedule: schedule,
                target: target,
                startDate: startDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$HabitsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({habitCheckInsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (habitCheckInsRefs) db.habitCheckIns],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (habitCheckInsRefs)
                    await $_getPrefetchedData<HabitRow, $HabitsTable, HabitCheckInRow>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences._habitCheckInsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$HabitsTableReferences(db, table, p0).habitCheckInsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.habitId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitRow,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitRow, $$HabitsTableReferences),
      HabitRow,
      PrefetchHooks Function({bool habitCheckInsRefs})
    >;
typedef $$HabitCheckInsTableCreateCompanionBuilder =
    HabitCheckInsCompanion Function({
      required int habitId,
      required String date,
      required int count,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$HabitCheckInsTableUpdateCompanionBuilder =
    HabitCheckInsCompanion Function({
      Value<int> habitId,
      Value<String> date,
      Value<int> count,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$HabitCheckInsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitCheckInsTable, HabitCheckInRow> {
  $$HabitCheckInsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias($_aliasNameGenerator(db.habitCheckIns.habitId, db.habits.id));

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager($_db, $_db.habits).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HabitCheckInsTableFilterComposer extends Composer<_$AppDatabase, $HabitCheckInsTable> {
  $$HabitCheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCheckInsTableOrderingComposer extends Composer<_$AppDatabase, $HabitCheckInsTable> {
  $$HabitCheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCheckInsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitCheckInsTable> {
  $$HabitCheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get count => $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitCheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitCheckInsTable,
          HabitCheckInRow,
          $$HabitCheckInsTableFilterComposer,
          $$HabitCheckInsTableOrderingComposer,
          $$HabitCheckInsTableAnnotationComposer,
          $$HabitCheckInsTableCreateCompanionBuilder,
          $$HabitCheckInsTableUpdateCompanionBuilder,
          (HabitCheckInRow, $$HabitCheckInsTableReferences),
          HabitCheckInRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitCheckInsTableTableManager(_$AppDatabase db, $HabitCheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitCheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitCheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitCheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCheckInsCompanion(
                habitId: habitId,
                date: date,
                count: count,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int habitId,
                required String date,
                required int count,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCheckInsCompanion.insert(
                habitId: habitId,
                date: date,
                count: count,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$HabitCheckInsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({habitId = false}) {
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
                    if (habitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.habitId,
                                referencedTable: $$HabitCheckInsTableReferences._habitIdTable(db),
                                referencedColumn: $$HabitCheckInsTableReferences._habitIdTable(db).id,
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

typedef $$HabitCheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitCheckInsTable,
      HabitCheckInRow,
      $$HabitCheckInsTableFilterComposer,
      $$HabitCheckInsTableOrderingComposer,
      $$HabitCheckInsTableAnnotationComposer,
      $$HabitCheckInsTableCreateCompanionBuilder,
      $$HabitCheckInsTableUpdateCompanionBuilder,
      (HabitCheckInRow, $$HabitCheckInsTableReferences),
      HabitCheckInRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required String title,
      Value<String> notes,
      Value<int> kind,
      required String startDate,
      Value<int?> startMinute,
      Value<int?> durationMinutes,
      Value<String?> recurrence,
      Value<int?> reminderMinutes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> title,
      Value<String> notes,
      Value<int> kind,
      Value<String> startDate,
      Value<int?> startMinute,
      Value<int?> durationMinutes,
      Value<String?> recurrence,
      Value<int?> reminderMinutes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$EventsTableReferences extends BaseReferences<_$AppDatabase, $EventsTable, EventRow> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EventExceptionsTable, List<EventExceptionRow>> _eventExceptionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.eventExceptions,
    aliasName: $_aliasNameGenerator(db.events.id, db.eventExceptions.eventId),
  );

  $$EventExceptionsTableProcessedTableManager get eventExceptionsRefs {
    final manager = $$EventExceptionsTableTableManager(
      $_db,
      $_db.eventExceptions,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventExceptionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EventsTableFilterComposer extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMinute =>
      $composableBuilder(column: $table.startMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes =>
      $composableBuilder(column: $table.durationMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> eventExceptionsRefs(Expression<bool> Function($$EventExceptionsTableFilterComposer f) f) {
    final $$EventExceptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventExceptions,
      getReferencedColumn: (t) => t.eventId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventExceptionsTableFilterComposer(
            $db: $db,
            $table: $db.eventExceptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMinute =>
      $composableBuilder(column: $table.startMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes =>
      $composableBuilder(column: $table.durationMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$EventsTableAnnotationComposer extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get startMinute =>
      $composableBuilder(column: $table.startMinute, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes =>
      $composableBuilder(column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> eventExceptionsRefs<T extends Object>(
    Expression<T> Function($$EventExceptionsTableAnnotationComposer a) f,
  ) {
    final $$EventExceptionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventExceptions,
      getReferencedColumn: (t) => t.eventId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventExceptionsTableAnnotationComposer(
            $db: $db,
            $table: $db.eventExceptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          EventRow,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (EventRow, $$EventsTableReferences),
          EventRow,
          PrefetchHooks Function({bool eventExceptionsRefs})
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                uuid: uuid,
                title: title,
                notes: notes,
                kind: kind,
                startDate: startDate,
                startMinute: startMinute,
                durationMinutes: durationMinutes,
                recurrence: recurrence,
                reminderMinutes: reminderMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String title,
                Value<String> notes = const Value.absent(),
                Value<int> kind = const Value.absent(),
                required String startDate,
                Value<int?> startMinute = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                uuid: uuid,
                title: title,
                notes: notes,
                kind: kind,
                startDate: startDate,
                startMinute: startMinute,
                durationMinutes: durationMinutes,
                recurrence: recurrence,
                reminderMinutes: reminderMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$EventsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({eventExceptionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (eventExceptionsRefs) db.eventExceptions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (eventExceptionsRefs)
                    await $_getPrefetchedData<EventRow, $EventsTable, EventExceptionRow>(
                      currentTable: table,
                      referencedTable: $$EventsTableReferences._eventExceptionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$EventsTableReferences(db, table, p0).eventExceptionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.eventId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      EventRow,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (EventRow, $$EventsTableReferences),
      EventRow,
      PrefetchHooks Function({bool eventExceptionsRefs})
    >;
typedef $$EventExceptionsTableCreateCompanionBuilder =
    EventExceptionsCompanion Function({
      required int eventId,
      required String date,
      Value<bool> skipped,
      Value<DateTime?> doneAt,
      Value<String?> movedDate,
      Value<int?> movedMinute,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$EventExceptionsTableUpdateCompanionBuilder =
    EventExceptionsCompanion Function({
      Value<int> eventId,
      Value<String> date,
      Value<bool> skipped,
      Value<DateTime?> doneAt,
      Value<String?> movedDate,
      Value<int?> movedMinute,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EventExceptionsTableReferences
    extends BaseReferences<_$AppDatabase, $EventExceptionsTable, EventExceptionRow> {
  $$EventExceptionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias($_aliasNameGenerator(db.eventExceptions.eventId, db.events.id));

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$EventExceptionsTableFilterComposer extends Composer<_$AppDatabase, $EventExceptionsTable> {
  $$EventExceptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movedDate =>
      $composableBuilder(column: $table.movedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get movedMinute =>
      $composableBuilder(column: $table.movedMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventExceptionsTableOrderingComposer extends Composer<_$AppDatabase, $EventExceptionsTable> {
  $$EventExceptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movedDate =>
      $composableBuilder(column: $table.movedDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get movedMinute =>
      $composableBuilder(column: $table.movedMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventExceptionsTableAnnotationComposer extends Composer<_$AppDatabase, $EventExceptionsTable> {
  $$EventExceptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<String> get movedDate =>
      $composableBuilder(column: $table.movedDate, builder: (column) => column);

  GeneratedColumn<int> get movedMinute =>
      $composableBuilder(column: $table.movedMinute, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventExceptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventExceptionsTable,
          EventExceptionRow,
          $$EventExceptionsTableFilterComposer,
          $$EventExceptionsTableOrderingComposer,
          $$EventExceptionsTableAnnotationComposer,
          $$EventExceptionsTableCreateCompanionBuilder,
          $$EventExceptionsTableUpdateCompanionBuilder,
          (EventExceptionRow, $$EventExceptionsTableReferences),
          EventExceptionRow,
          PrefetchHooks Function({bool eventId})
        > {
  $$EventExceptionsTableTableManager(_$AppDatabase db, $EventExceptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EventExceptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EventExceptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EventExceptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> eventId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> movedDate = const Value.absent(),
                Value<int?> movedMinute = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventExceptionsCompanion(
                eventId: eventId,
                date: date,
                skipped: skipped,
                doneAt: doneAt,
                movedDate: movedDate,
                movedMinute: movedMinute,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int eventId,
                required String date,
                Value<bool> skipped = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> movedDate = const Value.absent(),
                Value<int?> movedMinute = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventExceptionsCompanion.insert(
                eventId: eventId,
                date: date,
                skipped: skipped,
                doneAt: doneAt,
                movedDate: movedDate,
                movedMinute: movedMinute,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$EventExceptionsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({eventId = false}) {
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
                    if (eventId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.eventId,
                                referencedTable: $$EventExceptionsTableReferences._eventIdTable(db),
                                referencedColumn: $$EventExceptionsTableReferences._eventIdTable(db).id,
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

typedef $$EventExceptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventExceptionsTable,
      EventExceptionRow,
      $$EventExceptionsTableFilterComposer,
      $$EventExceptionsTableOrderingComposer,
      $$EventExceptionsTableAnnotationComposer,
      $$EventExceptionsTableCreateCompanionBuilder,
      $$EventExceptionsTableUpdateCompanionBuilder,
      (EventExceptionRow, $$EventExceptionsTableReferences),
      EventExceptionRow,
      PrefetchHooks Function({bool eventId})
    >;
typedef $$RoutinesTableCreateCompanionBuilder =
    RoutinesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required String name,
      Value<int> timeOfDay,
      required String schedule,
      Value<int?> startMinute,
      Value<int?> reminderMinutes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });
typedef $$RoutinesTableUpdateCompanionBuilder =
    RoutinesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> name,
      Value<int> timeOfDay,
      Value<String> schedule,
      Value<int?> startMinute,
      Value<int?> reminderMinutes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
    });

final class $$RoutinesTableReferences extends BaseReferences<_$AppDatabase, $RoutinesTable, RoutineRow> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutineStepsTable, List<RoutineStepRow>> _routineStepsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.routineSteps,
    aliasName: $_aliasNameGenerator(db.routines.id, db.routineSteps.routineId),
  );

  $$RoutineStepsTableProcessedTableManager get routineStepsRefs {
    final manager = $$RoutineStepsTableTableManager(
      $_db,
      $_db.routineSteps,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineStepsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RoutineRunsTable, List<RoutineRunRow>> _routineRunsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.routineRuns,
    aliasName: $_aliasNameGenerator(db.routines.id, db.routineRuns.routineId),
  );

  $$RoutineRunsTableProcessedTableManager get routineRunsRefs {
    final manager = $$RoutineRunsTableTableManager(
      $_db,
      $_db.routineRuns,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineRunsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutinesTableFilterComposer extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMinute =>
      $composableBuilder(column: $table.startMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> routineStepsRefs(Expression<bool> Function($$RoutineStepsTableFilterComposer f) f) {
    final $$RoutineStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineSteps,
      getReferencedColumn: (t) => t.routineId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutineStepsTableFilterComposer(
            $db: $db,
            $table: $db.routineSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> routineRunsRefs(Expression<bool> Function($$RoutineRunsTableFilterComposer f) f) {
    final $$RoutineRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineRuns,
      getReferencedColumn: (t) => t.routineId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutineRunsTableFilterComposer(
            $db: $db,
            $table: $db.routineRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMinute =>
      $composableBuilder(column: $table.startMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$RoutinesTableAnnotationComposer extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<String> get schedule =>
      $composableBuilder(column: $table.schedule, builder: (column) => column);

  GeneratedColumn<int> get startMinute =>
      $composableBuilder(column: $table.startMinute, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> routineStepsRefs<T extends Object>(
    Expression<T> Function($$RoutineStepsTableAnnotationComposer a) f,
  ) {
    final $$RoutineStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineSteps,
      getReferencedColumn: (t) => t.routineId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutineStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.routineSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> routineRunsRefs<T extends Object>(
    Expression<T> Function($$RoutineRunsTableAnnotationComposer a) f,
  ) {
    final $$RoutineRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineRuns,
      getReferencedColumn: (t) => t.routineId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutineRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.routineRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutinesTable,
          RoutineRow,
          $$RoutinesTableFilterComposer,
          $$RoutinesTableOrderingComposer,
          $$RoutinesTableAnnotationComposer,
          $$RoutinesTableCreateCompanionBuilder,
          $$RoutinesTableUpdateCompanionBuilder,
          (RoutineRow, $$RoutinesTableReferences),
          RoutineRow,
          PrefetchHooks Function({bool routineStepsRefs, bool routineRunsRefs})
        > {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> timeOfDay = const Value.absent(),
                Value<String> schedule = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => RoutinesCompanion(
                id: id,
                uuid: uuid,
                name: name,
                timeOfDay: timeOfDay,
                schedule: schedule,
                startMinute: startMinute,
                reminderMinutes: reminderMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String name,
                Value<int> timeOfDay = const Value.absent(),
                required String schedule,
                Value<int?> startMinute = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => RoutinesCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                timeOfDay: timeOfDay,
                schedule: schedule,
                startMinute: startMinute,
                reminderMinutes: reminderMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$RoutinesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({routineStepsRefs = false, routineRunsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routineStepsRefs) db.routineSteps,
                if (routineRunsRefs) db.routineRuns,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineStepsRefs)
                    await $_getPrefetchedData<RoutineRow, $RoutinesTable, RoutineStepRow>(
                      currentTable: table,
                      referencedTable: $$RoutinesTableReferences._routineStepsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RoutinesTableReferences(db, table, p0).routineStepsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.routineId == item.id),
                      typedResults: items,
                    ),
                  if (routineRunsRefs)
                    await $_getPrefetchedData<RoutineRow, $RoutinesTable, RoutineRunRow>(
                      currentTable: table,
                      referencedTable: $$RoutinesTableReferences._routineRunsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RoutinesTableReferences(db, table, p0).routineRunsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.routineId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoutinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutinesTable,
      RoutineRow,
      $$RoutinesTableFilterComposer,
      $$RoutinesTableOrderingComposer,
      $$RoutinesTableAnnotationComposer,
      $$RoutinesTableCreateCompanionBuilder,
      $$RoutinesTableUpdateCompanionBuilder,
      (RoutineRow, $$RoutinesTableReferences),
      RoutineRow,
      PrefetchHooks Function({bool routineStepsRefs, bool routineRunsRefs})
    >;
typedef $$RoutineStepsTableCreateCompanionBuilder =
    RoutineStepsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required int routineId,
      required int position,
      required String title,
      Value<int?> durationSeconds,
      Value<DateTime> updatedAt,
    });
typedef $$RoutineStepsTableUpdateCompanionBuilder =
    RoutineStepsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> routineId,
      Value<int> position,
      Value<String> title,
      Value<int?> durationSeconds,
      Value<DateTime> updatedAt,
    });

final class $$RoutineStepsTableReferences
    extends BaseReferences<_$AppDatabase, $RoutineStepsTable, RoutineStepRow> {
  $$RoutineStepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias($_aliasNameGenerator(db.routineSteps.routineId, db.routines.id));

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RoutineStepsTableFilterComposer extends Composer<_$AppDatabase, $RoutineStepsTable> {
  $$RoutineStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds =>
      $composableBuilder(column: $table.durationSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineStepsTableOrderingComposer extends Composer<_$AppDatabase, $RoutineStepsTable> {
  $$RoutineStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds =>
      $composableBuilder(column: $table.durationSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineStepsTableAnnotationComposer extends Composer<_$AppDatabase, $RoutineStepsTable> {
  $$RoutineStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds =>
      $composableBuilder(column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineStepsTable,
          RoutineStepRow,
          $$RoutineStepsTableFilterComposer,
          $$RoutineStepsTableOrderingComposer,
          $$RoutineStepsTableAnnotationComposer,
          $$RoutineStepsTableCreateCompanionBuilder,
          $$RoutineStepsTableUpdateCompanionBuilder,
          (RoutineStepRow, $$RoutineStepsTableReferences),
          RoutineStepRow,
          PrefetchHooks Function({bool routineId})
        > {
  $$RoutineStepsTableTableManager(_$AppDatabase db, $RoutineStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RoutineStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RoutineStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RoutineStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineStepsCompanion(
                id: id,
                uuid: uuid,
                routineId: routineId,
                position: position,
                title: title,
                durationSeconds: durationSeconds,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required int routineId,
                required int position,
                required String title,
                Value<int?> durationSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineStepsCompanion.insert(
                id: id,
                uuid: uuid,
                routineId: routineId,
                position: position,
                title: title,
                durationSeconds: durationSeconds,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$RoutineStepsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({routineId = false}) {
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
                    if (routineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.routineId,
                                referencedTable: $$RoutineStepsTableReferences._routineIdTable(db),
                                referencedColumn: $$RoutineStepsTableReferences._routineIdTable(db).id,
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

typedef $$RoutineStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineStepsTable,
      RoutineStepRow,
      $$RoutineStepsTableFilterComposer,
      $$RoutineStepsTableOrderingComposer,
      $$RoutineStepsTableAnnotationComposer,
      $$RoutineStepsTableCreateCompanionBuilder,
      $$RoutineStepsTableUpdateCompanionBuilder,
      (RoutineStepRow, $$RoutineStepsTableReferences),
      RoutineStepRow,
      PrefetchHooks Function({bool routineId})
    >;
typedef $$RoutineRunsTableCreateCompanionBuilder =
    RoutineRunsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required int routineId,
      required String date,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int> stepsDone,
      required int stepsTotal,
      Value<DateTime> updatedAt,
    });
typedef $$RoutineRunsTableUpdateCompanionBuilder =
    RoutineRunsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> routineId,
      Value<String> date,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> stepsDone,
      Value<int> stepsTotal,
      Value<DateTime> updatedAt,
    });

final class $$RoutineRunsTableReferences
    extends BaseReferences<_$AppDatabase, $RoutineRunsTable, RoutineRunRow> {
  $$RoutineRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias($_aliasNameGenerator(db.routineRuns.routineId, db.routines.id));

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RoutineRunsTableFilterComposer extends Composer<_$AppDatabase, $RoutineRunsTable> {
  $$RoutineRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepsDone =>
      $composableBuilder(column: $table.stepsDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepsTotal =>
      $composableBuilder(column: $table.stepsTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineRunsTableOrderingComposer extends Composer<_$AppDatabase, $RoutineRunsTable> {
  $$RoutineRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepsDone =>
      $composableBuilder(column: $table.stepsDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepsTotal =>
      $composableBuilder(column: $table.stepsTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineRunsTableAnnotationComposer extends Composer<_$AppDatabase, $RoutineRunsTable> {
  $$RoutineRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => column);

  GeneratedColumn<int> get stepsDone =>
      $composableBuilder(column: $table.stepsDone, builder: (column) => column);

  GeneratedColumn<int> get stepsTotal =>
      $composableBuilder(column: $table.stepsTotal, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineRunsTable,
          RoutineRunRow,
          $$RoutineRunsTableFilterComposer,
          $$RoutineRunsTableOrderingComposer,
          $$RoutineRunsTableAnnotationComposer,
          $$RoutineRunsTableCreateCompanionBuilder,
          $$RoutineRunsTableUpdateCompanionBuilder,
          (RoutineRunRow, $$RoutineRunsTableReferences),
          RoutineRunRow,
          PrefetchHooks Function({bool routineId})
        > {
  $$RoutineRunsTableTableManager(_$AppDatabase db, $RoutineRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RoutineRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RoutineRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RoutineRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> stepsDone = const Value.absent(),
                Value<int> stepsTotal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineRunsCompanion(
                id: id,
                uuid: uuid,
                routineId: routineId,
                date: date,
                startedAt: startedAt,
                finishedAt: finishedAt,
                stepsDone: stepsDone,
                stepsTotal: stepsTotal,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required int routineId,
                required String date,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> stepsDone = const Value.absent(),
                required int stepsTotal,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineRunsCompanion.insert(
                id: id,
                uuid: uuid,
                routineId: routineId,
                date: date,
                startedAt: startedAt,
                finishedAt: finishedAt,
                stepsDone: stepsDone,
                stepsTotal: stepsTotal,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$RoutineRunsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({routineId = false}) {
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
                    if (routineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.routineId,
                                referencedTable: $$RoutineRunsTableReferences._routineIdTable(db),
                                referencedColumn: $$RoutineRunsTableReferences._routineIdTable(db).id,
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

typedef $$RoutineRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineRunsTable,
      RoutineRunRow,
      $$RoutineRunsTableFilterComposer,
      $$RoutineRunsTableOrderingComposer,
      $$RoutineRunsTableAnnotationComposer,
      $$RoutineRunsTableCreateCompanionBuilder,
      $$RoutineRunsTableUpdateCompanionBuilder,
      (RoutineRunRow, $$RoutineRunsTableReferences),
      RoutineRunRow,
      PrefetchHooks Function({bool routineId})
    >;
typedef $$WaterLogsTableCreateCompanionBuilder =
    WaterLogsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required String date,
      required DateTime loggedAt,
      required int amountMl,
      Value<DateTime> updatedAt,
    });
typedef $$WaterLogsTableUpdateCompanionBuilder =
    WaterLogsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> date,
      Value<DateTime> loggedAt,
      Value<int> amountMl,
      Value<DateTime> updatedAt,
    });

class $$WaterLogsTableFilterComposer extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WaterLogsTableOrderingComposer extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WaterLogsTableAnnotationComposer extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WaterLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterLogsTable,
          WaterLogRow,
          $$WaterLogsTableFilterComposer,
          $$WaterLogsTableOrderingComposer,
          $$WaterLogsTableAnnotationComposer,
          $$WaterLogsTableCreateCompanionBuilder,
          $$WaterLogsTableUpdateCompanionBuilder,
          (WaterLogRow, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLogRow>),
          WaterLogRow,
          PrefetchHooks Function()
        > {
  $$WaterLogsTableTableManager(_$AppDatabase db, $WaterLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WaterLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WaterLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WaterLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WaterLogsCompanion(
                id: id,
                uuid: uuid,
                date: date,
                loggedAt: loggedAt,
                amountMl: amountMl,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String date,
                required DateTime loggedAt,
                required int amountMl,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WaterLogsCompanion.insert(
                id: id,
                uuid: uuid,
                date: date,
                loggedAt: loggedAt,
                amountMl: amountMl,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterLogsTable,
      WaterLogRow,
      $$WaterLogsTableFilterComposer,
      $$WaterLogsTableOrderingComposer,
      $$WaterLogsTableAnnotationComposer,
      $$WaterLogsTableCreateCompanionBuilder,
      $$WaterLogsTableUpdateCompanionBuilder,
      (WaterLogRow, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLogRow>),
      WaterLogRow,
      PrefetchHooks Function()
    >;
typedef $$SleepLogsTableCreateCompanionBuilder =
    SleepLogsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required String date,
      required DateTime bedtime,
      required DateTime wakeTime,
      Value<int?> quality,
      Value<DateTime> updatedAt,
    });
typedef $$SleepLogsTableUpdateCompanionBuilder =
    SleepLogsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> date,
      Value<DateTime> bedtime,
      Value<DateTime> wakeTime,
      Value<int?> quality,
      Value<DateTime> updatedAt,
    });

class $$SleepLogsTableFilterComposer extends Composer<_$AppDatabase, $SleepLogsTable> {
  $$SleepLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get bedtime =>
      $composableBuilder(column: $table.bedtime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get wakeTime =>
      $composableBuilder(column: $table.wakeTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SleepLogsTableOrderingComposer extends Composer<_$AppDatabase, $SleepLogsTable> {
  $$SleepLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get bedtime =>
      $composableBuilder(column: $table.bedtime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get wakeTime =>
      $composableBuilder(column: $table.wakeTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SleepLogsTableAnnotationComposer extends Composer<_$AppDatabase, $SleepLogsTable> {
  $$SleepLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid => $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get bedtime =>
      $composableBuilder(column: $table.bedtime, builder: (column) => column);

  GeneratedColumn<DateTime> get wakeTime =>
      $composableBuilder(column: $table.wakeTime, builder: (column) => column);

  GeneratedColumn<int> get quality => $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SleepLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SleepLogsTable,
          SleepLogRow,
          $$SleepLogsTableFilterComposer,
          $$SleepLogsTableOrderingComposer,
          $$SleepLogsTableAnnotationComposer,
          $$SleepLogsTableCreateCompanionBuilder,
          $$SleepLogsTableUpdateCompanionBuilder,
          (SleepLogRow, BaseReferences<_$AppDatabase, $SleepLogsTable, SleepLogRow>),
          SleepLogRow,
          PrefetchHooks Function()
        > {
  $$SleepLogsTableTableManager(_$AppDatabase db, $SleepLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SleepLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SleepLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SleepLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> bedtime = const Value.absent(),
                Value<DateTime> wakeTime = const Value.absent(),
                Value<int?> quality = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SleepLogsCompanion(
                id: id,
                uuid: uuid,
                date: date,
                bedtime: bedtime,
                wakeTime: wakeTime,
                quality: quality,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String date,
                required DateTime bedtime,
                required DateTime wakeTime,
                Value<int?> quality = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SleepLogsCompanion.insert(
                id: id,
                uuid: uuid,
                date: date,
                bedtime: bedtime,
                wakeTime: wakeTime,
                quality: quality,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SleepLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SleepLogsTable,
      SleepLogRow,
      $$SleepLogsTableFilterComposer,
      $$SleepLogsTableOrderingComposer,
      $$SleepLogsTableAnnotationComposer,
      $$SleepLogsTableCreateCompanionBuilder,
      $$SleepLogsTableUpdateCompanionBuilder,
      (SleepLogRow, BaseReferences<_$AppDatabase, $SleepLogsTable, SleepLogRow>),
      SleepLogRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings => $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ProjectsTableTableManager get projects => $$ProjectsTableTableManager(_db, _db.projects);
  $$TasksTableTableManager get tasks => $$TasksTableTableManager(_db, _db.tasks);
  $$HabitsTableTableManager get habits => $$HabitsTableTableManager(_db, _db.habits);
  $$HabitCheckInsTableTableManager get habitCheckIns =>
      $$HabitCheckInsTableTableManager(_db, _db.habitCheckIns);
  $$EventsTableTableManager get events => $$EventsTableTableManager(_db, _db.events);
  $$EventExceptionsTableTableManager get eventExceptions =>
      $$EventExceptionsTableTableManager(_db, _db.eventExceptions);
  $$RoutinesTableTableManager get routines => $$RoutinesTableTableManager(_db, _db.routines);
  $$RoutineStepsTableTableManager get routineSteps => $$RoutineStepsTableTableManager(_db, _db.routineSteps);
  $$RoutineRunsTableTableManager get routineRuns => $$RoutineRunsTableTableManager(_db, _db.routineRuns);
  $$WaterLogsTableTableManager get waterLogs => $$WaterLogsTableTableManager(_db, _db.waterLogs);
  $$SleepLogsTableTableManager get sleepLogs => $$SleepLogsTableTableManager(_db, _db.sleepLogs);
}
