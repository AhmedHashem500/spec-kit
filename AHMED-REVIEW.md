# Spec Kit code study (repo D:\My Apps\Skills\spec-kit, pyproject version 1.2.6.dev0, CHANGELOG top = 1.2.5 2026-10-28)
Paths below are relative to the repo root. Line counts measured with wc (md/py/sh/ps1/yml/json only).

## 1. Repo layout
- src/specify_cli (78,735 lines py). Biggest: extensions/__init__.py 6238, events/__init__.py 2632, integrations/base.py 1976, workflows/_commands.py 1834, command_init.py 1252. Subpkgs: extensions, presets, integrations (claude/ etc), workflows, bundles, events, artifacts, mcp_server.
- templates (3,062): spec-template.md, plan-template.md, tasks-template.md, checklist-template.md, constitution-template.md, vscode-settings.json, commands/ (analyze, checklist, clarify, constitution, converge, implement, plan, specify, tasks, taskstoissues .md).
- scripts (5,364): bash/, powershell/ (check-prerequisites, common, create-new-feature, resolve-template, setup-plan, setup-tasks .ps1), python/.
- extensions (15,687): bundled agent-context, assess, bug, git, github, selftest, template (starter), catalog.json, catalog.community.json.
- presets (2,895): lean, constitution-sync, scaffold, self-test, ARCHITECTURE.md, catalogs.
- docs (14,646): reference/, guides/ (customization.md), extensions/ (developing, api, publishing), integrations/ (claude.md), upgrade.md (558 lines).
- tests (181,167 lines, 315 test_*.py files). Also: workflows/ (1,567), bundles/ (260), integrations/ (catalogs only), .specify/ (only memory/), AGENTS.md, DEVELOPMENT.md, CONTRIBUTING.md.

## 2. `specify init` with integration claude
- Options (src/specify_cli/command_init.py:274-358): `--script` (sh|ps|py, :274), `--ignore-agent-tools` (:277), `--here` (:282), `--force` (:287), `--allow-symlinks` (:292), `--non-interactive` (:296), `--preset` (:330), `--integration` (:335), `--integration-options` (:340), `--extension` repeatable: bundled name, local path or HTTPS URL (:345), `--trust-extension-urls` (:350), `--trust-integration` (:355). Hidden no-ops: --skip-tls, --debug, --github-token, --offline (:306-329).
- Default script on Windows = ps: `default_script = "ps" if os.name == "nt" else "sh"` (command_init.py:637).
- Claude = skills mode only. src/specify_cli/integrations/claude/__init__.py:41-56: class ClaudeIntegration(SkillsIntegration), folder ".claude/", commands_subdir "skills", registrar dir ".claude/skills", extension "/SKILL.md". docs/integrations/claude.md:22: skills at `.claude/skills/speckit-<command>/SKILL.md`, invoked `/speckit-specify`. Extension commands: `/speckit-bug-assess` (claude.md:23-24). NO .claude/commands mode found.
- Claude-only option `--no-model-invocation` (claude/__init__.py:83-93; docs claude.md:35): core skills user-invocable only. Applies to core skills only; extension hook skills must stay model-invocable (claude/__init__.py:70-73 comment: "mandatory extension hooks rely on the model invoking the hook skill").
- Writes into project: .claude/skills/speckit-*/SKILL.md; .claude/settings.json for runtime events (claude/__init__.py:62-63 events_config_file, docs claude.md:64); .specify/templates (shared_infra.py:430), .specify/scripts (:576), .specify/memory/constitution.md (command_init.py:211-253), .specify/integrations/speckit.manifest.json (shared_infra.py:124), .specify/.gitignore (:690), .specify/integration.json (docs upgrade.md:93), .specify/extensions.yml (docs reference/extensions.md:324), workflow assets (command_init.py docstring :388).
- Example (docstring command_init.py:~385): `specify init --here --force --non-interactive --integration claude`.

