/// 卷次 DAO - 思谛 STDeel
///
/// 管理答案册/试卷来源（卷次）。用户导入答案册时创建一个卷次并命名，
/// 该卷的无题干答案条目通过 [AnswerLibrary.paperId] 归属卷次，
/// 供解题时"卷次+题号"认领匹配。
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'answer_paper_dao.g.dart';

@DriftAccessor(tables: [AnswerPapers])
class AnswerPaperDao extends DatabaseAccessor<AppDatabase>
    with _$AnswerPaperDaoMixin {
  AnswerPaperDao(super.db);

  Future<int> insert(String name, {String subject = '未分类'}) =>
      into(answerPapers).insert(AnswerPapersCompanion.insert(
        name: name,
        subject: Value(subject),
      ));

  /// 全部卷次（新导入在前）
  Future<List<AnswerPaperEntity>> getAll() =>
      (select(answerPapers)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<AnswerPaperEntity?> getById(int id) =>
      (select(answerPapers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 卷次名称 → 已存在的同名卷（导入答案册时避免重复创建）
  Future<AnswerPaperEntity?> getByName(String name) =>
      (select(answerPapers)..where((t) => t.name.equals(name.trim())))
          .getSingleOrNull();
}
