# flowmax-skills

Version: v1.0.0

Flowmax 产品操作 skills 包，为 Claude Code 提供操作 Flowmax Market API 的能力。以 Claude Code 插件形式分发（`.claude-plugin/`），skills 位于 `skills/`。

## Skills

| skill | 核心能力 |
|---|---|
| `flowmax_agents` | PM agent / User Research agent CRUD、fork、部署、版本管理 |
| `flowmax_credits` | 积分余额查询、充值、流水记录 |
| `flowmax_logs` | PM 决策/研究日志、订单、仓位、PnL、账户权益 |
| `flowmax_pm_agent` | PM agent 状态与调度管理、对账、紧急平仓 |
| `flowmax_runs` | 已有 agent 的 x402 付费执行（pay-per-run） |
| `flowmax_leaderboard` | 基金经理 / 分析师排行榜（公开只读） |
| `flowmax_marketplace` | 浏览公开 agent 及其决策/订单/仓位/PnL |
| `flowmax_callout` | 喊单广场实时流（SSE） |
| `flowmax_follows` | 关注 / 取关 / 列表 |

## 前置条件

- `FLOWMAX_API_BASE_URL` — 默认 `https://market.dev.gcp.hubble-rpc.xyz`
- `FLOWMAX_API_KEY` — API key，前缀 `hb_sk_`（在 Flowmax 网页登录后自助生成）

示例：

```bash
export FLOWMAX_API_BASE_URL="https://market.dev.gcp.hubble-rpc.xyz"
export FLOWMAX_API_KEY="hb_sk_xxxxxxxxxxxxxxxxx"
```

> API key 前缀仍是 `hb_sk_`（后端未改），环境变量名已改为 `FLOWMAX_*`。

## 安装

作为 Claude Code 插件安装（`.claude-plugin/plugin.json` + `skills/`）。也可 symlink 单个 skill 到 `~/.claude/skills/` 本地调试。

## 运行 Evals

见 [evals/README.md](./evals/README.md)。

## 设计原则

见 [docs/skill-design-principles.md](./docs/skill-design-principles.md)。

## 迁移说明

从 `hubble-skills` 迁移而来，详见 [docs/migration-plan.md](./docs/migration-plan.md)。
