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

  /// 拉取后端答案库后整体替换（简化实现：删表后批量插入）
  Future<void> replaceAll(List<AnswerLibraryCompanion> entries) async {
    await transaction(() async {
      await delete(answerLibrary).go();
      await batch((b) => b.insertAll(answerLibrary, entries));
    });
  }
}
