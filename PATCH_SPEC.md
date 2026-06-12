# PATCH_SPEC — 검증 게이트 일괄 패치 (2026-06-12 승인)

레퍼런스: 16-fullstack-webapp 패치 (커밋 0bda894). 4요소: ①Phase 3 검증 게이트 신설+리넘버 ②스캐폴드/실파일 저장 규칙 ③에러 핸들링 표 행 ④QA 에이전트 실행 검증 의무+실행한 검증 표+탈출구 봉쇄.

## 확정 기본값 규칙 6개 (심판 판정, 사용자 승인)
1. 게이트 강도 = 의존성 최소 정적 검사 (tsc --noEmit 등가: compileall/py_compile 등). 테스트 실행 제외, Node는 npm install 전제 허용
2. 스킵 조건 = 모드 기준 — 코드 산출 모드에서 코드 디렉토리가 비면 미통과 (파일 부재를 스킵 사유로 삼지 않음)
3. 도구 부재·검증 불가 = TODO.md 기록+보고, 통과 표기 금지
4. 전역 compile-gate hook 불개입 — skill 텍스트 게이트만. hook 다언어 확장은 7월 verify.log 리뷰 의제
5. 비Node 환경의 요소 2 번안 = "실행 가능 코드는 지정 디렉토리에 실파일로 저장" Phase 2 규칙
6. 요소 4 완화형 = 실행 가능한 명령만 실행·기록, 정적 검토는 정적임을 명기, 미실행을 실행으로 기재 금지

## 스코프 결정
- variant 12개: 아래 표. partial 2개(24, 28): 요소 4 정직성 패치만. 39: 패치 없음(기존 Phase 3이 문서 검증 수행).
- 24-test-automation 산출물 계약 변경(실제 테스트 파일 생성+러너 게이트)은 **별도 백로그** — 이번 스코프 아님 (사용자 결정).
- 41 프롬프트 모드: 문서 전용 실행은 게이트 스킵, src/ 코드가 실제 산출되면 모드 무관 게이트 적용.

## 17-mobile-app-builder (full)
- QA 담당: `qa-engineer.md`
- verify: 프레임워크 조건부: Flutter → (cd _workspace/02_app_code &&) flutter analyze / React Native(TS) → npx tsc --noEmit / SwiftUI·Jetpack Compose → 경량 검증 수단 부재(Xcode/Gradle 컴파일은 skill description이 명시적으로 범위 외 선언). 코드 미산출 모드(UX/스토어/리뷰)에서는 해당 없음
- 변형 지침: 구조적 패치(Phase 3 신설+리넘버, 에러 핸들링 표 행 추가, qa-engineer 실행 검증 의무)는 16번 패턴 그대로 이식 가능 — Phase 포맷·QA 에이전트·보고서 템플릿 모두 동형. 그러나 3가지 변형 필요: (1) verify 명령을 단일 명령이 아닌 프레임워크 조건부 표로 작성해야 함(Flutter→flutter analyze, RN→npx tsc --noEmit). (2) 스캐폴드 규칙(구성요소 2)의 'package.json에 verify 스크립트'는 RN에만 적용 가능 — Flutter는 pubspec.yaml에 스크립트 개념이 없어 글로벌 Stop hook 옵트인 메커니즘(package.json verify 기반)과 매핑 불가, 검증 명령을 02_app_architecture.md에 기록하는 식의 대체 필요. (3) 게이트 실행 위치가 프로젝트 루트가 아닌 _workspace/02_app_code/ 하위임을 명시해야 함. verify_mechanical=true는 Flutter/RN 분기에 한정 — flutter analyze와 tsc는 exit 0/1 판정 가능하나 SwiftUI/Compose 분기는 기계 판정 수단 자체가 범위 외 도구(Xcode/Gradle)에 묶여 있음

