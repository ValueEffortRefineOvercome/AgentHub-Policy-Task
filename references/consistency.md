# 여러 PC 에서 같은 결과를 내는 규칙

`task-policy` 4절의 상세. 환경 세팅 · PR 본문 작성 · 작업 중단 ·
다른 PC 에서 이어받기 — 이 네 상황에서 읽는다.


일관성은 세 가지가 같을 때만 성립한다 — **환경 · 경로 · 상태**.

## 환경이 같아야 한다
| 항목 | 고정 방법 |
|---|---|
| 정책 버전 | 서브모듈 SHA 핀. 올릴 때만 `--remote` |
| 줄바꿈 | `.gitattributes` 에 `* text=auto eol=lf` |
| hook 동작 | `.claude/settings.json` 을 커밋한다 (`settings.local.json` 은 개인용) |
| 도구 기능 | `env/tools.sh` 로 검사. 새 PC 세팅 때 이것부터 돌린다 |
| 프로젝트 런타임 | 버전 파일을 저장소에 커밋 (아래) |

#### 도구 — 숫자가 아니라 기능을 확인한다

```bash
bash .claude/skills/task-policy/env/tools.sh
```

| 도구 | 왜 필요한가 |
|---|---|
| git ≥ 2.25 | `switch`(2.23) · `branch --show-current`(2.22) · `submodule set-url`(2.25) |
| gh | `pr create --draft` · `pr list --draft` · `pr edit --body-file` · `pr merge --delete-branch` · `pr ready` |
| bash ≥ 3.2 | hook·lint 스크립트 |
| jq | **쓰지 않는다.** 없는 PC 에서 hook 이 죽지 않게 일부러 피했다 |

버전 숫자를 표에만 적어두는 건 고정이 아니다 — 아무도 안 읽으면 다른 PC 에서
그대로 깨진다. 그래서 `env/tools.sh` 가 **플래그 존재 여부를 직접 확인한다.**
벤더 빌드·패치 번호에서 버전 숫자는 믿기 어렵고, 정작 필요한 건 그 플래그다.

#### 프로젝트 런타임 — 버전 파일을 커밋한다

**버전 파일을 저장소에 넣어** 고정한다. 문서에 "Node 20 쓰세요" 로 적는 건 고정이
아니다 — 읽는 사람에게 의존한다. 파일로 두면 도구가 읽는다.

| 스택 | 버전 파일 | lockfile | 커밋하지 않는 것 |
|---|---|---|---|
| Python | `.python-version` | `uv.lock` 또는 `requirements.txt` | `.venv/` |
| Node | `.nvmrc` | `package-lock.json` | `node_modules/` |
| Dart | `.fvmrc` | `pubspec.lock` | `.dart_tool/` |
| Unity | `ProjectSettings/ProjectVersion.txt` (이미 있다) | — | `Library/` `Temp/` |

여러 스택을 섞으면 `mise.toml` 또는 `.tool-versions` 하나로 묶는다.

제외 목록은 전부 **머신에 묶인 것**이다 — 경로 규칙과 같은 이유로 커밋하지 않는다.
스택별 게이트 명령은 `/pipeline-policy` 의 `references/<스택>.md`.

## 경로는 머신에 묶이지 않아야 한다
- 추적되는 파일에 **절대경로 금지** — `C:\...`, `/home/...`, 사용자명, 드라이브 문자 <!-- abs-path-ok: 금지 예시 -->
- 저장소 루트 기준 상대경로만 쓴다
- 임시 파일은 저장소 밖(스크래치)에 두고 커밋하지 않는다

## 상태는 머신에 남지 않아야 한다
**Claude Code 세션 컨텍스트는 그 PC 에만 있다.** 다른 PC 의 새 세션은 작업 기억이
0 이다. 그래서 새 세션이 diff 만 보고 알 수 없는 것을 밖으로 꺼내 둔다.
장소는 **draft PR 본문** 하나다 — 작업 1개 = 브랜치 1개 = PR 1개라 1:1 로 맞고,
이미 흐름에 있어 새 산출물이 없고, 머지되면 같이 사라져 정리 단계가 없다.

| 남길 곳 | 무엇 |
|---|---|
| push 된 브랜치 | 코드 변경 |
| draft PR 본문 | 목표·접근·다음 할 일·막힌 것 |

**남기면 안 되는 곳**: 로컬 전용 브랜치 / 로컬 메모·스크래치 파일 /
전역 git config 에만 있는 설정 / 세션 대화에만 있는 결정.

브랜치에 첫 커밋이 생기면 **바로 draft PR 을 만든다.** PR 이 없는 동안은 상태를
둘 곳이 없다. 작업이 끝나면 `gh pr ready` 로 바꾼다 — draft 여부가 곧 진행 중인지
여부라, 어느 PC 에서 봐도 상태가 같다.

### PR 본문 형식
```markdown
## 목표
<1절 1단계에서 적은 한 문장>

## 접근
<택한 방법과 버린 선택지. diff 가 말하지 않는 것만>

## 다음
- [ ] <남은 작업>

## 막힌 것
<기다리는 답, 또는 "없음">
```

### 중단할 때 — 먼저 PR 본문 4칸을 확인한다

대화 보고는 이 PC 에서 사라지고 PR 본문만 남는다. 그래서 중단 직전에 본다.

- [ ] **목표** 가 한 문장으로 있다
- [ ] **접근** 에 버린 선택지가 있다 — 없으면 다른 PC 가 기각된 방법을 다시 시도한다
- [ ] **다음** 이 비어 있지 않다 — 비면 어디서 멈췄는지 알 수 없다
- [ ] **막힌 것** 이 "없음" 이라도 적혀 있다 — 빈칸은 안 쓴 것과 구분이 안 된다

네 칸 중 하나라도 비면 그 PR 은 인계 수단이 아니다. 스크립트로 검사하지 않는다 —
방금 쓴 텍스트에 제목이 있는지 보는 데 프로세스를 띄울 이유가 없다.

```bash
gh pr view --json body -q .body     # 확인
```

```bash
git push                                   # 커밋이 그 PC 에만 있으면 유실이다
gh pr create --draft --fill                # 처음이면
gh pr edit --body-file <파일>              # 이미 있으면 갱신
```

### 다른 PC 에서 이어받을 때
```bash
gh pr list --draft --author @me            # 진행 중인 작업 찾기
gh pr checkout <번호>
gh pr view <번호> --json body -q .body     # 상태 복원
```

이슈는 쓰지 않는다 — 작업이 PR 여러 개에 걸치거나 코드보다 먼저 존재해야 할 때만
필요하고, 지금은 그런 작업이 없다.

