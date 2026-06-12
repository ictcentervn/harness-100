---
name: api-client-generator
description: "API 클라이언트 SDK를 자동 생성하는 풀 파이프라인. API 스펙(OpenAPI/GraphQL/gRPC) 파싱, 타입 생성, 클라이언트 코드, 테스트, 사용 문서를 에이전트 팀이 협업하여 생성한다. 'API 클라이언트 만들어줘', 'SDK 생성', 'OpenAPI에서 클라이언트', 'API 래퍼', 'REST 클라이언트', 'GraphQL 클라이언트', 'API 타입 생성', 'Swagger에서 SDK' 등 API 클라이언트 SDK 생성 전반에 이 스킬을 사용한다. 단, API 서버 구현, API 게이트웨이 설정, API 모니터링 대시보드 구축은 이 스킬의 범위가 아니다."
---

# API Client Generator — SDK 생성 풀 파이프라인

API 스펙 파싱→타입 생성→클라이언트 코드→테스트→문서를 에이전트 팀이 협업하여 생성한다.

## 실행 모드

**에이전트 팀** — 5명이 SendMessage로 직접 통신하며 교차 검증한다.

## 에이전트 구성

| 에이전트 | 파일 | 역할 | 타입 |
|---------|------|------|------|
| spec-parser | `.claude/agents/spec-parser.md` | API 스펙 분석, 엔드포인트 추출 | general-purpose |
| type-generator | `.claude/agents/type-generator.md` | 타입 정의 생성 | general-purpose |
| sdk-developer | `.claude/agents/sdk-developer.md` | 클라이언트 SDK 코드 개발 | general-purpose |
| test-engineer | `.claude/agents/test-engineer.md` | 테스트 코드 작성 | general-purpose |
| doc-writer | `.claude/agents/doc-writer.md` | 사용 문서 작성 | general-purpose |

## 워크플로우

### Phase 1: 준비 (오케스트레이터 직접 수행)

1. 사용자 입력에서 추출한다:
    - **API 스펙**: 파일 경로/URL, 스펙 포맷(OpenAPI/GraphQL/gRPC)
    - **타깃 언어**: TypeScript, Python, Go, Java 등
    - **SDK 이름**: 패키지/모듈명
    - **설정** (선택): 인증 방식 우선순위, 네이밍 컨벤션, 추가 기능
2. `_workspace/` 디렉토리와 하위 디렉토리를 생성한다
3. 입력을 정리하여 `_workspace/00_input.md`에 저장한다
4. API 스펙 파일을 `_workspace/`에 복사한다
5. 기존 파일이 있으면 `_workspace/`에 복사하고 해당 Phase를 건너뛴다
6. 요청 범위에 따라 **실행 모드를 결정**한다

### Phase 2: 팀 구성 및 실행

| 순서 | 작업 | 담당 | 의존 | 산출물 |
|------|------|------|------|--------|
| 1 | 스펙 분석 | spec-parser | 없음 | `01_spec_analysis.md` |
| 2 | 타입 생성 | type-generator | 작업 1 | `02_types/` |
| 3 | SDK 개발 | sdk-developer | 작업 1, 2 | `03_client/` |
| 4a | 테스트 작성 | test-engineer | 작업 2, 3 | `04_tests/` |
| 4b | 문서 작성 | doc-writer | 작업 1, 3 | `05_docs/` |

작업 4a(테스트)와 4b(문서)는 **병렬 실행**한다.

**팀원 간 소통 흐름:**
- spec-parser 완료 → type-generator에게 모델 상세 전달, sdk-developer에게 엔드포인트 그룹핑 전달
- type-generator 완료 → sdk-developer에게 타입 임포트 정보 전달, test-engineer에게 팩토리 데이터 전달
- sdk-developer 완료 → test-engineer에게 공개 API 목록 전달, doc-writer에게 사용 예시 전달
- test-engineer/doc-writer → 코드/문서 불일치 발견 시 sdk-developer에게 수정 요청

**스캐폴드 규칙**: sdk-developer가 `_workspace/03_client/package.json`을 생성할 때 `"verify": "tsc --noEmit"` 스크립트를 반드시 포함한다 (테스트 산출 시 `"verify": "tsc --noEmit && vitest run"`). TypeScript 외 언어는 해당 언어의 표준 검증 명령을 `03_client/`의 README 또는 매니페스트에 기록한다. 실행 가능 코드는 문서 내 코드블록·의사코드로만 두지 말고 `02_types/`, `03_client/`, `04_tests/`에 실파일로 저장한다.

### Phase 3: 검증 게이트 (오케스트레이터가 메인 컨텍스트에서 직접 수행 — 서브에이전트 위임 금지)

테스트엔지니어의 산출물과 별개로, 명령을 실제로 실행해 통과를 확인한다:

1. 실행 모드에 따라 게이트 범위를 정한다:
   - **분석 모드 / 문서 모드**: 코드 미산출 — 게이트 해당 없음 ("해당 없음" 기록)
   - **타입 모드**: 타입 컴파일만 실행 (`02_types/` 대상)
   - **코드 모드 / 풀 파이프라인 / 테스트 모드**: 아래 표의 전체 verify 실행
