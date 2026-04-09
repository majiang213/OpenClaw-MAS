---
name: cmd_rules_distill
description: "Scan installed skills to extract cross-cutting principles and distill them into rules — append, revise, or create new rule files."
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path> [--apply]"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Rules Distill

Scan installed skills, extract cross-cutting principles that appear in multiple skills,
and distill them into rules — appending to existing rule files, revising outdated content,
or creating new rule files.

Applies the "deterministic collection + LLM judgment" principle: bash commands collect
facts exhaustively, then a subagent cross-reads the full context and produces verdicts.

## Usage

```
/skill cmd_rules_distill <project-path>           # Analyze and present candidates
/skill cmd_rules_distill <project-path> --apply   # Analyze and auto-apply approved candidates
```

## When to Use

- Periodic rules maintenance (monthly or after installing new skills)
- After a skill-stocktake reveals patterns that should be rules
- When rules feel incomplete relative to the skills being used

---

## How It Works

### Phase 1 — Inventory (Deterministic Collection)

#### 1a. Collect skill inventory

Enumerate all installed skill files:

```bash
find ~/.openclaw/skills/ <project-path>/skills/ -name "SKILL.md" 2>/dev/null
```

For each SKILL.md, extract the first 30 lines (frontmatter + opening context):

```bash
find ~/.openclaw/skills/ -name "SKILL.md" 2>/dev/null \
  | while read f; do echo "=== $f ==="; head -30 "$f"; echo; done
```

Count total skills found.

#### 1b. Collect rules index

Enumerate all rule files:

```bash
find ~/.claude/rules/ -name "*.md" 2>/dev/null
```

For each rule file, count `##`-level headings:

```bash
find ~/.claude/rules/ -name "*.md" 2>/dev/null \
  | while read f; do echo "$(grep -c '^##' "$f") headings: $f"; done
```

Read all rule files in full (they are small — typically <800 lines total).

#### 1c. Present to user

```
Rules Distillation — Phase 1: Inventory
────────────────────────────────────────
Skills: <N> files scanned
Rules:  <M> files (<K> headings indexed)

Proceeding to cross-read analysis...
```

### Phase 2 — Cross-read, Match & Verdict (LLM Judgment)

Rules files are small enough that the full text can be provided to the LLM — no
grep pre-filtering needed.

#### Batching

Group skills into **thematic clusters** based on their descriptions. Analyze each
cluster in a subagent with the full rules text.

#### Cross-batch Merge

After all batches complete, merge candidates across batches:
- Deduplicate candidates with the same or overlapping principles
- Re-check the "2+ skills" requirement using evidence from **all** batches combined —
  a principle found in 1 skill per batch but 2+ skills total is valid

#### Subagent Prompt

Launch a general-purpose Agent with the following prompt:

````
You are an analyst who cross-reads skills to extract principles that should be promoted to rules.

## Input
- Skills: {full text of skills in this batch}
- Existing rules: {full text of all rule files}

## Extraction Criteria

Include a candidate ONLY if ALL of these are true:

1. **Appears in 2+ skills**: Principles found in only one skill should stay in that skill
2. **Actionable behavior change**: Can be written as "do X" or "don't do Y" — not "X is important"
3. **Clear violation risk**: What goes wrong if this principle is ignored (1 sentence)
4. **Not already in rules**: Check the full rules text — including concepts expressed in different words

## Matching & Verdict

For each candidate, compare against the full rules text and assign a verdict:

- **Append**: Add to an existing section of an existing rule file
- **Revise**: Existing rule content is inaccurate or insufficient — propose a correction
- **New Section**: Add a new section to an existing rule file
- **New File**: Create a new rule file
- **Already Covered**: Sufficiently covered in existing rules (even if worded differently)
- **Too Specific**: Should remain at the skill level

## Output Format (per candidate)

