---
name: cli-tool-builder
description: "Full pipeline where an agent team collaborates to develop a CLI tool. Use this skill for requests like 'build me a CLI tool', 'command-line tool development', 'CLI utility', 'terminal tool', 'command-line program', 'CLI app build', 'shell tool development', and other CLI tool development tasks. Also supports design-only mode when only command design is needed. Note: GUI app development, web dashboard construction, and IDE plugin development are outside the scope of this skill."
---

# CLI Tool Builder — CLI Tool Development Pipeline

An agent team collaborates to develop CLI tools through command design > parser implementation > handlers > testing > documentation > deployment.

## Execution Mode

**Agent Team** — Five agents communicate directly via SendMessage and perform cross-validation.

## Agent Composition

| Agent | File | Role | Type |
|-------|------|------|------|
| command-designer | `.claude/agents/command-designer.md` | Command structure design | general-purpose |
| core-developer | `.claude/agents/core-developer.md` | Core implementation | general-purpose |
| test-engineer | `.claude/agents/test-engineer.md` | Test writing | general-purpose |
| docs-writer | `.claude/agents/docs-writer.md` | Documentation writing | general-purpose |
| release-engineer | `.claude/agents/release-engineer.md` | Build, deployment | general-purpose |

## Workflow

### Phase 1: Preparation (performed directly by the orchestrator)

1. Extract the following from user input:
    - **Tool purpose**: What the CLI does
    - **Language/Runtime**: Python/Node.js/Go/Rust (default: Python)
    - **Key features**: List of core subcommands
    - **Distribution channel**: PyPI/npm/Homebrew/binary
    - **Constraints** (optional): Dependency limitations, compatible OS, performance requirements
2. Create the `_workspace/` directory at the project root
3. Organize the input and save it to `_workspace/00_input.md`
4. Create the `_workspace/src/` directory
5. If pre-existing files are available, copy them to `_workspace/` and skip the corresponding phase
6. **Determine the execution mode** based on the scope of the request

### Phase 2: Team Assembly and Execution

| Order | Task | Owner | Dependencies | Deliverable |
|-------|------|-------|-------------|-------------|
| 1 | Command structure design | designer | None | `_workspace/01_command_design.md` |
| 2 | Core implementation | developer | Task 1 | `_workspace/02_core_implementation.md` + `src/` |
| 3a | Test writing | tester | Task 2 | `_workspace/03_test_suite.md` + `src/tests/` |
| 3b | Documentation | docs | Tasks 1, 2 | `_workspace/04_documentation.md` |
| 4 | Release configuration | release | Tasks 2, 3a | `_workspace/05_release_config.md` + CI files |

Tasks 3a (testing) and 3b (documentation) run **in parallel**.

**Inter-agent communication flow:**
- designer completes > passes command schema to developer, passes --help drafts to docs
- developer completes > passes mock points to tester, passes API to docs, passes build info to release
- tester completes > passes bug reports to developer (if any), passes CI test config to release
- docs completes > passes README path to release
- release integrates all deliverables to complete the deployment pipeline

**Real-file save / scaffold rules**:
- developer and tester must save executable code as real files in `_workspace/src/` (tests in `_workspace/src/tests/`) — never finish a deliverable with code embedded in `.md` documents only
- For Node.js output, when generating package.json always include a `"verify": "tsc --noEmit"` script (`node --check`-based for plain JS) — the compile gate (global Stop hook) opts in based on the presence of this script. For Python/Go/Rust, the Phase 3 verification gate covers verification

### Phase 3: Verification Gate (executed directly by the orchestrator in the main context — do NOT delegate to subagents)

Independent of the tester's test writing, actually run the commands and confirm they pass. Per-language verify commands:

| Language | verify command | Run from |
|----------|---------------|----------|
| Python (default) | `python -m compileall _workspace/src && python -m pytest _workspace/src/tests` | Project root |
| Node.js | `npm run verify` (`npx tsc --noEmit` for TypeScript) | `_workspace/src/` |
| Go | `go vet ./... && go test ./...` | `_workspace/src/` |
| Rust | `cargo check && cargo test` | `_workspace/src/` |

