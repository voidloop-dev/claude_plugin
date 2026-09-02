#!/usr/bin/env python3
"""Validate every skills/*/SKILL.md: present, opens with YAML frontmatter that
parses and carries a non-empty `name` and `description`."""
from __future__ import annotations

import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[2]
skills_dir = ROOT / "skills"

errors: list[str] = []
dirs = sorted(p for p in skills_dir.iterdir() if p.is_dir())
if not dirs:
    errors.append("no skills/ subdirectories found")

for d in dirs:
    f = d / "SKILL.md"
    if not f.is_file():
        errors.append(f"{d.name}: missing SKILL.md")
        continue
    text = f.read_text(encoding="utf-8")
    if not text.startswith("---"):
        errors.append(f"{d.name}: SKILL.md does not open with '---' frontmatter")
        continue
    parts = text.split("---", 2)
    if len(parts) < 3:
        errors.append(f"{d.name}: unterminated frontmatter block")
        continue
    try:
        meta = yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as e:
        errors.append(f"{d.name}: frontmatter is not valid YAML: {e}")
        continue
    if not str(meta.get("name", "")).strip():
        errors.append(f"{d.name}: frontmatter missing 'name'")
    if not str(meta.get("description", "")).strip():
        errors.append(f"{d.name}: frontmatter missing 'description'")
    else:
        print(f"ok: {d.name}")

if errors:
    print("\nFAILURES:", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)

print(f"\n{len(dirs)} skills validated.")
