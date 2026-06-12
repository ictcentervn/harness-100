#!/bin/bash
# 검증 게이트 일괄 패치 검사 오라클 (bash 3.2 호환 — macOS 기본 bash에 연관 배열 없음)
# 사용법: bash scripts/check-gate-patch.sh <하네스디렉토리명> | --all
# exit 0 = 통과, exit 1 = 미달 (미달 항목을 stdout에 출력)
cd "$(dirname "$0")/.." || exit 1

HARNESSES="17-mobile-app-builder 22-legacy-modernizer 27-data-pipeline 30-open-source-launcher 31-ml-experiment 34-data-migration 35-api-client-generator 36-design-system 37-web-scraper 38-chatbot-builder 40-cli-tool-builder 41-llm-app-builder 24-test-automation 28-security-audit"

spec_of() {
  case "$1" in
    17-mobile-app-builder)    echo "full:qa-engineer.md" ;;
    22-legacy-modernizer)     echo "full:regression-tester.md" ;;
    27-data-pipeline)         echo "full:pipeline-reviewer.md" ;;
    30-open-source-launcher)  echo "full:launch-reviewer.md" ;;
    31-ml-experiment)         echo "full:experiment-reviewer.md" ;;
    34-data-migration)        echo "full:validation-engineer.md" ;;
    35-api-client-generator)  echo "full:test-engineer.md" ;;
    36-design-system)         echo "full:a11y-auditor.md" ;;
    37-web-scraper)           echo "full:monitor-operator.md" ;;
    38-chatbot-builder)       echo "full:dialog-tester.md" ;;
    40-cli-tool-builder)      echo "full:test-engineer.md" ;;
    41-llm-app-builder)       echo "full:eval-specialist.md" ;;
    24-test-automation)       echo "partial:qa-reviewer.md" ;;
    28-security-audit)        echo "partial:audit-reviewer.md" ;;
    *)                        echo "" ;;
  esac
}

check_one() {
  local h="$1" entry type qa fail=0
  entry=$(spec_of "$h")
  [ -z "$entry" ] && { echo "FAIL $h: SPEC에 없는 하네스"; return 1; }
  type="${entry%%:*}"
  qa="${entry##*:}"

  if [ "$type" = "full" ]; then
    local ko_f en_f
    ko_f=$(grep -l "### Phase 3: 검증 게이트" ko/"$h"/.claude/skills/*/skill.md 2>/dev/null | head -1)
    [ -n "$ko_f" ] || { echo "FAIL $h: ko skill.md에 검증 게이트 Phase 없음"; fail=1; }
    if [ -n "$ko_f" ] && ! grep -q "### Phase 4" "$ko_f"; then echo "FAIL $h: ko Phase 4 리넘버 누락"; fail=1; fi
    en_f=$(grep -l "### Phase 3: Verification Gate" en/"$h"/.claude/skills/*/skill.md 2>/dev/null | head -1)
    [ -n "$en_f" ] || { echo "FAIL $h: en skill.md에 Verification Gate 없음"; fail=1; }
    if [ -n "$en_f" ] && ! grep -q "### Phase 4" "$en_f"; then echo "FAIL $h: en Phase 4 리넘버 누락"; fail=1; fi
  fi

  grep -q "실행 검증 의무\|실행한 검증" ko/"$h"/.claude/agents/"$qa" 2>/dev/null \
    || { echo "FAIL $h: ko $qa 실행 검증 패치 없음"; fail=1; }
  grep -q "Execution verification duty\|Executed Verification" en/"$h"/.claude/agents/"$qa" 2>/dev/null \
    || { echo "FAIL $h: en $qa 실행 검증 패치 없음"; fail=1; }
  return $fail
}

if [ "$1" = "--all" ]; then
  total_fail=0
  count=0
  for h in $HARNESSES; do
    count=$((count + 1))
    check_one "$h" || total_fail=1
  done
  [ $total_fail -eq 0 ] && echo "PASS: 전체 ${count}개 하네스쌍 통과"
  exit $total_fail
else
  check_one "$1" && echo "PASS: $1"
fi
