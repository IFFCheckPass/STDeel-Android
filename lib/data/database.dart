/// drift 数据库定义 - 思谛 STDeel
///
/// 使用 LazyDatabase + sqlite3_flutter_libs 在移动端打开 SQLite。
/// 通过 [AppDatabase.instance] 单例访问。
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'daos/answer_library_dao.dart';
import 'daos/knowledge_dao.dart';
import 'daos/solve_record_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [SolveRecords, AnswerLibrary, KnowledgeMastery],
  daos: [SolveRecordDao, AnswerLibraryDao, KnowledgeDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_open());
  AppDatabase.forTesting(super.e);

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // 创建 questionHash 索引，加速精确匹配
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_answer_hash ON answer_library(question_hash)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_solve_feedback ON solve_records(user_feedback)',
          );
        },
        onUpgrade: (m, from, to) async {
          // v1 -> v2：为四色状态标记新增 actionType 字段
          if (from < 2) {
            await m.addColumn(
              solveRecords,
              solveRecords.actionType,
            );
          }
          // v2 -> v3：下拉同步用后端主键 remoteId（幂等去重）
          if (from < 3) {
            await m.addColumn(
              solveRecords,
              solveRecords.remoteId,
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_solve_remote ON solve_records(remote_id)',
            );
          }
        },
      );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'stdeel.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  });
}
