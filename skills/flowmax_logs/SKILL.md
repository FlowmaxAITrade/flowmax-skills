---
name: flowmax_logs
description: Use when the user asks about PM agent logs, research logs, orders, positions, order history, position recovery, PnL data, or account equity from the Flowmax Market API.
---

# Flowmax Logs Skill

Version: v1.0.0

## When to use

Use this skill when the user asks about:

- PM logs (decision logs)
- Research logs
- Orders (list, single, history)
- Positions / PM positions
- Position recovery logs
- PnL summary and PnL order details
- Account equity snapshots

## Requirements

Read from environment:

- `FLOWMAX_API_BASE_URL` — default: `https://market.dev.gcp.hubble-rpc.xyz`
- `FLOWMAX_API_KEY` — must start with `hb_sk_`

## Safety rules

- **Never print `FLOWMAX_API_KEY`**.
- Always set `page_size` explicitly (default 100, max 200 unless user insists).
- Prefer narrow time windows — ask user for `start`/`end` if not provided.

## Setup

```bash
BASE="${FLOWMAX_API_BASE_URL%/}"
AUTH=(-H "Authorization: Bearer $FLOWMAX_API_KEY" -H "Content-Type: application/json")
```

---

## Common query params

Most endpoints support: `start`, `end` (RFC3339 or unix ms), `pm_id`, `round_id`, `token`, `page`, `page_size`.

**重要**：绝大多数查询接口**至少要求 `pm_id` 或 `round_id` 其中之一**（防止无界扫描）。用户只说"最近的日志"却没给 PM 或轮次时，先问清楚 `pm_id` / `round_id`，再发起请求。

---

## Actions

### PM logs

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/pm/logs?pm_id=$PM_ID&page=1&page_size=100"
```

必填：`pm_id` 或 `round_id` 至少一个。可选：`level`（`info` / `warn` / `error`）。

---

### Research logs

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/research/logs?pm_id=$PM_ID&page=1&page_size=100"
```

必填：`pm_id` 或 `round_id` 至少一个。可选：`level`（`info` / `warn` / `error`）。

---

### Orders (list)

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/orders?pm_id=$PM_ID&page=1&page_size=100"
```

必填：`pm_id` 或 `round_id` 至少一个。可选：`status`, `event_type`。

---

### Order (single)

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/orders/$ORDER_ID"
```

---

### Order history

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/order/history?pm_id=$PM_ID&page=1&page_size=100"
```

必填：`order_id` / `position_id` / `pm_id` / `round_id` 至少一个。可选：`symbol`, `status`, `action_type`。

---

### Positions

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/positions?pm_id=$PM_ID&page=1&page_size=100"
```

必填：`pm_id` 或 `round_id` 至少一个。可选：`status`, `event_type`。

---

### PM positions

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/pm/$PM_ID/positions?page=1&page_size=100"
```

路径 `pm_id` 必填。可选：`status`（`open` / `closed`）, `event_type`。

---

### PM position symbols

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/pm/$PM_ID/positions/symbols?page=1&page_size=100"
```

路径 `pm_id` 必填。可选：`status`（e.g. `open` / `closed`）。

---

### Position logs

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/position/logs?pm_id=$PM_ID&position_id=$POSITION_ID&page=1&page_size=100"
```

`pm_id` 和 `position_id` **两者都必填**。

---

### Position recovery

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/position/recovery?pm_id=$PM_ID&page=1&page_size=100"
```

必填：`pm_id` 或 `round_id` 至少一个。可选：`token`。

---

### PnL summary

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/pnl/summary?pm_id=$PM_ID&page=1&page_size=100&bucket=day"
```

必填：`pm_id` 或 `round_id` 至少一个。可选：`symbol`, `position_id`, `action_types`（逗号分隔，默认 `close,decrease`）, `bucket`（`hour` / `day`）。

---

### PnL orders

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/pnl/orders?pm_id=$PM_ID&page=1&page_size=100"
```

必填：`pm_id` 或 `round_id` 至少一个。可选：`symbol`, `position_id`, `action_types`。

---

### Account equity

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/agent-logs/account-equity?pm_id=$PM_ID&page=1&page_size=100"
```

`pm_id` 必填。仅该 PM 的 owner 可查。可选：`type`, `start`, `end`。
