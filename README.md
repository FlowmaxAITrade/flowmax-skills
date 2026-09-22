# flowmax-skills

Version: v1.0.1

Flowmax 产品操作 skills 包，为 Claude Code 提供操作 Flowmax Market API 的能力。以 Claude Code 插件形式分发（`.claude-plugin/`），skills 位于 `skills/`。

## Skills

| skill | 核心能力 |
|---|---|
| `flowmax_agents` | PM agent / User Research agent CRUD、fork、部署、版本管理 |
| `flowmax_credits` | 积分余额查询、充值、流水记录 |
| `flowmax_logs` | PM 决策/研究日志、订单、仓位、PnL、账户权益 |
| `flowmax_pm_agent` | PM agent 状态与调度管理、对账、紧急平仓 |
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

在 Claude Code 里执行：

```
/plugin marketplace add FlowmaxAITrade/flowmax-skills
/plugin install flowmax-skills
```

安装后即可在任意目录触发这些 skill。

> 经 marketplace 安装后，插件的**完整名**是 `flowmax-skills@flowmax-skills`（`插件名@marketplace名`）。下面「更新」和 `uninstall` 都要用这个完整名。

本地调试可 symlink 单个 skill 到 `~/.claude/skills/`。

## 运行 Evals

见 [evals/README.md](./evals/README.md)。

## 设计原则

见 [docs/skill-design-principles.md](./docs/skill-design-principles.md)。

## 版本发布

版本号**手动**管理（无构建产物，不需要 release-please）：

1. 把 `plugin.json` 的 `version` 和 `.claude-plugin/marketplace.json` 的 `plugins[].version` **同步**改成新版本（语义化版本，如 `1.0.1`）。
2. 打 tag（会自动校验两处版本一致；tag 格式固定为 `flowmax-skills--v<version>`）：

```bash
claude plugin tag --push          # 或先 --dry-run 预览
```

3. 用户侧更新到最新版本（`update` 是 `claude plugin` 的 CLI 命令，不是斜杠命令；用完整名）：

```bash
claude plugin update flowmax-skills@flowmax-skills
```

更新后需重启 Claude Code 生效。

## 迁移说明

从 `hubble-skills` 迁移而来，详见 [docs/migration-plan.md](./docs/migration-plan.md)。
