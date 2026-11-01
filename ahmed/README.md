# Ahmed customisation of Spec Kit

This folder holds the owner's customisation of [Spec Kit](https://github.com/github/spec-kit) as one
extension and one preset. Nothing outside `ahmed/` is edited, so weekly upstream merges stay
conflict-free.

| Path | What it is |
|---|---|
| `extension/` | Extension `ahmed`: the `speckit.ahmed.review-gate` command and a mandatory `before_implement` hook that runs it. |
| `preset/` | Preset `ahmed`: the owner's constitution template, owner rules prepended to seven core commands, and the implement approval gate. |
| `verify.ps1` | Proves the pieces still work: upstream extension/preset/hook tests plus a smoke install in a temp folder. |
| `check_hooks.py` | Helper for `verify.ps1`: parses `.specify/extensions.yml` and checks the hook is mandatory. |
| `update-from-upstream.ps1` | Merges the latest upstream release tag into branch `ahmed`, then runs `verify.ps1`. |
| `AHMED-REVIEW.md` | The code study (file:line facts) this design is based on. |

## What each piece does

### Extension `ahmed` (`extension/`)

`/speckit-ahmed-review-gate` (Claude Code skill; the command id is `speckit.ahmed.review-gate`):

1. Finds the active feature through the project's `check-prerequisites` script (needs `tasks.md`).
2. If `specs/<feature>/external-review/APPROVED.md` exists and the SHA256 of `spec.md` and
   `plan.md` still match the values recorded in it, reports "approval valid" and returns.
   A mismatch makes the approval stale: it is renamed `APPROVED.superseded-<time>.md` and the gate
   starts again. `tasks.md` is not hashed because `/speckit-implement` ticks its checkboxes.
3. Otherwise writes `external-review/review-package.md`: reviewer instructions plus the verbatim
   `spec.md`, `plan.md` and `tasks.md`, ready to paste into ChatGPT. Then it **stops** and asks the
   owner to paste the review result back.
4. When the owner returns with the review, it saves it as `review-result-<time>.md`, walks the
   findings with a marked recommendation each (one at a time when there are more than about six),
   applies only the changes the owner accepts, and asks for approval.
5. Only on the owner's **explicit** approval does it write `APPROVED.md` with the date, the owner's
   words verbatim, the review file, the hashes and the list of changes applied. A reviewer's
   "APPROVE" is never treated as the owner's approval.

The hook in `extension.yml` (`hooks.before_implement`, `optional: false`) makes
`/speckit-implement` run the gate before its outline.

### Preset `ahmed` (`preset/`)

- `templates/constitution-template.md` replaces the core `constitution-template`. Base principles
  I-IX: zero cost, no secrets, evidence before claims, real tests watched failing once, minimal
  complexity, production quality, owner approval gates, Arabic-first UX (RTL, Latin digits), owner
  communication. Marked `PROJECT-SPECIFIC SLOT` sections hold each project's own rules.
- `commands/owner-rules.md` is **prepended** to `specify`, `clarify`, `plan`, `tasks`, `checklist`
  and `analyze`: replies in Egyptian Arabic with English technical terms in Latin script; `spec.md`
  prose in Arabic with identifiers, code and paths in English; more than about six decisions become
  one numbered list with a marked recommendation, asked one at a time; no claim without evidence.
- `commands/speckit.implement.md` is **prepended** to `implement`: refuse to start unless
  `<feature>/external-review/APPROVED.md` exists, and run the review gate instead; followed by a
  copy of the owner rules (`verify.ps1` fails if that copy drifts from `owner-rules.md`).
- `preset.yml` declares `requires.extensions: [ahmed]`, so install the extension first.

## Install into a project

The fork's own CLI is used (it is installed editable in the fork's `.venv`; create it with
`uv venv .venv` and `uv pip install --python .venv\Scripts\python.exe -e ".[test]"`, or just run
`ahmed\verify.ps1` once).

New project (recommended: files are copied, not linked, and `.specify/memory/constitution.md` is
seeded from our template):

```powershell
$fork = 'D:\My Apps\Skills\spec-kit'
& "$fork\.venv\Scripts\specify.exe" init <project-dir> --integration claude --script ps --non-interactive `
  --extension "$fork\ahmed\extension" --preset "$fork\ahmed\preset"
```

Existing Spec Kit project (run inside the project folder; extension first):

```powershell
$fork = 'D:\My Apps\Skills\spec-kit'
& "$fork\.venv\Scripts\specify.exe" extension add --dev "$fork\ahmed\extension"
& "$fork\.venv\Scripts\specify.exe" preset add --dev "$fork\ahmed\preset"
```

Then run `/speckit-constitution` once so the project constitution adopts the Ahmed principles (an
existing `.specify/memory/constitution.md` is never overwritten by an install).

Notes:

- `extension add` accepts a local folder only with `--dev`. In dev mode the review-gate skill is a
  symlink into `.specify/extensions/ahmed/`; the `init --extension <path>` route copies instead.
- Windows: the project's PowerShell scripts look for `python3` first, which can be the Microsoft
  Store stub. Set `SPECKIT_PYTHON_EXECUTABLE` to a real Python 3 with PyYAML (for example the
  fork's `.venv\Scripts\python.exe`) or disable the `python3` App Execution Alias.

## Update from upstream

```powershell
powershell -NoProfile -File "D:\My Apps\Skills\spec-kit\ahmed\update-from-upstream.ps1"           # latest vX.Y.Z
powershell -NoProfile -File "D:\My Apps\Skills\spec-kit\ahmed\update-from-upstream.ps1" -Tag v1.2.6
```

It refuses to run on a dirty tree or a branch other than `ahmed`, merges the tag (never rebases or
resets), aborts and lists the files on a conflict, then runs `verify.ps1`. It never pushes.
Projects pick up the new behaviour with `specify integration upgrade claude`, then re-adding the
preset (`specify preset remove ahmed` then `preset add` again).

## Known limits

- **The implement gate is prompt-level.** Both the `before_implement` hook and the prepended gate
  are instructions to the model; nothing in Spec Kit's Python blocks `/speckit-implement`. A hard
  block needs a Claude Code hook in the project (for example a `PreToolUse` hook on `Edit|Write`
  that denies writes outside `specs/` while the active feature has no `external-review/APPROVED.md`).
- Spec Kit has no output-language setting; the Arabic rules are prompt text in the prepended block.
- The hook order on `before_implement` follows `.specify/extensions.yml` order, not `priority`.