1. Run the verify command for the output language from the table above and check the actual output
2. On failure, fix the errors directly and re-run — repeat until passing
3. If the same error repeats 3 times, change approach. If the fix requires changes to the command structure, interfaces, or other design decisions, report to the user instead of auto-fixing
4. If it ultimately cannot pass, record remaining errors in TODO.md and state them in the final report — never mark a failing result as passing
5. Never bypass the gate by deleting or skipping tests, adding `# type: ignore`/`@ts-ignore`, or loosening lint configuration
6. In modes that produce no code (design mode, deploy mode, etc.), skip the gate and record "N/A". However, in code-producing modes an empty `_workspace/src/` counts as a failure, not a skip
7. Proceed to Phase 4 only after confirming a pass (0 errors)

### Phase 4: Integration and Final Deliverables

1. Validate consistency between documentation and code
2. Report the final summary to the user (including the Phase 3 gate results)

## Execution Modes by Request Scope

| User Request Pattern | Execution Mode | Agents Deployed |
|---------------------|---------------|----------------|
| "Build me a CLI tool", "full development" | **Full pipeline** | All 5 agents |
| "Just design the command structure" | **Design mode** | designer only |
| "Add a subcommand to this CLI" | **Extension mode** | designer + developer + tester |
| "Write tests for this CLI" | **Test mode** | tester only |
| "Just set up deployment" | **Deploy mode** | release only |

## Data Transfer Protocol

| Strategy | Method | Purpose |
|----------|--------|---------|
| File-based | `_workspace/` directory | Design documents and configuration sharing |
| Message-based | SendMessage | Real-time key information transfer, bug reports |
| Code-based | `_workspace/src/` | Executable source code |

## Error Handling

| Error Type | Strategy |
|-----------|----------|
| Tool purpose unclear | Research similar CLI tools via WebSearch, propose 3 candidates |
| Language not specified | Default to Python (typer), state reasoning and alternatives |
| Build/type (syntax) errors | Orchestrator runs the per-language verify command directly > analyze errors > fix > re-verify (Phase 3 gate) |
| Test failure | Send bug report to developer, retest after fix (up to 2 rounds) > if unresolved, treat as a Phase 3 gate failure and record in TODO.md (never mark as passing) |
| Cross-platform build failure | Switch affected OS build to CI-only, present local build alternatives |
| Agent failure | Retry once > if still failing, proceed without that deliverable and state it in the final report (the Phase 3 gate is never skipped) |

## Test Scenarios

### Normal Flow
**Prompt**: "Build a file conversion CLI tool in Python. Support JSON/YAML/TOML conversion"
**Expected result**:
- Command design: `convert [input] --from json --to yaml --output out.yaml`
- Core: typer-based, parser + conversion logic + output formatter
- Testing: Each conversion combination, invalid format input, pipe input
- Documentation: README + installation + quick start + full command reference
- Release: pyproject.toml + GitHub Actions CI + PyPI deployment

### Existing File Reuse Flow
**Prompt**: "Just add tests and docs to this CLI code" + CLI source code attached
**Expected result**:
- Copy existing source code to `_workspace/src/`
- Skip designer and developer; deploy tester + docs + release
- Analyze existing code's command structure to generate tests and documentation

### Error Flow
**Prompt**: "Build me a CLI" (purpose unclear)
**Expected result**:
- designer requests tool purpose clarification from user
- Present 3 examples of similar popular CLI tools
- Proceed with remaining pipeline after purpose is confirmed

## Agent Extension Skills

Extension skills that enhance agent domain expertise:

| Skill | File | Target Agent | Role |
|-------|------|-------------|------|
| arg-parser-generator | `.claude/skills/arg-parser-generator/skill.md` | command-designer, core-developer | Argument type classification, subcommand patterns, per-language parser boilerplate, help text standard |
| ux-linter | `.claude/skills/ux-linter/skill.md` | test-engineer, docs-writer | CLI UX 12 principles, error message standards, output format guide, color/interaction patterns |
