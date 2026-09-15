# flowmax-skills evals

自动化 eval 套件。每次改 skill 描述都可以一键回归，避免"改了描述哪边悄悄漏触发"。

## 目录结构

```
evals/
├── trigger/                        # 每个 skill 单独的 should_trigger 测试集
│   ├── flowmax_credits.json        # 20 条: 10 should-trigger + 10 near-miss
│   ├── flowmax_agents.json
│   ├── flowmax_pm_agent.json
│   ├── flowmax_runs.json
│   ├── flowmax_logs.json
│   ├── flowmax_leaderboard.json
│   ├── flowmax_marketplace.json
│   ├── flowmax_callout.json
│   ├── flowmax_follows.json
│   └── run_trigger_eval.py         # runner: 针对单个 skill 跑 should_trigger 评测
├── routing/                        # 跨 skill 路由 eval（给所有 skill，挑一个）
│   ├── routing_eval.json           # 正例 / 歧义 / 负例（含 5 条 auth_neg guardrail）
│   └── run_routing_eval.py         # runner: 整组跑路由评测
├── results/                        # 本地结果（.gitignore 掉）
└── run_all.sh                      # 一键入口
```

> auth 类 skill 已移除，原因见 `docs/skill-design-principles.md` → 原则 1：skill 用 API key 鉴权，不应包含任何 auth / 登录 / API key 管理类接口。routing eval 里 `auth_neg_*`（expected=null）作为回归 guardrail，确保不会有 skill 错触发在登录 query 上。

`.github/workflows/skills-eval.yml` 在每次 PR 改到 `skills/**/SKILL.md` 或 `evals/**` 时自动跑，并在 PR 上贴结果评论。

## 前置

runner 走 `evals/_llm.py` 做后端自适应，**两种模式任挑一种**：

1. **本地 / Pro · Max 订阅用户（推荐）**：只要先用 `claude` 登过一次（auth 存 macOS Keychain / Linux `~/.claude/.credentials.json`），`bash evals/run_all.sh` 即可开跑，**不需要 API key**。runner 会 shell 出 `claude -p`，并以空临时目录作为 cwd 防止项目本地 `.claude/` 干扰。
2. **CI / 有 API key**：export `ANTHROPIC_API_KEY=sk-ant-...`，runner 会自动切到 urllib 直调 Anthropic Messages API 的路径（更快，支持 assistant-prefill 强制 JSON 输出）。

共同需要的只有 Python 3.9+。两边都是 stdlib，零 pip 依赖。

## 本地运行

```bash
# 模式 1：Pro / Max 订阅（已 `claude` 登录），不用 API key
bash evals/run_all.sh

# 模式 2：有 API key（CI 同路径）
export ANTHROPIC_API_KEY=sk-ant-...

# 全部：trigger + routing
bash evals/run_all.sh

# 只跑某一类
bash evals/run_all.sh trigger        # 只跑 per-skill trigger eval
bash evals/run_all.sh routing        # 只跑跨 skill routing eval

# Debug：每个 eval 只跑前 N 条
FLOWMAX_EVAL_LIMIT=3 bash evals/run_all.sh

# 换模型
FLOWMAX_EVAL_MODEL=claude-sonnet-5 bash evals/run_all.sh routing
```

CLI 模式下每次调用会起一个 `claude -p` 子进程，开销比 API 模式大。runner 会把 `--workers` 自动 clamp 到 4；全量跑（9 个 skill × 20 条 trigger + 约 60 条 routing）预期在 5–15 分钟，取决于网络和模型。
