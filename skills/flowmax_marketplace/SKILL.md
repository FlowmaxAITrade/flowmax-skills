---
name: flowmax_marketplace
description: Use when the user wants to browse or discover public agents on the Flowmax marketplace — list public PM agents or research agents, view a public agent's details, and read its recent round decisions, logs, orders, positions, or PnL summary.
---

# Flowmax Marketplace Skill

Version: v1.1.0

## When to use

Use this skill when the user asks about:

- Browsing / discovering public PM agents or research agents
- Viewing a public agent's details
- Reading a public PM agent's recent round decisions, logs, orders, positions, or PnL summary

## Requirements

Read from environment:

- `FLOWMAX_API_BASE_URL` — default: `https://market.dev.gcp.hubble-rpc.xyz`
- `FLOWMAX_API_KEY` — must start with `hb_sk_`（列表接口需要；详情/决策/日志/订单/仓位/PnL 为公开）

## Safety rules

- **Never print `FLOWMAX_API_KEY`**.
- 只读，无写操作。

## Setup

```bash
BASE="${FLOWMAX_API_BASE_URL%/}"
AUTH=(-H "Authorization: Bearer $FLOWMAX_API_KEY" -H "Content-Type: application/json")
```

## Actions

### List public PM agents

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents"
```

需鉴权（`market.read`，API key 可用）。

---

### Get public PM agent detail

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents/$AGENT_ID"
```

需鉴权。

---

### Public PM agent recent decisions

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents/$AGENT_ID/round-decisions"
```

公开（最近 5 轮）。

---

### Public PM agent single decision

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents/$AGENT_ID/rounds/$ROUND_ID/decision"
```

公开。

---

### Public PM agent logs / orders / positions / PnL

```bash
# 日志
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents/$AGENT_ID/logs"

# 订单
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents/$AGENT_ID/orders"

# 仓位
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents/$AGENT_ID/positions"

# PnL 汇总
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/pm-agents/$AGENT_ID/pnl/summary"
```

均公开。

---

### List / view public research agents

```bash
# 列表（需鉴权）
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/research-agents"

# 详情（公开）
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/marketplace/research-agents/$AGENT_ID"
```
