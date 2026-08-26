/// 待删除队列 DAO - 思谛 STDeel
///
/// 记录"本地已删、但后端删除未成功"的解题记录主键，供下次同步重试删除。
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'pending_delete_dao.g.dart';

@DriftAccessor(tables: [PendingDeletes])
class PendingDeleteDao extends DatabaseAccessor<AppDatabase>
    with _$PendingDeleteDaoMixin {
  PendingDeleteDao(super.db);

  /// 记录一条待删除的服务器主键（幂等：已存在则忽略）
  Future<void> add(int remoteId) async {
    if (remoteId <= 0) return;
    final exists = await (select(pendingDeletes)
          ..where((t) => t.remoteId.equals(remoteId)))
        .getSingleOrNull();
    if (exists != null) return;
    await into(pendingDeletes).insert(
      PendingDeletesCompanion.insert(remoteId: remoteId),
    );
  }

  /// 取全部待删除主键
  Future<List<PendingDeleteEntity>> getAll() => select(pendingDeletes).get();

  /// 取全部待删除 remoteId（去重集合）
  Future<Set<int>> getAllRemoteIds() async {
    final rows = await select(pendingDeletes).get();
    return rows.map((e) => e.remoteId).toSet();
  }

  /// 删除成功后移除该主键
  Future<int> remove(int remoteId) =>
      (delete(pendingDeletes)..where((t) => t.remoteId.equals(remoteId)))
          .go();

  /// 仅当已存在该主键才移除（供历史删除时"补记"判断用）
  Future<bool> contains(int remoteId) async {
    final r = await (select(pendingDeletes)
          ..where((t) => t.remoteId.equals(remoteId)))
        .getSingleOrNull();
    return r != null;
  }
}