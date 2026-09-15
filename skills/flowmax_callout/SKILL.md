---
name: flowmax_callout
description: Use when the user asks about the Flowmax callout square (喊单广场) — subscribing to the real-time stream of trade open/close, position adjustments, and analyst predictions.
---

# Flowmax Callout Skill

Version: v1.0.0

## When to use

Use this skill when the user asks about:

- The callout square (喊单广场) real-time event stream
- Following trader open/close/position-adjust events
- Following analyst prediction events

## Requirements

Read from environment:

- `FLOWMAX_API_BASE_URL` — default: `https://market.dev.gcp.hubble-rpc.xyz`
- `FLOWMAX_API_KEY` — optional（公开接口）

## Safety rules

- 纯只读 SSE 流，无写操作。

## Setup

```bash
BASE="${FLOWMAX_API_BASE_URL%/}"
```

## Action

### Subscribe to callout stream (SSE)

```bash
curl -sS -N \
  "$BASE/api/v1/callout/stream?category=trades,analysts"
```

Query params:

- `category`: `trades` / `analysts`，逗号分隔
- `Last-Event-ID` header：断线续传
- 用 `afterTimestamp`（`afterSeq` 已弃用）

事件 kind：`trade_open` / `trade_close` / `position_adjust` / `research_prediction`。
