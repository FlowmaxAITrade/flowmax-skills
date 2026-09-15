#!/usr/bin/env bash
# flowmax-skills 端到端自检脚本（只调用只读接口，绝不触发付费/写操作）
#
# 用法：
#   export FLOWMAX_API_BASE_URL="https://market.dev.gcp.hubble-rpc.xyz"
#   export FLOWMAX_API_KEY="hb_sk_...你的 key..."
#   # 可选：想自检 logs 接口时设置 PM_ID
#   export PM_ID="<你的 pm_id>"
#   bash docs/skills-selfcheck.sh
#
# 输出：每个接口一行 HTTP 状态 + 简短响应片段。完整响应存到 /tmp/flowmax-selfcheck/*.json。

set -u

: "${FLOWMAX_API_BASE_URL:?FLOWMAX_API_BASE_URL is required}"
: "${FLOWMAX_API_KEY:?FLOWMAX_API_KEY is required}"

case "$FLOWMAX_API_KEY" in
  hb_sk_*) ;;
  *) echo "FLOWMAX_API_KEY must start with hb_sk_"; exit 2 ;;
esac

BASE="${FLOWMAX_API_BASE_URL%/}"
OUT="/tmp/flowmax-selfcheck"
mkdir -p "$OUT"

pass=0
fail=0

check() {
  local name="$1"; shift
  local url="$1"; shift
  local out_file="$OUT/$(echo "$name" | tr ' /' '__').json"
  local http
  http=$(curl -sS -o "$out_file" -w "%{http_code}" \
    -H "Authorization: Bearer $FLOWMAX_API_KEY" \
    -H "Content-Type: application/json" \
    "$url" 2>/dev/null || echo "000")
  if [[ "$http" =~ ^2 ]]; then
    pass=$((pass+1))
    printf "  \033[32m✓\033[0m %-40s HTTP %s  (bytes: %s)\n" \
      "$name" "$http" "$(wc -c < "$out_file")"
  else
    fail=$((fail+1))
    printf "  \033[31m✗\033[0m %-40s HTTP %s  body: %s\n" \
      "$name" "$http" "$(head -c 200 "$out_file" | tr -d '\n')"
  fi
}

echo
echo "== flowmax_credits =="
check "credits: balance"       "$BASE/api/v1/credits/balance"
check "credits: transactions"  "$BASE/api/v1/credits/transactions?limit=5&offset=0"
check "credits: deposits"      "$BASE/api/v1/credits/deposits?limit=5&offset=0"
check "credits: packages"      "$BASE/api/v1/credits/packages"

echo
echo "== flowmax_agents =="
check "agents: list PM"        "$BASE/api/v1/agents/pm?limit=5&offset=0"
check "agents: list UR"        "$BASE/api/v1/agents/user-research?page=1&page_size=5"
check "agents: data-sources"   "$BASE/api/v1/agents/user-research/data-sources"
check "config: indicator-tpls" "$BASE/api/v1/config/indicator-templates"

echo
echo "== flowmax_leaderboard (公开) =="
check "leaderboard: fund-manager" "$BASE/api/v1/leaderboard/fund-manager?page=1&page_size=5"

echo
echo "== flowmax_marketplace =="
check "marketplace: pm-agents" "$BASE/api/v1/marketplace/pm-agents"

echo
echo "== flowmax_follows =="
check "follows: list"          "$BASE/api/v1/follows"

if [[ -n "${PM_ID:-}" ]]; then
  echo
  echo "== flowmax_logs (需 PM_ID) =="
  check "logs: pnl summary"      "$BASE/api/v1/agent-logs/pnl/summary?pm_id=$PM_ID&page=1&page_size=5&bucket=day"
  check "logs: pm positions"     "$BASE/api/v1/agent-logs/pm/$PM_ID/positions?page=1&page_size=5"
else
  echo
  echo "== flowmax_logs =="
  echo "  [skip] PM_ID 未设置，跳过 logs 接口（需 pm_id）。"
fi

echo
echo "== summary =="
echo "  pass: $pass"
echo "  fail: $fail"
echo "  raw:  $OUT"
echo

if [[ $fail -gt 0 ]]; then
  exit 1
fi