## 22-legacy-modernizer (full)
- QA 담당: `regression-tester.md`
- verify: 해당 없음 (문서 산출 기준). variant 채택 시 고정 명령 불가 — Phase 1에서 대상 프로젝트의 기존 빌드/테스트 명령을 탐지해 00_input.md에 기록하고 게이트에서 그 명령을 동적으로 사용해야 함
- 변형 지침: 16번 패턴을 그대로 적용 불가한 이유: (1) 파이프라인이 새 앱을 스캐폴드하지 않으므로 요소 2(package.json verify 스크립트)는 적용 대상이 없음. (2) verify 명령을 하네스에 고정 기입할 수 없음 — 대상 레거시 프로젝트의 스택이 매번 다름. 변형안: Phase 1(준비)에 "대상 프로젝트의 빌드/테스트 명령 탐지·기록" 단계 추가 → 게이트 Phase는 마이그레이션 모드(실제 코드 수정 발생 시)에만 그 명령을 실행, 문서 전용 모드(분석/전략)는 게이트 생략. (3) 요소 4는 regression-tester에 적용 ("실행한 검증" 표 + 미실행 테스트를 통과로 기재 금지), modernization-reviewer에는 "테스트 보고서의 실행 증빙 없는 통과 판정을 🔴 처리" 항목 추가. (4) regression-tester·오케스트레이터에 이미 있는 "실행 환경 없으면 정적 분석 대체" 탈출구는 전면 봉쇄가 아니라 "대체 시 종합 판정을 🟢로 표기 금지(🟡 조건부 + 동적 검증 불가 명시)" 수준으로 좁혀야 기존 설계 의도(환경 없는 레거시 분석 허용)와 양립함.

## 27-data-pipeline (full)
- QA 담당: `pipeline-reviewer.md`
- verify: find pipeline_code -name '*.py' -exec python3 -m py_compile {} + (pipeline_code/에 .py 파일이 존재할 때; 모니터링/리뷰 모드 등 코드 미산출 시 게이트 스킵). dbt SQL은 dbt 프로젝트 부재로 기계 검증 제외.
- 변형 지침: 패턴의 4요소 중 1번(게이트 Phase 삽입: 기존 Phase 3 '통합'→Phase 4 리넘버), 3번(에러 핸들링 표에 '코드 구문 에러 → 오케스트레이터가 verify 직접 실행' 행), 4번(pipeline-reviewer에 실행 검증 의무+'실행한 검증' 표+통과 처리 금지)은 그대로 이식 가능. 변형 필요 지점: (a) 2번 스캐폴드 규칙은 package.json이 없으므로 "코드 생성 에이전트(scheduler-engineer, etl-architect, quality-manager)는 코드를 .md 임베드와 별도로 pipeline_code/에 .py 파일로 저장한다"는 Phase 2 규칙으로 대체해야 함 — 현재 pipeline_code/는 최종 산출물 목록에만 있고 산출 주체·파일 구조가 미정의. (b) verify 명령은 tsc 대신 python3 -m py_compile (구문 수준). Airflow/GE import 검증은 apache-airflow 설치 필요로 무겁고, 하네스가 placeholder 접속정보 기반 설계 코드를 허용하므로 실행 검증은 부적합. (c) 게이트는 모드 조건부여야 함: 모니터링 모드·리뷰 모드 등 코드 미산출 모드에서는 "코드 파일 없음 → 게이트 해당 없음" 분기 필요(기계적으로 기술 가능).

