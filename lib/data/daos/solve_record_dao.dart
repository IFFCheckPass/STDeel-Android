/// 解题记录 DAO - 思谛 STDeel
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'solve_record_dao.g.dart';

@DriftAccessor(tables: [SolveRecords])
class SolveRecordDao extends DatabaseAccessor<AppDatabase>
    with _$SolveRecordDaoMixin {
  SolveRecordDao(super.db);

  Future<int> insert(SolveRecordsCompanion entry) =>
      into(solveRecords).insert(entry);

  Future<List<SolveRecordEntity>> getAll() =>
      (select(solveRecords)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// 获取所有标记为某反馈（correct / wrong）的记录
  Future<List<SolveRecordEntity>> getByFeedback(String feedback) =>
      (select(solveRecords)
            ..where((t) => t.userFeedback.equals(feedback))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// 更新单条记录的反馈（同时标记为未同步，并记录最近动作类型用于四色标记）
  Future<int> updateFeedback(int id, String feedback) =>
      (update(solveRecords)..where((t) => t.id.equals(id)))
          .write(SolveRecordsCompanion(
        userFeedback: Value(feedback),
        actionType: Value(feedback),
        synced: const Value(false),
      ));

  /// 按 id 覆盖答案/解答/模型等字段（重答/疑问场景），同时标记为未同步
  Future<int> overwriteAnswer({
    required int id,
    required String answer,
    required String solution,
    required String aiModel,
    required int latencyMs,
    required int tokensUsed,
    String? knowledgePoints,
    String actionType = 'retry',
  }) =>
      (update(solveRecords)..where((t) => t.id.equals(id))).write(
        SolveRecordsCompanion(
          answer: Value(answer),
          solution: Value(solution),
          aiModel: Value(aiModel),
          latencyMs: Value(latencyMs),
          tokensUsed: Value(tokensUsed),
          knowledgePoints:
              knowledgePoints == null ? const Value.absent() : Value(knowledgePoints),
          matched: const Value(false),
          userFeedback: const Value('none'),
          actionType: Value(actionType),
          synced: const Value(false),
        ),
      );

  /// 取尚未同步至后端的记录
  Future<List<SolveRecordEntity>> getUnsynced() =>
      (select(solveRecords)..where((t) => t.synced.equals(false))).get();

  /// 标记单条记录为已同步
  Future<int> markSynced(int id) =>
      (update(solveRecords)..where((t) => t.id.equals(id)))
          .write(const SolveRecordsCompanion(synced: Value(true)));

  /// 按后端 remoteId 幂等写回（下拉同步用）。
  ///
  /// 该 remoteId 已存在则更新字段；不存在则插入一条新记录。
  /// @return 写入的本地自增 id
  Future<int> upsertFromBackend({
    required int remoteId,
    required String questionText,
    required String answer,
    required String solution,
    required String userFeedback,
    String knowledgePoints = '[]',
    String aiModel = '',
    int latencyMs = 0,
    int tokensUsed = 0,
    bool matched = false,
    DateTime? createdAt,
  }) async {
    final rec = await (select(solveRecords)
          ..where((t) => t.remoteId.equals(remoteId)))
        .getSingleOrNull();
    final baseFields = SolveRecordsCompanion(
      questionText: Value(questionText),
      answer: Value(answer),
      solution: Value(solution),
      knowledgePoints: Value(knowledgePoints),
      aiModel: Value(aiModel),
      latencyMs: Value(latencyMs),
      tokensUsed: Value(tokensUsed),
      matched: Value(matched),
      userFeedback: Value(userFeedback),
      actionType: Value(userFeedback),
      synced: const Value(true),
      remoteId: Value(remoteId),
      createdAt: Value(createdAt ?? DateTime.now()),
    );
    if (rec != null) {
      await (update(solveRecords)..where((t) => t.remoteId.equals(remoteId)))
          .write(baseFields);
      return rec.id;
    }
    return into(solveRecords).insert(
      SolveRecordsCompanion.insert(
        questionText: questionText,
        answer: Value(answer),
        solution: Value(solution),
        knowledgePoints: Value(knowledgePoints),
        aiModel: Value(aiModel),
        latencyMs: Value(latencyMs),
        tokensUsed: Value(tokensUsed),
        matched: Value(matched),
        userFeedback: Value(userFeedback),
        actionType: Value(userFeedback),
        synced: const Value(true),
        remoteId: Value(remoteId),
        createdAt: Value(createdAt ?? DateTime.now()),
      ),
    );
  }

  /// 取所有已同步（存在后端 id）的记录
  Future<List<SolveRecordEntity>> getAllSynced() =>
      (select(solveRecords)
            ..where((t) => t.remoteId.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
}
