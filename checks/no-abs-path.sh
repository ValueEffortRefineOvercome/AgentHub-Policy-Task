#!/usr/bin/env bash
# task-policy 4절 "경로" 규칙 검사 — 추적 파일에 머신에 묶인 경로가 있으면 실패.
# 저장소 루트에서 실행한다. 의존성 없음 (git + grep).
# 추적 파일만 본다 — 새 파일을 추가했으면 git add 뒤에 돌려야 보인다.
#
# 면제: 예시로 적은 줄은 같은 줄에 abs-path-ok 를 붙인다.
#       금지 규칙 자체를 설명하는 문서가 자기 때문에 실패하면 안 되기 때문이다.

# 드라이브 문자는 한 글자여야 한다 — 앞에 글자가 붙으면 http:// 같은 스킴이다.
pat='(^|[^A-Za-z])[A-Za-z]:[\/]|/home/[a-z]|/Users/[A-Za-z]|/c/dev/' # abs-path-ok: 탐지 패턴 자체

hits=$(git ls-files -z \
  | while IFS= read -r -d '' f; do
      [ -f "$f" ] || continue
      grep -InE "$pat" -- "$f" | grep -v 'abs-path-ok' | sed "s|^|$f:|"
    done)

if [ -n "$hits" ]; then
  echo "FAIL 추적 파일에 절대경로 (면제는 줄 끝에 abs-path-ok):"
  echo "$hits" | sed 's/^/    /'
  exit 1
fi
echo "OK  절대경로 없음"
