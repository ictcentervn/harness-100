---
name: data-migration
description: "Full migration pipeline where an agent team collaborates to perform source analysis, schema mapping, transformation script generation, validation query design, and rollback planning. Use this skill for requests like 'data migration', 'DB migration', 'data transfer', 'schema conversion', 'database migration plan', 'ETL scripts', 'data transition', 'DB migration validation', 'system cutover', etc. Note: real-time CDC streaming setup, cloud infrastructure provisioning, and application code migration are outside the scope of this skill."
---

# Data Migration — Full Migration Pipeline

An agent team collaborates to perform source analysis, schema mapping, transformation script generation, validation queries, and rollback planning.

## Execution Mode

**Agent Team** — Five agents communicate directly via SendMessage and perform cross-validation.

## Agent Composition

| Agent | File | Role | Type |
|-------|------|------|------|
| source-analyst | `.claude/agents/source-analyst.md` | Source analysis, data profiling | general-purpose |
| schema-mapper | `.claude/agents/schema-mapper.md` | Schema mapping, transformation rule design | general-purpose |
| script-developer | `.claude/agents/script-developer.md` | ETL scripts, performance optimization | general-purpose |
| validation-engineer | `.claude/agents/validation-engineer.md` | Validation queries, integrity tests | general-purpose |
| rollback-planner | `.claude/agents/rollback-planner.md` | Rollback planning, emergency response | general-purpose |

## Workflow

### Phase 1: Preparation (performed directly by the orchestrator)

1. Extract the following from user input:
    - **Source system**: DBMS type, version, connection info, schema scope
    - **Target system**: DBMS type, version, existing schema availability
    - **Migration scope**: Full/partial, target tables, data time range
    - **Constraints**: Allowable downtime, performance requirements, schedule
2. Create the `_workspace/` directory and subdirectories
3. Organize the input and save it to `_workspace/00_input.md`
4. If pre-existing files are available, copy them to `_workspace/` and skip the corresponding phase
5. **Determine the execution mode** based on the scope of the request

### Phase 2: Team Assembly and Execution

| Order | Task | Owner | Dependencies | Deliverable |
|-------|------|-------|-------------|-------------|
| 1 | Source analysis | source-analyst | None | `01_source_analysis.md` |
| 2 | Schema mapping | schema-mapper | Task 1 | `02_schema_mapping.md` |
| 3a | Transformation scripts | script-developer | Task 2 | `03_migration_scripts/` |
| 3b | Validation suite | validation-engineer | Tasks 1, 2 | `04_validation_suite.md` |
| 4 | Rollback plan | rollback-planner | Tasks 1, 2, 3a, 3b | `05_rollback_plan.md` |

Tasks 3a (scripts) and 3b (validation) run **in parallel**.

**Inter-agent communication flow:**
- source-analyst completes > passes source schema to schema-mapper, volume/order to script-developer, integrity rules to validation-engineer
- schema-mapper completes > passes mapping spec to script-developer, transformation rules to validation-engineer, reverse mapping feasibility to rollback-planner
- script-developer completes > passes transaction boundaries to rollback-planner
- validation-engineer completes > passes rollback trigger conditions to rollback-planner
- rollback-planner develops the overall plan and feeds back risk items to each agent

**Scaffold rule**: Executable code must always be saved as real files (`.py`) in `_workspace/03_migration_scripts/` — never delivered only as code blocks embedded in `.md` documents. script-developer states the verification command (`python3 -m py_compile *.py`) in `_workspace/03_migration_scripts/README.md`. The verification gate (Phase 3) determines apply/skip by the presence of this directory.

### Phase 3: Verification Gate (executed directly by the orchestrator in the main context — do NOT delegate to subagents)

Independent of each agent's deliverable document review, actually run the command and confirm it passes:

