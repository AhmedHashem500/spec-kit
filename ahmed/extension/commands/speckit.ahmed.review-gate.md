---
description: Pack spec, plan and tasks into one review file for an external reviewer, wait for the owner's review result, and record explicit owner approval before implementation.
scripts:
  sh: .specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: .specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
  py: .specify/scripts/python/check_prerequisites.py --json --require-tasks --include-tasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). It may contain the external review result or the owner's approval.

## Purpose

This is the owner's external review gate. No implementation may start until the owner has had spec, plan and tasks reviewed outside this session (he pastes them to ChatGPT) and has **explicitly** approved the result. This command never approves on its own and never infers approval.

Talk to the owner in Egyptian Arabic with English technical terms in Latin script. Keep file contents in English unless they quote the owner.

## Outline

1. Run `{SCRIPT}` from repo root and parse `FEATURE_DIR`. All paths must be absolute. If the script fails (no feature, or `tasks.md` missing), report the error and stop: there is nothing to review yet.

2. Set `REVIEW_DIR = FEATURE_DIR/external-review`. Create it if missing.

3. **Already approved?** If `REVIEW_DIR/APPROVED.md` exists:
   - Read the `spec.md sha256` and `plan.md sha256` values recorded in it.
   - Compute the current SHA256 of `FEATURE_DIR/spec.md` and `FEATURE_DIR/plan.md` (PowerShell: `(Get-FileHash -Algorithm SHA256 -LiteralPath <file>).Hash.ToLower()`; bash: `sha256sum <file>`). Show the command output.
   - Both match: report "approval valid" with the approval date, and stop. If you were invoked as a `before_implement` hook, implementation may now continue.
   - Any mismatch: the approval is **stale** (spec or plan changed after approval). Tell the owner which file changed, rename the old file to `APPROVED.superseded-<YYYYMMDD-HHMM>.md`, and continue with step 4.
   - `tasks.md` is deliberately not hashed: `/speckit-implement` ticks its checkboxes, which would invalidate every approval.

4. **Owner already returned with a review?** Look at the user input and the conversation since the package was produced. If the owner has pasted a review result (findings, comments, or a verdict from the external reviewer), go to step 6. Otherwise go to step 5.

5. **Build the review package and STOP.**
   - Write `REVIEW_DIR/review-package.md` (overwrite) with exactly this structure:
     1. `# External review package: <feature directory name>`
     2. A line `Generated: <ISO 8601 date-time>` and a line per file with its SHA256.
     3. `## Instructions for the reviewer` containing: "You are reviewing a software feature specification, implementation plan and task list before any code is written. Report, as one numbered list ordered by severity (BLOCKER, MAJOR, MINOR): missing or ambiguous requirements, contradictions between spec, plan and tasks, tasks that do not trace to a requirement, requirements with no task, risky or over-complex design choices, missing tests or acceptance checks, security and privacy issues, and any cost (paid service) the plan introduces. For each item give the file, the section, the problem and a concrete fix. End with a one-line verdict: APPROVE, APPROVE WITH CHANGES, or REJECT."
     4. `## spec.md`, then the full verbatim content of `FEATURE_DIR/spec.md`.
     5. `## plan.md`, then the full verbatim content of `FEATURE_DIR/plan.md`.
     6. `## tasks.md`, then the full verbatim content of `FEATURE_DIR/tasks.md`.
     Wrap each file's content between the lines `<<<<< BEGIN <file> >>>>>` and `<<<<< END <file> >>>>>` (do not use code fences: the files contain their own).
   - Read the written file back and report its absolute path and size.
   - Tell the owner, in Egyptian Arabic: the package is ready at that path, paste it into ChatGPT, then paste the full review result back here.
   - **STOP.** End your turn. Do not continue to implementation, do not approve, do not modify spec, plan or tasks. If you were invoked as a hook from `/speckit-implement`, implementation does **not** continue in this turn.

6. **Process the returned review.**
   - Save the owner's pasted review verbatim to `REVIEW_DIR/review-result-<YYYYMMDD-HHMM>.md`.
   - List the findings as one numbered list, each with your recommendation (apply / reject with reason). Mark your overall recommendation.
   - When there are more than about 6 findings that need a decision, ask about them **one at a time**, each with a marked recommendation; never dump all questions at once.
   - Apply only the changes the owner accepts, to `spec.md`, `plan.md` and/or `tasks.md`. Keep a running list of every applied change (file, section, one-line summary).
   - After the changes, show the owner the list of applied changes and ask one question: does he approve implementation now?

7. **Record approval only on explicit owner approval.**
   - Explicit approval means the owner's own message clearly approves implementing this feature, for example: "approved", "I approve", "موافق", "اعتمد", "ابدأ التنفيذ". Anything ambiguous ("ok", "تمام" with no reference to implementation, thanks, silence, a question) is **not** approval: ask once, plainly, whether he approves implementation.
   - Never write `APPROVED.md` because the reviewer said APPROVE; only the owner approves.
   - On explicit approval, write `REVIEW_DIR/APPROVED.md`:

     ```markdown
     # Owner approval: <feature directory name>

     - Date: <ISO 8601 date-time>
     - Owner's words: "<the owner's approval message, quoted verbatim>"
     - Review result file: <review-result file name, or "none: owner approved without an external review">
     - spec.md sha256: <hash at approval time>
     - plan.md sha256: <hash at approval time>

     ## Changes applied after the external review

     1. <file>: <section>: <summary>
     (or "None")
     ```

   - Compute the hashes **after** all changes are applied, and show the hash command output.
   - Read `APPROVED.md` back and show it. Then tell the owner implementation is unblocked (`__SPECKIT_COMMAND_IMPLEMENT__`).

## Rules

- Never claim the package was written, a change was applied, or approval was recorded without reading the file back and showing the evidence.
- Never edit `APPROVED.md` by hand later; a new approval supersedes it through step 3.
- Never delete review files; superseded approvals are renamed, not removed.