## 30-open-source-launcher (full)
- QA 담당: `launch-reviewer.md`
- verify: 해당 없음 (단일 고정 명령 불가 — variant 제안: generated_files 내 .github/workflows/*.yml은 actionlint 또는 yamllint로 문법 검증, 사용자 코드베이스 제공 시 01_code_organization.md에 기재된 빌드/테스트 명령을 오케스트레이터가 직접 실행)
- 변형 지침: Phase 1/2/3 구조와 명시적 QA 에이전트(launch-reviewer, 🔴 재작업 루프 보유)가 있어 패치 골격은 그대로 이식 가능하나, 산출물이 문서+설정 파일이고 대상 스택이 가변이라 16번식 고정 verify 명령이 성립하지 않음. 변형안: (1) 검증 게이트 Phase 신설하되 검증 대상을 이원화 — generated_files의 YAML/TOML은 문법 린트(exit 0/1 기계 판정), 사용자 코드베이스는 01_code_organization.md '빌드 명령/테스트 명령' 기재값을 동적으로 실행. (2) 패치 요소 2는 'package.json verify 스크립트' 대신 '빌드 매니페스트 구성 시 test/lint 명령 정의 포함'으로 번안. (3) 문서-only 모드(문서/라이선스/리뷰 모드)는 게이트 조건부 스킵 명시. (4) 패치 요소 4는 launch-reviewer에 그대로 적합 — 현재 체크리스트의 '테스트 존재 및 통과', '빌드 스크립트 동작', '코드 예시 동작 가능' 항목이 실행 없이 단언만으로 통과 가능한 상태라 '실행한 검증' 표와 통과 처리 금지 조항이 정확히 필요함

## 31-ml-experiment (full)
- QA 담당: `experiment-reviewer.md`
- verify: python3 -m compileall -q _workspace/experiment_code/ (experiment_code/에 .py 파일이 존재할 때만 실행, 부재 시 게이트 생략)
- 변형 지침: 요소 1(게이트 Phase 신설, 기존 Phase 3→4 리넘버)과 요소 3(에러 핸들링 표에 "코드 구문/임포트 에러 → 오케스트레이터가 verify 직접 실행" 행)과 요소 4(experiment-reviewer에 실행 검증 의무 + "실행한 검증" 표)는 거의 그대로 적용 가능. 변형 필요 지점 2개: (1) 요소 2 — package.json이 없으므로 스캐폴드 규칙을 "실행 가능 코드는 .md 본문에만 두지 말고 _workspace/experiment_code/에 .py 파일로 저장한다"로 대체해야 게이트가 검사할 실물이 생김. (2) 게이트 문구를 조건부로: 리뷰/평가 모드 등 코드 미산출 런에서는 게이트를 명시적으로 생략("해당 없음" 기록). 또한 검증 명령은 stdlib 구문 검사(compileall) 수준으로 한정 — 학습 스모크 실행을 의무화하면 torch/xgboost/mlflow 미설치·데이터 부재 환경에서 게이트가 코드 품질과 무관하게 항상 실패함

## 34-data-migration (full)
- QA 담당: `validation-engineer.md`
- verify: test -d _workspace/03_migration_scripts && python3 -m py_compile _workspace/03_migration_scripts/*.py (03_migration_scripts/ 미존재 시 = 코드 미산출 모드 = 게이트 스킵)
- 변형 지침: Phase 구조('### Phase 1/2/3')와 리넘버(기존 Phase 3 통합→Phase 4)는 16번 그대로 적용 가능하나 3곳 변형 필요. (1) 패치요소 2(package.json verify 스크립트)는 부적용 — Node 앱이 아니라 _workspace/03_migration_scripts/에 Python 파일을 생성하는 구조. 치환안: script-developer 산출 규칙에 "README.md에 검증 명령(python3 -m py_compile *.py) 명시" 추가 + 오케스트레이터가 py_compile 직접 실행(요소 3과 통합). (2) verify는 npm 계열이 아닌 py_compile — DB·서드파티 패키지 없이 동작하는 문법 수준 게이트가 환경상 유일한 기계 검증. ETL 실행 자체는 사용자의 소스/타깃 DB가 필요해 하네스 환경에서 불가. (3) 패치요소 4(validation-engineer 실행 검증 의무)는 범위 한정 필수 — 이 에이전트의 핵심 산출물인 SQL 검증 쿼리는 DB 없이 실행 불가하므로, "실행한 검증" 표에는 실제 실행 가능한 py_compile(자기 validation.py 포함)만 기록하고 DB 의존 쿼리는 "설계 산출물 — 실행 환경 없음, 사용자 실행용"으로 명시 분리해야 함. 무조건적 "보고서 전 명령 직접 실행" 문구를 그대로 넣으면 실행 불가능한 것의 실행 기록 위조를 유도할 위험. (4) 게이트는 코드 미산출 모드(분석/매핑/검증설계/롤백 단독)에서 스킵되는 조건부여야 함 — 이 조건은 03_migration_scripts/ 존재 여부로 기계 판정 가능.

## 35-api-client-generator (full)
- QA 담당: `test-engineer.md`
- verify: 언어별 표 필요 — TypeScript(기본): npx tsc --noEmit (+ npx vitest run); Python: mypy + pytest; Go: go build ./... && go test ./... ; 분석/문서 단독 모드에서는 해당 없음
- 변형 지침: 패턴 골격(새 Phase 3 게이트 삽입 + 기존 Phase 3 '통합 및 최종 산출물' → Phase 4 리넘버, test-engineer에 실행 검증 의무 + '실행한 검증' 표 + 통과 처리 금지)은 그대로 적용 가능하나 3가지 변형 필요: (1) 타깃 언어가 가변이므로 verify를 단일 명령이 아닌 언어별 표로 기술하고 표 외 언어는 표준 컴파일러/테스트 러너 사용 후 보고하도록 함. (2) 스캐폴드 규칙의 앵커가 '새 앱 package.json'이 아니라 sdk-developer가 이미 산출하는 _workspace/03_client/package.json — 여기에 verify 스크립트 포함 규칙을 추가. (3) '작업 규모별 모드' 때문에 게이트를 모드 조건부로: 분석/문서 모드는 게이트 생략, 타입 모드는 타입 컴파일만, 코드/풀 모드는 전체 verify. 추가로 기존 Phase 3의 '빌드/테스트 실행 명령어와 함께 보고'(실행 없이 보고만) 문구가 게이트와 충돌하므로 '게이트 통과 결과와 함께 보고'로 수정 필요.

## 36-design-system (full)
- QA 담당: `a11y-auditor.md`
- verify: npm run verify (= npx tsc --noEmit) — 단, 현재 하네스는 package.json/tsconfig를 어디서도 생성하지 않으므로 Phase 2에 _workspace 스캐폴드(package.json + tsconfig + react/@types/react/typescript/@storybook deps) 생성 규칙을 추가해야만 실행 가능
- 변형 지침: 패치 1·3요소는 그대로 적용 가능: skill.md가 '### Phase 1/2/3' 포맷이고 기존 Phase 3(통합)을 Phase 4로 리넘버하면 됨. 변형 필요 지점 두 곳. (1) 2요소: 16번은 "새 앱 package.json 생성 시 verify 포함"인데 이 하네스는 package.json을 아예 만들지 않고 느슨한 소스 파일만 _workspace에 산출(grep으로 npm/package.json 언급 전무 확인). 조건부 규칙이 아니라 "Phase 2 시작 시 _workspace 루트에 package.json+tsconfig 스캐폴드 필수 생성(01~03 디렉토리를 모두 커버하는 paths 매핑 포함)"으로 강제해야 게이트가 공허해지지 않음. verify 스크립트를 package.json에 넣는 방식이면 Vue 선택 시 vue-tsc로의 분기도 기계적으로 해소됨. (2) 4요소: a11y-auditor의 검증은 WCAG 정적 검토(대비비 계산, ARIA 대조)라 "보고서 전 명령 직접 실행" 의무가 그대로는 성립 안 함 — axe/스토리북 a11y 애드온은 빌드된 스토리북이 필요한데 워크플로우에 없음. "실행한 검증" 표 + "미완성 시 통과 처리 금지"는 적용하되 실행 명령은 tsc 교차 실행으로 한정하거나 정적 검토임을 명기하는 변형 필요. 부수: storybook-builder 내부 모순(스토리 위치가 원칙은 컴포넌트 동일 디렉토리, 산출물 포맷은 03_storybook/ 분리)이 tsconfig 경로 설계에 영향.

## 37-web-scraper (full)
- QA 담당: `monitor-operator.md`
- verify: python3 -m compileall -q _workspace/src (Node.js 산출로 분기된 경우 node --check 또는 npx tsc --noEmit)
- 변형 지침: 3가지 변형 필요. (1) 게이트 위치: 16번은 "새 Phase 3 게이트 + 기존 Phase 3→4 리넘버"지만, 37은 기존 Phase 3(통합)이 코드를 생성함(main.py) — 16 방식 그대로 적용하면 main.py가 게이트 통과 후 미검증 생성됨. 변형안: 게이트를 통합 뒤 "### Phase 4: 검증 게이트"로 신설하고 기존 Phase 3의 4번 항목(최종 보고)을 게이트 통과 후로 이동(또는 Phase 3을 통합/보고로 분리). (2) verify 명령: tsc 대신 python3 -m compileall -q _workspace/src — stdlib 전용·exit 0/1 기계 판정. mypy는 에이전트 산출 코드에 타입 주석이 없어 무의미, ruff는 설치 비보장, main.py 실행 스모크는 외부 사이트 의존이라 게이트 부적합(비결정적). 에러 핸들링 표 추가 행은 "구문/임포트 에러 → 오케스트레이터가 compileall 직접 실행"으로 문구 교체. (3) 4요소(QA 에이전트 패치): QA 역할 에이전트 부재 — monitor-operator가 "모든 팀원의 산출물을 종합"하고 파싱 성공률 메트릭을 소유하므로 실행 검증 의무 + "실행한 검증" 표 + 통과 처리 금지 조항의 대체 대상으로 가장 적합(게이트 본체는 패턴대로 오케스트레이터 직접). 2요소(package.json 스캐폴드 규칙)는 ambiguities 참조 — Python 산출이라 자연스러운 대응물이 없음.

## 38-chatbot-builder (full)
- QA 담당: `dialog-tester.md`
- verify: _workspace/src/ 스캐폴드에 포함시킨 verify 진입점 실행 (Node 스캐폴드면 npm run verify ≒ npx tsc --noEmit, Python이면 python -m py_compile + pytest). 스택이 미지정이라 단일 고정 명령은 불가 — Phase 2 스캐폴드 규칙을 "src/ 생성 시 스택에 맞는 verify 진입점 필수 포함"으로 일반화하고 게이트는 그 진입점을 실행하는 방식. 설계/테스트 모드(코드 미산출)에서는 게이트 스킵
- 변형 지침: Phase 1/2/3 구조와 dialog-tester(명시적 '품질 게이트 역할', PASS/FAIL 템플릿 보유)는 16번 패턴이 그대로 맞지만 3가지 변형 필요: (1) 스택 미지정 — "npx tsc --noEmit" 고정 대신 스캐폴드 규칙을 "src/ 생성 시 스택에 맞는 verify 진입점(package.json verify 또는 verify.sh) 필수 포함"으로 일반화, 게이트는 그 진입점 실행. (2) 코드 위치가 프로젝트 루트가 아닌 _workspace/src/ — 게이트 실행 디렉토리 명시 필요. (3) 작업 규모별 모드 중 설계 모드(persona+designer)·테스트 모드는 코드 미산출 — "src/ 코드가 생성된 경우에만 게이트 적용" 조건 필요. 요소 4는 dialog-tester에 직접 적용 가능하며, 특히 "테스트 환경이 없는 경우 시뮬레이션 기반 테스트로 대체" 탈출구가 이미 존재해 '실행한 검증 표 + 미완성 시 통과 처리 금지' 봉쇄가 정확히 필요한 지점.

## 40-cli-tool-builder (full)
- QA 담당: `test-engineer.md`
- verify: 언어별 분기 — Python(기본): python -m compileall _workspace/src && python -m pytest _workspace/src/tests; Node.js: npm run verify(TS면 npx tsc --noEmit); Go: go vet ./... && go test ./...; Rust: cargo check && cargo test
- 변형 지침: 패턴 4요소가 구조적으로는 모두 적용 가능(### Phase 1/2/3 포맷, 에러 핸들링 표, QA역 에이전트 존재)하나 3가지 변형 필요. (1) 검증 명령: 16의 고정 "npx tsc --noEmit" 대신 언어→verify 명령 테이블을 게이트 본문에 넣어야 함(하네스가 Python/Node/Go/Rust 4종을 명시적으로 지원). (2) 스캐폴드 규칙(요소 2): "package.json에 verify 스크립트"는 Node 산출일 때만 성립 — 기본값 Python은 pyproject.toml이라 전역 compile-gate Stop hook(package.json 전용 옵트인, ~/.claude/hooks/compile-gate.sh:36)이 작동 안 함. Node일 때만 규칙 적용하고 그 외 언어는 스킬 텍스트 게이트만으로 커버하는 게 하네스 내 패치 범위. (3) 기존 Phase 3("통합 및 최종 산출물")의 1~2번 항목(실행 가능 확인, 테스트 통과 확인)이 게이트와 중복 — 단순 신설+리넘버 대신 기존 Phase 3의 1~2번을 게이트 절차로 강화·교체하고 3~4번(문서 일관성, 최종 보고)을 Phase 4로 분리하는 편이 자연스러움(행동상 동일하므로 기계적 결정 가능). 추가로 봉쇄할 탈출구: 에러 핸들링 표의 "에이전트 실패 → 해당 산출물 없이 진행"과 "테스트 실패 최대 2회" 규칙을 게이트의 "3회 시 보고/미완성 시 통과 처리 금지"와 정합화. test-engineer.md는 이미 종료코드 검증 원칙이 있고 산출물 포맷에 커버리지 보고서 섹션이 있어 "실행한 검증" 표 추가 지점이 명확. en 미러는 파일 구성 동일(9개 파일 일치) 확인.

## 41-llm-app-builder (full)
- QA 담당: `eval-specialist.md`
- verify: python3 -m compileall -q _workspace/src (의존성 설치 불요, 문법만 검사). src/에 package.json 존재 예외 시 npm install && npx tsc --noEmit|node --check 전환. Dockerfile/YAML은 게이트 범위 제외.
- 변형 지침: (a) 요소 2는 규칙 5 번안 — 'Phase 2: 실행 가능 코드는 _workspace/src/에 실파일로 저장, 문서 내 코드블록·의사코드만으로 산출 종료 금지' 규칙 신설. (b) 게이트 명령은 python3 -m compileall. (c) 요소 4는 규칙 6 완화형 — eval-specialist는 LLM 품질 평가 설계자(전담 QA 부재)이므로 실행 가능한 명령만 실행·기록, 정적 검토는 정적임을 명기. 기존 Phase 3(통합)을 Phase 4로 리넘버하고 Phase 4의 '코드가 실행 가능한지 확인한다' 항목(검증 방법 미정의)은 신설 게이트가 대체하므로 삭제. 에러 핸들링 표에 '빌드/문법 에러 → 오케스트레이터 compileall 직접 실행' 행 추가. 스킵 조건: 프롬프트 모드 등 문서 전용 실행은 게이트 스킵, 코드 산출 모드(풀/RAG/평가/최적화/배포)에서 src/ 부재는 미통과. src/ 코드가 실제 산출된 경우에는 모드와 무관하게 게이트 적용.

## 24-test-automation (partial)
- QA 담당: `qa-reviewer.md`
- verify: 현재 형태로는 "해당 없음" (마크다운 문서만 산출). variant 채택 시: 대상 프로젝트의 테스트 러너 실행(예: npx jest --ci 또는 npm test) — 단 스택이 요청별로 달라져 skill.md에 단일 명령 하드코딩 불가, 01_test_strategy.md에서 verify 명령을 선언하게 하는 계약 추가 필요
- 변형 지침: Phase 구조('### Phase 1/2/3')와 qa-reviewer 존재는 16번 패턴과 정합하나, 산출물이 코드블록 포함 마크다운뿐이라 표준 게이트(컴파일/테스트 실행)가 잡을 실물이 없음. 변형안: (1) unit-tester/integration-tester가 마크다운 가이드와 함께 실제 테스트 파일을 대상 프로젝트(또는 _workspace/tests/)에 쓰도록 산출물 계약 변경, (2) Phase 3 게이트에서 오케스트레이터가 전략서에 선언된 테스트 러너를 직접 실행(exit 0/1 기계 판정 가능), (3) 패치 2요소(스캐폴드 verify 스크립트)는 스캐폴딩이 없으므로 "CI/설정 코드블록에 실행 가능한 test 스크립트 필수" 규칙으로 대체, (4) qa-reviewer에 실행 검증 의무 + "실행한 검증" 표 추가는 그대로 적용 가능. 단, 마크다운-only 산출 형태를 유지하기로 하면 기계 게이트가 성립하지 않아 exclude에 가까워짐 — 이 갈림길이 핵심.

## 28-security-audit (partial)
- QA 담당: `audit-reviewer.md`
- verify: 해당 없음
- 변형 지침: 코드를 생성·수정하지 않는 문서 전용 하네스라 exit 0/1 기계 판정 가능한 verify 명령이 존재하지 않음 — 16번 패턴의 핵심(검증 명령 루프, 스캐폴드 verify 스크립트, 빌드 에러 행)이 모두 적용 지점 없음. 또한 audit-reviewer의 교차검증 루프(🔴 필수 수정 → 재작업 → 재검증 최대 2회, 정합성 매트릭스)가 이미 문서 품질 게이트로 내장되어 있어 게이트 Phase 신설은 중복. 단, 패치 4요소 중 4번만 부분 이식 가치 있음: vulnerability-scanner 템플릿의 '스캔 도구: [사용된 도구 목록]' 항목이 미실행 도구를 실행한 것처럼 기록할 환각 여지가 있으므로, '실행한 검증' 표(실제 실행 명령·종료코드만 기록, 미실행 시 오프라인 스캔 명기)를 scanner에 추가하는 변형은 고려 가능
