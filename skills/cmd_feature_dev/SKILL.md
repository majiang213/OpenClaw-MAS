---
name: cmd_feature_dev
description: "Guided feature development: explore codebase → design architecture → implement → review"
user-invocable: true
origin: openclaw-mas
---

## Project Path

The first argument is the project path. Before doing anything else:

1. Extract the project path from the first argument
2. Verify the path exists
3. Work within that directory for all file operations and shell commands

# Feature Development

A structured feature-development workflow that emphasizes understanding existing code before writing new code.

## Phases

### 1. Discovery

- Read the feature request carefully
- Identify requirements, constraints, and acceptance criteria
- Ask clarifying questions if the request is ambiguous

### 2. Codebase Exploration

Delegate to the `code-explorer` agent:

Include in the task payload:
- Project path
- The feature or area to explore
- Relevant files or modules if known

First, reply to the user briefly, then call sessions_spawn:
```json
{
  "agentId": "code-explorer",
  "sessionKey": "code-explorer",
  "task": "<project path and exploration request>",
  "runTimeoutSeconds": 0
}
```

### 3. Clarifying Questions

- Present findings from exploration
- Ask targeted design and edge-case questions
- Wait for user response before proceeding

### 4. Architecture Design

Delegate to the `code-architect` agent:

Include in the task payload:
- Project path
- Feature request and exploration findings
- Any constraints or preferences

```json
{
  "agentId": "code-architect",
  "sessionKey": "code-architect",
  "task": "<project path, feature request, and exploration findings>",
  "runTimeoutSeconds": 0
}
```

Wait for approval before implementing.

### 5. Implementation

- Implement the feature following the approved design
- Prefer TDD where appropriate
- Keep commits small and focused

### 6. Quality Review

Delegate to the `code-reviewer` agent:

```json
{
  "agentId": "code-reviewer",
  "sessionKey": "code-reviewer",
  "task": "<project path and review request>",
  "runTimeoutSeconds": 0
}
```

### 7. Summary

- Summarize what was built
- List follow-up items or limitations
- Provide testing instructions
