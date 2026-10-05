#!/usr/bin/env bash

# PreToolUse(Bash) guard. The Read/Edit deny rules in settings.json don't apply to
# shell commands, so without this `cat .env` would sidestep them entirely.

cmd=$(jq -r '.tool_input.command // empty')

# Surrounding non-word chars keep "environment" and "deny-env.sh" from matching.
if printf '%s' "$cmd" | grep -qE '(^|[^a-zA-Z0-9_])\.env([^a-zA-Z0-9_]|$)'; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked: command references a .env file"
  }
}
JSON
fi
