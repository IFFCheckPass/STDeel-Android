// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_record_dao.dart';

// ignore_for_file: type=lint
mixin _$SolveRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $SolveRecordsTable get solveRecords => attachedDatabase.solveRecords;
  SolveRecordDaoManager get managers => SolveRecordDaoManager(this);
}

class SolveRecordDaoManager {
  final _$SolveRecordDaoMixin _db;
  SolveRecordDaoManager(this._db);
  $$SolveRecordsTableTableManager get solveRecords =>
      $$SolveRecordsTableTableManager(_db.attachedDatabase, _db.solveRecords);
}
