#!/usr/bin/env bash
# 사용법: 과제 프로젝트 루트에서  bash <kit 경로>/setup.sh
# - 문서 템플릿을 docs/로 복사 (이미 있으면 건너뜀)
# - AGENTS.md를 루트에 복사 (이미 있으면 뒤에 덧붙임)
# - obra/superpowers(MIT) 원본 저장소에서 스킬 3개, mattpocock/skills(MIT)에서 handoff를 .agents/skills/로 복사
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(pwd)"
SKILLS="test-driven-development verification-before-completion systematic-debugging"

mkdir -p "$ROOT/docs/decisions" "$ROOT/docs/handoffs"
for f in PRD.md PLANS.md RISKS.md HANDOFF.md; do
  if [ -e "$ROOT/docs/$f" ]; then echo "건너뜀: docs/$f (이미 있음)"; else cp "$KIT/templates/$f" "$ROOT/docs/$f"; fi
done
[ -e "$ROOT/docs/decisions/0000-template.md" ] || cp "$KIT/templates/decisions/0000-template.md" "$ROOT/docs/decisions/"

if [ -e "$ROOT/AGENTS.md" ]; then
  if grep -q "^# 작업 규칙" "$ROOT/AGENTS.md"; then
    echo "건너뜀: AGENTS.md (이미 덧붙여짐)"
  else
    printf '\n\n' >> "$ROOT/AGENTS.md"; cat "$KIT/AGENTS.md" >> "$ROOT/AGENTS.md"; echo "AGENTS.md: 기존 파일 뒤에 덧붙임"
  fi
else
  cp "$KIT/AGENTS.md" "$ROOT/AGENTS.md"
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/kit.XXXXXX")"
if git clone --quiet --depth 1 --filter=blob:none --sparse https://github.com/obra/superpowers "$TMP/sp" \
   && git -C "$TMP/sp" sparse-checkout set skills; then
  mkdir -p "$ROOT/.agents/skills"
  for s in $SKILLS; do
    if [ -e "$ROOT/.agents/skills/$s" ]; then echo "건너뜀: 스킬 $s (이미 있음)"; else cp -R "$TMP/sp/skills/$s" "$ROOT/.agents/skills/$s"; fi
  done
  cp "$TMP/sp/LICENSE" "$ROOT/.agents/skills/SUPERPOWERS-LICENSE"
  echo "스킬 복사 완료: $SKILLS"
else
  echo "경고: superpowers clone 실패. 스킬 없이 AGENTS.md와 템플릿만으로 진행하세요."
fi

# mattpocock/skills(MIT)의 handoff 스킬. 저장소 안 위치가 바뀌어도 찾도록 경로를 검색한다.
if [ -e "$ROOT/.agents/skills/handoff" ]; then
  echo "건너뜀: 스킬 handoff (이미 있음)"
elif git clone --quiet --depth 1 --filter=blob:none --sparse https://github.com/mattpocock/skills "$TMP/mp" \
   && git -C "$TMP/mp" sparse-checkout set --no-cone '/skills/**/handoff/SKILL.md' '/LICENSE'; then
  SRC="$(find "$TMP/mp/skills" -path '*/handoff/SKILL.md' -not -path '*in-progress*' | head -1)"
  if [ -n "$SRC" ]; then
    mkdir -p "$ROOT/.agents/skills/handoff"
    cp "$SRC" "$ROOT/.agents/skills/handoff/SKILL.md"
    cp "$TMP/mp/LICENSE" "$ROOT/.agents/skills/MATTPOCOCK-LICENSE"
    echo "스킬 복사 완료: handoff"
  else
    echo "경고: mattpocock/skills에서 handoff 스킬을 찾지 못함. AGENTS.md의 인계 규칙만으로 진행하세요."
  fi
else
  echo "경고: mattpocock/skills clone 실패. AGENTS.md의 인계 규칙만으로 진행하세요."
fi
rm -rf "$TMP"

echo "완료. Codex를 다시 시작한 뒤 /skills 로 스킬이 보이는지 확인하세요."
