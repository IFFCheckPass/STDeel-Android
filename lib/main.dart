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
  await NotificationService().init();

  runApp(
    const AppProviders(
      child: StdeelApp(),
    ),
  );
}
