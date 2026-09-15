---
name: flowmax_leaderboard
description: Use when the user asks about Flowmax leaderboards — top fund managers (PM) ranked by PnL, win rate, or followers, the period champion, top analysts ranked by accuracy, or the real-time leaderboard stream. Read-only, no write actions.
---

# Flowmax Leaderboard Skill

Version: v1.0.0

## When to use

Use this skill when the user asks about:

- PM / fund-manager rankings
- The period champion (fund-manager champion)
- Analyst rankings
- The real-time leaderboard stream

## Requirements

Read from environment:

- `FLOWMAX_API_BASE_URL` — default: `https://market.dev.gcp.hubble-rpc.xyz`
- `FLOWMAX_API_KEY` — optional（公开接口；带上 key 会附加 `is_followed` 字段）

## Safety rules

- 纯只读，无写操作。

## Setup

```bash
BASE="${FLOWMAX_API_BASE_URL%/}"
AUTH=(-H "Authorization: Bearer $FLOWMAX_API_KEY")
```

## Actions

### Fund manager (PM) ranking

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/leaderboard/fund-manager?sort_by=pnl&period=7d&page=1&page_size=20"
```

Query params:

- `sort_by`: `pnl` / `win_rate` / `last_active` / `followers`
- `period`: `7d` / `30d` / `all`
- `asset_type`: `crypto` / `stock` / 空
- `page`, `page_size`

---

### Fund manager champion

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/leaderboard/fund-manager/champion?asset_type=crypto&period=7d"
```

`asset_type` 必填；`period` 可选。

---

### Analyst ranking

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/leaderboard/analyst?sort_by=accuracy&period=7d&page=1&page_size=20"
```

Query params:

- `sort_by`: `accuracy` / `last_active` / `followers`
- `period`: `7d` / `30d` / `all`
- `asset_type`, `symbol`, `q`（搜索）
- `page`, `page_size`

---

### Real-time stream (SSE)

```bash
curl -sS -N "${AUTH[@]}" \
  "$BASE/api/v1/leaderboard/stream"
```

SSE 流。用 `Last-Event-ID` header 做断线续传。用 `afterTimestamp`（`afterSeq` 已弃用）。
