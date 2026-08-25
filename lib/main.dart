/// 应用入口 - 思谛 STDeel
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 锁竖屏（拍照/解题场景）
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // 初始化本地通知（Failover / 解题完成 / 失败推送）
  // 唯一实例：await init() 后注入 AppProviders 复用，避免双重初始化。
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    AppProviders(
      notificationService: notificationService,
      child: const StdeelApp(),
    ),
  );
}
