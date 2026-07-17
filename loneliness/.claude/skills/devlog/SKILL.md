---
name: devlog
description: Register and document completed features in the project devlog. Use when a feature or behavior is finished, when the user says "done"/"complete"/"finished"/"register"/"log this"/"document the change", or when asking what was built so far. Proactively prompt the user to confirm completion and register the feature. The devlog is read at the start of every session to preserve context.
---

# devlog — feature registration

## Purpose

Keep a living record of completed features so no context is lost between sessions. Every new session reads `.claude/devlog.md` first (auto-loaded via `opencode.json` `instructions` in opencode, and via `CLAUDE.md` pointer in Claude Code). This skill governs how entries get added.

## When to register

Register a feature when it is **complete and working**. A feature is a coherent behavior or system, not every tiny edit. Group related edits into one feature set.

Examples of one feature:
- "NPC twitch" (NPCs jitter like the player)
- "Attachment system" (NPCs attach on proximity, lose glow, player glow grows, feedback ring)
- "Pollen repulsion" (pollen flees player within radius)

Examples of NOT a feature (too small, fold into a related entry):
- "changed 0.05 to 0.2" (that's a tweak inside attachment)
- "added a variable" (that's a tunable inside the feature it belongs to)

## Proactive prompt

After finishing a coherent piece of work, **ask the user before registering**. Do not silently log. Use this exact shape:

> Feature looks complete: **[Feature Name]**
> What it is: [one line]
> What it does: [one or two lines]
> Register in devlog? (y/n)

If the user says yes, append an entry. If no, skip. If the user corrects the name or description, use their version.

You propose the feature name and description — the user just confirms or adjusts. The user does not have to write the entry; you do.

## Entry format

Append to `.claude/devlog.md`, newest at the bottom, using this template:

```
## [Feature Name]
- **Date:** YYYY-MM-DD
- **Status:** complete
- **What it is:** one sentence
- **What it does:** one or two sentences on behavior
- **How implemented:** short bullet list — key files, functions, patterns used. Reference file:line where useful.
- **Tunables added:** name = default — what it controls (only if any)
```

Keep entries tight. This file is loaded every session — every line is recurring token cost. State what and where, not how-to tutorials. The `loneliness` skill already covers patterns; don't repeat them here.

## Writing an entry

1. Propose feature name + description to user (the prompt above).
2. On confirm, read `.claude/devlog.md`.
3. Append the new entry at the bottom.
4. Confirm done in one line: "Registered: [Feature Name]".

Do not rewrite or reorder existing entries. Append only. If a feature is revised later, add a new entry noting the change, don't edit the old one.

## Reading at session start

`.claude/devlog.md` is auto-loaded by opencode (`instructions` in `opencode.json`) and pointed to by `CLAUDE.md` for Claude Code. If for some reason it is not in context, read `.claude/devlog.md` before working on the cart. This is the project's memory.

## When NOT to register

- User is mid-feature and steps away → wait until it's done.
- User is just exploring/asking questions → nothing to log.
- A bug fix that's a one-line tweak → fold into the next feature entry, or note it under the original feature if recent.
- User says "don't log this" → don't.
