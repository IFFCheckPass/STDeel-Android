/// 通知服务 - 思谛 STDeel
///
/// 使用 flutter_local_notifications 推送本地通知：
///   - 解题成功："✅ 解题完成：共识别 N 道题，耗时 Xs"
///   - 解题失败："❌ 解题失败：所有 AI 组合均未在限时内响应"
///   - Failover 切换："⚠️ Qwen3.5 15s 未开始思考，已自动切换至 Kimi K2.6"
///   - 后台解题：拍照后可切至其他应用，AI 完成后推送通知
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _successChannel = AndroidNotificationChannel(
    'stdeel_solve_success',
    '解题成功',
    description: 'AI 解题完成的通知',
    importance: Importance.high,
  );
  static const _failoverChannel = AndroidNotificationChannel(
    'stdeel_failover',
    'Failover 切换',
    description: 'AI 模型切换通知',
    importance: Importance.defaultImportance,
  );
  static const _failChannel = AndroidNotificationChannel(
    'stdeel_solve_fail',
    '解题失败',
    description: '解题失败通知',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_successChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_failoverChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_failChannel);
    _initialized = true;
  }

  Future<void> _show({
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    int id = 0,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> notifySuccess({
    required int questionCount,
    required Duration elapsed,
  }) =>
      _show(
        title: '✅ 解题完成',
        body: '共识别 $questionCount 道题，耗时 ${elapsed.inSeconds}.${(elapsed.inMilliseconds % 1000) ~/ 100}s',
        channel: _successChannel,
        id: 1,
      );

  Future<void> notifyFailure(String reason) => _show(
        title: '❌ 解题失败',
        body: reason,
        channel: _failChannel,
        id: 2,
      );

  Future<void> notifyFailover(String reason) => _show(
        title: '⚠️ 模型切换',
        body: reason,
        channel: _failoverChannel,
        id: 3,
      );
}
