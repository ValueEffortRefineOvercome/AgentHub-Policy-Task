#!/usr/bin/env bash
# 여러 PC 에서 같은 결과를 내려면 도구가 같은 기능을 가져야 한다.
# 버전 숫자보다 기능을 확인한다 — 벤더 빌드·패치 번호에서 숫자는 믿기 어렵다.
# 새 PC 를 세팅하면 이것부터 돌린다.
fail=0
r(){ printf '  %-30s %s\n' "$1" "$2"; }

# git — switch(2.23) / branch --show-current(2.22) / submodule set-url(2.25) 를 쓴다
gv=$(git --version 2>/dev/null | sed -n 's/.* \([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')
if [ -n "$gv" ] && [ "$(printf '%s\n2.25\n' "$gv" | sort -V | head -1)" = "2.25" ]; then
  r "git $gv" "OK"
else
  r "git ${gv:-없음}" "FAIL 2.25 이상 필요"; fail=1
fi

# bash — herestring·case 를 쓴다. 3.2 면 충분
if [ "${BASH_VERSINFO[0]:-0}" -ge 3 ]; then r "bash ${BASH_VERSION%%(*}" "OK"
else r "bash" "FAIL 3.2 이상 필요"; fail=1; fi

# gh — 정책이 지시하는 명령에 필요한 플래그가 실제로 있는지 본다
if command -v gh >/dev/null 2>&1; then
  r "gh $(gh --version | sed -n '1s/^gh version \([0-9.]*\).*/\1/p')" "OK"
  while IFS='|' read -r sub flag; do
    [ -z "$sub" ] && continue
    if gh $sub --help 2>&1 | grep -q -- "$flag"; then r "gh $sub $flag" "OK"
    else r "gh $sub $flag" "FAIL 이 플래그가 없다"; fail=1; fi
  done <<'FLAGS'
pr create|--draft
pr list|--draft
pr edit|--body-file
pr merge|--delete-branch
FLAGS
  gh pr ready --help >/dev/null 2>&1 && r "gh pr ready" "OK" || { r "gh pr ready" "FAIL"; fail=1; }
else
  r "gh" "FAIL 없음 — branch-policy 4절 PR 흐름이 불가능하다"; fail=1
fi

# jq 는 일부러 쓰지 않는다. 없어도 hook·lint 가 돌아야 한다
command -v jq >/dev/null 2>&1 && r "jq" "있음 (불필요, 써도 무해)" || r "jq" "없음 (정상)"

[ "$fail" -eq 0 ] && echo "  환경 OK"
exit "$fail"