1. Check that the `_workspace/03_migration_scripts/` directory exists. If absent (analysis/mapping/validation/rollback-only or other no-code modes), skip the gate and record "gate not applicable (no-code mode)" in the final report
2. If present, run `python3 -m py_compile _workspace/03_migration_scripts/*.py` and check the actual output — this is syntax-level verification that works without DBs or third-party packages. Actually executing the ETL requires the user's source/target DBs and is outside the gate's scope
3. On failure, fix the errors directly and re-run — repeat until passing
4. If the same error repeats 3 times, change approach. If the fix requires schema mapping/transformation rule or other design changes, report to the user instead of auto-fixing
5. If it ultimately cannot pass, record remaining errors in TODO.md and state them in the final report
6. Never bypass the gate by deleting failing files, commenting out code, or reverting real files back to document code blocks
7. Proceed to Phase 4 only after confirming a pass (0 errors) or a legitimate skip

### Phase 4: Integration and Final Deliverables

1. Verify all deliverables in `_workspace/`
2. Validate cross-deliverable consistency (mapping vs. scripts, validation vs. mapping, rollback vs. scripts)
3. Present the final migration execution checklist to the user

## Execution Modes by Request Scope

| User Request Pattern | Execution Mode | Agents Deployed |
|---------------------|---------------|----------------|
| "Full migration plan" | **Full pipeline** | All 5 agents |
| "Analyze the source DB only" | **Analysis mode** | source-analyst only |
| "Just do schema mapping" | **Mapping mode** | source-analyst + schema-mapper |
| "Generate ETL scripts only" | **Script mode** | script-developer (assumes mapping exists) |
| "Create validation queries only" | **Validation mode** | validation-engineer (assumes mapping exists) |
| "Just create a rollback plan" | **Rollback mode** | rollback-planner (assumes full analysis exists) |

**Reusing existing files**: If the user provides existing DDL, ERD, or schema mapping documents, copy those files to the appropriate location in `_workspace/` and skip the corresponding agent.

## Data Transfer Protocol

| Strategy | Method | Purpose |
|----------|--------|---------|
| File-based | `_workspace/` directory | Deliverable documents |
| Script-based | `_workspace/03_migration_scripts/` | Executable code |
| Message-based | SendMessage | Key information transfer, feedback |

## Error Handling

| Error Type | Strategy |
|-----------|----------|
| DB connection unavailable | Fall back to DDL/ERD document-based analysis |
| Target schema undecided | Auto-generate recommended target schema based on source |
| Incompatible types | Propose two-stage conversion via intermediate type |
| Very large tables (>100M rows) | Partition-level migration strategy |
| Script syntax errors | Orchestrator runs `python3 -m py_compile` directly → analyze errors → fix → re-verify (Phase 3 gate) |
| Agent failure | Retry once; if still failing, proceed without that deliverable |

## Test Scenarios

### Normal Flow
**Prompt**: "Create a plan to migrate an e-commerce DB from MySQL 5.7 to PostgreSQL 16"
**Expected result**:
- Source analysis: MySQL schema reverse-engineering, data profiling, dependency graph
- Schema mapping: MySQL to PostgreSQL type mapping, auto-increment to sequence conversion, character set handling
- Scripts: Python ETL code, batch processing, index management SQL
- Validation: Row count, checksum, FK integrity, transformation accuracy queries
- Rollback: Backup strategy, Go/No-Go criteria, step-by-step rollback procedures

### Existing File Reuse Flow
**Prompt**: "Map this DDL file to a PostgreSQL target only"
**Expected result**:
- source-analyst parses the DDL for schema analysis
- schema-mapper generates the PostgreSQL target mapping
- script-developer, validation-engineer, and rollback-planner are not deployed

### Error Flow
**Prompt**: "Migrate from Oracle to MongoDB" (RDBMS to NoSQL)
**Expected result**:
- source-analyst analyzes the relational structure
- schema-mapper proposes an RDBMS-to-document model conversion strategy (denormalization, embedding vs. references)
- Many irreversible transformations arise > rollback-planner develops an archive preservation strategy


## Agent Extension Skills

| Skill | Path | Enhanced Agent | Role |
|-------|------|---------------|------|
| type-mapping-encyclopedia | `.claude/skills/type-mapping-encyclopedia/skill.md` | schema-mapper | MySQL/Oracle/PostgreSQL type mapping, RDBMS-to-NoSQL, character set conversion |
| data-validation-patterns | `.claude/skills/data-validation-patterns/skill.md` | validation-engineer | 5-level validation (count > schema > value > referential > business), Go/No-Go checklist |
