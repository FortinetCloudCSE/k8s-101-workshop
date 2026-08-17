# Plan: Deployment-Path Lint — Prevention Only
Date: 2026-08-17
Owner: Jeff Kopko
Slug: path-lint-prevention
Status: Approved
Supersedes: none
Superseded-By: none
Plan File: plans/0001_2026-08-17_Jeff-Kopko_path-lint-prevention.md
Log File: none — one session, no rejected options the commits won't show

## Goal

Install the deployment-path guardrail in this repo **preventatively**, with an empty path
vocabulary, so that a future path branch cannot ship in the silently-broken form that
`ai-101` shipped for six tab pairs.

This is Phase 5 of `ai-101/plans/2026-08-17_Jeff-Kopko_workshop-deployment-path-lock.md`.
Phases 0-4 are already merged in `ai-101`. Nothing in that repo is touched here.

## Context / Links

- Approved plan (authoritative, do not redesign): `~/pythonProjects/ai-101/plans/2026-08-17_Jeff-Kopko_workshop-deployment-path-lock.md`, `## Design` §9 + `### Phase 5`
- Reference implementation: `~/pythonProjects/ai-101/scripts/lint_paths.py` (356 lines, five checks)
- Why the bug exists: relearn's `tabs` shortcode falls back to the **first** tab, silently,
  when a group has no `groupid` or the stored `itemid` is absent. `ai-101` had six path tab
  pairs with no `groupid`, so each reset to "Docker Compose" on every page load.
- Related code paths here: `scripts/`, `.github/workflows/`, `CLAUDE.md`, `plans/`

## Constraints / Assumptions

- **This repo has no live deployment branch today.** AKS is commented out at
  `content/01_introduction/_index.md:41` and its overview pages exist only as disabled
  `*.md.txt`. So there is nothing to convert — the value is entirely preventative.
- **Never modify `.github/workflows/static.yml`** — it is in the template upgrade tool's
  `FILES_TO_COPY` and edits are silently reverted. New CI goes in new files.
- **Never write under `docs/`** — build output, gitignored, and `batch_repo_update.py`
  deletes it and pushes that deletion straight to `main`.
- **Do not fix the dead AKS references.** Documenting that they are dead is in scope;
  deleting them is a separately deferred follow-up.
- This repo's `tabs` groups are a **command vs "Expected Output"** axis, not a path axis.
  They must not be touched or flagged.
- The linter must exit 0 on current content, must not crash, and must emit no noise.
- Keep `scripts/lint_paths.py` structurally diffable against `ai-101`'s copy so a fix to
  one is cheap to apply to the other.
- No test suite. Verification = run the linter, break it deliberately, and run the
  CI-equivalent Hugo build to confirm the page count did not move.

## Plan

- [x] Port `scripts/lint_paths.py` from `scripts/lint_paths.py.ref`, empty vocabulary
- [x] Port `.github/workflows/path-lint.yml` from `.github/workflows/path-lint.yml.ref`
- [x] Delete both `.ref` files
- [x] Add a "Deployment paths" section to `CLAUDE.md`
- [x] Verify: linter exits 0 on current content, no spurious findings
- [x] Verify: linter catches a deliberately introduced `cd "~/foo"` and a hand-written
      `groupid="deploy-path"`, naming the right check for each; restore and re-verify clean
- [x] Verify: Hugo build page count and WARN count unchanged from the CLAUDE.md baseline
      (48 pages / 25 non-page files / 3 WARNs)
- [x] Verify: `path-lint.yml` parses as YAML

## Plan Changes

- (none)

## Decisions & Commentary

- **Empty the vocabulary, do not delete the checks.** `PATH_KEYS`, `PATH_TOKENS`,
  `ALLOWLIST` and `GENERATED_DIRS` become empty and `PATH_TITLE_RE` becomes `None`. The
  three vocabulary-driven checks (`path-tab-outside-pathtabs`, `token-outside-path-block`,
  `stale-handouts`) then no-op, while `handwritten-groupid` and `tilde-in-quotes` stay live.
  Keeping the dead config block in place is what makes the two repos diffable and makes
  adding a path here a config edit rather than a port.
- **`PATH_TITLE_RE = None` with a one-token guard, not a never-matching regex.** A
  `re.compile(r"(?!)")` would leave the implementation byte-identical but is obscure;
  `if PATH_TITLE_RE and ...` is a one-line diff that reads correctly.
