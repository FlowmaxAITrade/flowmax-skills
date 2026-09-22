---
name: flowmax_follows
description: Use when the user asks to follow or unfollow an agent, or list the agents they currently follow on Flowmax.
---

# Flowmax Follows Skill

Version: v1.1.0

## When to use

Use this skill when the user asks about:

- Following an agent
- Unfollowing an agent
- Listing followed agents

## Requirements

Read from environment:

- `FLOWMAX_API_BASE_URL` — default: `https://market.dev.gcp.hubble-rpc.xyz`
- `FLOWMAX_API_KEY` — must start with `hb_sk_`

## Safety rules

- **Never print `FLOWMAX_API_KEY`**.
- 写操作（follow/unfollow）前总结动作并等用户确认。

## Setup

```bash
BASE="${FLOWMAX_API_BASE_URL%/}"
AUTH=(-H "Authorization: Bearer $FLOWMAX_API_KEY" -H "Content-Type: application/json")
```

## Actions

### List followed agents

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  "$BASE/api/v1/follows"
```

---

### Follow an agent — requires confirmation

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  -X POST \
  "$BASE/api/v1/follows" \
  -d '{"agent_id": "<uuid>"}'
```

幂等：重复关注同一个 agent 不报错。

---

### Unfollow an agent — requires confirmation

```bash
curl -sS --fail-with-body "${AUTH[@]}" \
  -X DELETE \
  "$BASE/api/v1/follows/$AGENT_ID"
```
