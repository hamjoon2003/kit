# Codex 작업 키트

3시간짜리 AI 협업 개발 과제를 위한 최소 키트. 계획·결정·위험을 문서로 남기며 Codex에 단계별로 작업을 맡기도록 돕는다.

## 구성
| 파일 | 용도 |
|---|---|
| `AGENTS.md` | Codex 작업 규칙: 단계별 진행, 검증 후 완료, 결정·위험 기록 |
| `templates/PRD.md` | 요구사항 정리와 인터뷰 질문 틀 |
| `templates/PLANS.md` | 실행 계획 (OpenAI ExecPlan 형식 축약) |
| `templates/RISKS.md` | 사전 부검 방식 위험 목록 |
| `templates/decisions/0000-template.md` | 결정 기록 (MADR 최소형 축약) |
| `templates/HANDOFF.md` | 인계 문서 |
| `setup.sh` | 위 파일을 프로젝트에 복사하고 공개 스킬을 내려받음 |

## 사용
```bash
git clone <이 저장소 URL> /tmp/kit
cd <과제 프로젝트 루트>
bash /tmp/kit/setup.sh
```
그 뒤 Codex를 다시 시작하고 `/skills`로 스킬 4개가 보이는지 확인한다.

## 진행 순서
1. 과제를 읽고 `docs/PRD.md`를 채운다. 빈칸만 담당자에게 묻는다.
2. `docs/PLANS.md`에 단계를 쪼갠다. 단계마다 검증 방법을 적는다.
3. Codex에 한 단계씩 맡긴다. 예: "PLANS.md 2단계를 진행해. 테스트부터."
4. 결정할 때 `docs/decisions/`, 단계가 끝날 때 `docs/RISKS.md`를 갱신한다.
5. 끝나기 15분 전 `HANDOFF.md`를 쓰고 제출한다.

## 출처와 라이선스
- 스킬은 이 저장소에 포함하지 않고 `setup.sh`가 원본 [obra/superpowers](https://github.com/obra/superpowers)(MIT)와 [mattpocock/skills](https://github.com/mattpocock/skills)(MIT, `handoff`)에서 내려받는다.
- 계획 형식은 [OpenAI Cookbook ExecPlans](https://developers.openai.com/cookbook/articles/codex_exec_plans), 결정 기록은 [MADR](https://github.com/adr/madr), PRD 질문 방식은 [snarktank/ai-dev-tasks](https://github.com/snarktank/ai-dev-tasks)를 참고해 직접 축약했다.