## 3. Extension system
- File: `extension.yml` in extension root. Required top-level keys: `REQUIRED_FIELDS = ["schema_version","extension","requires","provides"]` (extensions/__init__.py:236); schema_version "1.0" (must match, :281-283). At least one of provides.commands/templates/scripts, hooks, events required (:412; docs developing.md:198-201).
- Sections: extension{id,name,version,description,author,repository,license,[category,effect(read-only|read-write: VALID_EFFECTS :82)]}; requires{speckit_version, tools[]}; provides{commands[{name,file,description,aliases}], templates[{name,file,description}], scripts[{name,file,runtime(bash|powershell|python: :80)}], config[]}; hooks (top-level, sibling of provides); events (top-level); tags; defaults (extensions/template/extension.yml full annotated sample).
- Command names must be namespaced `speckit.<ext-id>.<cmd>`; extension id and namespaces may NOT shadow core commands (extensions/__init__.py:1101-1116, 1162-1164). So an extension CANNOT override a core command (/speckit-implement); only a preset can.
- Extension templates/scripts: names `^[a-z0-9-]+$` (:77); `strategy` key is REJECTED, extension artifacts always use replace (:586-640). They sit in resolution layer 3, below presets and project overrides (docs guides/customization.md:78-83).
- Hooks: events like before_implement, after_tasks etc. (docs extensions/api.md:620-636); each hook {command, optional, prompt, description, condition, priority>=1} (validation extensions/__init__.py:423-450). Runtime events (session_start, pre_tool_use, post_tool_use, user_prompt_submit, stop, session_end) translated to .claude/settings.json natively (docs reference/extensions.md:297-322).
- Install: command_add.py:22-28: `specify extension add <name>` (catalog/bundled), `--dev <local dir>`, `--from <url>`, `--force`, `--priority N` (default 10, lower wins), `--version`. Also `specify init --extension ./path`. Project must already be initialized (reference/extensions.md:50). `.extensionignore` supported (developing.md:476).
- Real manifest, extensions/bug/extension.yml (full):
```
schema_version: "1.0"
extension:
  id: bug
  name: "Bug Triage Workflow"
  version: "1.0.2"
  description: "Assess, fix, and validate bug reports ... under .specify/bugs/<slug>/"
  author: spec-kit-core
  repository: https://github.com/github/spec-kit
  license: MIT
requires:
  speckit_version: ">=0.9.0"
provides:
  commands:
    - name: speckit.bug.assess
      file: commands/speckit.bug.assess.md
      description: "Assess a bug report ..."
    - name: speckit.bug.fix
      file: commands/speckit.bug.fix.md
      description: "Apply the remediation ..."
    - name: speckit.bug.test
      file: commands/speckit.bug.test.md
      description: "Validate that a previously fixed bug is resolved ..."
tags: ["bug","triage","workflow","qa"]
```
  (descriptions shortened by me; the real file is extensions/bug/extension.yml:1-30.) assess ext (extensions/assess/extension.yml) is the same shape with 5 commands, plus category "process", effect "read-write".

## 4. Presets
- Exist. Manifest `preset.yml` (presets/lean/preset.yml): schema_version, preset{id,name,version,description,author,repository,license}, requires{speckit_version}, provides.templates[{type: command|template|script, name, file, description, replaces, strategy}], tags.
- Override core AND extension templates/commands/scripts. Strategies: replace (default), prepend, append, wrap (`{CORE_TEMPLATE}` placeholder; scripts only replace/wrap with `$CORE_SCRIPT`) (docs reference/presets.md:350). Example wrap: presets/constitution-sync/preset.yml `strategy: "wrap"` on speckit.constitution. Lean preset replaces speckit.specify/plan/tasks/implement/constitution via `replaces:`.
- Stack: project-local .specify/templates/overrides/ > presets (by priority) > extensions > core .specify/templates (reference/presets.md:359-366). Commands are materialized into the active integration dir (.claude/skills) at install, not re-resolved at run time (presets.md:346; customization.md:88-92).
- Install: `specify preset add <id> [--dev path] [--from url] [--priority N]`; `specify init --preset <id>` (command_init.py:330). `preset update` is destructive remove-then-add, no rollback (reference/presets.md:106-135).
- Difference: extension = NEW commands/capabilities/hooks, cannot shadow core; preset = CHANGE existing templates/commands (the only way to modify /speckit-implement, spec-template, plan-template, constitution). Per docs/guides/customization.md:9-20.
- Recommendation implied by the code: one extension (new commands + hooks + templates) PLUS one preset (core overrides/wrap), kept in our own folder, both installed via --dev/--preset local path.

