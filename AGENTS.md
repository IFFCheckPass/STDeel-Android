# AGENTS.md — 思谛 STDeel 项目代理指令

> 本文件为持久化记忆文件。所有 AI 编码代理在任何会话/任何模式下都必须遵守以下规则。
> 本文件应随仓库保存并同步到 `main`，作为不可撤销的项目约束。

## 强制执行约束（不可协商，无论如何均不得违反）

### 签名分支禁止合并 / 禁止 PR
- 分支 **`feature/signing-config`** 仅用于留存统一签名的必要文件：
  - `android/upload-keystore.jks`（签名证书）
  - `android/key.properties`（密钥口令，含敏感信息）
- **严禁**将该分支合并到 `main` 或任何其他分支，合并命令一律不得执行。
- **严禁**以任何形式对该分支发起、创建或合并 Pull Request / Merge Request，也不得把它作为目标分支或源分支参与任何合并。
- 该分支上的文件带有 `.gitignore` 忽略 + 敏感口令，合并会污染主分支并泄露密钥凭证。
- 无论后续需求如何表述（如"统一签名""解决安装失败""同步签名"），只要涉及把该分支并入主分支或提 PR，一律拒绝并提醒用户此约束。

## 版本发布规则（GitHub Release）
- 版本号由 `pubspec.yaml` 的 `version` 决定，同步更新 `lib/screens/settings_screen.dart` 底部角标文案。
- **如无特别说明，版本号在 1.0.0 之前的一律发布为 GitHub Pre-Release**（包括 0.x、0.x.y 等所有未达 1.0.0 的版本）。
- 只有升到 **1.0.0** 才视为正式版（Release），在此之前不要发布非 pre-release。
- 发布动作统一使用 `gh release create <tag> --prerelease`，tag 格式沿用 `v<版本号>`。