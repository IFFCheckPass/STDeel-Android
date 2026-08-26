# BUILD.md — 思谛 STDeel 编译 / 打包 / 发布记录与指南

> 本文件由 AGENTS.md 规则驱动：**每次成功编译后，将一整套环境准备与编译过程
> （工具链/依赖/签名/构建/上传命令）写入本文，以备下次使用**，并随仓库同步 `main`。
> 最新一次成功的构建过程见底部「累计记录」。

## 一、环境准备（首次一次性）

### 1.1 Flutter SDK
- 本仓库 `.metadata` 记录的 Flutter revision：`4cf24164269a5ebf0c16a028a00727d0e77bbb05`（stable）。
- `pubspec.yaml` 要求 `flutter >= 3.35.0`，Dart SDK `>=3.5.0 <4.0.0`。
- 安装（无 Flutter 时）：
  ```bash
  cd /opt
  curl -L -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.1-stable.tar.xz
  tar -xf flutter.tar.xz -C /opt
  export PATH="/opt/flutter/bin:$PATH"
  flutter config --no-analytics
  ```

### 1.2 Android SDK
- `ANDROID_HOME=/opt/android`。
- 安装 cmdline-tools 后用 `sdkmanager` 安装：`platform-tools`、`platforms;android-<compileSdk>`、`build-tools;36.0.0`、所需 NDK。
- 接受许可：`yes | sdkmanager --licenses`。

### 1.3 Java / Gradle
- 本项目要求 JDK 17（`android/gradle.properties` 已固定 `org.gradle.java.home=.../java/17.0.2`）。
- Gradle 8.x（本机 8.14.5）。

### 1.4 网络（受限容器）
- 通过代理 `http://127.0.0.1:18080`（环境变量 `HTTP(S)_PROXY`；`android/gradle.properties` 也配置了 systemProp 代理）。
- 注意：`storage.googleapis.com` 大文件下载可能很慢（受容器限速）；如中断可用 `curl -C -` 续传。

## 二、构建与发布流程

```bash
scripts/build-release.sh              # 一键：环境→签名→构建→上传→回写本文
```

等价手动步骤：
```bash
# 1) 取签名文件（仅构建用，不并入 main）
git checkout feature/signing-config -- android/upload-keystore.jks android/key.properties

# 2) 在 android/app/build.gradle.kts 的 buildTypes.release 临时启用签名并构建
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --release

# 3) 产物改名为 app-<版本号>.apk 并上传
cp build/app/outputs/flutter-apk/app-release.apk app-<版本号>.apk
# 版本 >=1.0.0 且为 a.b.0 → Release；否则 Pre-Release
gh release create v<版本号> [--prerelease] --repo IFFCheckPass/STDeel-Android app-<版本号>.apk

# 4) 清理签名文件并恢复 build.gradle.kts，保持 main 干净
rm -f android/upload-keystore.jks android/key.properties
```

## 三、累计记录

### v0.5.1（✅ 已成功编译并发布）
- **工具链（本沙箱 / Linux x64）**：
  - Flutter **3.47.1**（stable，revision `6655482ec0`）/ Dart **3.13.1**
  - Gradle **9.3.1**（本仓库 wrapper 指定；AGP 9.1.0 需 Gradle 9）
  - AGP **9.1.0**、Kotlin **2.4.0**（`android/settings.gradle.kts` 内已固定）
  - JDK **17**（`android/gradle.properties` 固定 `org.gradle.java.home=.../java/17.0.2`）
  - Android SDK：compileSdk=36、minSdk=24、targetSdk=36、build-tools 36.0.0、**NDK 28.2.13676358**（Flutter 3.47 默认，来自 flutter_tools `gradle_utils.dart`）
- **关键：出国源极慢（~70-150KB/s），务必用国内镜像**：
  - Flutter SDK / 引擎产物：`FLUTTER_STORAGE_BASE_URL=https://mirrors.cloud.tencent.com/flutter`
  - pub 依赖：`PUB_HOSTED_URL=https://pub.flutter-io.cn`
  - Android SDK 压缩包（dl.google.com）替换为：`https://mirrors.cloud.tencent.com/AndroidSDK/<archive>`
  - Gradle 发行包：`https://mirrors.cloud.tencent.com/gradle/gradle-9.3.1-bin.zip`
  - Maven 依赖：项目 `android/settings.gradle.kts` 已用阿里云 `maven.aliyun.com/repository/{google,central,gradle-plugin}`
