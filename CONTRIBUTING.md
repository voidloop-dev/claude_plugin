# Contributing

## Ground rules

- Never push to `main`. Branch → PR → merge.
- Branch names: `<type>/<short-desc>` — `feat`, `fix`, `chore`, `docs`.
- [Conventional Commits](https://www.conventionalcommits.org/).

## What makes a good skill here

A skill earns its place only if it holds **concrete, non-obvious procedural
knowledge** for **one specific moment** in the workflow. Every `SKILL.md` must have:

1. A `description:` that names exactly when to trigger — and when not to.
2. A table of absolute **never/always** rules, each with its one-line reason.
3. A step **procedure**, each step ending in a check.
4. A hard **verification gate** (pass/fail list) before anything is "done".
5. A full **worked example**.
6. Real **reference files** (templates, configs, workflows) — not prose advice.

If your idea is "tell Claude to act like a senior X", that's a prompt snippet,
not a skill. Put it in a skill's `references/prompts.md`.

## Local check

```bash
# mirrors the validate workflow
for f in .claude-plugin/*.json; do python3 -c "import json;json.load(open('$f'))"; done
```

## PR

Fill in the template. The `validate` workflow must pass. One approving review.
