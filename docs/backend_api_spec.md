# 思谛 STDeel 后端接口适配清单

> 由前端整理，供后端团队适配。当前前端已按此约定预留代码并**隐藏**相关 UI；
> 后端适配完成、并与前端联调确认后，前端再开放功能。

## 总览

- 当前已上线统建的既有接口（第 0 批 / 第 2 批）：
  - `POST /users/register`（device_id 复用 / username 复用 / 匿名 / 全传）
  - `POST /solve-records`、`PATCH /solve-records/{id}/feedback`
  - `GET /knowledge/mastery?user_id=`、`GET /knowledge/weak?user_id=`
  - `GET /users/{user_id}/mastery`（{items,total}）
  - `GET /knowledge/points`（distinct 知识点）
  - `POST /answer-library`、`POST /answer-library/match`
  - `POST /files/upload`
- 本次新增待适配接口见下。

## 1. 解题记录下拉（双向同步）

**`GET /solve-records`**

用途：手动同步时，前端把本地上传后，再从后端拉回本机没有的记录。

Query 参数：
- `user_id`（必填）：当前设备对应的 user_id
- `correct_days`（可选）：返回最近 N 天内 `user_feedback=correct` 的记录，默认 30（1 个月）
- `wrong_days`（可选）：返回最近 N 天内 `user_feedback=wrong` 的记录，默认 90（3 个月）

响应体（沿用 {items,total} 外衣）：
```json
{
  "total": 123,
  "items": [
    {
      "id": 1001,
      "user_id": "u_xxx",
      "question_text": "...",
      "answer": "...",
      "solution": "...",
      "knowledge_points": ["...", "..."],
      "ai_model": "deepseek-chat",
      "latency_ms": 3200,
      "tokens_used": 512,
      "matched": true,
      "user_feedback": "correct",
      "image_path": "",
      "created_at": "2026-08-01T12:00:00Z"
    }
  ]
}
```

字段约定：
- `user_feedback` ∈ `correct | wrong`。其余（`none`、`solve` 等动作态）不回传。
- 正确记录取近 **1 个月**，错误记录取近 **3 个月**；窗口期取并集、按 `created_at` 倒序。
- `id` 为后端主键；前端用它做幂等（写回本地时按该 id 去重，避免重复插入）。

## 2. 用户名绑定（账号不变 / 数据不变）

**`POST /users/register`** 已支持"只传 username → 按 username 找或创建"。
前端预留前端方法：
- `bindUserByUsername(username)`：发起 `POST /users/register`，body `{username, platform}`，
  解析 `user_id` 并作为后续所有数据的归属用户。

需要后端确认：仅传 `username` 时，返回的 `user_id` 必须是该 username 在库中唯一的稳定用户，
以保证"跨端 / 跨设备用同一用户名即同一账号、同一份数据"。

## 3. 用户 api-key 跨端同步

目标：把用户在 App 内配置的 AI api-key 上传后端，实现"账号不变、数据不变、换机不重配"。

需后端新增接口（接口形状待定，以下为建议，可调整）：

**`PUT /users/api-key`**
- auth：`user_id`（可放 query 或 header）
- body：
```json
{ "user_id": "u_xxx", "api_key": "sk-..." }
```
- 语义：为该用户开设 / 更新一个 api-key 槽位（可含 key 名称、是否启用等）。

**`GET /users/api-key`**
- query：`user_id`
- 响应：该用户已保存的 api-key（或列表），供换机时拉回。

> 前置条件：需要"用户名密码"或更安全的鉴权能力（目前仅有 device_id / username 匿名复用），
> 否则任意知道 user_id 的请求都能读写该用户的 api-key。建议后端在正式上线前补充鉴权。

## 注意与约束

- 前端在 `AppConfig.kAccountBindingEnabled = false`（默认）下**不渲染**任何绑定 UI，
  保证后端适配完成前不产生与 username 归属冲突的数据污染。
- 功能开关开放时，需同时满足：本地已注册 user_id 与待绑定 username 的归属合并策略明确
  （合并 / 覆盖 / 保留本地）。