## 5. Hooks / lifecycle (external review gate before implement)
- YES. Core implement template reads `.specify/extensions.yml` `hooks.before_implement` (templates/commands/implement.md:16-46). Mandatory hook (`optional: false`) emits `EXECUTE_COMMAND: {command}` and "Wait for the result of the hook command before proceeding to the Outline" (implement.md:40-47).
- Extension declares it in extension.yml `hooks: before_implement: {command: speckit.<id>.review-gate, optional: false}` (sample extensions/template/extension.yml:60-93; git ext uses before_implement optional: true at extensions/git/extension.yml:66).
- CAVEAT (Fact): this is PROMPT-LEVEL enforcement, the model is told to run it; nothing in Python blocks implementation. implement.md:~48 "Emitting the block alone does not run the hook". Invalid extensions.yml only warns and continues (implement.md:22). `condition` hooks are skipped by templates (reference/extensions.md:381). `auto_execute_hooks` setting is reserved and unused (:360-362). Priority ordering is not applied by templates, YAML order is used (:383-385).
- Hard gate option: runtime events `pre_tool_use` / `stop` map to Claude `PreToolUse`/`Stop` in .claude/settings.json (claude/__init__.py:56-63). The referenced command's `scripts` entry runs directly (reference/extensions.md:318-322), so a script can exit non-zero. That is real machinery, but scoped to tool use, not to the /speckit-implement step.
- Also available: after_implement mandatory hooks (implement.md:180-215).

## 6. Constitution
- Template: templates/constitution-template.md (resolved name `constitution-template`). Command: templates/commands/constitution.md.
- Init seeds .specify/memory/constitution.md ONCE from the resolved template through the whole stack; existing file preserved (command_init.py:211-253; presets/ARCHITECTURE.md:64-75). Docstring says a preset shipping `constitution-template` with strategy replace can seed a ratified constitution (command_init.py:217-220).
- /speckit-constitution (constitution.md:~47-60): runs resolve-template script (ps: scripts/powershell/resolve-template.ps1 constitution-template -Json), loads live constitution as source of project values, fills `[ALL_CAPS]` placeholders, semver bump, writes Sync Impact Report comment. Since #3790 it no longer edits other templates (docs upgrade.md "Behavior change" section ~line 225).
- Yes, an extension (provides.templates name `constitution-template`, forced replace) or a preset (replace/prepend/append/wrap) can supply defaults. Preset is the better fit (priority above extensions). Optional preset `constitution-sync` restores propagation (presets/constitution-sync/preset.yml).

