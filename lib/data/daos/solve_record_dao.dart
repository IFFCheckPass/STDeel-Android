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

  /// 更新单条记录的反馈
  Future<bool> updateFeedback(int id, String feedback) =>
      (update(solveRecords)..where((t) => t.id.equals(id)))
          .write(SolveRecordsCompanion.userFeedback(Value(feedback)));

  /// 按 id 覆盖答案/解答/模型等字段（重答/疑问场景）
  Future<bool> overwriteAnswer({
    required int id,
    required String answer,
    required String solution,
    required String aiModel,
    required int latencyMs,
    required int tokensUsed,
    String? knowledgePoints,
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
        ),
      );

  /// 取尚未同步至后端的记录（matched + userFeedback 任一变化即视为需同步）
  Future<List<SolveRecordEntity>> getUnsynced() =>
      select(solveRecords).get();
}
