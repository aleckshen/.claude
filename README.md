# Personal Claude Code Configuration

This repository contains my personal configuration for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview), Anthropic's agentic coding tool. It's version-controlled so that settings, custom agents, skills, and slash commands stay portable and reproducible across machines.

## Repository Structure

```
~/.claude/
├── settings.json   # Global configuration (permissions, model, env)
├── agents/         # Custom sub-agent definitions (.md files)
├── commands/       # Custom slash commands (.md files)
├── skills/         # Reusable skill packages (folders with SKILL.md)
├── hooks/          # Custom hook scripts (statusline, etc.)
└── plugins/        # Plugin registry and cached data
```

- **`settings.json`** — Central config: permissions, model defaults, environment variables, and update preferences.
- **`agents/`** — Each `.md` file defines a sub-agent with its own system prompt, tool access, and model. Agents are spawned by Claude Code to handle specialized tasks autonomously.
- **`commands/`** — Each `.md` file becomes a `/slash-command`. The filename is the command name (e.g., `review.md` → `/review`). Commands typically delegate to an agent or provide a prompt template.
- **`skills/`** — Each subfolder is a skill package containing a `SKILL.md` and optional `references/` or `scripts/` directories. Skills give Claude domain-specific knowledge and workflows that activate based on context.
- **`hooks/`** — Custom scripts used by Claude Code hooks and the statusline. Currently contains `statusline.js`, which renders the status bar (directory, branch, context usage, model).
- **`plugins/`** — Managed by the plugin system. `installed_plugins.json` tracks installed plugins; other contents are auto-generated.

> Directories like `sessions/`, `cache/`, `file-history/`, and `projects/` are generated at runtime and excluded via `.gitignore`.

## Configuration

### settings.json

| Setting               | Value    | Purpose                              |
| --------------------- | -------- | ------------------------------------ |
| `effortLevel`         | `high`   | Maximum reasoning effort             |
| `includeCoAuthoredBy` | `false`  | Omit co-author trailers from commits |
| `autoUpdatesChannel`  | `latest` | Track the latest release channel     |
| `DISABLE_TELEMETRY`   | `1`      | Opt out of non-essential telemetry   |

### Permissions

Permissions follow a three-tier model:

- **Allow** — File reads/writes, web access, common shell utilities (`ls`, `tree`, `find`, `grep`, `rg`, `diff`, `wc`, etc.), and a full set of non-destructive git commands (`status`, `log`, `diff`, `show`, `branch`, `add`, `commit`, `blame`, `checkout`, `merge`, `rebase`, etc.)
- **Ask** — Potentially destructive or network-mutating commands that require confirmation: `rm`, `mv`, `cp`, `curl`, `wget`, `sudo`, `docker`, `git push`, `git pull`
- **Deny** — All `.env` files are blocked from read, write, and edit to prevent accidental secret exposure

## Usage

Clone this repo into `~/.claude` (or symlink it):

```sh
git clone <repo-url> ~/.claude
```

Claude Code picks up `settings.json` and the directory structure automatically on next launch — no restart required for most changes.

## Links

- [Claude Code Overview](https://docs.anthropic.com/en/docs/claude-code/overview)
- [Settings Reference](https://docs.anthropic.com/en/docs/claude-code/settings)
- [Sub-agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks-guide)
- [Slash Commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands)
