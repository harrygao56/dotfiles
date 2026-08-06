---
name: wta
description: Hand off a feature we just scoped in this conversation to a fresh agent running in its own git worktree and tmux pane. Distills the agreed scope, decisions, and file-level findings into a seed file, then spawns the worker via the `wta` fish function. Use when the user says "spin this up", "hand this off", "go build this", "start on this in a worktree", or otherwise wants the scoped work continued as a separate agent.
---

# wta — worktree agent handoff

Spawn a fresh coding agent in a new git worktree + tmux pane, seeded with the context we
scoped in this conversation. Must run inside tmux and a git repo (the function enforces both).
The point of this skill is the handoff file; `wta` handles the worktree/pane/launch.

## Steps

1. **Write the handoff to a temp file** (`seed=$(mktemp -t wta)`). It must let a cold agent
   start without re-scoping or re-exploring. Include:
   - **Goal** — what's being built and why.
   - **Locked decisions** — choices made and alternatives rejected, so it doesn't relitigate.
   - **File-level findings** — exact paths, symbols, line numbers (the highest-value part).
   - **Plan** — the ordered steps / PR stack.
   - **Gotchas** — anything non-obvious (caching, migrations, flags, size limits).
   - **First action.**

   Be specific to what was actually agreed; don't invent scope.

2. **Pick a branch:** `harrygao/<short-kebab-slug>`.

3. **Spawn it** (default agent `codex`; use `claude` only if asked). Inline the real absolute
   seed path — do not pass a `$var` into `fish -c` (it'd expand inside fish, not the caller).
   Run with the sandbox disabled (tmux socket + worktree path are outside it):

   ```
   fish -c 'wta <branch> --agent <codex|claude> --seed /abs/path/from/mktemp.md'
   ```

   `wta` is a fish autoload function and the Bash tool runs zsh, so always go through `fish -c`.

4. **Report** the branch, worktree path, and agent. The new agent is independent — this
   session doesn't manage it.
