/// 本地答案库 DAO - 思谛 STDeel
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'answer_library_dao.g.dart';

@DriftAccessor(tables: [AnswerLibrary])
class AnswerLibraryDao extends DatabaseAccessor<AppDatabase>
    with _$AnswerLibraryDaoMixin {
  AnswerLibraryDao(super.db);

  Future<int> insert(AnswerLibraryCompanion entry) =>
      into(answerLibrary).insert(entry);

  /// 精确匹配（question_hash）
  Future<AnswerLibraryEntity?> matchByHash(String hash) =>
      (select(answerLibrary)
            ..where((t) => t.questionHash.equals(hash))
            ..limit(1))
          .getSingleOrNull();

  /// 按 LIKE 模糊匹配（前端本地快速过滤，留给后端 FTS5 做精确相似度）
  Future<List<AnswerLibraryEntity>> searchByText(String keyword,
      {int limit = 20}) =>
      (select(answerLibrary)
            ..where((t) => t.questionText.like('%$keyword%'))
            ..limit(limit))
          .get();

  Future<List<AnswerLibraryEntity>> getAll() => select(answerLibrary).get();

  /// 按卷次 + 题号精确取答案条目（无题干条目认领匹配用）
  Future<AnswerLibraryEntity?> findByPaperAndNo(int paperId, int questionNo) =>
      (select(answerLibrary)
            ..where((t) =>
                t.paperId.equals(paperId) & t.questionNo.equals(questionNo))
            ..limit(1))
          .getSingleOrNull();

  /// 按题号集合查所有候选条目（跨卷），
  /// 供解题时用"一页连续题号段"识别唯一卷次。
  Future<List<AnswerLibraryEntity>> findByNos(Set<int> nos) {
    if (nos.isEmpty) return Future.value(const []);
    return (select(answerLibrary)
          ..where((t) => t.questionNo.isIn(nos)))
        .get();
  }

  /// 反哺补全：命中"无题干条目"后，把拆题得到的题干与 hash 写回，
  /// 使该条目升级为完整条目，之后同题走题干精确匹配。
  Future<int> enrichContent(
    int id, {
    required String questionText,
    required String questionHash,
    String subject = '未分类',
  }) =>
      (update(answerLibrary)..where((t) => t.id.equals(id))).write(
        AnswerLibraryCompanion(
          questionText: Value(questionText),
          questionHash: Value(questionHash),
          subject: Value(subject),
        ),
      );

  /// 拉取后端答案库后整体替换（简化实现：删表后批量插入）
  Future<void> replaceAll(List<AnswerLibraryCompanion> entries) async {
    await transaction(() async {
      await delete(answerLibrary).go();
      await batch((b) => b.insertAll(answerLibrary, entries));
    });
  }
}
