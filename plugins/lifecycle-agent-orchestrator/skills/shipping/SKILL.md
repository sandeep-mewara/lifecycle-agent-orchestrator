---
name: shipping
description: >
  Shipping workflow for platform services. Use this skill when creating pull requests,
  pushing code for review, updating Jira tickets to reflect PR status, or completing the ship cycle
  for a feature or bugfix. Trigger this skill when the user says things like "open a PR," "create a
  pull request," "ship this," "push for review," "update the ticket," "mark this as ready for review,"
  or "I'm done with this feature" — even if they don't explicitly say "shipping." Also trigger when
  the user wants to transition a Jira ticket status after code changes are ready.
---

# Shipping

You handle the shipping workflow: creating pull requests and keeping Jira tickets in sync. The goal is to make shipping frictionless while ensuring nothing gets lost between code and project tracking.

See PROJECT.md for the specific repository, branch conventions, Jira project, CI pipeline, and deployment details.

---

## Workflow Overview

The shipping workflow has two parts that usually happen together:

1. **Open a PR** — via `gh` CLI command or GitHub MCP
2. **Update Jira** — via Jira MCP (transition status, add comment with PR link)

You can run either part independently. If the user says "open a PR" without mentioning Jira, just do the PR. If they say "update the ticket," just do the Jira update. When they say "ship this" or "I'm done," do both.

---

## Step 1: Pre-Ship Checks

Before creating a PR, verify the basics. Don't skip these — a failed PR wastes everyone's time.

**Check the working tree:**
- Run `git status` — are there uncommitted changes? If so, ask the user if they want to commit first.
- Run `git diff <base-branch>...HEAD` — confirm there are actual changes to ship.
- Check the branch name follows the project's convention (see PROJECT.md). If it doesn't, mention it but don't block — the user may have a reason.

**Check the basics:**
- Are there tests for the new code? A quick `git diff --name-only <base-branch>...HEAD` to see if test files are in the diff.
- Does the branch have a clean commit history? Multiple "WIP" or "fix typo" commits are fine — squash happens at merge.

**Extract context:**
- Identify the Jira ticket from the branch name (e.g., `feature/PROJ-1234` → `PROJ-1234`).
- Run `git log <base-branch>...HEAD --oneline` to understand the full set of changes for the PR description.

If a pre-ship check reveals a problem (no tests, uncommitted changes, no changes vs base), tell the user clearly and ask how they want to proceed. Don't block them — they may be opening a draft PR intentionally.

---

## Step 2: Create the Pull Request

You have two methods available. Use whichever is appropriate for the context.

### Method A: `gh` CLI (preferred for local workflow)

Use the `gh` CLI when working locally and the branch is already pushed (or needs to be pushed).

```bash
# Push the branch if not already pushed
git push -u origin HEAD

# Create the PR
gh pr create --title "<title>" --body "<body>" --base <base-branch>
```

### Method B: GitHub MCP (preferred when working with remote context)

Use the GitHub MCP tool when:
- You're working in a context where `gh` CLI may not be available
- You need more control over PR parameters (draft, maintainer_can_modify)
- The repo context is remote (e.g., different org or fork)

### PR Title and Description

**Title format:** Keep it short (under 70 chars). Include the Jira ticket if available.
- `PROJ-1234: Add year-end summary report generation`
- `PROJ-5678: Fix null pointer in profile fetch`

**Description template:**

```markdown
## Summary
[1-3 bullet points describing what changed and why]

## Jira
[PROJ-XXXX](https://your-jira.atlassian.net/browse/PROJ-XXXX)

## Changes
- [Key change 1]
- [Key change 2]

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing done (describe if applicable)

## Checklist
- [ ] No PII or secrets in code or logs
- [ ] Follows project conventions
- [ ] New endpoints have auth checks
- [ ] Observability added for new critical paths
```

Adapt this template to the actual changes — don't include sections that aren't relevant. A one-line bugfix doesn't need a full checklist. Use judgment. See PROJECT.md for project-specific checklist items.

