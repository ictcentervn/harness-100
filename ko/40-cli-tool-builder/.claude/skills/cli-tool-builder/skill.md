---
name: cli-tool-builder
description: "CLI 도구를 에이전트 팀이 협업하여 개발하는 풀 파이프라인. 'CLI 만들어줘', '커맨드라인 도구 개발', 'CLI 유틸리티', '터미널 도구', '명령줄 프로그램', 'CLI 앱 빌드', '셸 도구 개발' 등 CLI 도구 개발 전반에 이 스킬을 사용한다. 명령 설계만 필요한 경우에도 설계 모드로 지원한다. 단, GUI 앱 개발, 웹 대시보드 구축, IDE 플러그인 개발은 이 스킬의 범위가 아니다."
---

# CLI Tool Builder — CLI 도구 개발 파이프라인

CLI 도구의 명령설계→파서구현→핸들러→테스트→문서→배포를 에이전트 팀이 협업하여 개발한다.

## 실행 모드

**에이전트 팀** — 5명이 SendMessage로 직접 통신하며 교차 검증한다.

## 에이전트 구성

| 에이전트 | 파일 | 역할 | 타입 |
|---------|------|------|------|
| command-designer | `.claude/agents/command-designer.md` | 명령 체계 설계 | general-purpose |
| core-developer | `.claude/agents/core-developer.md` | 코어 구현 | general-purpose |
| test-engineer | `.claude/agents/test-engineer.md` | 테스트 작성 | general-purpose |
| docs-writer | `.claude/agents/docs-writer.md` | 문서 작성 | general-purpose |
| release-engineer | `.claude/agents/release-engineer.md` | 빌드, 배포 | general-purpose |

## 워크플로우

### Phase 1: 준비 (오케스트레이터 직접 수행)

1. 사용자 입력에서 추출한다:
    - **도구 목적**: 무엇을 하는 CLI인가
    - **언어/런타임**: Python/Node.js/Go/Rust (기본: Python)
    - **주요 기능**: 핵심 서브커맨드 목록
    - **배포 채널**: PyPI/npm/Homebrew/바이너리
    - **제약 조건** (선택): 의존성 제한, 호환 OS, 성능 요구사항
2. `_workspace/` 디렉토리를 프로젝트 루트에 생성한다
3. 입력을 정리하여 `_workspace/00_input.md`에 저장한다
4. `_workspace/src/` 디렉토리를 생성한다
5. 기존 파일이 있으면 `_workspace/`에 복사하고 해당 Phase를 건너뛴다
6. 요청 범위에 따라 **실행 모드를 결정**한다

### Phase 2: 팀 구성 및 실행

| 순서 | 작업 | 담당 | 의존 | 산출물 |
|------|------|------|------|--------|
| 1 | 명령 체계 설계 | designer | 없음 | `_workspace/01_command_design.md` |
| 2 | 코어 구현 | developer | 작업 1 | `_workspace/02_core_implementation.md` + `src/` |
| 3a | 테스트 작성 | tester | 작업 2 | `_workspace/03_test_suite.md` + `src/tests/` |
| 3b | 문서 작성 | docs | 작업 1, 2 | `_workspace/04_documentation.md` |
| 4 | 릴리스 설정 | release | 작업 2, 3a | `_workspace/05_release_config.md` + CI 파일 |

작업 3a(테스트)와 3b(문서)는 **병렬 실행**한다.

**팀원 간 소통 흐름:**
- designer 완료 → developer에게 명령 스키마 전달, docs에게 --help 초안 전달
- developer 완료 → tester에게 mock 포인트 전달, docs에게 API 전달, release에게 빌드 정보 전달
- tester 완료 → developer에게 버그 리포트 전달 (있으면), release에게 CI 테스트 설정 전달
- docs 완료 → release에게 README 경로 전달
- release는 모든 산출물을 통합하여 배포 파이프라인 완성

**실파일 저장/스캐폴드 규칙**:
- developer와 tester는 실행 가능한 코드를 `.md` 문서에 임베드하는 것으로 끝내지 않고 반드시 `_workspace/src/`(테스트는 `_workspace/src/tests/`)에 실파일로 저장한다
- Node.js 산출일 때 package.json을 생성하면 `"verify": "tsc --noEmit"` 스크립트(순수 JS면 `node --check` 기반)를 반드시 포함한다 — 컴파일 게이트(전역 Stop hook)가 이 스크립트의 존재로 옵트인된다. Python/Go/Rust는 Phase 3 검증 게이트가 검증을 담당한다

### Phase 3: 검증 게이트 (오케스트레이터가 메인 컨텍스트에서 직접 수행 — 서브에이전트 위임 금지)

tester의 테스트 작성과 별개로, 명령을 실제로 실행해 통과를 확인한다. 언어별 verify 명령:

| 언어 | verify 명령 | 실행 위치 |
|------|------------|----------|
| Python (기본) | `python -m compileall _workspace/src && python -m pytest _workspace/src/tests` | 프로젝트 루트 |
| Node.js | `npm run verify` (TypeScript면 `npx tsc --noEmit`) | `_workspace/src/` |
| Go | `go vet ./... && go test ./...` | `_workspace/src/` |
| Rust | `cargo check && cargo test` | `_workspace/src/` |

