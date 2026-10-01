#!/usr/bin/env bash
# hooks/pipeline-reminder.sh 자체 검사.
# 매 턴 돌고 매 턴 토큰을 내므로 JSON 유효성과 크기를 둘 다 본다.
H="$(cd "$(dirname "$0")/../hooks" && pwd)/pipeline-reminder.sh"
LIMIT=400
fail=0
r(){ printf '  %-40s %s\n' "$1" "$2"; }
out=$(bash "$H" 2>/dev/null) || { r "실행" "FAIL"; exit 1; }

# 1) 필수 키 — jq 없이 문자열로 본다
for k in '"hookEventName":"UserPromptSubmit"' '"additionalContext":"'; do
  case "$out" in
    *"$k"*) r "키 있음" OK ;;
    *) r "키 $k" "FAIL 없음"; fail=1 ;;
  esac
done

# 2) 7 단계가 전부 — 하나라도 빠지면 파이프라인이 반쪽이다
miss=0
for s in Intake Context Planning Execution Validation Documentation Reporting; do
  case "$out" in *"$s"*) ;; *) r "단계 $s" "FAIL 없음"; miss=1; fail=1 ;; esac
done
[ "$miss" -eq 0 ] && r "7 단계 전부 포함" OK

# 3) 크기 상한 — 매 턴 내는 비용이다. 늘리려면 이 상한을 먼저 고친다
n=$(printf '%s' "$out" | wc -c | tr -d ' ')
if [ "$n" -le "$LIMIT" ]; then r "크기 ${n}B (상한 ${LIMIT}B)" OK
else r "크기 ${n}B" "FAIL ${LIMIT}B 초과"; fail=1; fi

# 4) 한 줄이어야 한다 — 여러 줄이면 JSON 파싱이 깨진다
if [ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 1 ]; then r "한 줄 JSON" OK
else r "한 줄 JSON" "FAIL 여러 줄"; fail=1; fi

exit "$fail"
