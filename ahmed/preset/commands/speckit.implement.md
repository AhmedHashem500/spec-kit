<!-- ahmed-preset:implement-gate -->
## Owner approval gate (Ahmed preset, runs BEFORE everything below)

Implementation is blocked until the owner has approved this feature after an external review.

1. Run `{SCRIPT}` from repo root and parse `FEATURE_DIR` (absolute path).
2. Check whether `FEATURE_DIR/external-review/APPROVED.md` exists. Show the check's output.
3. If it does **not** exist: do **not** implement anything, do not touch any source file, and do not run the rest of this command. Run `__SPECKIT_COMMAND_AHMED_REVIEW-GATE__` instead and follow it; it packs spec, plan and tasks for the external review and stops for the owner. End your turn when it stops.
4. If it exists: still let the mandatory `before_implement` hook (`__SPECKIT_COMMAND_AHMED_REVIEW-GATE__`) run as described under Pre-Execution Checks; it verifies the approval is not stale (spec.md or plan.md changed after approval). Continue with implementation only if it reports the approval as valid.

<!-- ahmed-preset:owner-rules -->
## Owner rules (Ahmed preset, apply throughout this command)

- **Reply language**: talk to the owner in Egyptian Arabic. Technical terms, identifiers, commands, file names and paths stay in English, in Latin script; never transliterate them into Arabic letters.
- **spec.md language**: when writing or editing `spec.md`, all user-facing prose (summaries, user stories, scenarios, requirements, success criteria, edge cases) is in Arabic. Identifiers, code, field names, file paths, requirement IDs (FR-001, SC-001) and headings that templates or scripts parse stay in English.
- **Many decisions**: when presenting more than about 6 decisions or questions, show them as one numbered list with your recommendation marked on each, then ask about them **one at a time**; never ask several open questions in one message.
- **Evidence before claims**: never say a file was written, a check passed, or a step is done without showing the evidence (the command output, or the file read back).