- **Emptying `PATH_TITLE_RE` is load-bearing, not cosmetic.** Two live tab titles here —
  `"4.helm version"` and `"K8s bootcamp deployment"` — match `ai-101`'s
  `\b(docker|compose|kubernetes|k8s|helm)\b`. Porting that regex as-is would fail CI on
  day one against 33 legitimate command-vs-output tab groups.
- **`stale-handouts` needs no change.** `check_handouts()` already returns `[]` when
  `scripts/gen_handouts.py` is absent, which it is here. The check is inert by
  construction, not by configuration.
- **Drop `scripts/gen_handouts.py` from the workflow's `paths` filter, keep
  `layouts/shortcodes/pathtab*.html`.** There is no handout generator here and no plan for
  one; but a future `pathtabs` shortcode should trigger the lint the moment it lands.
- **Adjust two user-facing strings, nothing else.** The clean-run message dropped
  ", handouts up to date" (false here) and the `tilde-in-quotes` remedy no longer names
  `$AI101_HOME`. Both are output text, not logic — the diff stays readable.

## Files Changed

- `scripts/lint_paths.py` (new, 337 lines) — ported from `ai-101`, vocabulary emptied,
  `PATH_TITLE_RE` guarded, docstring rewritten for this repo's situation
- `scripts/lint_paths.py.ref` (deleted) — staging copy, no longer needed
- `.github/workflows/path-lint.yml` (new) — runs the linter on `pull_request`
- `.github/workflows/path-lint.yml.ref` (deleted) — staging copy
- `CLAUDE.md` — new "Deployment paths" section; two new entries under
  `## Critical Patterns & Gotchas`; `path-lint.yml` and `lint_paths.py` added to the
  file map; "no automated test suite" note qualified
- `plans/0001_2026-08-17_Jeff-Kopko_path-lint-prevention.md` (this file)

## Session Summary

Phase 5 landed as prevention only: a linter with an empty path vocabulary, a PR workflow
that runs it, and the convention written down in `CLAUDE.md`. No content changed, so the
Hugo build is byte-for-byte the same shape as the `a55f83c` baseline (48 pages, 25
non-page files, 3 WARNs — all three pre-existing and documented as cosmetic).

The one substantive finding: porting `ai-101`'s `PATH_TITLE_RE` unchanged would have
broken CI immediately. `"4.helm version"` and `"K8s bootcamp deployment"` are ordinary
command-step tab titles here, and both match that regex. This repo's 33 `tabs` groups are
a command-vs-"Expected Output" axis, so a path-title heuristic has no signal here at all
and had to be switched off rather than tuned.

Both live checks were proven by deliberate breakage, not assumed: a `cd "~/foo"` inserted
into `content/03_participanttasks/03_02_k8sindepth/03_02_04_scaling/index.md` and a
`groupid="deploy-path"` inserted into `.../03_02_03_deployment/index.md` each produced
exit 1 naming `tilde-in-quotes` and `handwritten-groupid` respectively; both were reverted
and the linter returned to exit 0 with a clean `git status`.

## Promotion

- [x] `Decisions & Commentary` walked
- [x] Durable facts promoted to `CLAUDE.md`:
      (1) the whole "Deployment paths" convention — single path today, AKS dead and not a
      live choice, any future branch goes through a `groupid`-carrying `pathtabs` shortcode
      copied from `ai-101`, `scripts/lint_paths.py` enforces it;
      (2) the empty-vocabulary contract — which checks are live, which are inert, and that
      re-enabling `PATH_TITLE_RE` breaks CI against the existing tab titles;
      (3) relearn's silent first-tab fallback, the reason the guardrail exists at all.
- [x] `Status:` set to `Complete` — see header

## Follow-ups

- [ ] Remove the dead AKS references (`content/01_introduction/_index.md:41`, the
      commented block in `content/02_quickstart_overview_faq/`) — deferred by decision,
      tracked in the `ai-101` plan's follow-ups
- [ ] If `pathtabs` is upstreamed to CentralRepo, drop the "copy from `ai-101`" pointer in
      `CLAUDE.md` and fill in this repo's `PATH_KEYS`

## Risks / Open Questions

- **The guardrail is only as good as its trigger.** `path-lint.yml` filters on `content/**`,
  the pathtab shortcodes, the linter, and itself. A path branch introduced entirely in
  `layouts/` outside `shortcodes/pathtab*.html` would not trip it.
- **An empty vocabulary means the highest-value check is off.** `token-outside-path-block`
  is what actually catches drift; here it can only come online when someone defines
  `PATH_KEYS`. `CLAUDE.md` carries that instruction, which is a weaker mechanism than CI.
