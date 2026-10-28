# Codex 작업 키트

3시간짜리 AI 협업 과제를 위한 최소 키트. 비개발자가 Codex에 단계별로 일을 맡기고, 요구사항·결정·위험·검증을 문서로 남기도록 돕는다. 과제 풀이 코드는 포함하지 않는다.

## 구성
| 파일 | 용도 |
|---|---|
| `AGENTS.md` | Codex 작업 규칙: 단계별 진행, 증거로 완료 보고, 데이터 과제 규칙, 토큰·세션 인계 |
| `templates/PRD.md` | 요구사항과 담당자 인터뷰 질문 틀 |
| `templates/PLANS.md` | 실행 계획(OpenAI ExecPlan 축약), 요구사항별 검증표, 멈춤 기준 |
| `templates/RISKS.md` | 사전 부검 방식 위험 목록 |
| `templates/decisions/0000-template.md` | 결정 기록(MADR 축약) |
| `templates/HANDOFF.md` | 최종 인계 문서 |
| `setup.sh` | 위 파일을 과제에 복사하고 공개 스킬 5개를 고정 버전으로 설치 |

## 사용
```bash
git clone https://github.com/hamjoon2003/kit /tmp/kit
```
```bash
bash /tmp/kit/setup.sh
```
- 과제 프로젝트 루트에서 실행한다. 스킬은 기본으로 `~/.agents/skills`(작업 공간 밖)에 설치되고, 쓸 수 없으면 `./.agents/skills`에 설치한 뒤 `.gitignore`에 추가한다. `--project`로 강제할 수 있다.
- 그 뒤 과제 루트에서 Codex를 다시 시작하고 확인한다.
  1. `/skills`에 5개가 보이는지
  2. "적용 중인 AGENTS.md 규칙을 3줄로 요약해"로 규칙이 읽혔는지
  3. `/status`로 모델과 토큰 사용량
- 마지막 줄이 "부분 완료"면 그 위의 "실패"·"확인할 것" 목록을 읽는다. 스킬이 없어도 AGENTS.md와 양식만으로 진행할 수 있다.
- 예전 키트를 쓰던 곳에 다시 설치하면 이미 있는 docs/ 양식과 다른 버전 스킬은 건드리지 않고 "확인할 것"에 알려 준다.

## 사전 체험에서 행동 확인
목록에 보이는 것과 실제로 규칙대로 움직이는 것은 다르다. 빈 프로젝트에서 아래를 한 번 시켜 본다.

> 웨이퍼 10장 중 불량 2장일 때 불량률을 계산하는 함수를 만들어. PLANS.md 검증표에 먼저 행을 추가하고 진행해.

기대 행동: 검증표에 "기대 20%" 행을 먼저 쓴다 → 테스트를 먼저 만든다 → 실행 명령과 결과를 통과/실패로 보고한다 → 4줄로 보고하고 멈춘다. 화면이 있으면 확인 절차만 주고 직접 조작하지 않는다. 다르게 움직이면 어디가 달랐는지 적어 두고, 시험 당일에는 그 규칙을 프롬프트에 직접 덧붙인다.

## 설치되는 스킬 (검토한 커밋으로 고정)
| 스킬 | 출처 | 쓰는 때 |
|---|---|---|
| `verification-before-completion` | obra/superpowers v7.0.1 (MIT) | 완료 보고 직전 |
| `systematic-debugging` | obra/superpowers v7.0.1 (MIT) | 오류·실패 테스트 |
| `test-driven-development` | obra/superpowers v7.0.1 (MIT) | 확정된 계산·변환만, 직접 호출 |
| `explore-data` | anthropics/knowledge-work-plugins (Apache-2.0) | 데이터를 처음 받았을 때 |
| `validate-data` | anthropics/knowledge-work-plugins (Apache-2.0) | 분석 결과를 넘기기 전 |

원문을 고쳐 쓰지 않는다. 적용 범위는 `AGENTS.md`로 정한다. 설치 때 바꾸는 것은 새로 설치한 스킬에서만 네 가지다: 디버깅 스킬의 개발용 부속 파일 제외와 그 파일을 부르던 안내를 수동 절차로 교체, 스킬 이름 접두사(`superpowers:`) 제거, 데이터 스킬의 커넥터 안내 줄 제거, TDD 자동 호출 끄기. 이미 있던 스킬은 건드리지 않는다.

## 진행 순서
1. 과제를 읽고 `docs/PRD.md`를 채운다. 빈칸만 담당자에게 묻는다.
2. `docs/PLANS.md`에 단계를 쪼개고, 검증표에 요구사항별 기대 결과를 먼저 적는다.
3. Codex에 한 단계씩 맡긴다. 예: "PLANS.md 2단계 진행해. 끝나면 검증표 갱신하고 멈춰."
4. 결정은 `docs/decisions/`, 새 위험은 `docs/RISKS.md`에 남긴다.
5. 끝나기 15분 전 `docs/HANDOFF.md`를 쓰고 제출한다.

## GitHub에 접속할 수 없을 때
Codex에 아래를 그대로 입력한다.

> 먼저 프로젝트 루트의 AGENTS.md와 docs/ 파일이 있는지 확인해. 있으면 지우거나 덮어쓰지 말고 AGENTS.md 뒤에 덧붙이고, 기존 규칙과 충돌하면 기존 규칙을 따라. 덧붙일 규칙: PLANS.md 단계를 하나씩만 하고 멈춰서 4줄로 보고, 실행한 명령과 결과(통과/실패/미실행)로만 완료 판단, 확정된 계산은 손으로 확인 가능한 예시 테스트 먼저, 화면 확인은 내가 하니 확인 절차만 제시, 데이터는 누수·시간 순서·기준선부터 확인, 결정은 docs/decisions/, 위험은 docs/RISKS.md에 기록, 키·비밀번호를 파일에 쓰지 않고 외부로 보내는 명령(git push 포함)은 실행하지 않음. 그리고 docs/에 없는 파일만 PRD.md(목표·사용자·범위·데이터·틀렸을 때 비용·완료 기준), PLANS.md(단계·Progress·Decision Log·요구사항별 검증표), RISKS.md(약점·파급 범위·조기 신호·검증)를 빈 양식으로 만들어.

## 출처와 라이선스
- 스킬은 이 저장소에 포함하지 않고 `setup.sh`가 원본 [obra/superpowers](https://github.com/obra/superpowers)(MIT)와 [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins)(Apache-2.0)에서 고정 커밋으로 내려받는다. 각 라이선스 파일도 함께 복사한다.
- 계획 형식은 [OpenAI Cookbook ExecPlans](https://developers.openai.com/cookbook/articles/codex_exec_plans), 결정 기록은 [MADR](https://github.com/adr/madr), PRD 질문 방식은 [snarktank/ai-dev-tasks](https://github.com/snarktank/ai-dev-tasks)를 참고해 직접 축약했다.
