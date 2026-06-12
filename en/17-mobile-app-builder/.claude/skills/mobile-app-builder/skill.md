---
name: mobile-app-builder
description: "Full mobile app development pipeline. An agent team collaborates to perform UI/UX design, native/cross-platform code generation, API integration, and store deployment preparation. Use this skill for requests like 'build me a mobile app', 'app development', 'iOS app', 'Android app', 'Flutter app', 'React Native app', 'app UI design', 'app store deployment', 'app API integration', and other general mobile app development. Also supports API integration and store deployment for existing codebases. However, actual build/compilation (Xcode, Gradle), actual store submission, and CI/CD pipeline setup are outside this skill's scope."
---

# Mobile App Builder — Full Mobile App Development Pipeline

An agent team collaborates to generate mobile app UX design, code, API integration, and store deployment all at once.

## Execution Mode

**Agent Team** — 5 agents communicate directly via SendMessage and cross-verify.

## Agent Composition

| Agent | File | Role | Type |
|-------|------|------|------|
| ux-designer | `.claude/agents/ux-designer.md` | UX/UI design, wireframes, design system | general-purpose |
| app-developer | `.claude/agents/app-developer.md` | Native/cross-platform app code generation | general-purpose |
| api-integrator | `.claude/agents/api-integrator.md` | API client, auth, caching | general-purpose |
| store-manager | `.claude/agents/store-manager.md` | Store metadata, ASO, review preparation | general-purpose |
| qa-engineer | `.claude/agents/qa-engineer.md` | Quality verification, cross-consistency checks | general-purpose |

## Workflow

### Phase 1: Preparation (performed directly by the orchestrator)

1. Extract from user input:
   - **App Type**: What kind of app (social, commerce, utility, game, etc.)
   - **Platform**: iOS / Android / Cross-platform
   - **Framework Preference** (optional): Flutter, React Native, SwiftUI, Jetpack Compose
   - **Backend API** (optional): If an existing API spec exists
   - **Existing Files** (optional): Design, code, API specs, etc.
2. Create `_workspace/` directory at the project root
3. Organize input and save to `_workspace/00_input.md`
4. If existing files are provided, copy them to `_workspace/` and skip the corresponding Phase
5. Determine **execution mode** based on request scope (see "Scale-Based Modes" below)

### Phase 2: Team Assembly and Execution

Assemble the team and assign tasks. Task dependencies are as follows:

| Order | Task | Owner | Dependencies | Deliverables |
|-------|------|-------|-------------|--------------|
| 1 | UX/UI Design | ux-designer | None | `_workspace/01_ux_design.md` |
| 2a | App Code Generation | app-developer | Task 1 | `_workspace/02_app_code/`, `02_app_architecture.md` |
| 2b | Store Metadata | store-manager | Task 1 | `_workspace/04_store_listing.md` |
| 3 | API Integration | api-integrator | Tasks 1, 2a | `_workspace/03_api_integration.md` |
| 4 | QA Verification | qa-engineer | Tasks 2a, 2b, 3 | `_workspace/05_qa_report.md` |

Tasks 2a (app code) and 2b (store metadata) run **in parallel**.

**Inter-team Communication Flow:**
- ux-designer completes → delivers screen structure/design tokens to app-developer, screenshot scenarios to store-manager, data fields to api-integrator
- app-developer completes → delivers Repository interfaces to api-integrator, permission list to store-manager
- api-integrator completes → delivers API client code to app-developer
- qa-engineer cross-verifies all deliverables. On 🔴 required fix: requests fix from relevant agent → rework → re-verify (max 2 rounds)

**Scaffold rule**: Save runnable app code as real files in `_workspace/02_app_code/` — never finish with code blocks embedded in documents only. When scaffolding with React Native (TypeScript), always include a `"verify": "tsc --noEmit"` script in package.json — the compile gate (global Stop hook) opts in based on the presence of this script. Flutter has no package.json, so record the verification command (`flutter analyze`) in `02_app_architecture.md` instead.

### Phase 3: Verification Gate (executed directly by the orchestrator in the main context — do NOT delegate to subagents)

Independent of QA's cross-verification, actually run the commands and confirm they pass. In modes that produce no code (UX Mode / Store Mode / Review Mode), skip the gate and record "N/A" in the final report. However, in code-producing modes, an empty `_workspace/02_app_code/` counts as a gate failure — file absence is not a reason to skip.

The verification command is framework-conditional, and the gate runs in `_workspace/02_app_code/` rather than the project root:

| Framework | Verification Command | Mechanical Judgment |
|-----------|---------------------|---------------------|
| Flutter | `cd _workspace/02_app_code && flutter analyze` | Possible (exit 0/1) |
| React Native (TypeScript) | `cd _workspace/02_app_code && npm run verify` (or `npx tsc --noEmit` if absent) | Possible (exit 0/1) |
| SwiftUI / Jetpack Compose | No lightweight verification available — Xcode/Gradle compilation is outside this skill's scope | Not possible |

