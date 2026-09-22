# Flowmax Skills 迁移升级计划

> 历史文档：x402 付费执行 skill（flowmax_runs）现已移除，相关清单与结论不代表当前能力。

> 从 `hubble-skills` 迁移并升级为 `flowmax-skills`。版本目标：`v1.0.0`（品牌重命名属 breaking）。

## 背景结论

后端现状：Market Server（Python FastAPI，`hubble-erc8004-market-api-server`）仍是**唯一对外网关**，保留 `/api/v1/*` 前缀，把 credits / agent-logs / leaderboard / callout / pm-agent / position-manager 等**内部转发**给拆分的微服务。因此旧 5 个 skill 的**路径大部分仍有效**，真正的问题是：品牌改名、base URL 过时、少数废弃/语义变化、以及缺新能力。

关键事实：

- **base URL**：`market-v2.bedev.hubble-rpc.xyz` → dev `market.dev.gcp.hubble-rpc.xyz`（prod `market-api-v2.hubble-trading.xyz` / `market.prod.gcp.hubble-rpc.xyz` 待切）。
- **鉴权**：仍是 `Authorization: Bearer hb_sk_<64hex>`（前缀 `hb_sk_` 未变），API key 绑定 user；少数端点 `allow_api_key=False` 只吃 Hydra session（`/auth/me`、`/user-exchange-auths`、`/openclaw/api-keys`）。
- **废弃**：`POST /api/v1/agents`（410）、`POST/PUT /agents/research`（Deprecated）、publish/card/A2A/feedback（已下线）、内部 Celery 执行（410）。

## 决策

1. **弃用 OpenClaw 双轨**，迁移到 Claude Code 插件形态（`.claude-plugin/` + 根级 `skills/`）。
2. **环境变量直接改** `FLOWMAX_*`，不保留 `HUBBLE_*` 兼容。
3. **新 skill 全做**：leaderboard（P0）、marketplace（P1）、callout + follows（P2）。

## 执行阶段

- **Phase 0**：结构迁移（`cc/skills/*` → `skills/*`、删 `cc/`/`openclaw/`/`CC.md`/`OPENCLAW.md`）+ 插件文件 + 版本统一 `v1.0.0`。
- **Phase 1**：逐 skill 改名 + 换 base URL + 修语义/补新端点（见各 SKILL.md）。
- **Phase 2**：新增 `flowmax_leaderboard` / `flowmax_marketplace` / `flowmax_callout` / `flowmax_follows`。
- **Phase 3**：evals（trigger/routing 改名 + 新 skill 用例 + 单变体化）+ CI workflow + 顶层文档。

## 逐 skill 变更摘要

| 旧 skill | 新 skill | 动作 |
|---|---|---|
| hubble_credits | flowmax_credits | 响应改 `items` 包裹 + 字符串金额 + `available/buckets` |
| hubble_agents | flowmax_agents | 补 fork / ws-ticket / reconcile-creation |
| hubble_logs | flowmax_logs | 加 `pm_id`/`round_id` 必填说明 + `account-equity`；不加 decisions（未透传） |
| hubble_pm_agent | flowmax_pm_agent | 补 reconcile-creation / ws-ticket |
| hubble_runs | flowmax_runs | 补 `/api/v1/me/runs` |
| — | flowmax_leaderboard | 新增（公开只读） |
| — | flowmax_marketplace | 新增 |
| — | flowmax_callout | 新增（SSE） |
| — | flowmax_follows | 新增 |
