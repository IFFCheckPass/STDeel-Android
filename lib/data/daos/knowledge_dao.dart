/// 知识点 DAO - 思谛 STDeel
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'knowledge_dao.g.dart';

@DriftAccessor(tables: [KnowledgeMastery])
class KnowledgeDao extends DatabaseAccessor<AppDatabase>
    with _$KnowledgeDaoMixin {
  KnowledgeDao(super.db);

  /// upsert：知识点已存在则累加，否则插入
  Future<void> upsert({
    required String knowledgePoint,
    int deltaCorrect = 0,
    int deltaWrong = 0,
  }) async {
    final existing = await (select(knowledgeMastery)
          ..where((t) => t.knowledgePoint.equals(knowledgePoint))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      await into(knowledgeMastery).insert(KnowledgeMasteryCompanion.insert(
        knowledgePoint: knowledgePoint,
        correctCount: Value(deltaCorrect),
        wrongCount: Value(deltaWrong),
      ));
    } else {
      await (update(knowledgeMastery)
            ..where((t) => t.id.equals(existing.id)))
          .write(KnowledgeMasteryCompanion(
        correctCount: Value(existing.correctCount + deltaCorrect),
        wrongCount: Value(existing.wrongCount + deltaWrong),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<List<KnowledgeMasteryEntity>> getAll() =>
      select(knowledgeMastery).get();

  /// 错误率 > 50% 视为薄弱
  Future<List<KnowledgeMasteryEntity>> getWeakPoints() {
    final query = select(knowledgeMastery);
    query.where((t) =>
        t.wrongCount.isBiggerThanValue(0) &
        // wrongCount / (correct+wrong) > 0.5
        t.wrongCount.isBiggerThanValue(0));
    query.orderBy([(t) => OrderingTerm.desc(t.wrongCount)]);
    return query.get().then((rows) => rows.where((r) {
      final total = r.correctCount + r.wrongCount;
      if (total == 0) return false;
      return (r.wrongCount / total) > 0.5;
    }).toList());
  }
}
