/// 全局配置 - 思谛 STDeel
///
/// 集中管理后端 URL、SharedPreferences key、命中阈值等常量。
class AppConfig {
  AppConfig._();

  /// 默认后端 API 基础 URL（可在设置页覆盖）
  ///
  /// URL 语义为「完整 API 根」——含协议、host、以及到 API 根的全部前缀路径
  /// （如 `/api/v1` 或反代前缀 `/stapi`）。代码只在其后追加资源名
  /// （如 `/solve-records`、`/users/register`），不再硬编码 `/api/v1`，
  /// 从而兼容 `snserver.dpdns.org/stapi` 这类反代路径。
  static const String defaultBackendUrl = 'https://api.stdeel.com/api/v1';

  /// SharedPreferences keys
  static const String keyBackendUrl = 'backend_url';
  static const String keyUserId = 'user_id';
  static const String keyDeviceId = 'device_id';
  static const String keyAiCombos = 'ai_combos_json';
  static const String keyThinkTimeoutSeconds = 'think_timeout_seconds';

  /// 默认 think 检测超时（秒）
  static const int defaultThinkTimeoutSeconds = 20;

  /// 三层匹配阈值
  static const double matchHighThreshold = 0.85; // 直接返回
  static const double matchLowThreshold = 0.60;  // 低于走 AI

  /// AI 返回 JSON 解析失败时的兜底文案
  static const String fallbackAnswerText = '（AI 未返回有效答案）';
}
