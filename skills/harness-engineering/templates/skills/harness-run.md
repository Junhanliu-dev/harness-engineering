---
name: harness-run
description: Execute the harness development pipeline for a requirement
---

# Harness Pipeline Runner

## When to Use
- "Implement this requirement using the harness"
- "Run the full pipeline for this feature"
- "/harness-run <requirement description>"

## Instructions

You are the pipeline orchestrator. For the given requirement, drive it through
all 10 stages defined in `harness/pipeline.md`.

### Before Starting

1. Read `harness/pipeline.md` for stage definitions
2. Check for existing state: look in `harness/changes/` for a matching requirement
   - If found, read `pipeline-state.md` and RESUME from the current stage
   - If not found, create a new directory and start from Stage 1

### Session Resumption

On every invocation, check:
```
ls harness/changes/ | grep -v _template
```

If a directory exists with an in-progress `pipeline-state.md`:
- Read it to find current stage and history
- Announce: "Resuming {requirement} from Stage {N}"
- Continue from that stage (do NOT restart from 1)

### Stage Execution Protocol

For each stage:
1. **Announce:** "## Stage N: {name}"
2. **Update state:** Write current stage to pipeline-state.md
3. **Load context:** Read the skill/agent file specified for this stage
4. **Execute:** Perform work or delegate to sub-agent
5. **Verify gate:** Check the quality gate
6. **Record:** Append result to pipeline-state.md
7. **Decision:**
   - PASS → advance to next stage
   - FAIL → follow rollback path
   - HUMAN → pause and ask user (use AskUserQuestion tool)

### Sub-Agent Delegation

Stages 3-6 use sub-agents for separation of concerns:

**Stage 3 (Coding):**
```
Agent tool:
  prompt: |
    You are the harness-coder.
    Read harness/agents/harness-coder.md for your full instructions.

    REQUIREMENT: {paste requirement from Stage 1 output}
    TASK: {specific sub-task from decomposition}

    When done, write your coding report to:
    harness/changes/{slug}/coding-report.md
```

**Stage 4 (Review):**
```
Agent tool:
  prompt: |
    You are the harness-reviewer.
    Read harness/agents/harness-reviewer.md for your full instructions.

    WHAT TO REVIEW: Read harness/changes/{slug}/coding-report.md to see
    what the coder did. Then read the actual files listed there.

    Write your review to: harness/changes/{slug}/review-record.md
```

**Stage 5 (Testing):**
```
Agent tool:
  prompt: |
    You are the harness-coder in testing mode.
    Read harness/agents/harness-coder.md AND harness/skills/harness-testing/SKILL.md.

    WHAT TO TEST: Read harness/changes/{slug}/coding-report.md to see
    what was implemented. Write tests for those changes.

    Append test report to: harness/changes/{slug}/coding-report.md
```

**Stage 6 (Test Review):**
```
Agent tool:
  prompt: |
    You are the harness-reviewer reviewing tests.
    Read harness/agents/harness-reviewer.md for your instructions.

    WHAT TO REVIEW: The test files created in Stage 5.
    Read harness/changes/{slug}/coding-report.md for the list.

    Check: Are tests meaningful? Do they cover edge cases?
    Do they match project testing patterns in harness/skills/harness-testing/SKILL.md?

    Append review to: harness/changes/{slug}/review-record.md
```

### State File Format

Create `harness/changes/{slug}/pipeline-state.md`:

```markdown
# Pipeline State: {requirement title}

## Status
- Current Stage: {N}
- Started: {ISO timestamp}
- Last Updated: {ISO timestamp}
- Total Rollbacks: {count}
- Review Rounds: req={n}/3, code={n}/2, test={n}/2

## Stage History
| Stage | Status | Timestamp | Notes |
|-------|--------|-----------|-------|
| 1 | PASSED | 2025-01-15T10:00 | Requirements accepted |
| 2 | PASSED | 2025-01-15T10:05 | 1 round, no P0s |
| 3 | IN_PROGRESS | 2025-01-15T10:10 | |
```

### Rollback Protocol

When a gate fails:
1. Identify failure type from gate output
2. Look up rollback target in pipeline.md
3. Update pipeline-state.md (increment rollback counter, record failure)
4. If total rollbacks > 3: STOP and ask human
5. Otherwise: announce rollback target and re-execute from that stage

### Human Checkpoints

At stages marked with human checkpoint in pipeline.md:
- Present a concise summary of what was done
- Use AskUserQuestion tool with options: Approve / Request Changes / Skip
- "Skip" only allowed for stages 9-10
- "Request Changes" triggers rollback with human's feedback as context

### Completion

When Stage 10 passes:
- Update pipeline-state.md with final status: COMPLETE
- Summarize: files changed, tests added, review findings addressed
- Report total rounds and rollbacks
