# Phase 10: Wiring (Connect Harness to Claude Code Runtime)

Generated files are inert until wired into the execution environment. Run these steps in order.

## 10.1 Wire Rules → Auto-loaded Context

```bash
# Create .claude/rules/ if it doesn't exist
mkdir -p .claude/rules

# Symlink harness rules (auto-loaded every session)
ln -sf "$(pwd)/harness/rules/engineering-structure.md" .claude/rules/harness-structure.md
ln -sf "$(pwd)/harness/rules/coding-standards.md" .claude/rules/harness-standards.md
ln -sf "$(pwd)/harness/rules/development-process.md" .claude/rules/harness-process.md
```

## 10.2 Wire Skills → Discoverable Slash Commands

```bash
mkdir -p .claude/skills

# Symlink harness skills
ln -sf "$(pwd)/harness/skills/harness-coding" .claude/skills/harness-coding
ln -sf "$(pwd)/harness/skills/harness-review" .claude/skills/harness-review
ln -sf "$(pwd)/harness/skills/harness-testing" .claude/skills/harness-testing
ln -sf "$(pwd)/harness/skills/harness-requirements" .claude/skills/harness-requirements
ln -sf "$(pwd)/harness/skills/harness-run" .claude/skills/harness-run
```

## 10.3 Wire Sub-Agents → Agent Definitions

```bash
mkdir -p .claude/agents

# Symlink harness agent definitions
ln -sf "$(pwd)/harness/agents/harness-coder.md" .claude/agents/harness-coder.md
ln -sf "$(pwd)/harness/agents/harness-reviewer.md" .claude/agents/harness-reviewer.md
```

These agents are now available for the Agent tool to reference.

## 10.4 Wire Agent Definition → CLAUDE.md

Append to the project's CLAUDE.md:

```markdown
## Harness Engineering

This project uses a Harness Engineering system for AI code quality.

**Always-loaded rules** are symlinked in .claude/rules/harness-*.md

**For any implementation work**, use `/harness-run` to execute the full pipeline.

**Agent definition:** Read `harness/agent.md` for your operating instructions.

**Key principle:** The coder agent and reviewer agent are ALWAYS separate.
Never review your own code in the same invocation that wrote it.
```

## 10.5 Wire Quality Gates → Hooks

Add to `.claude/settings.json` (project-level, create if needed):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/harness/hooks/post-edit-wrapper.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/harness/hooks/pre-push-gate-wrapper.sh\"",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Note on `$HOOK_FILE_PATH`:** The PostToolUse hook receives `tool_input.file_path` in its JSON input. The hook script must parse this from stdin. The harness generates a wrapper that extracts it:

```bash
# harness/hooks/post-edit-wrapper.sh
#!/bin/bash
# Reads hook input JSON from stdin, extracts file_path, runs boundary check
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
  exec bash "$CLAUDE_PROJECT_DIR/harness/hooks/check-layer-boundaries.sh" "$FILE_PATH"
fi
exit 0
```

**IMPORTANT:** All hook commands in `.claude/settings.json` MUST use `$CLAUDE_PROJECT_DIR` to build absolute paths. Hook subprocesses do NOT inherit the project root as cwd — relative paths like `bash harness/hooks/foo.sh` will fail with `No such file or directory` at fire time. Same rule applies inside wrapper scripts when they `exec` other scripts.

## 10.6 Wire Change Tracking

```bash
# Ensure template exists
mkdir -p harness/changes/_template

# The pipeline-state.md template for session resumption
cat > harness/changes/_template/pipeline-state.md << 'EOF'
# Pipeline State: {requirement}

## Status
- Current Stage: 0
- Started: {timestamp}
- Last Updated: {timestamp}
- Total Rollbacks: 0
- Review Rounds: req=0/3, code=0/2, test=0/2

## Stage History
| Stage | Status | Timestamp | Notes |
|-------|--------|-----------|-------|
EOF
```

## 10.7 Make Hooks Executable

```bash
chmod +x harness/hooks/check-layer-boundaries.sh
chmod +x harness/hooks/pre-push-gate.sh
chmod +x harness/hooks/post-edit-wrapper.sh
chmod +x harness/hooks/pre-push-gate-wrapper.sh
```
