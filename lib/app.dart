/// 应用根组件 - 思谛 STDeel
///
/// 通过 MultiProvider 在启动时一次性注入所有服务与 Provider，
/// 服务依赖均为单例，不需要 ProxyProvider 的"依赖变更回放"语义。
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database.dart';
import 'providers/settings_provider.dart';
import 'providers/solve_provider.dart';
import 'screens/answer_screen.dart';
import 'screens/home_screen.dart';
import 'services/ai_service.dart';
import 'services/backend_api.dart';
import 'services/failover_manager.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';

class StdeelApp extends StatelessWidget {
  const StdeelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '思谛 STDeel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: const Color(0xFF4F7CFF)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const HomeScreen(),
      routes: {
        '/answer': (_) => const AnswerScreen(),
      },
    );
  }
}

/// 启动期注入依赖；服务之间通过构造函数装配好，
/// 子组件只读即可，避免 ProxyProvider 的复杂签名与潜在误用。
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(create: (_) => AppDatabase.instance),
        Provider<BackendApi>(create: (_) => BackendApi()),
        Provider<AiService>(create: (_) => AiService()),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        Provider<SyncService>(
          create: (ctx) => SyncService(
            database: ctx.read<AppDatabase>(),
            backendApi: ctx.read<BackendApi>(),
          ),
        ),
        Provider<FailoverManager>(
          create: (ctx) => FailoverManager(
            aiService: ctx.read<AiService>(),
            notificationService: ctx.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<SolveProvider>(
          create: (ctx) => SolveProvider(
            aiService: ctx.read<AiService>(),
            failoverManager: ctx.read<FailoverManager>(),
            syncService: ctx.read<SyncService>(),
            notificationService: ctx.read<NotificationService>(),
            database: ctx.read<AppDatabase>(),
            backendApi: ctx.read<BackendApi>(),
          ),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (ctx) =>
              SettingsProvider(backendApi: ctx.read<BackendApi>()),
        ),
      ],
      child: child,
    );
  }
}
