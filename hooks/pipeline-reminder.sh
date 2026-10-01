#!/usr/bin/env bash
# UserPromptSubmit hook — 매 명령마다 작업 파이프라인을 컨텍스트에 넣는다.
#
# 이것은 **강제 수단이 아니다.** 파이프라인이 매 턴 "존재하게" 만들 뿐이고,
# 따르는지는 검사하지 않는다 — 보고문을 볼 수 있는 hook 이 없다 (SKILL.md 3절).
#
# 설치 — 소비 프로젝트의 .claude/settings.json:
#   { "hooks": { "UserPromptSubmit": [{ "hooks": [{
#       "type": "command",
#       "command": "bash .claude/skills/task-policy/hooks/pipeline-reminder.sh"
#   }]}]}}
#
# 비용: 매 턴 이 텍스트만큼 토큰을 낸다. 그래서 단계 이름과 규칙 한 줄만 넣고
# 상세는 넣지 않는다. 400B 상한을 tests/ 가 검사한다 — 늘리면 실패한다.
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"작업 파이프라인(매 명령 7단계): Intake → Context → Planning → Execution → Validation → Documentation → Reporting. 단계를 건너뛰지 않는다 — 통과가 한 줄일 수 있다. 상세는 /task-policy 1절, references/pipeline.md."}}
JSON
