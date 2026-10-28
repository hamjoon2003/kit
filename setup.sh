#!/usr/bin/env bash
# 사용법: 과제 프로젝트 루트에서  bash <kit 경로>/setup.sh [--project]
# - 문서 양식을 docs/로 복사 (이미 있으면 건너뜀)
# - AGENTS.md를 루트에 복사 (이미 있으면 뒤에 덧붙임)
# - 공개 스킬 5개를 검토한 커밋으로 고정해 내려받음
#   기본 설치 위치는 ~/.agents/skills (작업 공간 밖). 쓸 수 없거나 --project면 ./.agents/skills
# - 하나라도 실패하면 마지막에 "부분 완료"와 실패 목록을 보여 주고 종료 코드 1로 끝난다
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

FAIL=""      # 실패한 항목
NOTE=""      # 사람이 확인해야 할 안내
fail() { FAIL="$FAIL
  - $1"; }
note() { NOTE="$NOTE
  - $1"; }

# 1. 문서 양식
mkdir -p "$ROOT/docs/decisions" "$ROOT/docs/handoffs" || fail "docs/ 폴더 만들기"
skipped=""
for f in PRD.md PLANS.md RISKS.md HANDOFF.md; do
  if [ -e "$ROOT/docs/$f" ]; then skipped="$skipped $f"
  else cp "$KIT/templates/$f" "$ROOT/docs/$f" || fail "docs/$f 복사"; fi
done
[ -e "$ROOT/docs/decisions/0000-template.md" ] \
  || cp "$KIT/templates/decisions/0000-template.md" "$ROOT/docs/decisions/" || fail "docs/decisions 양식 복사"
[ -n "$skipped" ] && note "docs/에 이미 있어 건너뜀:$skipped — 이전 양식이면 검증표·제출 점검이 없을 수 있음"

# 2. AGENTS.md
if [ -e "$ROOT/AGENTS.md" ] && grep -qF "$MARK" "$ROOT/AGENTS.md"; then
  note "AGENTS.md에 키트 규칙이 이미 있어 건너뜀 — 이전 키트 규칙이면 그 부분을 지우고 다시 실행"
elif [ -e "$ROOT/AGENTS.md" ]; then
  { printf '\n\n'; cat "$KIT/AGENTS.md"; } >> "$ROOT/AGENTS.md" || fail "AGENTS.md 덧붙이기"
  note "AGENTS.md: 기존 파일 뒤에 덧붙임. 기존 규칙과 충돌하면 기존(운영 측) 규칙을 따를 것"
else
  cp "$KIT/AGENTS.md" "$ROOT/AGENTS.md" || fail "AGENTS.md 복사"
fi

# 3. 스킬 설치 위치
DEST="$HOME/.agents/skills"
if [ "${1:-}" = "--project" ] || ! mkdir -p "$DEST" 2>/dev/null || [ ! -w "$DEST" ]; then
  DEST="$ROOT/.agents/skills"; mkdir -p "$DEST" || fail "스킬 폴더 만들기"
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

# 새로 설치한 스킬만 손본다. 이미 있던 스킬은 건드리지 않는다.
# put_skill <원본 폴더> <이름> <sha>  → 성공하면 0, 건너뛰거나 실패하면 1
put_skill() {
  local src="$1" s="$2" sha="$3"
  if [ -e "$DEST/$s" ]; then
    if [ "$(cat "$DEST/$s/.cofa-kit-version" 2>/dev/null)" = "$sha" ]; then
      echo "건너뜀: 스킬 $s (같은 버전 설치됨)"
    else
      note "스킬 $s: 다른 버전이 이미 있어 건드리지 않음. 키트 버전을 쓰려면 rm -rf \"$DEST/$s\" 후 다시 실행"
    fi
    return 1
  fi
  cp -R "$src" "$DEST/$s" && echo "$sha" > "$DEST/$s/.cofa-kit-version" && return 0
  rm -rf "$DEST/$s"; fail "스킬 $s 복사"; return 1
}

if fetch "$SP_REPO" "$SP_SHA" "$TMP/sp" '/skills/' '/LICENSE'; then
  cp "$TMP/sp/LICENSE" "$DEST/SUPERPOWERS-LICENSE" || fail "superpowers 라이선스 복사"
  for s in $SP_SKILLS; do
    put_skill "$TMP/sp/skills/$s" "$s" "$SP_SHA" || continue
    case "$s" in
      systematic-debugging)
        d="$DEST/$s"
        # 개발용 부속 파일 제외 (find-polluter.sh는 테스트 0개여도 '깨끗함'으로 보고함)
        rm -f "$d/find-polluter.sh" "$d/CREATION-LOG.md" "$d"/test-*.md
        # 지운 스크립트를 부르는 안내를 수동 절차로 바꾸고, 스킬 이름 접두사를 설치 이름에 맞춤
        awk '/^Use the bisection script `find-polluter.sh`/ {print "Run the test files one at a time and report the first one that causes it. A run that found 0 tests is not clean."; skip=1; next}
             skip && /^See script for usage\./ {skip=0; next}
             !skip' "$d/root-cause-tracing.md" > "$TMP/rct" && mv "$TMP/rct" "$d/root-cause-tracing.md" \
          && sed -i.bak -E 's/superpowers:(test-driven-development|verification-before-completion)/\1/g' "$d/SKILL.md" \
          && rm -f "$d/SKILL.md.bak" \
          && ! grep -rq 'find-polluter\|superpowers:' "$d" \
          || fail "systematic-debugging 손보기"
        ;;
      test-driven-development)
        # 자동 호출을 끄고 확정된 계산·변환에만 직접 부른다 (AGENTS.md 참고)
        mkdir -p "$DEST/$s/agents" \
          && printf 'policy:\n  allow_implicit_invocation: false\n' > "$DEST/$s/agents/openai.yaml" \
          || fail "test-driven-development 자동 호출 끄기"
        ;;
    esac
  done
