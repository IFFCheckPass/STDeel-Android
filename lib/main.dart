/// 应用入口 - 思谛 STDeel
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/flutter_tex.dart';

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

  // 初始化 flutter_tex 渲染服务（Android/iOS 上通过本地 HttpServer 提供 Mathjax）。
  // 不调用会导致 TeXView 答案/解答渲染空白。
  if (!kIsWeb) {
    await TeXRenderingServer.start();
  }

  runApp(
    const AppProviders(
      child: StdeelApp(),
    ),
  );
}
