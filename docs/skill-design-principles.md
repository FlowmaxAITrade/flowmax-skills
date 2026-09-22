# flowmax-skills 设计原则

本文件记录 flowmax-skills 仓库在设计新 skill 或修改现有 skill 时必须遵守的原则。每条原则都对应一次实际踩坑，写下来是为了**不再踩第二次**。

---

## 原则 1：skill 以 API key 鉴权，不应包含任何 auth / 登录 / API key 管理类接口

### 背景

`skills/` 里曾经有一个 `flowmax_auth` skill，覆盖了：

- 邮箱验证码发送 (`POST /auth/email-code/send`)
- 邮箱验证码登录 (`POST /auth/email-code/verify`)
- 钱包签名挑战 (`POST /auth/challenge`)
- 钱包签名登录 (`POST /auth/login`)
- 当前用户信息 (`GET /auth/me`)

静态审查时我们把"openclaw 缺 flowmax_auth"当成 P0 遗漏，要求补齐。**这个判断是错的**。

### 为什么错

所有 flowmax-skills 的运行前提是：

- `FLOWMAX_API_KEY` (`hb_sk_...`) 已经在环境变量里
- skill 调 API 时统一用 `Authorization: Bearer $FLOWMAX_API_KEY`

API key 是用户在 Flowmax Market 网页上登录之后生成的长期凭证，**skill 永远不需要也不应该参与"怎么拿到 key"这一步**。把 auth skill 放进来会导致：

1. **功能不可达**：用户说"帮我用邮箱验证码登录 Flowmax"，skill 即使触发了也拿不到用户邮箱 / 验证码 / 交互通道，根本完不成登录。结果就是 skill 返回一个"请你去网页上登录"——那为什么还要这个 skill？
2. **路由噪音**：router 看到用户说"登录"就去触发 auth skill，挤占了正确的"回答：你得先去网页上登录 → 拿 `hb_sk_` → 导出到环境变量"这条指引。用户体验反而更差。
3. **安全误导**：auth 接口返回 JWT access token，跟 API key 是两套东西。放在 skill 里会让用户误以为"skill 拿到 token 就能用了"，其实 skill 的其它接口根本不吃 JWT，只吃 `hb_sk_` API key。

### 原则陈述

> **Skill 只做 post-auth 的业务调用。"怎么拿到可用的 API key" 属于用户在 Flowmax Market 网页或 CLI 的 onboarding 流程，绝不进入 skill。**

### 允许的例外

- **profile 查询**（例如 `GET /auth/me` 用 `Bearer $FLOWMAX_API_KEY` 调，查当前 key 绑定的账号信息）：这是 *post-auth* 的只读查询，严格意义上跟"登录"无关。如果业务上需要，**独立成 `flowmax_profile` 或并入已有 skill**，不要放进以 "auth" 命名的 skill 里。命名很重要——名字里带 auth 会诱导 router 和用户对号入座。

### 执行

- 不要新增 `flowmax_auth` / `flowmax_login` / `flowmax_api_key` / `flowmax_token` 这类 skill。
- Review 任何 skill 的 description 时，如果看到 "login"、"sign in"、"access token"、"login with email"、"wallet signature" 这些关键词，直接驳回。
- CI 层面：`evals/routing/routing_eval.json` 不应有 `expected` 指向 auth 类 skill 的用例。如果用户 query 是"帮我登录"，正确的 expected 是 `null`（没有合适 skill，走通用回答）。

---

## 原则 2：一个 skill 的 description 必须覆盖 skill body 里的所有操作

### 背景

`flowmax_agents` description 原来写 "list, view, create, update, or delete agents"，但 skill body 里实际支持：

- 查询部署 job 状态 (`GET /agents/user-research/jobs/{job_id}`)
- 版本历史 / 详情 / 回滚
- 数据源 / indicator 模板列表

用户说"查 research agent 的部署 job 状态"时，routing eval 曾把它分到现已移除的旧执行 skill（因为其 description 有 "status"），而正确应该是 `flowmax_agents`。

### 原则陈述

> **description 是 LLM router 唯一能看到的摘要。body 能做的操作如果 description 没提，等于不存在——用户永远触发不到。**

### 执行

- 写 description 时把 skill body 的每一类操作都扫一遍，每类至少一个关键词进 description。
- Review 任何 skill 改动时，确认 diff 里 body 新加的接口，description 里有对应的词。
- CI 层面：routing eval 如果某个用例稳定路由到错的 skill，先看 description 覆盖是否完整，再考虑改描述的风格/写法。

---

## 原则 3：跨 skill 有语义重叠时，两边 description 都要显式划边界

### 原则陈述

> **description 应说明当前业务语义和操作范围，避免宽泛动词造成路由歧义。**

### 执行

- “跑个新的 research agent”属于创建/部署，应路由到 `flowmax_agents`；description 保留 create / deploy 和部署状态等关键词。
- 已移除的付费执行流程不属于当前 skills 的能力，旧 run 状态和列表请求在 routing eval 中应返回 `null`。
- Review 任何路由失败时，先检查相关 skill 的 description 是否清楚表达各自的操作范围。

---

## 附：原则检查清单（新建 / 修改 skill 时跑一遍）

- [ ] description 里没有出现 "login"、"sign in"、"access token"、"authenticate"、"API key 管理" 等字样
- [ ] SKILL.md body 里每一类 API 调用，description 都有对应的关键词
- [ ] 有语义重叠的 skill，description 都显式划清边界
- [ ] 新加的 skill 在 `evals/trigger/` 下有 20 条测试
- [ ] 新加的 skill 在 `evals/routing/routing_eval.json` 里至少有 2 条正例
- [ ] CI workflow 在本次改动范围内（`*/skills/**/SKILL.md` 或 `evals/**`）
