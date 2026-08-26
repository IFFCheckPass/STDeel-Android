package com.stdeel.steel

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "stdeel/updater",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // 应用内更新：用 FileProvider 暴露已下载的 APK 并拉起系统安装器
                "installApk" -> {
                    val path = call.argument<String>("path") ?: ""
                    installApk(this, path, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(activity: Activity, path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("INSTALL_FAILED", "APK 文件不存在：$path", null)
                return
            }
            val uri: Uri = FileProvider.getUriForFile(
                activity,
                activity.packageName + ".fileprovider",
                file,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                // 部分国产 ROM 需要此标识才会弹安装确认
                putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
            }
            activity.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }
}