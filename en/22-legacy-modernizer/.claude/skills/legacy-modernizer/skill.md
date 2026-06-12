---
name: legacy-modernizer
description: "A full pipeline for transforming legacy codebases into modern architectures. An agent team collaborates to perform technical debt analysis, refactoring strategy formulation, code migration, and regression testing. Use this skill for requests like 'modernize legacy code', 'create a refactoring strategy', 'code migration', 'technical debt analysis', 'legacy system upgrade', 'framework migration', 'code modernization', 'refactoring plan', and other legacy code modernization tasks. Also supports strategy formulation and migration when existing analysis reports are available. Note: actual production deployment, CI/CD pipeline execution, and infrastructure provisioning are outside the scope of this skill."
---

# Legacy Modernizer — Legacy Code Modernization Pipeline

An agent team collaborates to perform analysis -> refactoring strategy -> migration -> verification of legacy code.

## Execution Mode

**Agent Team** — 5 members communicate directly via SendMessage and cross-validate each other.

## Agent Composition

| Agent | File | Role | Type |
|-------|------|------|------|
| legacy-analyzer | `.claude/agents/legacy-analyzer.md` | Tech debt identification, dependency mapping, complexity measurement | general-purpose |
| refactoring-strategist | `.claude/agents/refactoring-strategist.md` | Pattern selection, prioritization, roadmap | general-purpose |
| migration-engineer | `.claude/agents/migration-engineer.md` | Code transformation, API modernization, framework migration | general-purpose |
| regression-tester | `.claude/agents/regression-tester.md` | Behavior preservation verification, performance comparison | general-purpose |
| modernization-reviewer | `.claude/agents/modernization-reviewer.md` | Cross-validation, consistency verification | general-purpose |

## Workflow

### Phase 1: Preparation (Performed directly by Orchestrator)

1. Extract from user input:
    - **Target Code/System**: Codebase or system information to modernize
    - **Target Architecture** (optional): Desired technology stack/patterns to migrate to
    - **Constraints** (optional): Downtime tolerance, budget, timeline
    - **Existing Documentation** (optional): Architecture documents, analysis reports, etc.
2. Create `_workspace/` directory at the project root
3. Organize input and save to `_workspace/00_input.md`
4. If the target codebase is accessible, **detect its existing build/test commands** and record them in `_workspace/00_input.md` (detect from `package.json` scripts, `Makefile`, `pom.xml`, `build.gradle`, CI configuration, etc. — the Phase 3 verification gate uses these commands). If detection is not possible, record "verification command not detected"
5. If existing files are available, copy them to `_workspace/` and skip the corresponding Phase
6. Determine **execution mode** based on the scope of the request (see "Modes by Task Scale" below)

### Phase 2: Team Assembly and Execution

| Order | Task | Assignee | Dependencies | Deliverable |
|-------|------|----------|-------------|-------------|
| 1 | Legacy Analysis | analyzer | None | `_workspace/01_legacy_analysis.md` |
| 2 | Refactoring Strategy | strategist | Task 1 | `_workspace/02_refactoring_strategy.md` |
| 3 | Migration Execution Plan | engineer | Tasks 1, 2 | `_workspace/03_migration_plan.md` |
| 4 | Regression Testing | tester | Tasks 1, 3 | `_workspace/04_test_report.md` |
| 5 | Final Review | reviewer | Tasks 1-4 | `_workspace/05_review_report.md` |

**Inter-team Communication Flow:**
- analyzer completes -> delivers tech debt, hotspots, and dependencies to strategist; delivers tech stack and business logic to engineer; delivers current coverage to tester
- strategist completes -> delivers roadmap and migration mapping to engineer; delivers Phase completion criteria to tester
- engineer completes -> delivers Before/After and verification points to tester
- tester completes -> requests fixes from engineer if regressions are found
- reviewer cross-validates all deliverables. When RED Must Fix items are found, requests fixes from the relevant agent -> rework -> re-verification (up to 2 times)

**Real-file output rule**: In Migration Mode, the engineer must not finish with transformed code existing only as code blocks in `_workspace/03_migration_plan.md` — apply the changes to the target project's actual files. If the target codebase is not writable, save the transformed code as real files under `_workspace/migrated_src/` and specify the intended target paths — the Phase 3 verification gate needs real artifacts to check.

### Phase 3: Verification Gate (Performed directly by Orchestrator in the main context — do NOT delegate to subagents)

Independent of the tester's regression test report, actually run the commands and confirm they pass. This gate applies **only when actual code changes occurred** (e.g., Migration Mode). Document-only runs (Analysis/Strategy Mode, etc.) skip the gate and record "verification gate not applicable (document-only)" in the final report.