- **Android SDK 安装关键点**：
  - `platform-tools`、`platforms;android-36`、`build-tools;36.0.0`、`ndk;28.2.13676358` 从 Tencent 直下 zip 解压到对应目录（不要去用 sdkmanager，它走 dl.google 慢）。
  - 版本与 zip 文件名映射见 Google `repository2-3.xml`（Tencent 也镜像该 xml）。
  - 用 `yes | sdkmanager --licenses` 接受许可。
- **耗时**：源码已就绪（任务1~5、6 已修），仅补编译；`flutter build apk --release` Gradle 阶段约 **756s**（首次含 AGP/Kotlin/原生 sqlite 编译）。产物 **app-release.apk 67.7MB**。
- **签名**：从 `feature/signing-config` 分支仅取 `upload-keystore.jks` + `key.properties` 到工作区（不并入 main），临时在 `app/build.gradle.kts` 启用 release 签名；构建后恢复、删除密钥文件。校验 SHA-256 `ed7379e8...`。
- **发布**：`gh release create v0.5.1 --prerelease`（0.5.1 < 1.0.0 → Pre-Release），产物 `app-0.5.1.apk`。
  - 链接：https://github.com/IFFCheckPass/STDeel-Android/releases/tag/v0.5.1

### v0.5.1 re-build（✅ 增量重打包——单纯补打 de8e087 两处编译修复）
- 场景：`v0.5.1` 首次发布后，`main` 又新增 `de8e087`（修复知识点分学科两处编译错误 + 补文档）。本次**在不改版本号**的前提下基于当前 `main` 重新打包，`gh release upload v0.5.1 --clobber` 覆盖发布产物。
- 签名切换：在 `android/app/build.gradle.kts` 增加 `signingConfigs.release`（读 `android/key.properties`），`buildTypes.release.signingConfig` 改为按 `project.hasProperty("signingEnabled")` 选择；构建命令加 `-PsigningEnabled` 启用。**必须**在文件顶部 `import java.util.Properties`，否则 Kotlin 脚本 `Unresolved reference 'Properties'`。
- 构建：`flutter build apk --release -PsigningEnabled`，Gradle 阶段 **47.8s**（增量热缓存，非首次 756s）。产物 67.7MB。
- 校验：`apksigner verify --print-certs` → SHA-256 `ed7379e8...`（与首发一致）。`gh release upload v0.5.1 app-0.5.1.apk --clobber`。
- 收尾：`git checkout -- android/app/build.gradle.kts` 还原，删除 `android/upload-keystore.jks`、`android/key.properties`、`app-0.5.1.apk`，保持 `main` 干净。

### v0.5.5（✅ 已成功编译并发布）
- 版本：`pubspec.yaml version: 0.5.5+11`；`settings_screen.dart` 底部文案 `v0.5.5`。
- **关键新增依赖**：`file_picker ^8.0.0`（选 PDF/Word）、`pdfx ^2.11.0`（PDF 渲染为图片、docx 解压提取文本）、`archive ^3.6.0`。
- **⚠️ compileSdk 36 强制覆盖（本次新增的重要坑）**：
  - 报错：`:file_picker:checkReleaseAarMetadata` — `flutter_plugin_android_lifecycle` 要求依赖方 compileSdk>=36，而 `file_picker` 固定 `compileSdk 34`。
  - 直接用根 `android/build.gradle.kts` 的 `subprojects { afterEvaluate { ... compileSdk = 36 } }` 会抛 `Cannot run Project.afterEvaluate when the project is already evaluated`（Flutter Gradle 插件重入求值导致），且载入时 `plugins.withId` 的扩展配置会被插件自带 `android { compileSdk = 34 }` 覆盖。
  - **有效方案**：直接改 pub-cache 里插件源码：
    ```bash
    sed -i 's/compileSdk 34/compileSdk 36/' /root/.pub-cache/hosted/pub.flutter-io.cn/file_picker-8.3.7/android/build.gradle
    ```
    本次仅 `file_picker` 依赖 lifecycle 报了错；`flutter_local_notifications/pdfx/jni*` 虽也固定更低 SDK 但无该依赖，无需改。
- **构建**：`flutter build apk --release -PsigningEnabled`，Gradle 阶段 **115.7s**（增量）。产物 **app-release.apk 68.0MB**。
- **签名**：与 v0.5.1 相同证书，SHA-256 `ed7379e83486704322dba43361dde16c307fe64f8fdabdc7e437f70eb457f933`（`apksigner verify --print-certs`）。产物改名 `app-0.5.5.apk`。
- **代码同步**：先 `git push` 源码到 `main`（commit `8ff2471`），再 `gh release create v0.5.5 --prerelease app-0.5.5.apk`（0.5.5 < 1.0.0 → Pre-Release）。
  - 链接：https://github.com/IFFCheckPass/STDeel-Android/releases/tag/v0.5.5
