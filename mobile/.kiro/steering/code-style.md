# Code style

## Comments

Do not add code comments. The code should document itself through clear
naming and structure.

Exceptions where a comment IS warranted:

- Non-obvious edge cases where behavior looks wrong at a glance but is
  intentionally correct (explain *why*, not *what*)
- Workarounds for external bugs, with a link or reference
- Public API doc comments (`///`) on library-facing types and methods in
  modules meant to be consumed by other modules
- `TODO(context)` markers that point at a future spec or decision
- License headers if the project requires them

Do not add:

- Comments that restate what the code obviously does
- Section-divider banners like `// ===== Helpers =====`
- Inline comments explaining standard language features
- Commented-out code (delete it instead)
- Noise like `// constructor`, `// getter`, `// imports`

If a block of code seems to need a comment to be understandable, refactor it
(extract a well-named function, rename a variable, split an expression)
before reaching for a comment.