1. Run the target project's build/test commands recorded in `_workspace/00_input.md` during Phase 1 against the modified code and check the actual output
2. On failure, fix the errors directly and re-run — repeat until passing
3. If the same error repeats 3 times, change approach. If the fix requires design changes such as the migration strategy or target architecture, report to the user instead of auto-fixing
4. If it ultimately cannot pass, record remaining errors in TODO.md and state them in the final report
5. If no verification command was detected or no execution environment exists, never mark it as passing — record it in TODO.md, and when substituting with static analysis, never mark the overall verdict GREEN (YELLOW Conditional + note "Dynamic verification not possible")
6. Never bypass the gate by deleting or commenting out failing tests, narrowing the verification command, or loosening the build configuration
7. Proceed to Phase 4 only after confirming a pass

### Phase 4: Integration and Final Deliverables

1. Check all files in `_workspace/`
2. Verify that all RED Must Fix items from the review report have been addressed
3. Report the final summary to the user

## Modes by Task Scale

| User Request Pattern | Execution Mode | Deployed Agents |
|---------------------|----------------|-----------------|
| "Modernize the legacy code", "Full refactoring" | **Full Pipeline** | All 5 agents |
| "Analyze technical debt", "Diagnose code health" | **Analysis Mode** | analyzer + reviewer |
| "Create a refactoring strategy" (existing analysis available) | **Strategy Mode** | strategist + reviewer |
| "Migrate this code" (strategy available) | **Migration Mode** | engineer + tester + reviewer |
| "Verify the migration" | **Test Mode** | tester + reviewer |

**Leveraging Existing Files**: If the user provides analysis reports, strategy documents, etc., the corresponding step is skipped.

## Data Transfer Protocol

| Strategy | Method | Purpose |
|----------|--------|---------|
| File-based | `_workspace/` directory | Store and share main deliverables |
| Message-based | SendMessage | Real-time delivery of key information, fix requests |
| Task-based | TaskCreate/TaskUpdate | Progress tracking, dependency management |

File naming convention: `{order}_{agent}_{deliverable}.{extension}`

## Error Handling

| Error Type | Strategy |
|-----------|----------|
| Code inaccessible | Inference-based analysis from user-provided information, note "Limited Access" in report |
| No test environment | Substitute with static analysis and code review-based verification — but never mark the overall verdict GREEN (YELLOW Conditional + note "Dynamic verification not possible") |
| Build/test errors | Orchestrator directly runs the build/test commands recorded in `00_input.md` -> analyze errors -> fix -> re-verify (Phase 3 gate) |
| Agent failure | Retry once -> if fails, proceed without that deliverable, note omission in review |
| RED found in review | Request fix from relevant agent -> rework -> re-verify (up to 2 times) |
| Circular dependency unresolvable | Insert Anti-Corruption Layer to isolate, then resolve incrementally |

## Test Scenarios

### Normal Flow
**Prompt**: "Modernize a legacy web app based on jQuery + Express.js to React + NestJS"
**Expected Result**:
- Analysis: jQuery dependency mapping, Express route structure analysis, technical debt inventory
- Strategy: Strangler Fig pattern, frontend-first migration roadmap
- Migration: jQuery -> React component transformation, Express -> NestJS controller transformation
- Testing: DOM manipulation behavior preservation, API compatibility, performance comparison
- Review: Full consistency verification across all items

### Existing File Utilization Flow
**Prompt**: "Create a refactoring strategy based on this analysis report" + analysis report attached
**Expected Result**:
- Copy existing report to `_workspace/01_legacy_analysis.md`
- Strategy mode: only strategist + reviewer deployed
- analyzer is skipped

### Error Flow
**Prompt**: "Refactor this code" (only code snippet provided, no full context)
**Expected Result**:
- Start in analysis mode, perform inference-based analysis with limited information
- Note in report: "Partial code-based analysis — full system context unverified"
- Ask user for additional information if needed

## Agent Extension Skills

| Skill | Path | Enhanced Agent | Role |
|-------|------|---------------|------|
| strangler-fig-patterns | `.claude/skills/strangler-fig-patterns/skill.md` | refactoring-strategist, migration-engineer | Detailed implementation of incremental migration patterns (Strangler Fig, Branch by Abstraction, Parallel Run, ACL) |
| dependency-analysis | `.claude/skills/dependency-analysis/skill.md` | legacy-analyzer, refactoring-strategist | Dependency graph analysis, coupling/cohesion metrics, circular dependency detection and resolution |
