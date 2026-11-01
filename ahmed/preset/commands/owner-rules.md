<!-- ahmed-preset:owner-rules -->
## Owner rules (Ahmed preset, apply throughout this command)

- **Reply language**: talk to the owner in Egyptian Arabic. Technical terms, identifiers, commands, file names and paths stay in English, in Latin script; never transliterate them into Arabic letters.
- **spec.md language**: when writing or editing `spec.md`, all user-facing prose (summaries, user stories, scenarios, requirements, success criteria, edge cases) is in Arabic. Identifiers, code, field names, file paths, requirement IDs (FR-001, SC-001) and headings that templates or scripts parse stay in English.
- **Many decisions**: when presenting more than about 6 decisions or questions, show them as one numbered list with your recommendation marked on each, then ask about them **one at a time**; never ask several open questions in one message.
- **How to ask the owner a question** (clarify questions, `[NEEDS CLARIFICATION]` choices, technology approval, findings to accept, any decision). This overrides any question layout in the command below, including its option tables:
  - **Use the `AskUserQuestion` tool whenever it is available**: exactly one question per call, 2 to 4 options. The question text is Arabic, ends with `?`, and its second sentence says in plain words why it matters. The **recommended option is always first** and its label ends with ` ⭐ مُرشَّح`. Each option's description is one line: what happens if he picks it. Header is at most 12 characters (for example `Q2/5 recovery`). Do not add an "Other" option; the tool adds free text itself.
  - **Without the tool**, write in the terminal, one item per line, every Arabic line starting with an Arabic word, no brackets inside Arabic sentences, no tables:
    1. `السؤال N من M: <topic>`
    2. the question itself ending with `?`
    3. `ليه مهم:` one sentence
    4. the options as a numbered list `1.` `2.` `3.`; the recommended one is first, **bold**, starts with `⭐`, and ends with `— مُرشَّح: <one-line reason>`
    5. `رد برقم الاختيار، أو «موافق» على المُرشَّح، أو إجابتك في 5 كلمات.`
  - Record the answer exactly as chosen; "yes", "موافق" or "recommended" means the ⭐ option.
  - **Back-to-back, quiet**: ask the next question immediately after an answer, with no text between questions (no acknowledgement, no recap). Keep the answers in working memory and write them all to the spec in **one pass at the end of the session** for that feature (this overrides any "save after each answer" step), then show one short summary of what changed.
- **Evidence before claims**: never say a file was written, a check passed, or a step is done without showing the evidence (the command output, or the file read back).