- 收尾：删除 `android/upload-keystore.jks`、`android/key.properties`、`app-0.5.5.apk`，保持 `main` 干净。

### v0.6.0（✅ 已成功编译并发布）
- 版本：`pubspec.yaml version: 0.6.0+12`；`settings_screen.dart` 底部文案 `v0.6.0`。
- **功能**：对齐后端 `PUT /users/api-key` 批量契约（发送 `{user_id, api_keys:[{api_key,name,enabled}]}`，全量覆盖该用户所有 key）。
- **环境笔记（本沙箱重置后）**：
  - 工具链目录：`/opt/flutter`（3.47.1 stable）、`/opt/android`（compileSdk 36、build-tools 36.0.0、NDK 28.2.13676358）。JDK 17 位于 `/root/.local/share/mise/installs/java/17.0.2`。
  - 构建前必须显式设置环境变量（否则命中 mise shim 的 JDK25）：`export ANDROID_HOME=/opt/android; export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java17 2>/dev/null))))`，并用 miseshims 之外的 JDK17 `java`。本环境用：`export PATH=/opt/flutter/bin:/root/.local/share/mise/installs/java/17.0.2/bin:$PATH`，再 `unset _MISE_SESSION`。
- **⚠️ Gradle daemon 锁（新坑）**：
  - 报错：`Timeout waiting to lock journal cache (/root/.gradle/caches/journal-1). Owner PID <残留>`。
  - 原因：上次构建留下的残留 Gradle/Java 进程（旧 PID）未退出，占用 journal 锁。构建命令 `flutter build apk --release -PsigningEnabled` 使用 `| tail` 时会先启动 daemon，若上轮进程未清，daemon 间会互锁。
  - 处理：`ps aux | grep -iE 'gradle|GradleDaemon'` 找到残留 PID，`kill -9 <pid>` 全部清掉；Gradle daemon 对锁超时约 1 分钟后报错。清理后重建即可。
- **⚠️ 旧 KGP 插件与 Gradle 9.3.1 不兼容（本次新增的重要坑）**：
  - 报错：`:app:compileReleaseJavaWithJavac` — `GeneratedPluginRegistrant.java:49 cannot find symbol class PackageInfoPlugin`。
  - 原因：App 用 AGP 9.1.0/ Kotlin 2.4.0/ Gradle 9.3.1（Flutter 3.47 模板）；而插件 `package_info_plus` 8.3.1 内置 `kotlin-gradle-plugin:1.7.22` + AGP 8.3.1，KGP 1.7.22 在 Gradle 9 下编译 Kotlin 不产出 class（其 AAR 存在但 `classes=0`），导致 registrant 引用的类缺失。同批 `pdfx` 用 KGP 1.9.23 可正常编译。
  - 修复：把 pub-cache 插件 build.gradle 的 Kotlin/AGP 提到与 pdfx 一致（已验证能在 Gradle 9 下编译）：
    ```bash
    sed -i "s/kotlin_version = '1.7.22'/kotlin_version = '1.9.23'/" $P/package_info_plus-8.3.1/android/build.gradle
    sed -i "s#com.android.tools.build:gradle:8.3.1#com.android.tools.build:gradle:8.5.2#" $P/package_info_plus-8.3.1/android/build.gradle
    ```
    本环境 pub-cache 在 `/root/.pub-cache/hosted/pub.dev/`（以 `.dart_tool/package_config.json` 的 rootUri 为准）。
  - file_picker 的 compileSdk：本次路径是 `pub.dev` 副本（v0.5.5 记的是 `pub.flutter-io.cn`），同样 `sed -i 's/compileSdk 34/compileSdk 36/' .../file_picker-8.3.7/android/build.gradle`。
- **构建**：`flutter build apk --release -PsigningEnabled`，增量 Gradle 阶段约 **68s**（前两次因锁/KGP/file_picker 先后失败，清理更正后续传成功）。产物 **app-release.apk 68.3MB**。
- **签名**：从 `feature/signing-config` 取 `upload-keystore.jks`+`key.properties`（不并入 main）；`apksigner verify --print-certs` SHA-256 `ed7379e8...`（与历史一致）。产物改名 `app-0.6.0.apk`。
- **发布**：先 `git push` 到 `main`（commit `1e16c5b`），再 `gh release create v0.6.0 --prerelease app-0.6.0.apk`（0.6.0 < 1.0.0 → Pre-Release）。
  - 链接：https://github.com/IFFCheckPass/STDeel-Android/releases/tag/v0.6.0
- 收尾：删除 `android/upload-keystore.jks`、`android/key.properties`、`/tmp/app-0.6.0.apk`，保持 `main` 干净。