## 7. Language / localization
- NOT FOUND as a feature: no output-language setting. Grepped templates/, docs/reference/core.md, docs/guides/customization.md, presets/README.md for language/locali/translat/arabic/i18n; hits were only unrelated ("programming language", clarify.md:89 "localization notes" as a spec topic).
- Only pointer: docs/guides/customization.md:62-64 says presets can "localize a workflow"; community preset "Pirate Speak (Full)" rewrites 6 templates + 9 commands (docs/community/presets.md:38). So Arabic or bilingual output = our own preset (instruction lines in command files plus template headings).
- PowerShell non-Latin description crash fixed (CHANGELOG.md:500 #4138); UTF-8 decode fix for feature.json (CHANGELOG.md:538 #4359). Branch-name acronym logic is Latin-oriented (assumption, not verified).

## 8. Update path
- Docs/upgrade.md:10-14 and 105-130: CLI via `specify self upgrade` (uv tool or pipx). Project files via `specify integration upgrade claude` then `specify extension update`. Fallback: `specify init --here --force --integration claude` (upgrade.md:140-150).
- Customizations: integration upgrade uses the manifest (.specify/integrations/speckit.manifest.json) and STOPS if a managed file was edited, unless --force (upgrade.md:120-122, 176-178). Shared scripts/templates refreshed only if unchanged vs previous managed copy (:179-181). Constitution never touched by integration upgrade; init --here --force also preserves it (:171-173). specs/ never touched (:125).
- So never edit .claude/skills or .specify/templates in place; put changes in our extension/preset/overrides. Caveat: preset update = remove then add, may lose local mods tracked by the preset (reference/presets.md:135-140). After upgrade, preset command overrides re-apply on the active integration (presets.md:346).
- Our fork merges: our code lives in new dirs (extensions/<ours>, presets/<ours>) so upstream merges stay clean; catalog.json files are upstream-edited, do not touch them (assumption).

## 9. Tests
- CONTRIBUTING.md:265-282: `uv pip install -e ".[test]"` then `.venv\Scripts\python -m pytest tests -q` (Windows). Prefer project .venv over bare `uv run pytest` (namespace-package gotcha with other checkouts, CONTRIBUTING.md:277-282). Single file: `uv run python -m pytest tests/test_agent_config_consistency.py -q` (:262). pyproject.toml:62-70 has pytest, pytest-cov, pytest-xdist; testpaths=tests; requires-python >=3.11 (pyproject.toml:6).
- Count: 315 test_*.py files, ~181k lines. Exact test count NOT obtained: `python -m pytest tests --collect-only` failed here with "ModuleNotFoundError: No module named 'specify_cli'" (package not installed in this Python; I did not install anything, read-only).
- CI includes windows-latest (CHANGELOG.md:2035 #2233).

## 10. Risks (Windows / PowerShell / Claude Code)
- Hook gate is prompt-based, not enforced (see 5). Model may skip it; `--no-model-invocation` can break hook chaining for extension skills only if applied to them (it is scoped to core skills, claude/__init__.py:70-73). History: "allow Claude to chain skills for hook execution" (CHANGELOG.md:2037 #2227).
- /speckit-analyze fork freezes: "stop forking /speckit-analyze to prevent long-session freezes" (CHANGELOG.md:1380 #3188); claude skill frontmatter overrides exist (claude/__init__.py:26-27 forked-subagent overrides).
- PowerShell: docs target Windows PowerShell 5.1 (CHANGELOG.md:116 #4973), so our own .ps1 must be 5.1-safe (no `?.`, ASCII only: CHANGELOG.md:1736 #2709, 2198 #1975). Past bugs: bracketed feature paths (CHANGELOG.md:67 #4970), literal feature paths (:121 #4956), BOM in templates (:1791 #2280), Out-Null swallowing AVAILABLE_DOCS (:609, :644), Rich Live hang on PS 5.1 (:1508 #2938), UnicodeEncodeError (:1639 #2817), Store python3 alias stub (:1210 #3385). Scripts count: scripts/powershell has only 6 .ps1; command/script composition runs in Python (presets/ARCHITECTURE.md:60-62), so Python 3.11+ is required on PATH.
- Windows file/symlink: dev-mode installs may symlink (extensions/__init__.py:1541, 2390), which needs privileges on Windows (assumption); use copy install, not --dev, for stable use. `--allow-symlinks` default deny.
- Duplicate-command issue after upgrade exists for IDE agents (upgrade.md:200-215), not Claude.
- Open GitHub issues were NOT checked (no network use); only CHANGELOG/docs searched.
- Upstream churn: 1.2.x ships roughly every 1-5 days (CHANGELOG top entries 1.2.3 10-22, 1.2.4 10-27, 1.2.5 10-28); pin with `specify self upgrade --tag vX.Y.Z`.

CHECK: PASS
