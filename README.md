# Personal Claude Code Configuration

This repository contains my personal configuration for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview), Anthropic's agentic coding tool. It's version-controlled so that settings, custom agents, skills, slash commands, and hooks stay portable and reproducible across machines.

## Repository Structure

```
~/.claude/
├── CLAUDE.md       # Global behavioral guidelines, loaded into every session
├── settings.json   # Global configuration (permissions, hooks, plugins, env)
├── agents/         # Custom sub-agent definitions (.md files)
├── commands/       # Custom slash commands (.md files)
├── skills/         # Reusable skill packages (folders with SKILL.md)
└── hooks/          # Custom hook scripts (statusline, etc.)
```

- **`CLAUDE.md`** — User-level memory. Behavioural guidelines (think before coding, keep changes surgical, favour simplicity) that Claude loads automatically in every project, merged with any project-specific `CLAUDE.md`.
- **`settings.json`** — Central config: permissions, hooks, enabled plugins, environment variables, and update preferences.
- **`agents/`** — Each `.md` file defines a sub-agent with its own system prompt, tool access, and model. Agents are spawned by Claude Code to handle specialized tasks autonomously.
- **`commands/`** — Each `.md` file becomes a `/slash-command`. The filename is the command name (e.g., `review.md` → `/review`). Commands typically delegate to an agent or provide a prompt template.
- **`skills/`** — Each subfolder is a skill package containing a `SKILL.md` and optional `references/` or `scripts/` directories. Skills give Claude domain-specific knowledge and workflows that activate based on context.
- **`hooks/`** — Scripts invoked by Claude Code hooks. Contains `statusline.sh`, which renders the status bar (directory, git branch, context usage, rate-limit usage, model, vim mode). Other hooks are defined inline in `settings.json` (see below).

> Directories like `plugins/`, `sessions/`, `cache/`, `file-history/`, and `projects/` are generated at runtime and excluded via `.gitignore`. Enabled plugins are declared in `settings.json` under `enabledPlugins`, which is the only plugin state worth version-controlling.

## Configuration

### settings.json

| Setting                             | Value        | Purpose                                                         |
| ----------------------------------- | ------------ | --------------------------------------------------------------- |
| `includeCoAuthoredBy`               | `false`      | Omit co-author trailers from commits                            |
| `autoUpdatesChannel`                | `latest`     | Track the latest release channel                                |
| `tui`                               | `fullscreen` | Flicker-free alt-screen renderer with virtualized scrollback    |
| `cleanupPeriodDays`                 | `90`         | Retain session transcripts for 90 days before cleanup           |
| `skillListingBudgetFraction`        | `0.02`       | Larger context budget for the skill listing (better triggering) |
| `skipDangerousModePermissionPrompt` | `true`       | Bypass-mode opt-in dialog already acknowledged                  |
| `skipAutoPermissionPrompt`          | `true`       | Auto-mode opt-in dialog already acknowledged                    |
| `DISABLE_TELEMETRY`                 | `1`          | Opt out of non-essential telemetry (env)                        |

### Permissions

`defaultMode` is `auto` — Claude Code routes each tool call through a classifier that
allows safe operations, blocks genuinely dangerous ones, and only prompts for the
ambiguous middle. The explicit allow / ask / deny rules act as deterministic
guardrails on top of that:

- **Allow** — File reads/writes, web access, common shell utilities (`ls`, `tree`, `find`, `grep`, `rg`, `diff`, `wc`, etc.), and a full set of non-destructive git commands (`status`, `log`, `diff`, `show`, `branch`, `add`, `commit`, `blame`, `checkout`, `merge`, `rebase`, etc.)
- **Ask** — Potentially destructive or network-mutating commands that require confirmation: `rm`, `mv`, `cp`, `curl`, `wget`, `sudo`, `docker`, `git push`, `git pull`
- **Deny** — All `.env` files are blocked from read and edit. A `PreToolUse` hook (below) closes the same gap for the Bash tool.

### Hooks

Defined inline in `settings.json`:

- **`PreToolUse` (Bash)** — Inspects each Bash command and denies it if it references a `.env` file, so `cat .env` / `grep KEY .env` can't sidestep the `Read`/`Edit` deny rules.
- **`Notification`** — Plays a sound (`Ping`) only when the notification is a permission prompt; idle and other notifications stay silent.
- **`Stop`** — Plays a sound (`Funk`) when Claude finishes a turn.

### Plugins

Enabled plugins are declared in `settings.json` under `enabledPlugins` (see that
file for the authoritative list). They cover language-server integration
(go-to-definition, references, diagnostics) for the languages I work in, plus
skills such as `frontend-design` for UI work. Install with `/plugin` or
`claude plugin install <name>@<marketplace>`.

## Usage

`~/.claude` already exists on any machine where Claude Code has run, and git refuses to
clone into a non-empty directory. So the repo is cloned alongside and its `.git` directory
moved into place, then checked out over the existing files:

```sh
if [ -d "$HOME/.claude/.git" ]; then
  echo "already cloned: $HOME/.claude"
else
  git clone https://github.com/aleckshen/.claude.git "$HOME/.claude.tmp"
  mkdir -p "$HOME/.claude"
  mv "$HOME/.claude.tmp/.git" "$HOME/.claude/"
  rm -rf "$HOME/.claude.tmp"
  git -C "$HOME/.claude" checkout -- .
fi
```

The whitelist `.gitignore` means the checkout leaves runtime state (`projects/`,
`sessions/`, `cache/`, …) untouched, but it does overwrite tracked files with the
committed versions — commit local tweaks before re-running it.

My dotfiles bootstrap runs this automatically when setting up a new machine.

Claude Code picks up `settings.json` and the directory structure automatically. Most
changes (permissions, most hooks, `CLAUDE.md`) hot-reload, but **new LSP plugins and
some hooks require a session restart** to take effect.

## Links

- [Claude Code Overview](https://docs.anthropic.com/en/docs/claude-code/overview)
- [Settings Reference](https://docs.anthropic.com/en/docs/claude-code/settings)
- [Sub-agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks-guide)
- [Slash Commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands)
- [Plugins](https://docs.anthropic.com/en/docs/claude-code/plugins)
