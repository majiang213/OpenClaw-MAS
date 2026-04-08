---
name: cmd_skill_health
description: "Audit all installed OpenClaw skills for missing frontmatter fields, stub descriptions, and format compliance. Reports a health dashboard."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [--fix]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Skill Health Dashboard

Scans all skills installed in `~/.openclaw/skills/` (and optionally in
`<project-path>/skills/`) and reports a health summary: required frontmatter
fields, stub descriptions, and format compliance.

## Usage

```
/skill cmd_skill_health <project-path>         # Audit installed skills
/skill cmd_skill_health <project-path> --fix   # Audit and suggest fixes
```

## What to Do

### Step 1: Locate skill directories

Scan two locations:

1. **Installed skills**: `~/.openclaw/skills/`
2. **Project skills**: `<project-path>/skills/`

For each location, find all SKILL.md files:

```bash
find ~/.openclaw/skills/ -name "SKILL.md" 2>/dev/null
find <project-path>/skills/ -name "SKILL.md" 2>/dev/null
```

If both locations are empty, report: "No skills found." Stop.

### Step 2: Parse each SKILL.md

For each SKILL.md, extract frontmatter fields by reading the YAML block between
the opening and closing `---` lines. Check for:

**Required fields:**
- `name` — must be present and non-empty
- `description` — must be present, non-empty, and not a stub
- `user-invocable` — must be `true` or `false`
- `origin` — must be present
- `argument-hint` — must be present (may be empty string for no-arg skills)

**Stub detection** — flag description as a stub if it:
- Is shorter than 20 characters
- Matches a generic pattern like `"<skill-name> workflow"`, `"<skill-name> command"`,
  `"TODO"`, `"..."`, or is identical to the skill name

### Step 3: Categorize each skill

Assign one of three statuses:

- **PASS** — all required fields present and non-stub
- **WARN** — `argument-hint` missing (added later, not always present in older skills)
- **FAIL** — `name`, `description`, `user-invocable`, or `origin` missing, or description is a stub

### Step 4: Display the dashboard

```
============================================================
  SKILL HEALTH DASHBOARD
  Scanned: ~/.openclaw/skills/ + <project-path>/skills/
  Total skills: <N>
============================================================

PASS  (<count>)
──────────────────────────────────────────────────────────
  ✓  cmd_save_session        "Save current session state..."
  ✓  cmd_evolve              "Cluster MEMORY.md entries..."
  ...

WARN  (<count>)  — missing argument-hint
──────────────────────────────────────────────────────────
  ⚠  some_old_skill          "Does something useful"

FAIL  (<count>)  — missing fields or stub description
──────────────────────────────────────────────────────────
  ✗  broken_skill            MISSING: description
  ✗  stub_skill              STUB: "stub_skill workflow"

============================================================
  Summary: <PASS> passed · <WARN> warnings · <FAIL> failed
============================================================
```

### Step 5: If --fix is NOT passed

Print suggested next steps:

```
To fix FAIL items:
  - Edit the SKILL.md file and add missing fields
  - Replace stub descriptions with accurate one-liners

To add missing argument-hint to WARN items:
  - Add: argument-hint: "<project-path> [options]"
  - Or:  argument-hint: "" (for skills with no arguments)

Run with --fix to see per-skill fix suggestions inline.
```

### Step 6: If --fix IS passed

For each WARN or FAIL skill, print an inline fix suggestion:

```
FIX NEEDED: ~/.openclaw/skills/some_old_skill/SKILL.md
  Add after `origin:` line:
    argument-hint: "<project-path>"

FIX NEEDED: <project-path>/skills/broken_skill/SKILL.md
  Add to frontmatter:
    description: "<accurate one-liner describing what this skill does>"
```

Do not modify any files automatically — only print suggestions.

## Notes

- This skill reads files directly; it does not call any external CLI or script
- Only SKILL.md files are scanned — agent AGENTS.md, hook HOOK.md, etc. are out of scope
- A skill with `user-invocable: false` is still checked for all required fields
- The `argument-hint` field may be an empty string `""` for skills that take no arguments — this is valid (PASS)
