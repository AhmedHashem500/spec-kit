---
description: Run the whole Spec Kit workflow in the owner's fixed order (specify, clarify, discover, plan, tasks, analyze, external review gate, implement, converge), resuming from whatever stage each feature has reached and stopping only at the owner's decision points.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). It may be empty ("continue"), one
feature description, several feature descriptions (one per line or numbered), a feature directory name to
focus on, or an answer to a question you asked in the previous turn.

## Purpose

The owner gives one command and the agent drives every Spec Kit step in order, without the owner naming
the next command. The agent **never skips a step and never passes an owner gate on its own**. State is
always derived from the files on disk, never from memory of an earlier turn, so the command can be re-run
at any time and resumes exactly where the work stopped.

Talk to the owner in Egyptian Arabic with English technical terms in Latin script. Open every stop with
one line: the feature, the step just finished, and the next step.

## Step order (fixed)

| # | Stage | Command run by you | Done when (file evidence) | Owner gate? |
|---|-------|--------------------|---------------------------|-------------|
| 1 | specify | `/speckit-specify <description>` | `FEATURE_DIR/spec.md` exists | Only if the spec has `[NEEDS CLARIFICATION]` markers it could not resolve |
| 2 | clarify | `/speckit-clarify` | `spec.md` contains a `## Clarifications` section with a `### Session` entry, **or** the clarify run reported no material ambiguity and you appended `### Session <date>` with the line `- No material ambiguities found.` | **Yes**: each question, one at a time |
| 2b | discover | `/speckit-ahmed-discover` | `FEATURE_DIR/discovery.md` exists with an owner decision on every proposed feature (or `Not applicable`), and `docs/design/direction.md` names the chosen style once the project has a UI | **Yes**: the owner picks one of up to 10 styles (choice page, home + one inner screen each) and ticks the competitor features to add |
| 3 | plan | `/speckit-plan` | `FEATURE_DIR/plan.md` exists and has no unresolved `NEEDS CLARIFICATION` | **Yes**: owner approves the technology choice before step 4 (first feature of a project, or whenever the plan introduces a new dependency or service) |
| 4 | checklist | `/speckit-checklist <domain>` | `FEATURE_DIR/checklists/<domain>.md` exists | No, but run it **only** when the spec touches sync, encryption, credentials, privacy, payments or health/finance data; domain = `security` and/or `sync`. Otherwise mark the stage "not applicable" |
| 5 | tasks | `/speckit-tasks` | `FEATURE_DIR/tasks.md` exists | No |
| 6 | analyze | `/speckit-analyze` | `FEATURE_DIR/checks/analyze-<YYYYMMDD-HHMM>.md` exists and is newer than spec.md, plan.md and tasks.md | **Yes** if it reports any CRITICAL or HIGH finding: list them with your recommendation, apply only what the owner accepts, then re-run analyze. LOW/MEDIUM only: apply the obvious fixes, report them, continue |
| 7 | review gate | `/speckit-ahmed-review-gate` | `FEATURE_DIR/external-review/APPROVED.md` exists and its hashes match | **Yes**: the gate builds the package and stops; the owner pastes ChatGPT's review back; owner approves explicitly |
| 8 | implement | `/speckit-implement` | every checkbox in `tasks.md` is `[x]`, and the test/build commands named in plan.md pass with output shown | Report at the end with evidence |
| 9 | converge | `/speckit-converge` | converge appended no new tasks | No. If it appended tasks, go back to step 8 for those tasks only |
| 10 | done | none | all above | Report the feature as done with evidence; move to the next feature |

`/speckit-analyze` writes no file by itself. After running it, **you** save its full report verbatim to
`FEATURE_DIR/checks/analyze-<YYYYMMDD-HHMM>.md` (create `checks/` if missing), so the stage is detectable.

## Execution flow

