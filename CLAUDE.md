# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

`flowmax-skills` 是一个 AI assistant skill 包，为 Claude Code 提供操作 Flowmax Market API 的能力。当前版本：`v1.0.0`（见 `VERSION`）。

每个 skill 对应一类业务操作，通过 `FLOWMAX_API_KEY`（前缀 `hb_sk_`）鉴权，直接调 REST API。网关为 Market Server，默认 dev 域名 `https://market.dev.gcp.hubble-rpc.xyz`。

## 目录结构

```
skills/             # Claude Code skills（9 个，每个 skill 一个 SKILL.md）
evals/              # 自动化 eval 套件
  trigger/          # per-skill should_trigger 测试（每个 skill 20 条）
  routing/          # 跨 skill 路由测试
  results/          # 本地结果，已 gitignore
docs/               # 设计文档和原则
.claude-plugin/     # 插件清单（plugin.json / marketplace.json）
```

## 已有 Skills

| skill | 核心能力 |
|---|---|
| `flowmax_agents` | PM agent / User Research agent CRUD、部署、版本管理 |
| `flowmax_credits` | 积分余额查询、充值、流水记录 |
| `flowmax_logs` | PM agent 决策日志、订单、仓位、PnL、账户权益 |
| `flowmax_pm_agent` | PM agent 状态与调度管理 |
| `flowmax_runs` | 已有 agent 的 x402 付费执行（pay-per-run） |
| `flowmax_leaderboard` | 基金经理 / 分析师排行榜 |
| `flowmax_marketplace` | 浏览公开 agent |
| `flowmax_callout` | 喊单广场实时流 |
| `flowmax_follows` | 关注 / 取关 |

## 运行 Evals

```bash
# 全部（trigger + routing）
bash evals/run_all.sh

# 只跑某一类
bash evals/run_all.sh trigger
bash evals/run_all.sh routing

# Debug：每个 eval 只跑前 N 条
FLOWMAX_EVAL_LIMIT=3 bash evals/run_all.sh

# 换模型
FLOWMAX_EVAL_MODEL=claude-sonnet-5 bash evals/run_all.sh routing
```

**后端选择**（自动）：
- 未设置 `ANTHROPIC_API_KEY` → 走 `claude -p`（需先登录一次 Claude Code），以空临时目录作为 cwd 防止项目本地 `.claude/` 干扰
- 已设置 `ANTHROPIC_API_KEY` → 走 urllib 直调 API（更快，CI 使用此路径）

## CI

`.github/workflows/skills-eval.yml` 在以下情况自动跑 eval：
- PR 或 push 修改了 `skills/**/SKILL.md` 或 `evals/**`
- 需要 Actions secret：`ANTHROPIC_API_KEY`

## 修改 Skill 的工作流

1. 编辑 `skills/<skill_name>/SKILL.md`
2. 检查 `evals/trigger/<skill_name>.json` 是否需要补测试
3. 检查 `evals/routing/routing_eval.json` 的路由用例是否覆盖新改动
4. 本地跑 `bash evals/run_all.sh` 确认 F1 ≥ 0.85、routing pass rate 无下降

## 关键设计原则（见 `docs/skill-design-principles.md`）

**原则 1**：不要新增 auth/login 类 skill。所有 skill 以 `$FLOWMAX_API_KEY` 鉴权，"如何获取 key"属于用户在 Flowmax 网页上的 onboarding 流程，不进 skill。

**原则 2**：skill 的 `description` 必须覆盖 body 里的所有操作类型——description 是 LLM router 唯一能看到的摘要。

**原则 3**：有语义重叠的 skill，两边 description 都要显式划边界。在 Flowmax 业务里，"run" 专指 x402 付费执行（`flowmax_runs`），"跑 research agent"是创建/部署（`flowmax_agents`）。

**新建 skill 检查清单**（每次都跑）：
- [ ] description 无 "login"、"sign in"、"access token"、"authenticate" 等字样
- [ ] body 每类 API 调用在 description 里有对应关键词
- [ ] 有语义重叠的 skill，description 都显式划清边界
- [ ] `evals/trigger/<new_skill>.json` 有 10 正 + 10 负共 20 条测试
- [ ] `evals/routing/routing_eval.json` 里有至少 2 条正例

## 安装 Skills

正式安装走 marketplace：

```
/plugin marketplace add FlowmaxAITrade/flowmax-skills
/plugin install flowmax-skills
```

完整名 `flowmax-skills@flowmax-skills`（`插件名@marketplace名`，更新/卸载用完整名）。

本地调试可用 symlink：

```bash
mkdir -p ~/.claude/skills
ln -sfn "$(pwd)/skills/flowmax_credits"      ~/.claude/skills/flowmax_credits
ln -sfn "$(pwd)/skills/flowmax_agents"       ~/.claude/skills/flowmax_agents
ln -sfn "$(pwd)/skills/flowmax_pm_agent"     ~/.claude/skills/flowmax_pm_agent
ln -sfn "$(pwd)/skills/flowmax_runs"         ~/.claude/skills/flowmax_runs
ln -sfn "$(pwd)/skills/flowmax_logs"         ~/.claude/skills/flowmax_logs
ln -sfn "$(pwd)/skills/flowmax_leaderboard"  ~/.claude/skills/flowmax_leaderboard
ln -sfn "$(pwd)/skills/flowmax_marketplace"  ~/.claude/skills/flowmax_marketplace
ln -sfn "$(pwd)/skills/flowmax_callout"      ~/.claude/skills/flowmax_callout
ln -sfn "$(pwd)/skills/flowmax_follows"      ~/.claude/skills/flowmax_follows
```

安装后验证 API key 是否可用：

```bash
BASE="${FLOWMAX_API_BASE_URL%/}"
curl -sS --fail-with-body \
  -H "Authorization: Bearer $FLOWMAX_API_KEY" \
  -H "Content-Type: application/json" \
  "$BASE/api/v1/credits/balance"
```
