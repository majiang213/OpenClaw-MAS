---
name: cmd_skill_stocktake
description: "Audit all installed OpenClaw skills for quality: content overlap, freshness, and uniqueness. Supports Quick Scan (changed only) and Full Stocktake modes."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [--full]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Skill Stocktake

Audit all installed OpenClaw skills using a quality checklist and AI holistic judgment.
Supports two modes: **Quick Scan** for recently changed skills, and **Full Stocktake**
for a complete review.

## Usage

```
/skill cmd_skill_stocktake <project-path>         # Quick Scan (default if results exist)
/skill cmd_skill_stocktake <project-path> --full  # Force Full Stocktake
```

## Scope

Scans two locations:

| Path | Description |
|------|-------------|
| `~/.openclaw/skills/` | Global installed skills |
| `<project-path>/skills/` | Project-local skills (if the directory exists) |

At the start of Phase 1, explicitly list which paths were found and scanned.

## Modes

| Mode | Trigger | Duration |
|------|---------|---------|
| Quick Scan | Results file exists and `--full` not passed | 5–10 min |
| Full Stocktake | Results file absent, or `--full` passed | 20–30 min |

**Results cache:** `<project-path>/skill-stocktake-results.json`

---

## Quick Scan Flow

Re-evaluate only skills that changed since the last run.

1. Read `<project-path>/skill-stocktake-results.json`
2. Find changed skills by comparing current mtimes to cached mtimes:
   ```bash
   find ~/.openclaw/skills/ <project-path>/skills/ -name "SKILL.md" 2>/dev/null \
     | while read f; do echo "$(stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f") $f"; done
   ```
3. If no files changed since `evaluated_at`: report "No changes since last run." and stop.
4. Re-evaluate only changed skills using the same Phase 2 criteria.
5. Carry forward unchanged skills from previous results.
6. Output only the diff table.
7. Update `<project-path>/skill-stocktake-results.json` with new results.

---

## Full Stocktake Flow

### Phase 1 — Inventory

Enumerate all skill files and extract frontmatter:

```bash
find ~/.openclaw/skills/ <project-path>/skills/ -name "SKILL.md" 2>/dev/null
```

For each SKILL.md, extract:
- `name` (from frontmatter)
- `description` (from frontmatter)
- `origin` (from frontmatter)
- Last modified time: `stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' <file>` (macOS) or `stat -c '%y' <file>` (Linux)
- Line count: `wc -l < <file>`

Present the scan summary:

```
Skill Stocktake — Phase 1: Inventory
──────────────────────────────────────────────────────
Scanning:
  ✓ ~/.openclaw/skills/         (<N> files)
  ✓ <project-path>/skills/      (<M> files)

Total: <N+M> skills
```

Build the inventory table:

| Skill | Origin | Lines | Last Modified | Description |
|-------|--------|-------|---------------|-------------|

### Phase 2 — Quality Evaluation

Launch an Agent tool subagent (general-purpose) with the full inventory and checklist.
Process ~20 skills per subagent invocation to keep context manageable.

For each batch, the subagent evaluates each skill against this checklist:

```
- [ ] Content overlap with other skills checked
- [ ] Overlap with MEMORY.md / CLAUDE.md checked
- [ ] Freshness of technical references verified (use WebSearch if tool names / CLI flags / APIs are present)
- [ ] Usage frequency considered (infer from recency of last modification)
```

The subagent returns per-skill JSON:

```json
{ "verdict": "Keep|Improve|Update|Retire|Merge into [X]", "reason": "..." }
```

**Verdict criteria:**

| Verdict | Meaning |
|---------|---------|
| Keep | Useful and current |
| Improve | Worth keeping, but specific improvements needed |
| Update | Referenced technology is outdated (verify with WebSearch) |
| Retire | Low quality, stale, or cost-asymmetric |
| Merge into [X] | Substantial overlap with another skill; name the merge target |

Evaluation is **holistic AI judgment** — not a numeric rubric. Guiding dimensions:
- **Actionability**: code examples, commands, or steps that let you act immediately
- **Scope fit**: name, trigger, and content are aligned; not too broad or narrow
- **Uniqueness**: value not replaceable by MEMORY.md / CLAUDE.md / another skill
- **Currency**: technical references work in the current environment

**Reason quality requirements** — the `reason` field must be self-contained:
- For **Retire**: state (1) what specific defect was found, (2) what covers the same need instead
- For **Merge**: name the target and describe what content to integrate
- For **Improve**: describe the specific change needed (what section, what action)
- For **Keep** (Quick Scan mtime-only change): restate the original verdict rationale

Save intermediate results to `<project-path>/skill-stocktake-results.json` with
`"status": "in_progress"` after each chunk.

**Resume detection:** If `status: "in_progress"` is found on startup, resume from
the first unevaluated skill.

After all skills are evaluated: set `status: "completed"`, proceed to Phase 3.

### Phase 3 — Summary Table

```
| Skill | Origin | Verdict | Reason |
|-------|--------|---------|--------|
```

### Phase 4 — Consolidation

1. **Retire / Merge**: present detailed justification per file before confirming with user:
   - What specific problem was found (overlap, staleness, broken references, etc.)
   - What alternative covers the same functionality
   - Impact of removal (any dependent skills, MEMORY.md references, or workflows affected)
2. **Improve**: present specific improvement suggestions with rationale
3. **Update**: present updated content with sources checked
4. Check `~/.openclaw/workspace-main/MEMORY.md` line count; propose compression if >100 lines

**Never retire or merge skills without explicit user confirmation.**

---

## Results File Schema

`<project-path>/skill-stocktake-results.json`:

```json
{
  "evaluated_at": "2026-02-21T10:00:00Z",
  "mode": "full",
  "batch_progress": {
    "total": 80,
    "evaluated": 80,
    "status": "completed"
  },
  "skills": {
    "skill-name": {
      "path": "~/.openclaw/skills/skill-name/SKILL.md",
      "verdict": "Keep",
      "reason": "Concrete, actionable, unique value for X workflow",
      "mtime": "2026-01-15T08:30:00Z"
    }
  }
}
```

Get the current UTC timestamp for `evaluated_at`:
```bash
date -u +%Y-%m-%dT%H:%M:%SZ
```

---

## Notes

- Evaluation is blind: the same checklist applies to all skills regardless of origin
- Archive / delete operations always require explicit user confirmation
- No verdict branching by skill origin (ECC, openclaw-mas, community all treated equally)