1. **Project ready?** Check that `.specify/` exists, that `.specify/memory/constitution.md` contains no
   `[ALL_CAPS]` placeholder tokens, and that `.specify/extensions.yml` registers `speckit.ahmed.review-gate`
   under `before_implement`. If the constitution still has placeholders, run `/speckit-constitution` first
   (derive project principles from the repository's docs; ask the owner only what the docs do not answer),
   then continue. If `.specify/` is missing, stop and tell the owner the project is not initialised.

2. **Build the feature list.** Work from the branch of the highest-numbered feature (`git branch --list
   '[0-9][0-9][0-9]-*'`), since branches are stacked. List every directory under `specs/` whose name starts with three digits
   (`001-...`). For each, derive its stage from the table above by checking the "Done when" evidence in
   order; the first stage whose evidence is missing is the feature's current stage. Show the list as one
   line per feature: `<dir>: <current stage>`.

3. **New features in the input?** If the user input contains feature descriptions that do not match an
   existing feature, create them first, one at a time, with `/speckit-specify` (in the order given).
   **Stacked branches:** before each specify run, check out the branch of the highest-numbered existing
   feature (or the main branch when there is none), so the new feature branch starts from it. Each feature
   then sees every earlier spec under `specs/` (a branch cut from main would see none, and sequential
   numbering would collide) and builds on the earlier features' code, matching the foundations-first
   order. Never discard uncommitted work to switch — if there is any, commit the finished step or stop
   and ask. Merging the stack into the main branch happens only with the owner's approval.

   **Empty input and no features yet** (a fresh project): do not invent features. Read the repository's
   docs (README, `docs/`, any plan, roadmap or checklist file) and propose the feature list for the first
   phase as one numbered list, each item one line, in the order you recommend building them (foundations
   first), with your recommendation marked. If the docs give nothing to propose from, ask the owner one
   question: what is the first thing this project must do? End your turn; his answer becomes the input of
   the next run.

4. **Choose what to advance (batch rule).** When several features exist:
   - First bring **every** feature through stages 1-2b (specify, clarify, discover). Later features often reveal what
     an earlier, foundational feature is missing; fix that in the earlier spec before planning it.
   - Then take features **one at a time in numeric order** through stages 3-10. A later feature never
     passes stage 8 before an earlier one is done, unless the owner says otherwise.
   - If the input names a feature directory, advance only that feature.

5. **Switch to the feature.** Check out the feature's git branch if one exists (the `git` extension's
   `before_specify` hook creates it; its name is usually the directory name). Then write
   `.specify/feature.json` as `{"feature_directory": "specs/<dir>"}` so every later script resolves this
   feature, and read it back. Never switch branches with uncommitted changes; commit the finished step
   first (see step 7) or stop and ask.

6. **Run the stage.** Invoke the stage's command exactly as listed and follow that command's own
   instructions fully (including its mandatory hooks). Then re-check the "Done when" evidence from disk and
   show it (file path + the line or check output that proves it).
   - Stage passed and no owner gate: continue immediately with the next stage of the same feature, in the
     same turn.
   - Owner gate reached: ask **one** question (or present the gate's package) with your recommendation
     marked, and **end your turn**. On the next run, treat the owner's message as the answer to that gate.
   - Stage failed (script error, missing prerequisite, test failure): stop, show the raw error, give one
     recommended fix. Do not jump to a later stage to work around it.

7. **Commit each finished stage** on the feature branch with a message that says why, e.g.
   `spec(001-shell): clarify session 2026-11-01`. If the commit landed on an earlier feature's branch while
   later stacked branches exist, propagate it up the stack in order with `git merge --no-edit <earlier>`
   on each later branch (merge, never rebase or reset), and show the result. Never push, never merge to the main branch, never commit
   credential values; these stay with the owner.

8. **Stop points summary.** You stop and wait for the owner only at: clarify questions; the discover style pick and feature ticks; unresolved
   `[NEEDS CLARIFICATION]` after specify; technology approval in plan; CRITICAL/HIGH analyze findings; the
   external review gate (package ready, then explicit approval); the end-of-implementation report; any
   failure. Everywhere else you keep going.

9. **End of every turn**: print the feature list from step 2 again with each feature's stage, and the one
   next step. If all features are done, say so and suggest the next backlog item only if the repository's
   docs list one.

## Rules

- The order in the table is fixed. Never skip clarify, discover, analyze or the review gate, and never write
  `APPROVED.md` yourself outside `/speckit-ahmed-review-gate`.
- Never edit `.claude/skills/speckit-*` or `.specify/templates/*` in a project; process changes belong in the
  Ahmed fork (`ahmed/extension`, `ahmed/preset`).
- Evidence before claims: every "done" shows the file or command output that proves it.