2. 타깃 언어별 verify 명령을 `_workspace/03_client/`(타입 모드는 `02_types/`)에서 실행하고 실제 출력을 확인한다:

   | 타깃 언어 | verify 명령 |
   |----------|------------|
   | TypeScript (기본) | `npm run verify` (없으면 `npx tsc --noEmit`) + `npx vitest run` |
   | Python | `mypy .` + `pytest` |
   | Go | `go build ./... && go test ./...` |
   | 표 외 언어 | 해당 언어의 표준 컴파일러/테스트 러너 실행 후 결과 보고 |

3. 실패 시 에러를 직접 수정하고 재실행한다 — 통과할 때까지 반복
4. 동일 에러가 3회 반복되면 접근을 바꾼다. 수정이 스펙 해석/타입 구조 등 설계 변경을 요구하면 자동 수정하지 말고 사용자에게 보고한다
5. 끝내 통과하지 못하면 잔여 에러를 TODO.md에 기록하고 최종 보고에 명시한다
6. `@ts-ignore` 추가, any 캐스팅, 컴파일러 설정 완화, 테스트 비활성화로 게이트를 우회하지 않는다
7. 코드 산출 모드에서 코드 디렉토리가 비어 있으면 게이트 스킵이 아니라 미통과로 처리한다
8. 통과(에러 0건)를 확인한 뒤에만 Phase 4로 진행한다

### Phase 4: 통합 및 최종 산출물

1. `_workspace/` 내 모든 파일을 확인한다
2. 코드-타입-테스트-문서 간 정합성을 최종 검증한다
3. Phase 3 게이트 통과 결과와 함께 최종 요약을 보고한다

## 작업 규모별 모드

| 사용자 요청 패턴 | 실행 모드 | 투입 에이전트 |
|----------------|----------|-------------|
| "SDK 전체 생성", "풀 클라이언트" | **풀 파이프라인** | 5명 전원 |
| "타입만 생성해줘" | **타입 모드** | spec-parser + type-generator |
| "클라이언트 코드만" | **코드 모드** | spec-parser + type-generator + sdk-developer |
| "테스트만 작성" (기존 SDK 있음) | **테스트 모드** | test-engineer 단독 |
| "문서만 작성" (기존 SDK 있음) | **문서 모드** | doc-writer 단독 |
| "스펙 분석만" | **분석 모드** | spec-parser 단독 |

## 데이터 전달 프로토콜

| 전략 | 방식 | 용도 |
|------|------|------|
| 파일 기반 | `_workspace/` 디렉토리 | 코드, 타입, 테스트, 문서 |
| 메시지 기반 | SendMessage | 핵심 정보 전달, 수정 요청 |

## 에러 핸들링

| 에러 유형 | 전략 |
|----------|------|
| 스펙 파싱 실패 | 문법 오류 위치 보고, 파싱 가능 부분만 진행 |
| 불완전한 스펙 | 타입 추론으로 보완, "추론됨" 표시 |
| 순환 참조 | lazy reference 패턴 자동 적용 |
| 비표준 인증 | 커스텀 인터셉터 확장 포인트 제공 |
| 빌드/타입 에러 | 오케스트레이터가 언어별 verify 직접 실행 → 에러 분석 → 수정 → 재검증 (Phase 3 게이트) |
| 에이전트 실패 | 1회 재시도 후 해당 산출물 없이 진행 |
| 코드-문서 불일치 | doc-writer/test-engineer가 sdk-developer에게 수정 요청 (최대 2회) |

## 테스트 시나리오

### 정상 흐름
**프롬프트**: "이 OpenAPI 3.1 스펙으로 TypeScript SDK를 만들어줘"
**기대 결과**:
- 스펙 분석: 엔드포인트 그룹핑, 모델 목록, 인증 방식 식별
- 타입: TypeScript interface/type, enum, 유니온 타입, 직렬화 헬퍼
- SDK: 리소스 기반 클라이언트 클래스, 인증, 페이지네이션, 재시도
- 테스트: 리소스별 단위 테스트, 인증 통합 테스트, 목 서버
- 문서: README, 빠른 시작, API 레퍼런스, 코드 예제

### 기존 파일 활용 흐름
**프롬프트**: "이 Swagger 파일에서 Python 타입만 뽑아줘"
**기대 결과**:
- spec-parser가 스키마 분석
- type-generator가 Python dataclass/Pydantic 모델 생성
- sdk-developer, test-engineer, doc-writer는 미투입

### 에러 흐름
**프롬프트**: "이 API의 SDK를 만들어줘" (불완전한 스펙, 응답 타입 미정의 다수)
**기대 결과**:
- spec-parser가 불완전한 부분을 목록화하여 보고
- type-generator가 추론 가능한 범위에서 타입 생성, "추론됨" 주석 추가
- sdk-developer가 런타임 타입 체크 레이어를 추가
- doc-writer가 "알려진 제한사항" 섹션에 미정의 응답 목록 기록


## 에이전트별 확장 스킬

| 스킬 | 경로 | 강화 대상 에이전트 | 역할 |
|------|------|-----------------|------|
| openapi-spec-patterns | `.claude/skills/openapi-spec-patterns/skill.md` | spec-parser | 엔드포인트 그룹핑, 인증 매핑, 페이지네이션/에러 패턴, GraphQL/gRPC |
| sdk-design-patterns | `.claude/skills/sdk-design-patterns/skill.md` | sdk-developer | 빌더 패턴, 인터셉터 체인, 재시도, 타입 안전, 페이지네이션 래퍼 |
