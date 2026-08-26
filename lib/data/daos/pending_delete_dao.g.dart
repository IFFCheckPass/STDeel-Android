// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_delete_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingDeleteDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingDeletesTable get pendingDeletes => attachedDatabase.pendingDeletes;
  PendingDeleteDaoManager get managers => PendingDeleteDaoManager(this);
}

class PendingDeleteDaoManager {
  final _$PendingDeleteDaoMixin _db;
  PendingDeleteDaoManager(this._db);
  $$PendingDeletesTableTableManager get pendingDeletes =>
      $$PendingDeletesTableTableManager(
          _db.attachedDatabase, _db.pendingDeletes);
}