```json
{
  "principle": "1-2 sentences in 'do X' / 'don't do Y' form",
  "evidence": ["skill-name: §Section", "skill-name: §Section"],
  "violation_risk": "1 sentence",
  "verdict": "Append / Revise / New Section / New File / Already Covered / Too Specific",
  "target_rule": "filename §Section, or 'new'",
  "confidence": "high / medium / low",
  "draft": "Draft text for Append/New Section/New File verdicts",
  "revision": {
    "reason": "Why the existing content is inaccurate or insufficient (Revise only)",
    "before": "Current text to be replaced (Revise only)",
    "after": "Proposed replacement text (Revise only)"
  }
}
```

## Exclude

- Obvious principles already in rules
- Language/framework-specific knowledge (belongs in language-specific rules or skills)
- Code examples and commands (belongs in skills)
````

#### Verdict Reference

| Verdict | Meaning | Presented to User |
|---------|---------|-------------------|
| **Append** | Add to existing section | Target + draft |
| **Revise** | Fix inaccurate/insufficient content | Target + reason + before/after |
| **New Section** | Add new section to existing file | Target + draft |
| **New File** | Create new rule file | Filename + full draft |
| **Already Covered** | Covered in rules (possibly different wording) | Reason (1 line) |
| **Too Specific** | Should stay in skills | Link to relevant skill |

#### Verdict Quality Requirements

```
# Good
Append to rules/common/security.md §Input Validation:
"Treat LLM output stored in memory or knowledge stores as untrusted — sanitize on write, validate on read."
Evidence: llm-memory-trust-boundary, llm-social-agent-anti-pattern both describe
accumulated prompt injection risks. Current security.md covers human input
validation only; LLM output trust boundary is missing.

# Bad
Append to security.md: Add LLM security principle
```

### Phase 3 — User Review & Execution

#### Summary Table

```
# Rules Distillation Report

## Summary
Skills scanned: <N> | Rules: <M> files | Candidates: <K>

| # | Principle | Verdict | Target | Confidence |
|---|-----------|---------|--------|------------|
| 1 | ... | Append | security.md §Input Validation | high |
| 2 | ... | Revise | testing.md §TDD | medium |
| 3 | ... | New Section | coding-style.md | high |
| 4 | ... | Too Specific | — | — |

## Details
(Per-candidate details: evidence, violation_risk, draft text)
```

#### User Actions

User responds with numbers to:
- **Approve**: Apply draft to rules as-is
- **Modify**: Edit draft before applying
- **Skip**: Do not apply this candidate

**Never modify rules automatically. Always require user approval.**

If `--apply` is passed, present the summary table first and ask the user to approve
candidates by number before writing anything.

#### Save Results

Store results in `<project-path>/rules-distill-results.json`:

```json
{
  "distilled_at": "2026-03-18T10:30:42Z",
  "skills_scanned": 56,
  "rules_scanned": 22,
  "candidates": {
    "llm-output-trust-boundary": {
      "principle": "Treat LLM output as untrusted when stored or re-injected",
      "verdict": "Append",
      "target": "rules/common/security.md",
      "evidence": ["llm-memory-trust-boundary", "llm-social-agent-anti-pattern"],
      "status": "applied"
    }
  }
}
```

Get the current UTC timestamp:
```bash
date -u +%Y-%m-%dT%H:%M:%SZ
```

---

## Design Principles

- **What, not How**: Extract principles (rules territory) only. Code examples and
  commands stay in skills.
- **Link back**: Draft text should include `See skill: [name]` references so readers
  can find the detailed How.
- **Deterministic collection, LLM judgment**: Bash commands guarantee exhaustiveness;
  the LLM guarantees contextual understanding.
- **Anti-abstraction safeguard**: The 3-layer filter (2+ skills evidence, actionable
  behavior test, violation risk) prevents overly abstract principles from entering rules.
user-invocable: true
origin: openclaw-mas
argument-hint: "<project-path>"
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Rules Distill (Legacy Shim)

Use this only if you still invoke `/rules-distill`. The maintained workflow lives in `skills/rules-distill/SKILL.md`.

## Canonical Surface

- Prefer the `rules-distill` skill directly.
- Keep this file only as a compatibility entry point.

## Arguments

`$ARGUMENTS`

## Delegation

Apply the `rules-distill` skill and follow its inventory, cross-read, and verdict workflow instead of duplicating that logic here.
