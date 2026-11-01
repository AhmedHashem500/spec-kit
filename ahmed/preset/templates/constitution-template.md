# [PROJECT_NAME] Constitution
<!-- ahmed-preset:constitution -->
<!-- Base principles I-IX come from the Ahmed preset and apply to every project of this owner. Do not weaken them per project; add project rules in the PROJECT-SPECIFIC slots below. -->

## Core Principles

### I. Zero Cost (NON-NEGOTIABLE)
The project uses free services and tools only. No dependency, API, cloud resource or account may be added if it can ever bill the owner (no card on file, no pay-as-you-go tier, no "free trial" that converts). A paid option is allowed only with the owner's explicit written approval recorded in the plan.

### II. No Secrets in the Repository, the App or the Logs (NON-NEGOTIABLE)
Credential values (passwords, PINs, OTPs, phone numbers, API keys, tokens, signing keys, card data) never appear in source, committed files, build outputs, the shipped app, logs or chat. Code reads them by key from gitignored local files or environment variables injected at runtime. No hard-coded or blank-password accounts.

### III. Evidence Before Claims
Nothing is reported as done, fixed, passing or working without the actual command output (test run, build, lint, screenshot) shown alongside the claim. Numbers in reports are copied from generated output, never typed from memory.

### IV. Real Tests, Watched Failing Once
Every new function gets a real test with a real assertion on behaviour. Each new test is seen failing once (before the implementation, or by a deliberate mutation) before it is trusted. A test that cannot fail is removed, not kept.

### V. Minimal Complexity
Build the simplest thing that meets the approved spec. No speculative abstractions, layers, plugins or configuration for needs that are not in the spec. Any added complexity is justified in the plan's Complexity Tracking table.

### VI. Production Quality Only
No placeholders, pseudocode, TODO stubs, fake data paths or "temporary" shortcuts in delivered code. Errors are handled at their root cause, never suppressed to make a check pass.

### VII. Owner Approval Gates (NON-NEGOTIABLE)
No implementation starts before (a) the owner approves the spec and the plan, and (b) spec, plan and tasks pass an external review whose result the owner explicitly approves, recorded in `specs/<feature>/external-review/APPROVED.md`. A change to spec.md or plan.md after approval invalidates that approval.

### VIII. Arabic-First UX (where the project has a user interface)
User-facing text is Arabic first, laid out right-to-left, with Latin digits (0-9) for all numbers, dates, prices and phone numbers. Mixed Arabic/English text, icons and directional arrows are checked in RTL. A project without a UI marks this principle "Not applicable".

### IX. Owner Communication
The agent talks to the owner in Egyptian Arabic with English technical terms in Latin script. spec.md user-facing prose is Arabic; identifiers, code and paths are English. Decisions are presented as a numbered list with a marked recommendation, one question at a time.

## Project-Specific Principles
<!-- PROJECT-SPECIFIC SLOT: add the rules that only this project needs (domain, platform, data, compliance). Remove unused slots. -->

### [PROJECT_PRINCIPLE_1_NAME]
[PROJECT_PRINCIPLE_1_DESCRIPTION]
<!-- PROJECT-SPECIFIC SLOT. Example: X. Offline First - every core flow works without network; sync is best-effort -->

### [PROJECT_PRINCIPLE_2_NAME]
[PROJECT_PRINCIPLE_2_DESCRIPTION]
<!-- PROJECT-SPECIFIC SLOT. Example: XI. Health Data Stays Local - patient data never leaves the device unencrypted -->

## Technology and Constraints
<!-- PROJECT-SPECIFIC SLOT: stack, supported platforms and versions, storage, hosting (free tiers only, per Principle I). -->

[TECH_CONSTRAINTS]

## Development Workflow
Spec, then clarify, then plan, then tasks, then external review gate (`/speckit-ahmed-review-gate`), then implement. All work happens on a branch; nothing merges to the main branch without the owner's approval.
<!-- PROJECT-SPECIFIC SLOT: add CI, release or device-testing steps for this project. -->

[WORKFLOW_ADDITIONS]

## Governance
This constitution supersedes other practices in this project. Principles I-IX are the owner's base rules and change only by the owner's explicit decision, applied to the Ahmed preset itself. Project-specific principles change through `/speckit-constitution` with a version bump (MAJOR: a principle removed or redefined; MINOR: a principle or section added; PATCH: wording). Every plan's Constitution Check covers all principles.

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