1. In `_workspace/02_app_code/`, run the verification command from the table above and check the actual output
2. On failure, fix the errors directly and re-run — repeat until passing
3. If the same error repeats 3 times, change approach. If the fix requires screen structure/API/data model or other design changes, report to the user instead of auto-fixing
4. If it ultimately cannot pass, record remaining errors in TODO.md and state them in the final report
5. For branches with no verification means (SwiftUI/Jetpack Compose), record "mechanical verification not possible" in TODO.md and state it in the final report — never mark it as passed
6. Never bypass the gate by adding `// ignore` comments, casting to `dynamic`/`any`, or loosening analysis_options.yaml/tsconfig
7. Proceed to Phase 4 only after confirming a pass (0 errors) or the explicit records from steps 4-5

### Phase 4: Integration and Final Deliverables

Organize final deliverables based on the QA report:

1. Verify all files in `_workspace/`
2. Confirm all 🔴 required fixes from the QA report have been addressed
3. Report final summary to the user:
   - UX Design — `01_ux_design.md`
   - App Architecture — `02_app_architecture.md`
   - App Code — `02_app_code/`
   - API Integration — `03_api_integration.md`
   - Store Deployment — `04_store_listing.md`
   - QA Report — `05_qa_report.md`

## Scale-Based Modes

| Request Pattern | Execution Mode | Deployed Agents |
|----------------|---------------|----------------|
| "Build me a mobile app", "full development" | **Full Pipeline** | All 5 |
| "Just design the app UI" | **UX Mode** | ux-designer + qa-engineer |
| "Generate code from this design" (existing design) | **Code Mode** | app-developer + api-integrator + qa-engineer |
| "Prepare app store deployment" (existing app) | **Store Mode** | store-manager + qa-engineer |
| "Review this app code" | **Review Mode** | qa-engineer alone |

**Leveraging Existing Files**: If the user provides design documents, code, or other existing files, skip the corresponding phases.

## Data Transfer Protocol

| Strategy | Method | Purpose |
|----------|--------|---------|
| File-based | `_workspace/` directory | Store and share main deliverables |
| Message-based | SendMessage | Real-time key info delivery, fix requests |
| Task-based | TaskCreate/TaskUpdate | Progress tracking, dependency management |

File naming convention: `{order}_{agent}_{deliverable}.{extension}`

## Error Handling

| Error Type | Strategy |
|-----------|----------|
| Platform unspecified | UX designer defaults to cross-platform (Flutter), reflecting both platform guidelines |
| No backend API | API integrator designs mock API, structured for easy replacement with real API |
| Build/type (analysis) errors | Orchestrator directly runs the framework-specific verify (`flutter analyze` / `npx tsc --noEmit`) in `_workspace/02_app_code/` → analyze errors → fix → re-verify (Phase 3 gate) |
| Agent failure | Retry once → proceed without that deliverable if failed, note in QA report |
| 🔴 found in QA | Request fix from relevant agent → rework → re-verify (max 2 rounds) |
| Framework compatibility | App developer suggests alternative framework with pros/cons comparison |

## Test Scenarios

### Normal Flow
**Prompt**: "Build me a to-do management app in Flutter. I need add/delete/complete-check, category classification, and notification features."
**Expected Result**:
- UX Design: 5 screens (list/add/detail/category/settings), navigation structure, design system
- App Code: Flutter + Riverpod + go_router, MVVM structure, per-screen widgets/viewmodels
- API Integration: RESTful CRUD endpoints, auth, local cache
- Store: iOS + Android metadata, ASO keywords
- QA: Full cross-verification, consistency matrix

### Existing File Flow
**Prompt**: "Generate iOS app code from this Figma design" + design file
**Expected Result**:
- Existing design copied to `_workspace/01_ux_design.md`
- Code Mode: app-developer + api-integrator + qa-engineer deployed
- ux-designer, store-manager skipped

### Error Flow
**Prompt**: "Build me an app quickly, anything is fine"
**Expected Result**:
- App type unclear → UX designer proposes 3 trending app types then proceeds
- Full pipeline mode execution
- QA report notes "assumption-based design due to absent user requirements"

## Agent Extension Skills

Extension skills that enhance each agent's domain expertise:

| Skill | Target Agent | Role |
|-------|-------------|------|
| `mobile-ux-patterns` | ux-designer | iOS HIG/Material Design 3 comparison, navigation patterns, design tokens |
| `app-store-optimization` | store-manager | ASO metadata optimization, keyword strategy, review rejection response |
