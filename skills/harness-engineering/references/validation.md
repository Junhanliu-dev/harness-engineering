# Phase 11: Validation (Dry Run)

After all generation and wiring is complete, validate end-to-end.

## Final Wiring Verification

| # | Check | Command | Expected |
|---|-------|---------|----------|
| 1 | Rules auto-load | `ls -la .claude/rules/harness-*` | 3 symlinks |
| 2 | Skills discoverable | `ls -la .claude/skills/harness-*` | 5 symlinks |
| 3 | Agents registered | `ls -la .claude/agents/harness-*` | 2 symlinks |
| 4 | Hooks configured | `cat .claude/settings.json \| grep harness` | Hook entries |
| 5 | Symlinks valid | `readlink .claude/rules/harness-structure.md` | Points to harness/ |
| 6 | Hooks executable | `test -x harness/hooks/check-layer-boundaries.sh` | Exit 0 |
| 7 | Pipeline state template | `cat harness/changes/_template/pipeline-state.md` | Template content |
| 8 | CLAUDE.md updated | `grep "harness" CLAUDE.md` | Reference found |
| 9 | Build command works | `{build_command}` | Exit 0 |
| 10 | Test command works | `{test_command}` | Exit 0 with count > 0 |
| 11 | Skill folder/name parity | `for f in harness/skills/*/SKILL.md; do dir=$(basename $(dirname "$f")); name=$(grep '^name:' "$f" \| awk '{print $2}'); [ "$dir" = "$name" ] \|\| echo "MISMATCH $dir != $name"; done` | No output (all match) |

## End-to-End Checks

1. **Trace a simple requirement** through all 10 stages mentally
2. **Verify all cross-references resolve:**
   - pipeline.md references skills → skills exist
   - agent.md references rules → rules exist
   - coding SKILL.md references specs → specs exist
   - sub-agents reference skills → skills exist
   - **every skill folder name equals its SKILL.md `name:` frontmatter**
3. **Check for contradictions:**
   - coding-standards.md vs. layer specs (no conflicts?)
   - pipeline gates vs. development-process (aligned?)
4. **Test hooks:**
   - Create a file violating layer boundaries → hook blocks
   - Attempt push at Stage 2 → gate blocks
5. **Session resumption test:**
   - Create a pipeline-state.md at Stage 3
   - Run `/harness-run` → it should resume, not restart

Report: "Harness validated. {N} checks passed, {M} issues found: {list}"
