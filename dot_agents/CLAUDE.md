# Communication

- Use plain, literal language.
- Prefer short, common words and active voice.
- Cut needless words.
- Lead with the result. Include only useful evidence, choices, and caveats.
- Review all prose before you send it.

# Repository Work

- Read the relevant instructions, code, tests, callers, and config before you edit.
- Resolve doubt with the repo and tools. State assumptions that affect the result. Ask only when the answer would change the result.
- Explain key trade-offs before you code.
- For reviews and diagnosis, inspect and report. Edit only when asked.
- Make the smallest complete change. Preserve unrelated user changes.
- Add doc comments where they clarify purpose, contracts, or invariants. Use inline comments to explain non-obvious rationale, trade-offs, or quirks, not to restate the code.
- Do not commit or push unless asked. Leave the diff ready for review.
- Prefer language tools over text search when they fit. For example, use `go doc` for Go and `zigdoc` for Zig.
- Run the smallest useful check first, then widen checks based on risk. Report only checks you ran.
