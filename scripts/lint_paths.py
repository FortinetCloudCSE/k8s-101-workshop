#!/usr/bin/env python3
"""Fail the build when deployment-path content drifts out of its path block.

**`ai-101` is the reference implementation of this script.** Keep this copy
structurally identical to `ai-101/scripts/lint_paths.py` so a fix to one is cheap
to apply to the other; everything repo-specific lives in the CONFIG block below.

This workshop has **one** deployment path today: self-managed `kubeadm` on Azure
VMs. AKS was never a live choice -- it is commented out in
`content/01_introduction/_index.md` and its overview pages exist only as disabled
``*.md.txt`` files. So the path vocabulary here is deliberately **empty** and this
linter is purely preventative: it exists so that if a second path is ever
reintroduced, it cannot ship in the silently-broken form.

That broken form is the bug this guards against. Relearn's ``tabs`` shortcode
synchronises groups site-wide only when they share a ``groupid``; a group without
one falls back to its **first** tab on every page load, silently. In `ai-101` six
path tab pairs did exactly that, so participants' chosen path reset itself
mid-workshop with no warning anywhere.

Checks, in ``ai-101``'s numbering:

1. path-like titles in a plain ``tabs`` group -- a hand-rolled path switch that
   does not synchronise with the reader's choice.
   **Inert here:** ``PATH_TITLE_RE`` is ``None``. It must stay that way -- this
   repo's ``tabs`` groups are a command-vs-"Expected Output" axis, and titles like
   ``"4.helm version"`` would false-positive against ``ai-101``'s pattern.
2. hand-written ``groupid="deploy-path"`` -- bypasses the pathtabs shortcode and
   its missing-path check. **Live.**
3. path-specific tokens outside a path block. **Inert here:** ``PATH_TOKENS`` is
   empty, because with a single path every token is in scope everywhere.
4. ``cd "~`` anywhere -- bash does not expand ``~`` inside double quotes, so the
   command always fails when a participant pastes it. **Live.**
5. stale generated handouts (delegates to ``gen_handouts.py --check``).
   **Inert here:** there is no handout generator in this repo, and
   ``check_handouts`` no-ops when the script is absent.

Usage
-----
    python3 scripts/lint_paths.py            # lint, exit 1 on any violation
    python3 scripts/lint_paths.py --list     # print the config and exit

To bring a second path online here: fill in ``PATH_KEYS``, ``PATH_TITLE_RE`` and
``PATH_TOKENS``, copy ``layouts/shortcodes/pathtab{s,}.html`` from `ai-101`, and
expect to add ``ALLOWLIST`` entries for conceptual prose. Re-enabling
``PATH_TITLE_RE`` alone will fail CI against the existing tab titles.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

# ==========================================================================
# CONFIG -- the path vocabulary. Everything repo-specific lives in this block.
# This repo has a single deployment path, so the vocabulary is empty on purpose;
# see the module docstring for which checks that switches off.
# ==========================================================================

REPO_ROOT = Path(__file__).resolve().parent.parent
CONTENT = REPO_ROOT / "content"

# Generated single-path pages. Path tokens outside pathtabs are the whole point
# there, so the token checks would be nothing but false positives. Their
# freshness is checked separately (check 5).
# Empty: no handout generator in this repo.
GENERATED_DIRS: list[Path] = []

# Front-matter key that marks a whole page as belonging to one path.
PAGE_PATH_KEY = "deploymentPath"

# Keys accepted by the pathtab shortcode. Must match layouts/shortcodes/pathtab.html
# and PATHS in scripts/gen_handouts.py.
# Empty: no paths defined, so any page carrying PAGE_PATH_KEY is a mistake and is
# reported by the page-marker check.
PATH_KEYS: list[str] = []

# A tab title matching this is a path switch. Catching it in a plain `tabs` group
# is the point: such a group has its own random groupid, so clicking it does not
# follow the reader's choice on any other page.
# None disables check 1. Required here: this repo's 33 `tabs` groups are a
# command-vs-"Expected Output" axis, and "4.helm version" / "K8s bootcamp
# deployment" both match ai-101's \b(docker|compose|kubernetes|k8s|helm)\b.
PATH_TITLE_RE: re.Pattern | None = None

# Tokens that only make sense on one path. Each is (label, regex).
# Empty: with one path, kubectl/helm/NodePort are in scope on every page.
PATH_TOKENS: list[tuple[str, re.Pattern]] = []

# Lines allowed to carry a path token outside a path block. Each entry needs a
# reason -- if you cannot write one, the line probably belongs in a pathtabs block.
#
# ``file`` is relative to content/ (or None for any file); ``match`` must appear
# in the line.
# Empty: nothing to allow while PATH_TOKENS is empty.
ALLOWLIST: list[dict] = []

# ==========================================================================
# Implementation
# ==========================================================================

FENCE_RE = re.compile(r"^\s*(```+|~~~+)")
FRONT_MATTER_DELIM = "---"

PATHTABS_OPEN_RE = re.compile(r"\{\{<\s*pathtabs\b")
PATHTABS_CLOSE_RE = re.compile(r"\{\{<\s*/\s*pathtabs\s*>\}\}")
TABS_OPEN_RE = re.compile(r"\{\{<\s*tabs\b")
TABS_CLOSE_RE = re.compile(r"\{\{<\s*/\s*tabs\s*>\}\}")
TAB_TITLE_RE = re.compile(r"\{\{%\s*tab\s+[^%]*title=\"([^\"]+)\"")
GROUPID_RE = re.compile(r"groupid\s*=\s*\"deploy-path\"")
BAD_TILDE_RE = re.compile(r'cd\s+"~')


class Violation:
    def __init__(self, path: Path, line_no: int, check: str, detail: str, line: str):
        self.path = path
        self.line_no = line_no
        self.check = check
        self.detail = detail
        self.line = line.strip()

    def __str__(self) -> str:
        rel = self.path.relative_to(REPO_ROOT)
        return f"{rel}:{self.line_no}: [{self.check}] {self.detail}\n    {self.line}"


def front_matter_value(lines: list[str], key: str) -> str | None:
    if not lines or lines[0].strip() != FRONT_MATTER_DELIM:
        return None
    for raw in lines[1:]:
        if raw.strip() == FRONT_MATTER_DELIM:
            return None
        m = re.match(rf"^{key}\s*:\s*(.*)$", raw.strip())
        if m:
            return m.group(1).strip().strip('"').strip("'")
    return None


def allowed(rel_md: Path, line: str) -> bool:
    for entry in ALLOWLIST:
        if entry["file"] is not None and Path(entry["file"]) != rel_md:
            continue
        if entry["match"] in line:
            return True
    return False


def content_pages() -> list[Path]:
    pages = []
    for md in sorted(CONTENT.rglob("*.md")):
        if md.name not in ("index.md", "_index.md"):
            continue
        if any(gen in md.parents for gen in GENERATED_DIRS):
            continue
        pages.append(md)
    return pages


def lint_page(md: Path) -> list[Violation]:
    lines = md.read_text(encoding="utf-8").splitlines()
    rel_md = md.relative_to(CONTENT)
    page_path = front_matter_value(lines, PAGE_PATH_KEY)
    violations: list[Violation] = []

    # A page declaring a single deploymentPath is itself a path block, so tokens
    # anywhere on it are already scoped. Its marker must still be a real path.
    if page_path and page_path not in PATH_KEYS:
        violations.append(
            Violation(md, 1, "page-marker", f"unknown {PAGE_PATH_KEY}: {page_path!r}", page_path)
        )
    page_is_path_scoped = page_path in PATH_KEYS

    fence: str | None = None
    in_pathtabs = False
    in_plain_tabs = False

    for i, line in enumerate(lines, start=1):
        m = FENCE_RE.match(line)
        if fence is not None:
            if m and line.strip().startswith(fence):
                fence = None
            in_fence = True
        elif m:
            fence = m.group(1)[0] * 3
            in_fence = True
        else:
            in_fence = False

        if BAD_TILDE_RE.search(line):
            violations.append(
                Violation(
                    md,
                    i,
                    "tilde-in-quotes",
                    'bash does not expand ~ inside double quotes; use cd ~/... or unquoted $HOME',
                    line,
                )
            )

        if in_fence:
            continue

        if GROUPID_RE.search(line):
            violations.append(
                Violation(
                    md,
                    i,
                    "handwritten-groupid",
                    'use the pathtabs shortcode instead of groupid="deploy-path"',
                    line,
                )
            )

        if PATHTABS_OPEN_RE.search(line):
            in_pathtabs = True
        elif PATHTABS_CLOSE_RE.search(line):
            in_pathtabs = False
        elif TABS_OPEN_RE.search(line):
            in_plain_tabs = True
        elif TABS_CLOSE_RE.search(line):
            in_plain_tabs = False

        if in_plain_tabs and PATH_TITLE_RE is not None:
            title = TAB_TITLE_RE.search(line)
            if title and PATH_TITLE_RE.search(title.group(1)):
                violations.append(
                    Violation(
                        md,
                        i,
                        "path-tab-outside-pathtabs",
                        f"tab title {title.group(1)!r} looks like a deployment path; "
                        "use pathtabs so it follows the reader's choice",
                        line,
                    )
                )

        if in_pathtabs or page_is_path_scoped:
            continue
        if allowed(rel_md, line):
            continue
        for label, token in PATH_TOKENS:
            if token.search(line):
                violations.append(
                    Violation(
                        md,
                        i,
                        "token-outside-path-block",
                        f"{label!r} is path-specific; wrap it in pathtabs, set "
                        f"{PAGE_PATH_KEY} on the page, or add an allowlist entry with a reason",
                        line,
                    )
                )
                break

    if in_pathtabs:
        violations.append(Violation(md, len(lines), "unclosed-pathtabs", "pathtabs block never closed", ""))

    return violations


def check_handouts() -> list[str]:
    gen = REPO_ROOT / "scripts" / "gen_handouts.py"
    if not gen.is_file():
        return []
    proc = subprocess.run(
        [sys.executable, str(gen), "--check"], capture_output=True, text=True
    )
    if proc.returncode == 0:
        return []
    return [line for line in (proc.stdout + proc.stderr).splitlines() if line.strip()]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--list", action="store_true", help="print the config and exit")
    args = ap.parse_args()

    if args.list:
        print(f"path keys:   {', '.join(PATH_KEYS) or '(none)'}")
        print(f"page marker: {PAGE_PATH_KEY}")
        print(f"path titles: {PATH_TITLE_RE.pattern if PATH_TITLE_RE else '(check disabled)'}")
        print("tokens:")
        for label, token in PATH_TOKENS:
            print(f"  {label:26} {token.pattern}")
        if not PATH_TOKENS:
            print("  (none -- check disabled)")
        print(f"allowlist:   {len(ALLOWLIST)} entries")
        for entry in ALLOWLIST:
            print(f"  {entry['file'] or '<any>':28} {entry['match'][:40]!r} -- {entry['why']}")
        return 0

    violations: list[Violation] = []
    pages = content_pages()
    for md in pages:
        violations.extend(lint_page(md))

    stale = check_handouts()

    for v in violations:
        print(str(v), file=sys.stderr)
    if stale:
        print("[stale-handouts] generated handouts do not match the source pages:", file=sys.stderr)
        for line in stale:
            print(f"    {line}", file=sys.stderr)

    if violations or stale:
        print(
            f"\nlint_paths: {len(violations)} violation(s) in {len(pages)} page(s)"
            + (", handouts stale" if stale else ""),
            file=sys.stderr,
        )
        return 1

    print(f"lint_paths: clean ({len(pages)} pages)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
