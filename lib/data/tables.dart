/// drift 表定义 - 思谛 STDeel
///
/// 三张核心表：
/// - SolveRecords：解题记录
/// - AnswerLibrary：本地答案库缓存
/// - KnowledgeMastery：知识点掌握度
library;

import 'package:drift/drift.dart';

/// 解题记录表
///
/// 每次解题（无论成功/失败/匹配命中）写入一行；
/// 同一图片的多道题分别记录。
@DataClassName('SolveRecordEntity')
class SolveRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionText => text()();
  TextColumn get answer => text().withDefault(const Constant(''))();
  TextColumn get solution => text().withDefault(const Constant(''))();
  TextColumn get knowledgePoints =>
      text().withDefault(const Constant('[]'))(); // JSON 数组字符串
  TextColumn get aiModel => text().withDefault(const Constant(''))();
  IntColumn get latencyMs => integer().withDefault(const Constant(0))();
  IntColumn get tokensUsed => integer().withDefault(const Constant(0))();
  BoolColumn get matched =>
      boolean().withDefault(const Constant(false))(); // 是否本地/后端答案库命中
  TextColumn get userFeedback => text().withDefault(
    const Constant('none'),
  )(); // none | correct | wrong
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))(); // 是否已同步至后端
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// 本地答案库缓存表
///
/// 同步自后端答案库；新上传的标准答案也写入本地。
@DataClassName('AnswerLibraryEntity')
class AnswerLibrary extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionText => text()();
  TextColumn get questionHash => text()(); // sha256，精确匹配用
  TextColumn get answer => text()();
  TextColumn get solution => text().withDefault(const Constant(''))();
  TextColumn get knowledgePoints =>
      text().withDefault(const Constant('[]'))();
  TextColumn get source => text().withDefault(const Constant('local'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// 知识点掌握度表
///
/// 同步自后端 /api/v1/knowledge/mastery；离线时本地累计。
@DataClassName('KnowledgeMasteryEntity')
class KnowledgeMastery extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get knowledgePoint => text()();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