---

## Step 3: Update Jira Ticket

After the PR is created, update the Jira ticket to reflect the current status. This keeps the team's project board accurate.

### Determine the Jira ticket

In order of preference:
1. The user explicitly provides the ticket key
2. Extract from the branch name (e.g., `feature/PROJ-1234` → `PROJ-1234`)
3. Extract from commit messages (look for ticket key patterns)
4. Ask the user — don't guess

### Transition the ticket status

Use the Jira MCP to discover valid transitions, then apply the appropriate one.

**Typical transitions:**
- When PR is opened → transition to **"In Review"** or **"Ready for Review"** (depends on project workflow)
- When PR is merged → transition to **"Done"** or **"Closed"** (usually handled by CI automation, but confirm)

Always check available transitions first — don't assume a transition name exists. Workflow configurations vary across projects.

**Before transitioning:** Tell the user what transition you're about to make and get confirmation. Changing ticket status is visible to the team.

### Add a comment with the PR link

Add a comment linking the PR to the ticket:

```markdown
## PR Opened

**PR:** [#<number> <title>](<pr-url>)
**Branch:** `<branch-name>`
**Base:** `<base-branch>`

### Changes
- <summary of changes from PR description>
```

This creates a traceable link between the ticket and the code change.

### Update other fields (if applicable)

When the user requests specific field updates:
- **Fix version** — if the user specifies which release this targets
- **Labels** — if the team uses labels for tracking (e.g., `needs-review`)
- **Assignee** — if the reviewer should be assigned

Don't update fields the user didn't ask to update. Don't guess field values.

---

## Confirmation and Summary

After completing the workflow, provide a clear summary of what was done:

```
## Shipped

**PR:** [#<number> <title>](<pr-url>)
**Branch:** `<branch>` → `<base>`
**Jira:** [PROJ-XXXX](<jira-url>) — transitioned to "<status>", comment added with PR link

### What's next
- PR needs review from the team
- CI pipeline will run (see PROJECT.md for pipeline details)
- After merge, automation handles ticket transition (if configured)
```

---

## Handling Edge Cases

**No Jira ticket found:**
- Create the PR anyway — not every change has a ticket.
- Mention that no Jira ticket was updated. Ask if there's a ticket they want to link.

**PR already exists for this branch:**
- Check with `gh pr list --head <branch>` or the GitHub MCP.
- If a PR exists, tell the user and offer to update it instead of creating a duplicate.

**Branch not pushed:**
- Push first with `git push -u origin HEAD`, then create the PR.
- If the push fails (e.g., remote branch conflicts), surface the error and let the user resolve it.

**Draft PR:**
- If the user says "open a draft" or the work is explicitly incomplete, create the PR as draft.
- In the Jira comment, note that it's a draft PR.

**Multiple tickets in one PR:**
- If the branch or commits reference multiple tickets, ask which ticket(s) to update.
- Add the PR comment to all relevant tickets.

**Jira transition fails:**
- If the transition isn't available (e.g., ticket is already in the target status), tell the user what status the ticket is currently in and what transitions are available.
- Don't retry silently — the user needs to know.

---

## What NOT to Do

- **Don't push to the default branch directly.** All changes go through PRs.
- **Don't merge the PR.** Your job is to open it. Merging is a team decision after review.
- **Don't transition tickets without confirmation.** Status changes are visible to the team and affect sprint boards. Always confirm with the user first.
- **Don't fabricate PR descriptions.** Base the description on actual changes (`git log`, `git diff`). Don't invent requirements or changes that aren't in the diff.
- **Don't update Jira fields you weren't asked to update.** Updating the wrong field (e.g., story points, priority) can disrupt sprint planning.
- **Don't include secrets, tokens, or PII in PR descriptions or Jira comments.** Even if they appear in the code (which they shouldn't), don't propagate them to PR or Jira text.
