// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SolveRecordsTable extends SolveRecords
    with TableInfo<$SolveRecordsTable, SolveRecordEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolveRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionTextMeta =
      const VerificationMeta('questionText');
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
      'question_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
      'answer', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _solutionMeta =
      const VerificationMeta('solution');
  @override
  late final GeneratedColumn<String> solution = GeneratedColumn<String>(
      'solution', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _knowledgePointsMeta =
      const VerificationMeta('knowledgePoints');
  @override
  late final GeneratedColumn<String> knowledgePoints = GeneratedColumn<String>(
      'knowledge_points', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _aiModelMeta =
      const VerificationMeta('aiModel');
  @override
  late final GeneratedColumn<String> aiModel = GeneratedColumn<String>(
      'ai_model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _latencyMsMeta =
      const VerificationMeta('latencyMs');
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
      'latency_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _tokensUsedMeta =
      const VerificationMeta('tokensUsed');
  @override
  late final GeneratedColumn<int> tokensUsed = GeneratedColumn<int>(
      'tokens_used', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _matchedMeta =
      const VerificationMeta('matched');
  @override
  late final GeneratedColumn<bool> matched = GeneratedColumn<bool>(
      'matched', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("matched" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _userFeedbackMeta =
      const VerificationMeta('userFeedback');
  @override
  late final GeneratedColumn<String> userFeedback = GeneratedColumn<String>(
      'user_feedback', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _actionTypeMeta =
      const VerificationMeta('actionType');
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
      'action_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('solve'));
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        questionText,
        answer,
        solution,
        knowledgePoints,
        aiModel,
        latencyMs,
        tokensUsed,
        matched,
        userFeedback,
        actionType,
        synced,
        remoteId,
        imagePath,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solve_records';
  @override
  VerificationContext validateIntegrity(Insertable<SolveRecordEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_text')) {
      context.handle(
          _questionTextMeta,
          questionText.isAcceptableOrUnknown(
              data['question_text']!, _questionTextMeta));
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(_answerMeta,
          answer.isAcceptableOrUnknown(data['answer']!, _answerMeta));
    }
    if (data.containsKey('solution')) {
      context.handle(_solutionMeta,
          solution.isAcceptableOrUnknown(data['solution']!, _solutionMeta));
    }
    if (data.containsKey('knowledge_points')) {
      context.handle(
          _knowledgePointsMeta,
          knowledgePoints.isAcceptableOrUnknown(
              data['knowledge_points']!, _knowledgePointsMeta));
    }
    if (data.containsKey('ai_model')) {
      context.handle(_aiModelMeta,
          aiModel.isAcceptableOrUnknown(data['ai_model']!, _aiModelMeta));
    }
    if (data.containsKey('latency_ms')) {
      context.handle(_latencyMsMeta,
          latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta));
    }
    if (data.containsKey('tokens_used')) {
      context.handle(
          _tokensUsedMeta,
          tokensUsed.isAcceptableOrUnknown(
              data['tokens_used']!, _tokensUsedMeta));
    }
    if (data.containsKey('matched')) {
      context.handle(_matchedMeta,
          matched.isAcceptableOrUnknown(data['matched']!, _matchedMeta));
    }
    if (data.containsKey('user_feedback')) {
      context.handle(
          _userFeedbackMeta,
          userFeedback.isAcceptableOrUnknown(
              data['user_feedback']!, _userFeedbackMeta));
    }
    if (data.containsKey('action_type')) {
      context.handle(
          _actionTypeMeta,
          actionType.isAcceptableOrUnknown(
              data['action_type']!, _actionTypeMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolveRecordEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolveRecordEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_text'])!,
      answer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer'])!,
      solution: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}solution'])!,
      knowledgePoints: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}knowledge_points'])!,
      aiModel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_model'])!,
      latencyMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}latency_ms'])!,
      tokensUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tokens_used'])!,
      matched: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}matched'])!,
      userFeedback: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_feedback'])!,
      actionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_type'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remote_id']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SolveRecordsTable createAlias(String alias) {
    return $SolveRecordsTable(attachedDatabase, alias);
  }
}

class SolveRecordEntity extends DataClass
    implements Insertable<SolveRecordEntity> {
  final int id;
  final String questionText;
  final String answer;
  final String solution;
  final String knowledgePoints;
  final String aiModel;
  final int latencyMs;
  final int tokensUsed;
  final bool matched;
  final String userFeedback;
  final String actionType;
  final bool synced;
  final int? remoteId;
  final String imagePath;
  final DateTime createdAt;
  const SolveRecordEntity(
      {required this.id,
      required this.questionText,
      required this.answer,
      required this.solution,
      required this.knowledgePoints,
      required this.aiModel,
      required this.latencyMs,
      required this.tokensUsed,
      required this.matched,
      required this.userFeedback,
      required this.actionType,
      required this.synced,
      this.remoteId,
      required this.imagePath,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_text'] = Variable<String>(questionText);
    map['answer'] = Variable<String>(answer);
    map['solution'] = Variable<String>(solution);
    map['knowledge_points'] = Variable<String>(knowledgePoints);
    map['ai_model'] = Variable<String>(aiModel);
    map['latency_ms'] = Variable<int>(latencyMs);
    map['tokens_used'] = Variable<int>(tokensUsed);
    map['matched'] = Variable<bool>(matched);
    map['user_feedback'] = Variable<String>(userFeedback);
    map['action_type'] = Variable<String>(actionType);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['image_path'] = Variable<String>(imagePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SolveRecordsCompanion toCompanion(bool nullToAbsent) {
    return SolveRecordsCompanion(
      id: Value(id),
      questionText: Value(questionText),
      answer: Value(answer),
      solution: Value(solution),
      knowledgePoints: Value(knowledgePoints),
      aiModel: Value(aiModel),
      latencyMs: Value(latencyMs),
      tokensUsed: Value(tokensUsed),
      matched: Value(matched),
      userFeedback: Value(userFeedback),
      actionType: Value(actionType),
      synced: Value(synced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      imagePath: Value(imagePath),
      createdAt: Value(createdAt),
    );
  }

  factory SolveRecordEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolveRecordEntity(
      id: serializer.fromJson<int>(json['id']),
      questionText: serializer.fromJson<String>(json['questionText']),
      answer: serializer.fromJson<String>(json['answer']),
      solution: serializer.fromJson<String>(json['solution']),
      knowledgePoints: serializer.fromJson<String>(json['knowledgePoints']),
      aiModel: serializer.fromJson<String>(json['aiModel']),
      latencyMs: serializer.fromJson<int>(json['latencyMs']),
      tokensUsed: serializer.fromJson<int>(json['tokensUsed']),
      matched: serializer.fromJson<bool>(json['matched']),
      userFeedback: serializer.fromJson<String>(json['userFeedback']),
      actionType: serializer.fromJson<String>(json['actionType']),
      synced: serializer.fromJson<bool>(json['synced']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionText': serializer.toJson<String>(questionText),
      'answer': serializer.toJson<String>(answer),
      'solution': serializer.toJson<String>(solution),
      'knowledgePoints': serializer.toJson<String>(knowledgePoints),
      'aiModel': serializer.toJson<String>(aiModel),
      'latencyMs': serializer.toJson<int>(latencyMs),
      'tokensUsed': serializer.toJson<int>(tokensUsed),
      'matched': serializer.toJson<bool>(matched),
      'userFeedback': serializer.toJson<String>(userFeedback),
      'actionType': serializer.toJson<String>(actionType),
      'synced': serializer.toJson<bool>(synced),
      'remoteId': serializer.toJson<int?>(remoteId),
      'imagePath': serializer.toJson<String>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SolveRecordEntity copyWith(
          {int? id,
          String? questionText,
          String? answer,
          String? solution,
          String? knowledgePoints,
          String? aiModel,
          int? latencyMs,
          int? tokensUsed,
          bool? matched,
          String? userFeedback,
          String? actionType,
          bool? synced,
          Value<int?> remoteId = const Value.absent(),
          String? imagePath,
          DateTime? createdAt}) =>
      SolveRecordEntity(
        id: id ?? this.id,
        questionText: questionText ?? this.questionText,
        answer: answer ?? this.answer,
        solution: solution ?? this.solution,
        knowledgePoints: knowledgePoints ?? this.knowledgePoints,
        aiModel: aiModel ?? this.aiModel,
        latencyMs: latencyMs ?? this.latencyMs,
        tokensUsed: tokensUsed ?? this.tokensUsed,
        matched: matched ?? this.matched,
        userFeedback: userFeedback ?? this.userFeedback,
        actionType: actionType ?? this.actionType,
        synced: synced ?? this.synced,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        imagePath: imagePath ?? this.imagePath,
        createdAt: createdAt ?? this.createdAt,
      );
  SolveRecordEntity copyWithCompanion(SolveRecordsCompanion data) {
    return SolveRecordEntity(
      id: data.id.present ? data.id.value : this.id,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      answer: data.answer.present ? data.answer.value : this.answer,
      solution: data.solution.present ? data.solution.value : this.solution,
      knowledgePoints: data.knowledgePoints.present
          ? data.knowledgePoints.value
          : this.knowledgePoints,
      aiModel: data.aiModel.present ? data.aiModel.value : this.aiModel,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      tokensUsed:
          data.tokensUsed.present ? data.tokensUsed.value : this.tokensUsed,
      matched: data.matched.present ? data.matched.value : this.matched,
      userFeedback: data.userFeedback.present
          ? data.userFeedback.value
          : this.userFeedback,
      actionType:
          data.actionType.present ? data.actionType.value : this.actionType,
      synced: data.synced.present ? data.synced.value : this.synced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolveRecordEntity(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('answer: $answer, ')
          ..write('solution: $solution, ')
          ..write('knowledgePoints: $knowledgePoints, ')
          ..write('aiModel: $aiModel, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('matched: $matched, ')
          ..write('userFeedback: $userFeedback, ')
          ..write('actionType: $actionType, ')
          ..write('synced: $synced, ')
          ..write('remoteId: $remoteId, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      questionText,
      answer,
      solution,
      knowledgePoints,
      aiModel,
      latencyMs,
      tokensUsed,
      matched,
      userFeedback,
      actionType,
      synced,
      remoteId,
      imagePath,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolveRecordEntity &&
          other.id == this.id &&
          other.questionText == this.questionText &&
          other.answer == this.answer &&
          other.solution == this.solution &&
          other.knowledgePoints == this.knowledgePoints &&
          other.aiModel == this.aiModel &&
          other.latencyMs == this.latencyMs &&
          other.tokensUsed == this.tokensUsed &&
          other.matched == this.matched &&
          other.userFeedback == this.userFeedback &&
          other.actionType == this.actionType &&
          other.synced == this.synced &&
          other.remoteId == this.remoteId &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt);
}

class SolveRecordsCompanion extends UpdateCompanion<SolveRecordEntity> {
  final Value<int> id;
  final Value<String> questionText;
  final Value<String> answer;
  final Value<String> solution;
  final Value<String> knowledgePoints;
  final Value<String> aiModel;
  final Value<int> latencyMs;
  final Value<int> tokensUsed;
  final Value<bool> matched;
  final Value<String> userFeedback;
  final Value<String> actionType;
  final Value<bool> synced;
  final Value<int?> remoteId;
  final Value<String> imagePath;
  final Value<DateTime> createdAt;
  const SolveRecordsCompanion({
    this.id = const Value.absent(),
    this.questionText = const Value.absent(),
    this.answer = const Value.absent(),
    this.solution = const Value.absent(),
    this.knowledgePoints = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.tokensUsed = const Value.absent(),
    this.matched = const Value.absent(),
    this.userFeedback = const Value.absent(),
    this.actionType = const Value.absent(),
    this.synced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SolveRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String questionText,
    this.answer = const Value.absent(),
    this.solution = const Value.absent(),
    this.knowledgePoints = const Value.absent(),
    this.aiModel = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.tokensUsed = const Value.absent(),
    this.matched = const Value.absent(),
    this.userFeedback = const Value.absent(),
    this.actionType = const Value.absent(),
    this.synced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : questionText = Value(questionText);
  static Insertable<SolveRecordEntity> custom({
    Expression<int>? id,
    Expression<String>? questionText,
    Expression<String>? answer,
    Expression<String>? solution,
    Expression<String>? knowledgePoints,
    Expression<String>? aiModel,
    Expression<int>? latencyMs,
    Expression<int>? tokensUsed,
    Expression<bool>? matched,
    Expression<String>? userFeedback,
    Expression<String>? actionType,
    Expression<bool>? synced,
    Expression<int>? remoteId,
    Expression<String>? imagePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionText != null) 'question_text': questionText,
      if (answer != null) 'answer': answer,
      if (solution != null) 'solution': solution,
      if (knowledgePoints != null) 'knowledge_points': knowledgePoints,
      if (aiModel != null) 'ai_model': aiModel,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (tokensUsed != null) 'tokens_used': tokensUsed,
      if (matched != null) 'matched': matched,
      if (userFeedback != null) 'user_feedback': userFeedback,
      if (actionType != null) 'action_type': actionType,
      if (synced != null) 'synced': synced,
      if (remoteId != null) 'remote_id': remoteId,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SolveRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? questionText,
      Value<String>? answer,
      Value<String>? solution,
      Value<String>? knowledgePoints,
      Value<String>? aiModel,
      Value<int>? latencyMs,
      Value<int>? tokensUsed,
      Value<bool>? matched,
      Value<String>? userFeedback,
      Value<String>? actionType,
      Value<bool>? synced,
      Value<int?>? remoteId,
      Value<String>? imagePath,
      Value<DateTime>? createdAt}) {
    return SolveRecordsCompanion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      answer: answer ?? this.answer,
      solution: solution ?? this.solution,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      aiModel: aiModel ?? this.aiModel,
      latencyMs: latencyMs ?? this.latencyMs,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      matched: matched ?? this.matched,
      userFeedback: userFeedback ?? this.userFeedback,
      actionType: actionType ?? this.actionType,
      synced: synced ?? this.synced,
      remoteId: remoteId ?? this.remoteId,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (solution.present) {
      map['solution'] = Variable<String>(solution.value);
    }
    if (knowledgePoints.present) {
      map['knowledge_points'] = Variable<String>(knowledgePoints.value);
    }
    if (aiModel.present) {
      map['ai_model'] = Variable<String>(aiModel.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (tokensUsed.present) {
      map['tokens_used'] = Variable<int>(tokensUsed.value);
    }
    if (matched.present) {
      map['matched'] = Variable<bool>(matched.value);
    }
    if (userFeedback.present) {
      map['user_feedback'] = Variable<String>(userFeedback.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolveRecordsCompanion(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('answer: $answer, ')
          ..write('solution: $solution, ')
          ..write('knowledgePoints: $knowledgePoints, ')
          ..write('aiModel: $aiModel, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('matched: $matched, ')
          ..write('userFeedback: $userFeedback, ')
          ..write('actionType: $actionType, ')
          ..write('synced: $synced, ')
          ..write('remoteId: $remoteId, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AnswerLibraryTable extends AnswerLibrary
    with TableInfo<$AnswerLibraryTable, AnswerLibraryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswerLibraryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionTextMeta =
      const VerificationMeta('questionText');
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
      'question_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionHashMeta =
      const VerificationMeta('questionHash');
  @override
  late final GeneratedColumn<String> questionHash = GeneratedColumn<String>(
      'question_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
      'answer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _solutionMeta =
      const VerificationMeta('solution');
  @override
  late final GeneratedColumn<String> solution = GeneratedColumn<String>(
      'solution', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _knowledgePointsMeta =
      const VerificationMeta('knowledgePoints');
  @override
  late final GeneratedColumn<String> knowledgePoints = GeneratedColumn<String>(
      'knowledge_points', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        questionText,
        questionHash,
        answer,
        solution,
        knowledgePoints,
        source,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_library';
  @override
  VerificationContext validateIntegrity(
      Insertable<AnswerLibraryEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_text')) {
      context.handle(
          _questionTextMeta,
          questionText.isAcceptableOrUnknown(
              data['question_text']!, _questionTextMeta));
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('question_hash')) {
      context.handle(
          _questionHashMeta,
          questionHash.isAcceptableOrUnknown(
              data['question_hash']!, _questionHashMeta));
    } else if (isInserting) {
      context.missing(_questionHashMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(_answerMeta,
          answer.isAcceptableOrUnknown(data['answer']!, _answerMeta));
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('solution')) {
      context.handle(_solutionMeta,
          solution.isAcceptableOrUnknown(data['solution']!, _solutionMeta));
    }
    if (data.containsKey('knowledge_points')) {
      context.handle(
          _knowledgePointsMeta,
          knowledgePoints.isAcceptableOrUnknown(
              data['knowledge_points']!, _knowledgePointsMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnswerLibraryEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerLibraryEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_text'])!,
      questionHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_hash'])!,
      answer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer'])!,
      solution: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}solution'])!,
      knowledgePoints: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}knowledge_points'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AnswerLibraryTable createAlias(String alias) {
    return $AnswerLibraryTable(attachedDatabase, alias);
  }
}

class AnswerLibraryEntity extends DataClass
    implements Insertable<AnswerLibraryEntity> {
  final int id;
  final String questionText;
  final String questionHash;
  final String answer;
  final String solution;
  final String knowledgePoints;
  final String source;
  final DateTime createdAt;
  const AnswerLibraryEntity(
      {required this.id,
      required this.questionText,
      required this.questionHash,
      required this.answer,
      required this.solution,
      required this.knowledgePoints,
      required this.source,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_text'] = Variable<String>(questionText);
    map['question_hash'] = Variable<String>(questionHash);
    map['answer'] = Variable<String>(answer);
    map['solution'] = Variable<String>(solution);
    map['knowledge_points'] = Variable<String>(knowledgePoints);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnswerLibraryCompanion toCompanion(bool nullToAbsent) {
    return AnswerLibraryCompanion(
      id: Value(id),
      questionText: Value(questionText),
      questionHash: Value(questionHash),
      answer: Value(answer),
      solution: Value(solution),
      knowledgePoints: Value(knowledgePoints),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory AnswerLibraryEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerLibraryEntity(
      id: serializer.fromJson<int>(json['id']),
      questionText: serializer.fromJson<String>(json['questionText']),
      questionHash: serializer.fromJson<String>(json['questionHash']),
      answer: serializer.fromJson<String>(json['answer']),
      solution: serializer.fromJson<String>(json['solution']),
      knowledgePoints: serializer.fromJson<String>(json['knowledgePoints']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionText': serializer.toJson<String>(questionText),
      'questionHash': serializer.toJson<String>(questionHash),
      'answer': serializer.toJson<String>(answer),
      'solution': serializer.toJson<String>(solution),
      'knowledgePoints': serializer.toJson<String>(knowledgePoints),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnswerLibraryEntity copyWith(
          {int? id,
          String? questionText,
          String? questionHash,
          String? answer,
          String? solution,
          String? knowledgePoints,
          String? source,
          DateTime? createdAt}) =>
      AnswerLibraryEntity(
        id: id ?? this.id,
        questionText: questionText ?? this.questionText,
        questionHash: questionHash ?? this.questionHash,
        answer: answer ?? this.answer,
        solution: solution ?? this.solution,
        knowledgePoints: knowledgePoints ?? this.knowledgePoints,
        source: source ?? this.source,
        createdAt: createdAt ?? this.createdAt,
      );
  AnswerLibraryEntity copyWithCompanion(AnswerLibraryCompanion data) {
    return AnswerLibraryEntity(
      id: data.id.present ? data.id.value : this.id,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      questionHash: data.questionHash.present
          ? data.questionHash.value
          : this.questionHash,
      answer: data.answer.present ? data.answer.value : this.answer,
      solution: data.solution.present ? data.solution.value : this.solution,
      knowledgePoints: data.knowledgePoints.present
          ? data.knowledgePoints.value
          : this.knowledgePoints,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerLibraryEntity(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('questionHash: $questionHash, ')
          ..write('answer: $answer, ')
          ..write('solution: $solution, ')
          ..write('knowledgePoints: $knowledgePoints, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionText, questionHash, answer,
      solution, knowledgePoints, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerLibraryEntity &&
          other.id == this.id &&
          other.questionText == this.questionText &&
          other.questionHash == this.questionHash &&
          other.answer == this.answer &&
          other.solution == this.solution &&
          other.knowledgePoints == this.knowledgePoints &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class AnswerLibraryCompanion extends UpdateCompanion<AnswerLibraryEntity> {
  final Value<int> id;
  final Value<String> questionText;
  final Value<String> questionHash;
  final Value<String> answer;
  final Value<String> solution;
  final Value<String> knowledgePoints;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const AnswerLibraryCompanion({
    this.id = const Value.absent(),
    this.questionText = const Value.absent(),
    this.questionHash = const Value.absent(),
    this.answer = const Value.absent(),
    this.solution = const Value.absent(),
    this.knowledgePoints = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnswerLibraryCompanion.insert({
    this.id = const Value.absent(),
    required String questionText,
    required String questionHash,
    required String answer,
    this.solution = const Value.absent(),
    this.knowledgePoints = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : questionText = Value(questionText),
        questionHash = Value(questionHash),
        answer = Value(answer);
  static Insertable<AnswerLibraryEntity> custom({
    Expression<int>? id,
    Expression<String>? questionText,
    Expression<String>? questionHash,
    Expression<String>? answer,
    Expression<String>? solution,
    Expression<String>? knowledgePoints,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionText != null) 'question_text': questionText,
      if (questionHash != null) 'question_hash': questionHash,
      if (answer != null) 'answer': answer,
      if (solution != null) 'solution': solution,
      if (knowledgePoints != null) 'knowledge_points': knowledgePoints,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnswerLibraryCompanion copyWith(
      {Value<int>? id,
      Value<String>? questionText,
      Value<String>? questionHash,
      Value<String>? answer,
      Value<String>? solution,
      Value<String>? knowledgePoints,
      Value<String>? source,
      Value<DateTime>? createdAt}) {
    return AnswerLibraryCompanion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      questionHash: questionHash ?? this.questionHash,
      answer: answer ?? this.answer,
      solution: solution ?? this.solution,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (questionHash.present) {
      map['question_hash'] = Variable<String>(questionHash.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (solution.present) {
      map['solution'] = Variable<String>(solution.value);
    }
    if (knowledgePoints.present) {
      map['knowledge_points'] = Variable<String>(knowledgePoints.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerLibraryCompanion(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('questionHash: $questionHash, ')
          ..write('answer: $answer, ')
          ..write('solution: $solution, ')
          ..write('knowledgePoints: $knowledgePoints, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KnowledgeMasteryTable extends KnowledgeMastery
    with TableInfo<$KnowledgeMasteryTable, KnowledgeMasteryEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgeMasteryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _knowledgePointMeta =
      const VerificationMeta('knowledgePoint');
  @override
  late final GeneratedColumn<String> knowledgePoint = GeneratedColumn<String>(
      'knowledge_point', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('未分类'));
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _wrongCountMeta =
      const VerificationMeta('wrongCount');
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
      'wrong_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, knowledgePoint, subject, correctCount, wrongCount, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_mastery';
  @override
  VerificationContext validateIntegrity(
      Insertable<KnowledgeMasteryEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('knowledge_point')) {
      context.handle(
          _knowledgePointMeta,
          knowledgePoint.isAcceptableOrUnknown(
              data['knowledge_point']!, _knowledgePointMeta));
    } else if (isInserting) {
      context.missing(_knowledgePointMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
          _wrongCountMeta,
          wrongCount.isAcceptableOrUnknown(
              data['wrong_count']!, _wrongCountMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnowledgeMasteryEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgeMasteryEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      knowledgePoint: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}knowledge_point'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      wrongCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wrong_count'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $KnowledgeMasteryTable createAlias(String alias) {
    return $KnowledgeMasteryTable(attachedDatabase, alias);
  }
}

class KnowledgeMasteryEntity extends DataClass
    implements Insertable<KnowledgeMasteryEntity> {
  final int id;
  final String knowledgePoint;
  final String subject;
  final int correctCount;
  final int wrongCount;
  final DateTime updatedAt;
  const KnowledgeMasteryEntity(
      {required this.id,
      required this.knowledgePoint,
      required this.subject,
      required this.correctCount,
      required this.wrongCount,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['knowledge_point'] = Variable<String>(knowledgePoint);
    map['subject'] = Variable<String>(subject);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KnowledgeMasteryCompanion toCompanion(bool nullToAbsent) {
    return KnowledgeMasteryCompanion(
      id: Value(id),
      knowledgePoint: Value(knowledgePoint),
      subject: Value(subject),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      updatedAt: Value(updatedAt),
    );
  }

  factory KnowledgeMasteryEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgeMasteryEntity(
      id: serializer.fromJson<int>(json['id']),
      knowledgePoint: serializer.fromJson<String>(json['knowledgePoint']),
      subject: serializer.fromJson<String>(json['subject']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'knowledgePoint': serializer.toJson<String>(knowledgePoint),
      'subject': serializer.toJson<String>(subject),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  KnowledgeMasteryEntity copyWith(
          {int? id,
          String? knowledgePoint,
          String? subject,
          int? correctCount,
          int? wrongCount,
          DateTime? updatedAt}) =>
      KnowledgeMasteryEntity(
        id: id ?? this.id,
        knowledgePoint: knowledgePoint ?? this.knowledgePoint,
        subject: subject ?? this.subject,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  KnowledgeMasteryEntity copyWithCompanion(KnowledgeMasteryCompanion data) {
    return KnowledgeMasteryEntity(
      id: data.id.present ? data.id.value : this.id,
      knowledgePoint: data.knowledgePoint.present
          ? data.knowledgePoint.value
          : this.knowledgePoint,
      subject: data.subject.present ? data.subject.value : this.subject,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount:
          data.wrongCount.present ? data.wrongCount.value : this.wrongCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeMasteryEntity(')
          ..write('id: $id, ')
          ..write('knowledgePoint: $knowledgePoint, ')
          ..write('subject: $subject, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, knowledgePoint, subject, correctCount, wrongCount, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgeMasteryEntity &&
          other.id == this.id &&
          other.knowledgePoint == this.knowledgePoint &&
          other.subject == this.subject &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.updatedAt == this.updatedAt);
}

class KnowledgeMasteryCompanion
    extends UpdateCompanion<KnowledgeMasteryEntity> {
  final Value<int> id;
  final Value<String> knowledgePoint;
  final Value<String> subject;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<DateTime> updatedAt;
  const KnowledgeMasteryCompanion({
    this.id = const Value.absent(),
    this.knowledgePoint = const Value.absent(),
    this.subject = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  KnowledgeMasteryCompanion.insert({
    this.id = const Value.absent(),
    required String knowledgePoint,
    this.subject = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : knowledgePoint = Value(knowledgePoint);
  static Insertable<KnowledgeMasteryEntity> custom({
    Expression<int>? id,
    Expression<String>? knowledgePoint,
    Expression<String>? subject,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (knowledgePoint != null) 'knowledge_point': knowledgePoint,
      if (subject != null) 'subject': subject,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  KnowledgeMasteryCompanion copyWith(
      {Value<int>? id,
      Value<String>? knowledgePoint,
      Value<String>? subject,
      Value<int>? correctCount,
      Value<int>? wrongCount,
      Value<DateTime>? updatedAt}) {
    return KnowledgeMasteryCompanion(
      id: id ?? this.id,
      knowledgePoint: knowledgePoint ?? this.knowledgePoint,
      subject: subject ?? this.subject,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (knowledgePoint.present) {
      map['knowledge_point'] = Variable<String>(knowledgePoint.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeMasteryCompanion(')
          ..write('id: $id, ')
          ..write('knowledgePoint: $knowledgePoint, ')
          ..write('subject: $subject, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SolveRecordsTable solveRecords = $SolveRecordsTable(this);
  late final $AnswerLibraryTable answerLibrary = $AnswerLibraryTable(this);
  late final $KnowledgeMasteryTable knowledgeMastery =
      $KnowledgeMasteryTable(this);
  late final SolveRecordDao solveRecordDao =
      SolveRecordDao(this as AppDatabase);
  late final AnswerLibraryDao answerLibraryDao =
      AnswerLibraryDao(this as AppDatabase);
  late final KnowledgeDao knowledgeDao = KnowledgeDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [solveRecords, answerLibrary, knowledgeMastery];
}

typedef $$SolveRecordsTableCreateCompanionBuilder = SolveRecordsCompanion
    Function({
  Value<int> id,
  required String questionText,
  Value<String> answer,
  Value<String> solution,
  Value<String> knowledgePoints,
  Value<String> aiModel,
  Value<int> latencyMs,
  Value<int> tokensUsed,
  Value<bool> matched,
  Value<String> userFeedback,
  Value<String> actionType,
  Value<bool> synced,
  Value<int?> remoteId,
  Value<String> imagePath,
  Value<DateTime> createdAt,
});
typedef $$SolveRecordsTableUpdateCompanionBuilder = SolveRecordsCompanion
    Function({
  Value<int> id,
  Value<String> questionText,
  Value<String> answer,
  Value<String> solution,
  Value<String> knowledgePoints,
  Value<String> aiModel,
  Value<int> latencyMs,
  Value<int> tokensUsed,
  Value<bool> matched,
  Value<String> userFeedback,
  Value<String> actionType,
  Value<bool> synced,
  Value<int?> remoteId,
  Value<String> imagePath,
  Value<DateTime> createdAt,
});

class $$SolveRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SolveRecordsTable> {
  $$SolveRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solution => $composableBuilder(
      column: $table.solution, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knowledgePoints => $composableBuilder(
      column: $table.knowledgePoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiModel => $composableBuilder(
      column: $table.aiModel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get latencyMs => $composableBuilder(
      column: $table.latencyMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get matched => $composableBuilder(
      column: $table.matched, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userFeedback => $composableBuilder(
      column: $table.userFeedback, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SolveRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SolveRecordsTable> {
  $$SolveRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solution => $composableBuilder(
      column: $table.solution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knowledgePoints => $composableBuilder(
      column: $table.knowledgePoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiModel => $composableBuilder(
      column: $table.aiModel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get latencyMs => $composableBuilder(
      column: $table.latencyMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get matched => $composableBuilder(
      column: $table.matched, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userFeedback => $composableBuilder(
      column: $table.userFeedback,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SolveRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SolveRecordsTable> {
  $$SolveRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get solution =>
      $composableBuilder(column: $table.solution, builder: (column) => column);

  GeneratedColumn<String> get knowledgePoints => $composableBuilder(
      column: $table.knowledgePoints, builder: (column) => column);

  GeneratedColumn<String> get aiModel =>
      $composableBuilder(column: $table.aiModel, builder: (column) => column);

  GeneratedColumn<int> get latencyMs =>
      $composableBuilder(column: $table.latencyMs, builder: (column) => column);

  GeneratedColumn<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => column);

  GeneratedColumn<bool> get matched =>
      $composableBuilder(column: $table.matched, builder: (column) => column);

  GeneratedColumn<String> get userFeedback => $composableBuilder(
      column: $table.userFeedback, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<int> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SolveRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SolveRecordsTable,
    SolveRecordEntity,
    $$SolveRecordsTableFilterComposer,
    $$SolveRecordsTableOrderingComposer,
    $$SolveRecordsTableAnnotationComposer,
    $$SolveRecordsTableCreateCompanionBuilder,
    $$SolveRecordsTableUpdateCompanionBuilder,
    (
      SolveRecordEntity,
      BaseReferences<_$AppDatabase, $SolveRecordsTable, SolveRecordEntity>
    ),
    SolveRecordEntity,
    PrefetchHooks Function()> {
  $$SolveRecordsTableTableManager(_$AppDatabase db, $SolveRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolveRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolveRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolveRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> questionText = const Value.absent(),
            Value<String> answer = const Value.absent(),
            Value<String> solution = const Value.absent(),
            Value<String> knowledgePoints = const Value.absent(),
            Value<String> aiModel = const Value.absent(),
            Value<int> latencyMs = const Value.absent(),
            Value<int> tokensUsed = const Value.absent(),
            Value<bool> matched = const Value.absent(),
            Value<String> userFeedback = const Value.absent(),
            Value<String> actionType = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int?> remoteId = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SolveRecordsCompanion(
            id: id,
            questionText: questionText,
            answer: answer,
            solution: solution,
            knowledgePoints: knowledgePoints,
            aiModel: aiModel,
            latencyMs: latencyMs,
            tokensUsed: tokensUsed,
            matched: matched,
            userFeedback: userFeedback,
            actionType: actionType,
            synced: synced,
            remoteId: remoteId,
            imagePath: imagePath,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String questionText,
            Value<String> answer = const Value.absent(),
            Value<String> solution = const Value.absent(),
            Value<String> knowledgePoints = const Value.absent(),
            Value<String> aiModel = const Value.absent(),
            Value<int> latencyMs = const Value.absent(),
            Value<int> tokensUsed = const Value.absent(),
            Value<bool> matched = const Value.absent(),
            Value<String> userFeedback = const Value.absent(),
            Value<String> actionType = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int?> remoteId = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SolveRecordsCompanion.insert(
            id: id,
            questionText: questionText,
            answer: answer,
            solution: solution,
            knowledgePoints: knowledgePoints,
            aiModel: aiModel,
            latencyMs: latencyMs,
            tokensUsed: tokensUsed,
            matched: matched,
            userFeedback: userFeedback,
            actionType: actionType,
            synced: synced,
            remoteId: remoteId,
            imagePath: imagePath,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SolveRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SolveRecordsTable,
    SolveRecordEntity,
    $$SolveRecordsTableFilterComposer,
    $$SolveRecordsTableOrderingComposer,
    $$SolveRecordsTableAnnotationComposer,
    $$SolveRecordsTableCreateCompanionBuilder,
    $$SolveRecordsTableUpdateCompanionBuilder,
    (
      SolveRecordEntity,
      BaseReferences<_$AppDatabase, $SolveRecordsTable, SolveRecordEntity>
    ),
    SolveRecordEntity,
    PrefetchHooks Function()>;
typedef $$AnswerLibraryTableCreateCompanionBuilder = AnswerLibraryCompanion
    Function({
  Value<int> id,
  required String questionText,
  required String questionHash,
  required String answer,
  Value<String> solution,
  Value<String> knowledgePoints,
  Value<String> source,
  Value<DateTime> createdAt,
});
typedef $$AnswerLibraryTableUpdateCompanionBuilder = AnswerLibraryCompanion
    Function({
  Value<int> id,
  Value<String> questionText,
  Value<String> questionHash,
  Value<String> answer,
  Value<String> solution,
  Value<String> knowledgePoints,
  Value<String> source,
  Value<DateTime> createdAt,
});

class $$AnswerLibraryTableFilterComposer
    extends Composer<_$AppDatabase, $AnswerLibraryTable> {
  $$AnswerLibraryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionHash => $composableBuilder(
      column: $table.questionHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get solution => $composableBuilder(
      column: $table.solution, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knowledgePoints => $composableBuilder(
      column: $table.knowledgePoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AnswerLibraryTableOrderingComposer
    extends Composer<_$AppDatabase, $AnswerLibraryTable> {
  $$AnswerLibraryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionHash => $composableBuilder(
      column: $table.questionHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get solution => $composableBuilder(
      column: $table.solution, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knowledgePoints => $composableBuilder(
      column: $table.knowledgePoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AnswerLibraryTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnswerLibraryTable> {
  $$AnswerLibraryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => column);

  GeneratedColumn<String> get questionHash => $composableBuilder(
      column: $table.questionHash, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get solution =>
      $composableBuilder(column: $table.solution, builder: (column) => column);

  GeneratedColumn<String> get knowledgePoints => $composableBuilder(
      column: $table.knowledgePoints, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnswerLibraryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnswerLibraryTable,
    AnswerLibraryEntity,
    $$AnswerLibraryTableFilterComposer,
    $$AnswerLibraryTableOrderingComposer,
    $$AnswerLibraryTableAnnotationComposer,
    $$AnswerLibraryTableCreateCompanionBuilder,
    $$AnswerLibraryTableUpdateCompanionBuilder,
    (
      AnswerLibraryEntity,
      BaseReferences<_$AppDatabase, $AnswerLibraryTable, AnswerLibraryEntity>
    ),
    AnswerLibraryEntity,
    PrefetchHooks Function()> {
  $$AnswerLibraryTableTableManager(_$AppDatabase db, $AnswerLibraryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswerLibraryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswerLibraryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswerLibraryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> questionText = const Value.absent(),
            Value<String> questionHash = const Value.absent(),
            Value<String> answer = const Value.absent(),
            Value<String> solution = const Value.absent(),
            Value<String> knowledgePoints = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AnswerLibraryCompanion(
            id: id,
            questionText: questionText,
            questionHash: questionHash,
            answer: answer,
            solution: solution,
            knowledgePoints: knowledgePoints,
            source: source,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String questionText,
            required String questionHash,
            required String answer,
            Value<String> solution = const Value.absent(),
            Value<String> knowledgePoints = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AnswerLibraryCompanion.insert(
            id: id,
            questionText: questionText,
            questionHash: questionHash,
            answer: answer,
            solution: solution,
            knowledgePoints: knowledgePoints,
            source: source,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnswerLibraryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnswerLibraryTable,
    AnswerLibraryEntity,
    $$AnswerLibraryTableFilterComposer,
    $$AnswerLibraryTableOrderingComposer,
    $$AnswerLibraryTableAnnotationComposer,
    $$AnswerLibraryTableCreateCompanionBuilder,
    $$AnswerLibraryTableUpdateCompanionBuilder,
    (
      AnswerLibraryEntity,
      BaseReferences<_$AppDatabase, $AnswerLibraryTable, AnswerLibraryEntity>
    ),
    AnswerLibraryEntity,
    PrefetchHooks Function()>;
typedef $$KnowledgeMasteryTableCreateCompanionBuilder
    = KnowledgeMasteryCompanion Function({
  Value<int> id,
  required String knowledgePoint,
  Value<String> subject,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime> updatedAt,
});
typedef $$KnowledgeMasteryTableUpdateCompanionBuilder
    = KnowledgeMasteryCompanion Function({
  Value<int> id,
  Value<String> knowledgePoint,
  Value<String> subject,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime> updatedAt,
});

class $$KnowledgeMasteryTableFilterComposer
    extends Composer<_$AppDatabase, $KnowledgeMasteryTable> {
  $$KnowledgeMasteryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get knowledgePoint => $composableBuilder(
      column: $table.knowledgePoint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$KnowledgeMasteryTableOrderingComposer
    extends Composer<_$AppDatabase, $KnowledgeMasteryTable> {
  $$KnowledgeMasteryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get knowledgePoint => $composableBuilder(
      column: $table.knowledgePoint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$KnowledgeMasteryTableAnnotationComposer
    extends Composer<_$AppDatabase, $KnowledgeMasteryTable> {
  $$KnowledgeMasteryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get knowledgePoint => $composableBuilder(
      column: $table.knowledgePoint, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$KnowledgeMasteryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KnowledgeMasteryTable,
    KnowledgeMasteryEntity,
    $$KnowledgeMasteryTableFilterComposer,
    $$KnowledgeMasteryTableOrderingComposer,
    $$KnowledgeMasteryTableAnnotationComposer,
    $$KnowledgeMasteryTableCreateCompanionBuilder,
    $$KnowledgeMasteryTableUpdateCompanionBuilder,
    (
      KnowledgeMasteryEntity,
      BaseReferences<_$AppDatabase, $KnowledgeMasteryTable,
          KnowledgeMasteryEntity>
    ),
    KnowledgeMasteryEntity,
    PrefetchHooks Function()> {
  $$KnowledgeMasteryTableTableManager(
      _$AppDatabase db, $KnowledgeMasteryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnowledgeMasteryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnowledgeMasteryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnowledgeMasteryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> knowledgePoint = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              KnowledgeMasteryCompanion(
            id: id,
            knowledgePoint: knowledgePoint,
            subject: subject,
            correctCount: correctCount,
            wrongCount: wrongCount,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String knowledgePoint,
            Value<String> subject = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              KnowledgeMasteryCompanion.insert(
            id: id,
            knowledgePoint: knowledgePoint,
            subject: subject,
            correctCount: correctCount,
            wrongCount: wrongCount,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KnowledgeMasteryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KnowledgeMasteryTable,
    KnowledgeMasteryEntity,
    $$KnowledgeMasteryTableFilterComposer,
    $$KnowledgeMasteryTableOrderingComposer,
    $$KnowledgeMasteryTableAnnotationComposer,
    $$KnowledgeMasteryTableCreateCompanionBuilder,
    $$KnowledgeMasteryTableUpdateCompanionBuilder,
    (
      KnowledgeMasteryEntity,
      BaseReferences<_$AppDatabase, $KnowledgeMasteryTable,
          KnowledgeMasteryEntity>
    ),
    KnowledgeMasteryEntity,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SolveRecordsTableTableManager get solveRecords =>
      $$SolveRecordsTableTableManager(_db, _db.solveRecords);
  $$AnswerLibraryTableTableManager get answerLibrary =>
      $$AnswerLibraryTableTableManager(_db, _db.answerLibrary);
  $$KnowledgeMasteryTableTableManager get knowledgeMastery =>
      $$KnowledgeMasteryTableTableManager(_db, _db.knowledgeMastery);
}
