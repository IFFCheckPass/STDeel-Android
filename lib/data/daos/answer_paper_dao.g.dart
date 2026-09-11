// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_paper_dao.dart';

// ignore_for_file: type=lint
mixin _$AnswerPaperDaoMixin on DatabaseAccessor<AppDatabase> {
  $AnswerPapersTable get answerPapers => attachedDatabase.answerPapers;
  AnswerPaperDaoManager get managers => AnswerPaperDaoManager(this);
}

class AnswerPaperDaoManager {
  final _$AnswerPaperDaoMixin _db;
  AnswerPaperDaoManager(this._db);
  $$AnswerPapersTableTableManager get answerPapers =>
      $$AnswerPapersTableTableManager(_db.attachedDatabase, _db.answerPapers);
}
