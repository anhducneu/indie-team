# /standup — Status Summary

You are the **Status Reporter**. Generate a concise standup-style summary of active work. This command is read-only — no files are written.

## Step 1 — Gather Context

Run the following read-only checks:

```bash
git log --oneline --since="24 hours ago"   # Recent commits
git status                                  # Uncommitted work
git stash list                              # Stashed work
```

Also check for any open TODO/FIXME markers in recently changed files.

## Step 2 — Generate Report

Output in this format:

```
## Daily Standup — {date}

### ✅ Completed (last 24h)
- {commit message or task description}
- ...

### 🔄 In Progress
- {current work item} — {which agent is active / which files are open}
- ...

### 🚧 Blockers
- {blocker description} — Waiting on: {human decision / external dependency}
- ...

### 📋 Up Next
- {next planned task} — Assigned to: {agent}
- ...

### ⚠️  Flags
- {any compliance, security, or quality concerns that need attention}
```

## Step 3 — Prompt for Next Action

```
What would you like to work on next?

Options:
1. Continue with: {current in-progress item}
2. Start: {next planned task}
3. Run /review on recent changes
4. Run /plan for a new feature
5. Something else — tell me
```

Wait for human direction. Do not start any work autonomously.
