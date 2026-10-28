#!/usr/bin/env bash
# 사용법: 과제 프로젝트 루트에서  bash <kit 경로>/setup.sh [--project]
# - 문서 양식을 docs/로 복사 (이미 있으면 건너뜀)
# - AGENTS.md를 루트에 복사 (이미 있으면 뒤에 덧붙임)
# - 공개 스킬 5개를 검토한 커밋으로 고정해 내려받음
#   기본 설치 위치는 ~/.agents/skills (작업 공간 밖). 쓸 수 없거나 --project면 ./.agents/skills
set -uo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(pwd)"
MARK="<!-- cofa-kit:agents -->"

SP_REPO="https://github.com/obra/superpowers"
SP_SHA="2ce8aa15d05bd57213e6f746f953aafb7ded7a8b"   # v7.0.1 (2026-10-21), MIT
AK_REPO="https://github.com/anthropics/knowledge-work-plugins"
AK_SHA="2574e29377c7173d0cecffef29a6ecbd7f8ccb5d"   # 2026-10-27, Apache-2.0
SP_SKILLS="verification-before-completion systematic-debugging test-driven-development"
AK_SKILLS="explore-data validate-data"

# 1. 문서 양식
mkdir -p "$ROOT/docs/decisions" "$ROOT/docs/handoffs"
for f in PRD.md PLANS.md RISKS.md HANDOFF.md; do
  if [ -e "$ROOT/docs/$f" ]; then echo "건너뜀: docs/$f (이미 있음)"; else cp "$KIT/templates/$f" "$ROOT/docs/$f"; fi
done
[ -e "$ROOT/docs/decisions/0000-template.md" ] || cp "$KIT/templates/decisions/0000-template.md" "$ROOT/docs/decisions/"

# 2. AGENTS.md
if [ -e "$ROOT/AGENTS.md" ] && grep -qF "$MARK" "$ROOT/AGENTS.md"; then
  echo "건너뜀: AGENTS.md (이미 덧붙여짐)"
elif [ -e "$ROOT/AGENTS.md" ]; then
  printf '\n\n' >> "$ROOT/AGENTS.md"; cat "$KIT/AGENTS.md" >> "$ROOT/AGENTS.md"
  echo "AGENTS.md: 기존 파일 뒤에 덧붙임. 기존 규칙과 충돌하면 기존(운영 측) 규칙을 따를 것"
else
  cp "$KIT/AGENTS.md" "$ROOT/AGENTS.md"
fi

# 3. 스킬 설치 위치
DEST="$HOME/.agents/skills"
if [ "${1:-}" = "--project" ] || ! mkdir -p "$DEST" 2>/dev/null || [ ! -w "$DEST" ]; then
  DEST="$ROOT/.agents/skills"; mkdir -p "$DEST"
  grep -qsx '.agents/' "$ROOT/.gitignore" || echo ".agents/" >> "$ROOT/.gitignore"
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/kit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# 고정 커밋 하나만 내려받는다: fetch <repo> <sha> <dir> <sparse 경로...>
fetch() {
  local repo="$1" sha="$2" dir="$3"; shift 3
  git init -q "$dir" && git -C "$dir" remote add origin "$repo" \
    && git -C "$dir" sparse-checkout set --no-cone "$@" >/dev/null 2>&1 \
    && git -C "$dir" fetch -q --depth 1 --filter=blob:none origin "$sha" \
    && git -C "$dir" checkout -q FETCH_HEAD
}

if fetch "$SP_REPO" "$SP_SHA" "$TMP/sp" '/skills/' '/LICENSE'; then
  for s in $SP_SKILLS; do
    [ -e "$DEST/$s" ] && { echo "건너뜀: 스킬 $s (이미 있음)"; continue; }
    cp -R "$TMP/sp/skills/$s" "$DEST/$s"
  done
  # 개발용 부속 파일 제외 (find-polluter.sh는 테스트 0개여도 '깨끗함'으로 보고함)
  rm -f "$DEST/systematic-debugging/find-polluter.sh" "$DEST/systematic-debugging/CREATION-LOG.md" "$DEST"/systematic-debugging/test-*.md
  # 스킬 이름 접두사를 설치 이름에 맞춤
  sed -i.bak -E 's/superpowers:(test-driven-development|verification-before-completion)/\1/g' "$DEST/systematic-debugging/SKILL.md"
  rm -f "$DEST/systematic-debugging/SKILL.md.bak"
  cp "$TMP/sp/LICENSE" "$DEST/SUPERPOWERS-LICENSE"
else
  echo "경고: superpowers 내려받기 실패"
fi

if fetch "$AK_REPO" "$AK_SHA" "$TMP/ak" '/data/skills/' '/LICENSE'; then
  for s in $AK_SKILLS; do
    [ -e "$DEST/$s" ] && { echo "건너뜀: 스킬 $s (이미 있음)"; continue; }
    cp -R "$TMP/ak/data/skills/$s" "$DEST/$s"
  done
  cp "$TMP/ak/LICENSE" "$DEST/ANTHROPIC-KNOWLEDGE-WORK-PLUGINS-LICENSE"
else
  echo "경고: anthropics/knowledge-work-plugins 내려받기 실패"
fi

# TDD는 자동 호출을 끄고 확정된 계산·변환에만 직접 부른다 (AGENTS.md 참고)
if [ -d "$DEST/test-driven-development" ]; then
  mkdir -p "$DEST/test-driven-development/agents"
  printf 'policy:\n  allow_implicit_invocation: false\n' > "$DEST/test-driven-development/agents/openai.yaml"
fi

# 4. 결과 보고: 실제로 있는 것만 센다
ok=0; missing=""
for s in $SP_SKILLS $AK_SKILLS; do
  if [ -f "$DEST/$s/SKILL.md" ]; then ok=$((ok+1)); else missing="$missing $s"; fi
done
echo "스킬 설치 위치: $DEST"
if [ -z "$missing" ]; then
  echo "완료: 스킬 $ok/5, AGENTS.md, docs/ 양식. Codex를 다시 시작한 뒤 /skills 로 확인하세요."
else
  echo "부분 완료: 스킬 $ok/5 (없음:$missing). AGENTS.md와 docs/ 양식만으로도 진행할 수 있습니다."
fi
