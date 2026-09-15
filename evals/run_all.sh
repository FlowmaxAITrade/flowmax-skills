#!/usr/bin/env bash
# flowmax-skills 一键 eval 入口。
#
# 顺序跑：
#   1) per-skill trigger eval (每个 skill 单独打 should_trigger 分)
#   2) 跨 skill routing eval
#
# 用法：
#   bash evals/run_all.sh                  # 全部
#   bash evals/run_all.sh trigger          # 仅 trigger
#   bash evals/run_all.sh routing          # 仅 routing
#
# 后端自动选择（见 evals/_llm.py）：
#   - 设置了 ANTHROPIC_API_KEY   → 走 urllib 直调 API（快、支持 prefill）
#   - 未设置                     → 走 `claude -p`，以空临时目录作为 cwd 防止项目本地 .claude/ 干扰
#
# 本地使用 Pro / Max 订阅：只要先 `claude` 登过就不需要 API key。
# CI：设置 ANTHROPIC_API_KEY secret。
#
# 可选环境变量：
#   FLOWMAX_EVAL_MODEL=claude-sonnet-5   # 被测 router/trigger 模型
#   FLOWMAX_EVAL_WORKERS=6               # 并发 worker 数量（CLI 模式下会被 clamp 到 4）
#   FLOWMAX_EVAL_LIMIT=0                 # >0 时每个 eval 只跑前 N 条（debug 用）

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="${1:-all}"
SKILLS_ROOT="skills"
VARIANT="flowmax"

# Preflight: make sure at least one backend is reachable.
if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  if ! command -v claude >/dev/null 2>&1; then
    cat <<'EOF' >&2
[err] No eval backend available.
      Options (pick one):
        a) Install Claude Code and run `claude` once to log in (Pro/Max auth), then rerun.
           https://claude.com/code
        b) export ANTHROPIC_API_KEY=sk-ant-... to use the direct API path.
EOF
    exit 2
  fi
  echo "[info] ANTHROPIC_API_KEY not set → will use \`claude -p\` (cwd isolated)."
else
  echo "[info] ANTHROPIC_API_KEY set → will use direct API via urllib."
fi

MODEL="${FLOWMAX_EVAL_MODEL:-claude-sonnet-5}"
WORKERS="${FLOWMAX_EVAL_WORKERS:-6}"
LIMIT="${FLOWMAX_EVAL_LIMIT:-0}"

mkdir -p evals/results

extra_args=()
if [[ "$LIMIT" != "0" ]]; then
  extra_args+=(--limit "$LIMIT")
fi

run_trigger() {
  for skill_dir in "$SKILLS_ROOT"/*/; do
    skill_dir="${skill_dir%/}"
    skill_name="$(basename "$skill_dir")"
    eval_file="evals/trigger/${skill_name}.json"
    if [[ ! -f "$eval_file" ]]; then
      echo "[skip] no trigger eval for $skill_name"
      continue
    fi
    out="evals/results/trigger-${skill_name}.json"
    echo
    echo "==> trigger  skill=$skill_name  model=$MODEL"
    python3 evals/trigger/run_trigger_eval.py \
      --skill "$skill_dir" \
      --eval "$eval_file" \
      --variant "$VARIANT" \
      --out "$out" \
      --workers "$WORKERS" \
      --model "$MODEL" \
      "${extra_args[@]}" || echo "[warn] non-zero exit; see $out"
  done
}

run_routing() {
  out="evals/results/routing-flowmax.json"
  echo
  echo "==> routing  model=$MODEL"
  python3 evals/routing/run_routing_eval.py \
    --skills-root "$SKILLS_ROOT" \
    --variant "$VARIANT" \
    --eval evals/routing/routing_eval.json \
    --out "$out" \
    --workers "$WORKERS" \
    --model "$MODEL" \
    "${extra_args[@]}" || echo "[warn] non-zero exit; see $out"
}

aggregate() {
  python3 - <<'PY'
import json, pathlib
res = pathlib.Path("evals/results")
rows = []
for p in sorted(res.glob("trigger-*.json")):
    j = json.loads(p.read_text())
    m = j.get("metrics", {})
    if m.get("total", 0) == 0:
        continue  # skip tombstone / empty results
    rows.append(("trigger", j.get("variant",""), j["skill"]["name"], m["accuracy"], m["precision"], m["recall"], m["f1"], m["errors"]))
for p in sorted(res.glob("routing-*.json")):
    j = json.loads(p.read_text())
    s = j.get("summary", {})
    rows.append(("routing", j.get("variant",""), "-", s.get("pass_rate", 0.0), None, None, None, 0))

print()
print("============================== SUMMARY ==============================")
print(f"{'kind':<8} {'skill':<20} {'acc/rate':>10}  {'P':>6} {'R':>6} {'F1':>6}  {'err':>4}")
for kind, variant, skill, acc, P, R, F1, err in rows:
    acc_s = f"{acc*100:>6.1f}%" if acc is not None else "-"
    P_s = f"{P*100:>5.1f}%" if P is not None else "-"
    R_s = f"{R*100:>5.1f}%" if R is not None else "-"
    F1_s = f"{F1*100:>5.1f}%" if F1 is not None else "-"
    print(f"{kind:<8} {skill:<20} {acc_s:>10}  {P_s:>6} {R_s:>6} {F1_s:>6}  {err:>4}")
print("=====================================================================")
PY
}

case "$MODE" in
  all)
    run_trigger
    run_routing
    aggregate
    ;;
  trigger)
    run_trigger
    aggregate
    ;;
  routing)
    run_routing
    aggregate
    ;;
  *)
    echo "usage: $0 [all|trigger|routing]"
    exit 2
    ;;
esac