else
  fail "superpowers 내려받기 (GitHub 접속 확인)"
fi

if fetch "$AK_REPO" "$AK_SHA" "$TMP/ak" '/data/skills/' '/LICENSE'; then
  cp "$TMP/ak/LICENSE" "$DEST/ANTHROPIC-KNOWLEDGE-WORK-PLUGINS-LICENSE" || fail "knowledge-work-plugins 라이선스 복사"
  for s in $AK_SKILLS; do
    put_skill "$TMP/ak/data/skills/$s" "$s" "$AK_SHA" || continue
    # 설치하지 않는 CONNECTORS.md 안내 줄 제거 (로컬 파일만 쓴다)
    sed -i.bak '/CONNECTORS\.md/d' "$DEST/$s/SKILL.md" && rm -f "$DEST/$s/SKILL.md.bak" || fail "$s 손보기"
  done
else
  fail "anthropics/knowledge-work-plugins 내려받기 (GitHub 접속 확인)"
fi

[ -e "$DEST/handoff" ] && note "이전 키트의 handoff 스킬이 남아 있음. 인계는 AGENTS.md 규칙으로 하므로 rm -rf \"$DEST/handoff\" 권장"

# 4. 결과 보고: 키트 버전으로 실제 설치된 것만 센다
ok=0; missing=""
for s in $SP_SKILLS $AK_SKILLS; do
  case " $SP_SKILLS " in *" $s "*) sha="$SP_SHA";; *) sha="$AK_SHA";; esac
  if [ -f "$DEST/$s/SKILL.md" ] && [ "$(cat "$DEST/$s/.cofa-kit-version" 2>/dev/null)" = "$sha" ]; then
    ok=$((ok+1))
  else missing="$missing $s"; fi
done

echo
echo "스킬 설치 위치: $DEST"
[ -n "$NOTE" ] && echo "확인할 것:$NOTE"
if [ -z "$FAIL" ] && [ -z "$missing" ]; then
  echo "완료: 스킬 $ok/5, AGENTS.md, docs/ 양식. Codex를 다시 시작한 뒤 /skills 로 확인하세요."
  exit 0
fi
[ -n "$FAIL" ] && echo "실패:$FAIL"
[ -n "$missing" ] && echo "없거나 다른 버전인 스킬:$missing"
echo "부분 완료: 스킬 $ok/5. 위 항목을 확인하세요. 스킬이 없어도 AGENTS.md와 docs/ 양식만으로 진행할 수 있습니다."
exit 1
