---
name: flowmax_credits
description: Use when the user asks about Flowmax credits balance, transaction history, deposit records, listing recharge packages (tiers, optional bonus_percent for UI copy), creating a raw-credits deposit, or creating a deposit by package slug (by-package) via the Flowmax Market API.
---

# Flowmax Credits Skill

Version: v1.0.1

## When to use

Use this skill when the user asks about:

- Current credits balance
- Credits transactions history
- Deposits records
- Creating a recharge (deposit) order (raw `credits` amount **or** by selecting a package)
- Listing available recharge packages
- Creating a deposit by selecting a package (`package_id` / slug from the packages list)

## Requirements

Read from environment (never ask user to paste keys):

- `FLOWMAX_API_BASE_URL` — default: `https://market.dev.gcp.hubble-rpc.xyz`
- `FLOWMAX_API_KEY` — must start with `hb_sk_`

## Safety rules

- **Never print `FLOWMAX_API_KEY`** in any response or tool output.
- Use the Bash tool with `curl` only.
- Always pass `--fail-with-body`; surface non-2xx bodies to the user verbatim.
- For write actions (`POST`), summarize the request and wait for explicit user confirmation before calling the API.

## Setup (one-liner for Bash tool)

```bash
BASE="${FLOWMAX_API_BASE_URL%/}"
```

## Package semantics (important)

- `GET /credits/packages` returns **`credits` as the total amount credited on a successful paid deposit** for that tier (not a "base" before a bonus).
- `bonus_percent` (if present) is **marketing / UI only**; it does **not** change the API math—do not multiply `credits` by the bonus. Omit from field list when missing.
- 金额类字段（`credits` / `amount` / `balance` / `amount_usd`）在响应中是**字符串**（decimal），不是 number。

## Actions

### Get credits balance

```bash
curl -sS --fail-with-body \
  -H "Authorization: Bearer $FLOWMAX_API_KEY" \
  -H "Content-Type: application/json" \
  "$BASE/api/v1/credits/balance"
```

Response fields: `user_id`, `balance` (string), `available` (bool), `buckets` (数组，每项含 `remaining`/`expires_at`)，可选 `expiring_soon`。

> 用户由网关从 API key 解析，无需在请求里传 `user_id`。

---

### List credits transactions

```bash
curl -sS --fail-with-body \
  -H "Authorization: Bearer $FLOWMAX_API_KEY" \
  -H "Content-Type: application/json" \
  "$BASE/api/v1/credits/transactions?limit=50&offset=0"
```

Query params: `limit` (default 50, max 200), `offset` (default 0).

Response 为 `{"items": [...]}`。每条字段：`tx_id`, `user_id`, `tx_type` (e.g. `DEPOSIT`/`CONSUME`), `amount` (string), `balance_after`, `idempotency_key`, `source`, `remark`, `created_at`。

---

### List deposits

```bash
curl -sS --fail-with-body \
  -H "Authorization: Bearer $FLOWMAX_API_KEY" \
  -H "Content-Type: application/json" \
  "$BASE/api/v1/credits/deposits?limit=50&offset=0"
```

Query params: `limit` (default 50, max 200), `offset` (default 0).

Response 为 `{"items": [...]}`。每条字段：`deposit_id`, `user_id`, `credits` (string), `amount_usd`, `currency`, `client_reference`, `status` (e.g. `PENDING`/`PAID`/`EXPIRED`), `infini_order_id`, `checkout_url`, `paid_at`, `created_at`。

---

### Create deposit (recharge) — requires confirmation

Ask user for the number of credits to recharge, then confirm before calling:

```bash
curl -sS --fail-with-body \
  -H "Authorization: Bearer $FLOWMAX_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  "$BASE/api/v1/credits/deposits" \
  -d '{"credits": "<decimal string>"}'
```

Response fields: `deposit_id`, `client_reference`, `credits`, `amount_usd`, `currency`, `infini_order_id`, `checkout_url` (redirect to Infini checkout page).

When you get the `checkout_url`, please print it in full on a new line, like this:
Checkout URL: <full_url>

---

### List recharge packages

列出平台提供的充值套餐，供用户选择后按套餐充值。

```bash
curl -sS --fail-with-body \
  -H "Authorization: Bearer $FLOWMAX_API_KEY" \
  -H "Content-Type: application/json" \
  "$BASE/api/v1/credits/packages"
```

Response 为 `{"items": [...]}`。每条字段：`package_id`（套餐 slug，传给按套餐充值接口）、`credits`（**到账总数**，string，见上文 Package semantics）、`amount_usd`、`currency`、`label`（展示名，如 `"Starter"`）、`is_default`、`sort_order`、`bonus_percent`（可选，仅文案/展示，可能省略）。

---

### Create deposit by package — requires confirmation

先调 `GET /credits/packages` 列出可用套餐，让用户选择后再执行。确认时展示：套餐名（`label`）、`credits`、`amount_usd`；如有 `bonus_percent` 可一并说明为营销标注，**不要**在 `credits` 上再乘比例。

```bash
curl -sS --fail-with-body \
  -H "Authorization: Bearer $FLOWMAX_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  "$BASE/api/v1/credits/deposits/by-package" \
  -d '{"package_id": "<package_slug>"}'
```

Response fields 与 `POST /deposits` 相同。其中 `credits` 与所选套餐一致（已含该档总积分，**不因** `bonus_percent` 再变）。

When you get the `checkout_url`, please print it in full on a new line, like this:
Checkout URL: <full_url>
