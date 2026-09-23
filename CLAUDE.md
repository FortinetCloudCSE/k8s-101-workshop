# CLAUDE.md — k8s-101-workshop

> Global preferences (planning workflow, code quality, operations): `~/.claude/CLAUDE.md`
> **On-demand docs** (read only when relevant — not auto-loaded):
> - [plans/claude/reference.md](plans/claude/reference.md) — Key File Map (content/layouts/terraform tree)
> - [plans/claude/gotchas.md](plans/claude/gotchas.md) — Critical Patterns: Hugo config generation, page-bundle migration, Terraform/lab infra, CI build mechanics. Grep before touching any of those.
> - [plans/claude/deployment-paths.md](plans/claude/deployment-paths.md) — full mechanics behind the one-path rule below; read before adding any second deployment path

## Project in One Line

A FortinetCloudCSE hands-on workshop — "Containers & Microservices 101: K8s Foundational" — published as a Hugo static site to GitHub Pages, with Terraform that stands up an Azure two-node VM pair and shell scripts that build a `kubeadm` cluster on them.

## Stack Quick Reference

| Layer | Tech | Port |
|-------|------|------|
| Site generator | Hugo 0.162.1 (`hugomods/hugo:std` base) via `public.ecr.aws/k4n6m5h8/fortinet-hugo:latest` | 1313 (local dev) |
| Site theme/config | [CentralRepo](https://github.com/FortinetCloudCSE/CentralRepo) — lives inside the image at `/home/CentralRepo`, **not** in this repo | — |
| Local dev driver | [fortihugorunner](https://github.com/FortinetCloudCSE/fortihugorunner) CLI | — |
| Hosting | GitHub Pages (`https://fortinetcloudcse.github.io/k8s-101-workshop/`) | — |
| Template version | `Hugo-v2.1` (`.repo_upgrade_version` + `repo_upgrade_spec.json`) | — |
| Lab infra | Terraform + `azurerm` provider **pinned to `=3.0.0`** | — |
| Lab cluster | `kubeadm` on Ubuntu VMs (1 master + 1 worker) | 30913 (NodePort used in content) |

Module map (content/, layouts/, terraform/, scripts/, `.github/workflows/`): [plans/claude/reference.md](plans/claude/reference.md).

## Build & Run Commands

```bash
# Preview the site locally (requires Docker + fortihugorunner on PATH)
fortihugorunner pull-image --env author-dev
fortihugorunner launch-server \
  --docker-image fortinet-hugo:latest \
  --host-port 1313 --container-port 1313 --watch-dir .
# open http://localhost:1313

# Reproduce the CI static build exactly (this is what static.yml does)
CID=$(docker run -d -v "$PWD:/home/UserRepo" fortinet-hugo:latest build)
STATUS=$(docker wait "$CID"); docker logs "$CID"
docker cp "$CID:/home/CentralRepo/public" /tmp/out
docker rm "$CID"

# Lab infrastructure (Azure — costs money, creates real VMs).
# The resource group "<username>-k8s101-workshop" MUST already exist; Terraform only reads it.
cd terraform && terraform apply -var="username=$(whoami)"
```

There is no automated test suite. Content changes are validated by rendering locally and diffing the build log; lab changes by running the scripts against real Azure VMs. The one automated check is `python3 scripts/lint_paths.py` (run by `path-lint.yml` on PRs) — it lints content conventions, not the build.

**Known-good build baseline (verified on `jkopkoEdits` @ `a55f83c`):** exit 0, `Pages 48`, `Non-page files 25`, `Static files 13` — identical to pristine `main`. All 57 local `<img>` src occurrences resolve, 0 broken. Log contains exactly **1 WARN** (the Workshop PDF `menu`/`pageRef` warning — not fixable from this repo, see gotchas); the two `is not a page or a resource` link WARNs that used to accompany it were fixed by converting to `/`-rooted refs. Pristine `main` by contrast emits 17 `image ... is not a resource` WARNs, all eliminated by the page-bundle migration. **1 WARN is the baseline — treat any additional WARN as a regression.**

## Critical Rules

- **Never run `scripts/regression.sh` casually — it's destructive.** `terraform destroy --auto-approve` on real Azure infra, then wipes `~/.ssh/known_hosts` and regenerates `~/.ssh/id_rsa`. Requires explicit approval every time.
- **No `hugo.toml` here on purpose** — config is generated at build time from `scripts/repoConfig.json`. Edit that file to change site chrome; anything not exposed there isn't configurable from this repo.
- **`uglyURLs = true` is hardcoded upstream, not overridable** — leaf bundles render to `<name>.html`. Page-bundling changed zero output URLs.
- **Cross-page links must be `/`-rooted content refs**, never `../`-relative — Hugo validates `/`-rooted refs on every build; a broken `../` ref fails silently.
- **The one remaining WARN (PDF menu shortcut) can't be fixed from this repo** — `hugo.jinja` (in CentralRepo) has no `pageRef`/`errorignore` passthrough. Documented baseline, don't chase it.
- **Never put spaces or percent-encoding in image filenames** — the page-bundle migrator doesn't URL-decode destinations, producing a literal `%20` filename that 404s in the browser.
- **The migrator relocates unreferenced images even without `--move-assets`** — anything unreferenced under `content/`/`static/`/`assets/` gets moved to `content/unusedimages/`, which Hugo still publishes (not an exclusion).
- **When checking image resolution in build output**, srcs are absolute with the baseURL prefix and HTML is minified with unquoted attributes — strip the prefix, don't regex for `href="..."`.
- **`.gitignore` has a malformed line** (`**/terraform.tfstate.backupvenv/`) — `terraform.tfstate.backup` is NOT actually ignored. `package.json`/`package-lock.json` are gitignored but already tracked (ignore rules don't apply retroactively).
- **Never put plan/spec/log files in `docs/`** — it's CI build output, gitignored, and deleted on every template upgrade by CentralRepo's `batch_repo_update.py` (pushed directly to `main`). Use root-level `plans/` instead.
- **CI does not use the local `Dockerfile`** — `static.yml` pulls the prebuilt ECR image. Editing the Dockerfile won't change CI behavior, and the next template upgrade overwrites local edits anyway.
- **Dockerfile pins CentralRepo to a branch, not a tag** — theme changes land here without a version bump (moot for CI, which uses the prebuilt image).
- **Terraform does NOT create the resource group** — `"<username>-k8s101-workshop"` must exist out-of-band first, or `apply` fails immediately.
- **VM size is `Standard_D16as_v5`** (`azurevm_linux.tf:55`) — the lever if lab steps fail on resource limits.
- **Lab hostnames follow `<username>-{master,worker}.<region>.cloudapp.azure.com`** — content hardcodes the username substitution and `eastus` region.
- **The Jenkinsfile lint is advisory only** — swallows all exceptions, never fails the build; FortiDevSec SAST is disabled.
- **Shortcodes come from the CentralRepo theme** — grep existing content before inventing new ones; all 33 existing `tabs` groups are command-vs-output, not an environment axis (see Deployment Paths).
- **Page ordering is `weight` in front matter, not filename** — numeric directory prefixes are cosmetic.
- **`*.md.txt` files are deliberately disabled pages** — Hugo doesn't build them but still publishes them as non-page files, reachable on the live site.
- **Deploy triggers only on push to `main`** (plus `workflow_dispatch` with `runner_type`/`image_variant` inputs).

Full detail and incident history for every rule above: [plans/claude/gotchas.md](plans/claude/gotchas.md).

## Deployment Paths

**This workshop has exactly ONE deployment path: self-managed `kubeadm` on the two Azure VMs Terraform creates.** AKS is dead here (commented out, not a live choice). Read [plans/claude/deployment-paths.md](plans/claude/deployment-paths.md) before adding any second path, any "choose your environment" branch, or any `tabs` group whose tabs are environments rather than commands — a bare `{{< tabs >}}` group without relearn's shared `groupid` silently resets to its first tab on every page load (this bit `ai-101` in production). `ai-101` is the reference implementation to copy from, not reinvent.

## Environment Variables

```bash
# Required — none for authoring or for the CI build.

# Terraform
# Authenticated Azure CLI session (`az login`) + the mandatory `username` variable:
#   terraform apply -var="username=$(whoami)"

# Optional / Dev
DOCKER_CONTEXT=   # fortihugorunner honors the active Docker context
DOCKER_HOST=      # same
GITHUB_TOKEN=     # only for CentralRepo/scripts/batch_repo_update.py (not run from this repo)
```

`fdevsec.yaml` carries the FortiDevSec org/app IDs (`org: 2e3b7756-…`, `app: c93a42d4-…`); all optional scanner settings are commented out.

## Common Tasks

**Add a workshop section**: create a page bundle — `content/<parent>/<NN_slug>/index.md` with `title`, `linkTitle`, `weight` front matter — and put its images in that same directory, referenced by bare filename (`![alt](foo.png)`). No spaces, no percent-encoding in image names. Preview with `launch-server`, then run the CI build and confirm the counts moved by exactly the number of pages/files you added.

**Change site chrome** (title, banner, analytics, sidebar links): edit `scripts/repoConfig.json`. Nothing else in this repo affects Hugo config.

**Change the lab environment**: edit `terraform/azurevm_linux.tf` for VM shape/image, `scripts/install_kubeadm_*.sh` for cluster bootstrap. Both are walked through step-by-step in `content/03_participanttasks/` — update the content in the same change.

**Add a second deployment path** (e.g. bring AKS back): read **Deployment Paths** above first. Copy `layouts/shortcodes/pathtabs.html` + `pathtab.html` from `ai-101`, fill in `PATH_KEYS` / `PATH_TITLE_RE` / `PATH_TOKENS` in `scripts/lint_paths.py`, then run the linter — expect to add `ALLOWLIST` entries for conceptual prose that names both paths. Never hand-write `groupid="deploy-path"`.

**File a plan/spec/log**: root-level `plans/NNNN_YYYY-MM-DD_<git-username>_<slug>.md` (plus optional `.log.md`, `.spec.md`). **Not** `docs/plans/` — see the `docs/` gotcha. `NNNN` is a per-repo sequence; the log is optional; on completion, durable facts get promoted into this file and the plan is left to decay. `plans/README.md` has the details.

**Debug a broken published page**: run the CI build command above and diff the log against the known-good baseline (exit 0, 48 pages, 25 non-page files, 1 WARN). `errorLevel` in `repoConfig.json` is `warning`, so Hugo warnings never fail the build — a page can render wrong with a green CI check. To verify images, extract srcs from `/tmp/out/**/*.html` accounting for unquoted attributes, strip the `/k8s-101-workshop` prefix, and test each path against the output root.