1. 위 표에서 산출 언어의 verify 명령을 실행하고 실제 출력을 확인한다
2. 실패 시 에러를 직접 수정하고 재실행한다 — 통과할 때까지 반복
3. 동일 에러가 3회 반복되면 접근을 바꾼다. 수정이 명령 체계/인터페이스 등 설계 변경을 요구하면 자동 수정하지 말고 사용자에게 보고한다
4. 끝내 통과하지 못하면 잔여 에러를 TODO.md에 기록하고 최종 보고에 명시한다 — 미통과를 통과로 표기하지 않는다
5. 테스트 삭제·스킵 처리, `# type: ignore`/`@ts-ignore` 추가, 린트 설정 완화로 게이트를 우회하지 않는다
6. 설계 모드·배포 모드 등 코드 미산출 모드에서는 게이트를 생략하고 "해당 없음"으로 기록한다. 단, 코드 산출 모드에서 `_workspace/src/`가 비어 있으면 스킵이 아니라 미통과로 처리한다
7. 통과(에러 0건)를 확인한 뒤에만 Phase 4로 진행한다

### Phase 4: 통합 및 최종 산출물

1. 문서와 코드의 일관성을 검증한다
2. 최종 요약을 사용자에게 보고한다 (Phase 3 게이트 결과 포함)

## 작업 규모별 모드

| 사용자 요청 패턴 | 실행 모드 | 투입 에이전트 |
|----------------|----------|-------------|
| "CLI 도구 만들어줘", "풀 개발" | **풀 파이프라인** | 5명 전원 |
| "명령 구조만 설계해줘" | **설계 모드** | designer 단독 |
| "이 CLI에 서브커맨드 추가해줘" | **확장 모드** | designer + developer + tester |
| "CLI 테스트 작성해줘" | **테스트 모드** | tester 단독 |
| "배포 설정만 해줘" | **배포 모드** | release 단독 |

## 데이터 전달 프로토콜

| 전략 | 방식 | 용도 |
|------|------|------|
| 파일 기반 | `_workspace/` 디렉토리 | 설계 문서 및 설정 공유 |
| 메시지 기반 | SendMessage | 실시간 핵심 정보 전달, 버그 리포트 |
| 코드 기반 | `_workspace/src/` | 실행 가능한 소스코드 |

## 에러 핸들링

| 에러 유형 | 전략 |
|----------|------|
| 도구 목적 불명확 | 유사 CLI 도구를 WebSearch로 조사, 3개 후보 제안 |
| 언어 미지정 | Python(typer) 기본 선택, 이유와 대안 명시 |
| 빌드/타입(문법) 에러 | 오케스트레이터가 언어별 verify 명령 직접 실행 → 에러 분석 → 수정 → 재검증 (Phase 3 게이트) |
| 테스트 실패 | developer에게 버그 리포트 전달, 수정 후 재테스트 (최대 2회) → 미해결 시 Phase 3 게이트 미통과로 처리, TODO.md 기록 (통과 표기 금지) |
| 크로스 플랫폼 빌드 실패 | 해당 OS 빌드를 CI-only로 전환, 로컬 빌드 대안 제시 |
| 에이전트 실패 | 1회 재시도 → 실패 시 해당 산출물 없이 진행하되 최종 보고에 명시 (Phase 3 게이트는 생략하지 않음) |

## 테스트 시나리오

### 정상 흐름
**프롬프트**: "파일 변환 CLI 도구를 Python으로 만들어줘. JSON↔YAML↔TOML 변환 지원"
**기대 결과**:
- 명령 설계: `convert [input] --from json --to yaml --output out.yaml`
- 코어: typer 기반, 파서+변환 로직+출력 포맷터
- 테스트: 각 변환 조합, 잘못된 형식 입력, 파이프 입력
- 문서: README + 설치 + 빠른 시작 + 전체 명령 레퍼런스
- 릴리스: pyproject.toml + GitHub Actions CI + PyPI 배포

### 기존 파일 활용 흐름
**프롬프트**: "이 CLI 코드에 테스트랑 문서만 추가해줘" + CLI 소스코드 첨부
**기대 결과**:
- 기존 소스코드를 `_workspace/src/`에 복사
- designer와 developer는 건너뛰고 tester + docs + release 투입
- 기존 코드의 명령 구조를 분석하여 테스트와 문서 생성

### 에러 흐름
**프롬프트**: "CLI 만들어줘" (목적 불명확)
**기대 결과**:
- designer가 사용자에게 도구 목적 확인 요청
- 유사 인기 CLI 도구 3개 예시 제시
- 목적 확정 후 나머지 파이프라인 진행

## 에이전트별 확장 스킬

에이전트의 도메인 전문성을 강화하는 확장 스킬:

| 스킬 | 파일 | 대상 에이전트 | 역할 |
|------|------|-------------|------|
| arg-parser-generator | `.claude/skills/arg-parser-generator/skill.md` | command-designer, core-developer | 인자 유형 분류, 서브커맨드 패턴, 언어별 파서 보일러플레이트, 도움말 표준 |
| ux-linter | `.claude/skills/ux-linter/skill.md` | test-engineer, docs-writer | CLI UX 12원칙, 에러 메시지 표준, 출력 포맷 가이드, 색상/인터랙션 패턴 |
