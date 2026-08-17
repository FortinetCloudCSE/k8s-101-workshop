# CLAUDE.md — k8s-101-workshop

> Global preferences (planning workflow, code quality, operations): `~/.claude/CLAUDE.md`

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

## Key File Map

Every leaf content page is a **Hugo page bundle** (`dir/index.md`) with its images co-located in the same directory. Section pages remain `_index.md`. This is the state since commit `a55f83c`.

```
content/
  _index.md                              — site landing (branch bundle)
  k8s-101.pdf                            — linked from repoConfig.json shortcuts
  01_introduction/_index.md
  02_quickstart_overview_faq/
    _index.md
    02_01_quickstart/
      _index.md
      02_01_02_cloudshell/index.md       + cloudshell-01..10.{jpg,png}
      02_01_03_terraform/index.md        + K8s-workshop-101.png, linux_passwd.png,
                                           output.png, terraform{1,2}.png, terraformoutput.png
    02_02_k8s_overview/                  — ONLY *.md.txt files: disabled pages, not built
  03_participanttasks/
    _index.md
    03_01_k8sinstall/
      _index.md
      03_01_02_k8sinstall/index.md       + K8s-workshopafter-101.png
      03_01_03_HPA_demo/index.md
      03_01_04_k8smanualinstall.md.txt   — disabled
    03_02_k8sindepth/
      _index.md
      03_01_01_pods/index.md             (note: 03_01_* prefix under 03_02_* — inconsistent, harmless)
      03_02_02_configmap/index.md
      03_02_03_deployment/index.md
      03_02_04_scaling/index.md
      03_02_05_upgrades/index.md
      03_02_06_exposingapp/index.md
      03_02_07_cleanup/index.md
      7_k8sappendix/index.md
      test/index.md                      — front-matter-less scratch page, SHIPS as test.html
  unusedimages/                          — parking lot for unreferenced images (still published)
    Kubernetes-vs-Docker.jpg
    images/{container.png,deployment_replicaset_pod.png}
scripts/
  repoConfig.json                            — per-repo site config (title, banner, analytics, shortcuts)
  install_kubeadm_masternode.sh              — control-plane bootstrap
  install_kubeadm_workernode.sh              — worker join
  deploy_application_with_hpa_masternode.sh  — sample app + HPA
  regression.sh                              — DESTRUCTIVE end-to-end lab rebuild (see gotchas)
terraform/
  main.tf                — required_providers + provider block ONLY
  variables.tf           — single variable: username (no default)
  azurevm_linux.tf       — RG data source, VNet/subnet/NIC/public IPs, the master+worker VMs
  output.tf              — linuxvm_{master,worker}_FQDN, linuxvm_username, linuxvm_password
.repo_upgrade_version    — "Hugo-v2.1"
repo_upgrade_spec.json   — files_to_copy / files_to_delete / folders_to_delete for the upgrade tool
Dockerfile               — synced by the upgrade tool; NOT used by CI (see gotchas)
Jenkinsfile              — content-lint pipeline; sets a GitHub commit status
.github/workflows/static.yml — build + deploy to Pages on push to main
migration_log_dry_run_20260817_193337.csv — page-bundle migrator dry-run audit trail
migration_log_run_20260817_193508.csv     — page-bundle migrator actual-run audit trail
```

There is no `static/`, `assets/`, `layouts/`, or `data/` directory — all of that comes from CentralRepo inside the image.

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

There is no automated test suite. Content changes are validated by rendering locally and diffing the build log; lab changes by running the scripts against real Azure VMs.

**Known-good build baseline (verified on `jkopkoEdits` @ `a55f83c`):** exit 0, `Pages 48`, `Non-page files 25`, `Static files 13` — page and non-page counts are identical to pristine `main`. All 57 local `<img>` src occurrences in the output resolve, 0 broken. Log contains exactly 3 WARNs: 2 cosmetic link WARNs (see gotchas) and 1 pre-existing `menu` `url` vs `pageRef` WARN for the Workshop PDF shortcut. Pristine `main` by contrast emits 17 `image ... is not a resource` WARNs, all eliminated by the page-bundle migration.

## Critical Patterns & Gotchas

- **`scripts/regression.sh` is DESTRUCTIVE — never run or suggest running it casually.** Line 3 is `terraform destroy -var="username=$(whoami)" --auto-approve`. It then re-applies the whole lab, does `rm -f ~/.ssh/known_hosts`, and regenerates `~/.ssh/id_rsa` via `ssh-keygen -q -N "" -f ~/.ssh/id_rsa`. Destroys real Azure infrastructure and clobbers the caller's SSH identity. Requires explicit approval every time.

- **No `hugo.toml` or `config.toml` here — on purpose.** Hugo config is generated at build time by CentralRepo's `scripts/generate_toml.py` from `scripts/repoConfig.json` via the Jinja template `CentralRepo/scripts/templates/hugo.jinja`. To change the site title, banner, Google Analytics ID, video header, or sidebar shortcuts, edit **`scripts/repoConfig.json`**. Anything not exposed in `repoConfig.json` is not configurable from this repo.

- **`uglyURLs = true` is set in CentralRepo's `scripts/templates/hugo.jinja`, NOT in `scripts/repoConfig.json`.** It is not overridable from this repo. Consequence: leaf bundles render to `<name>.html`, not `<name>/index.html`. `content/.../02_01_03_terraform/index.md` → `/02_quickstart_overview_faq/02_01_quickstart/02_01_03_terraform.html`. **Page-bundling therefore changed zero output URLs.** Branch bundles (`_index.md`) still render to `dir/index.html`.

- **2 cosmetic Hugo link WARNs are expected on this branch and are NOT bugs. Do not "fix" them.** Both come from `content/03_participanttasks/03_01_k8sinstall/03_01_02_k8sinstall/index.md`:
  ```
  WARN link '../../02_quickstart_overview_faq/02_01_quickstart/02_01_03_terraform.html' is not a page or a resource
  WARN link '../../03_participanttasks/03_01_k8sinstall/03_01_03_hpa_demo.html' is not a page or a resource
  ```
  Hugo's page-ref resolver walks up from the *content* path, which is now 3 levels deep, so it wants `../../../`. But the page *outputs* to `/03_participanttasks/03_01_k8sinstall/03_01_02_k8sinstall.html`, whose directory is 2 levels deep, so the emitted `../../` href is correct and resolves. Verified: the emitted `href=../../02_quickstart_overview_faq/02_01_quickstart/02_01_03_terraform.html` points at a file that exists in the build output. Adding a third `../` would satisfy Hugo's warning and **break the working link**. Cosmetic only; `errorLevel` is `warning` so it does not fail the build either way.

- **The page-bundle migrator does NOT URL-decode destination filenames.** `/home/ubuntu/pythonProjects/tools/hugo-page-bundle-migrator/hugo_migrate_to_page_bundles.py` uses `unquote()` when *resolving* the source image (`clean_url()`, line ~100) but computes the destination from the still-encoded URL: `dest = bundle_dir / Path(urlparse(url).path).name` (line ~224). An image named `K8s workshop-101.png` referenced as `K8s%20workshop-101.png` is therefore copied to a file **literally named `K8s%20workshop-101.png`**, and the rewritten Markdown ref is that same literal string — which the browser decodes back to a space and 404s. Confirmed in `migration_log_dry_run_20260817_193337.csv`, which shows `dest = .../03_01_02_k8sinstall/K8s%20workshopafter-101.png`. **Fix: rename source images to hyphenated names and rewrite all references BEFORE running the migrator.** That is what `a55f83c` did (`K8s workshop-101.png` → `K8s-workshop-101.png`, `K8s workshopafter-101.png` → `K8s-workshopafter-101.png`). Never put spaces or percent-encoding in image filenames here.

- **The migrator relocates unreferenced images even without `--move-assets`.** `process_unused_images()` is called unconditionally from `main()` and uses `shutil.move` regardless of the `--move-assets` flag. Anything under `content/`, `static/`, or `assets/` with an image extension that no page references gets moved to `content/unusedimages/<path-after-anchor>` — hence the nested `content/unusedimages/images/`. `a55f83c` relocated 3 images this way and deleted the then-orphaned `content/images/` directory. Note `content/unusedimages/` is still inside `content/`, so Hugo **publishes** those images as non-page files; it is a parking lot, not an exclusion.

- **When checking image resolution in the build output, do NOT resolve srcs relative to the page.** Output srcs are absolute and carry the baseURL prefix: `src=/k8s-101-workshop/03_participanttasks/.../K8s-workshopafter-101.png`. Strip `/k8s-101-workshop` and resolve from the output root. Also: **output HTML is minified and attributes are UNQUOTED** (`href=../../foo.html`), so any regex expecting `href="..."` will silently match nothing.

- **`.gitignore` contents (read it, don't assume):** `**/.DS_Store`, `public/`, `docs/`, `node_modules/`, `docker-compose.yml`, `package-lock.json`, `package.json`, `**/.terraform/*`, `**/.terraform.lock.hcl`, `**/terraform.tfstate`, `**/terraform.tfstate.backupvenv/`, `venv/`. Note `package.json` and `package-lock.json` are ignored yet both are **tracked** in the repo (ignore rules do not apply to already-tracked files). Note also the malformed line `**/terraform.tfstate.backupvenv/` — the intended `terraform.tfstate.backup` and `venv/` entries got concatenated, so `terraform.tfstate.backup` is **not** actually ignored.

- **Never put plan/spec/log files in `docs/` — use a root-level `plans/` directory.** `docs/` is the CI build output (`static.yml` does `rm -rf $GITHUB_WORKSPACE/docs` then `docker cp $CONT_ID:/home/CentralRepo/public docs`), `.gitignore` excludes it, AND `repo_upgrade_spec.json` lists `"folders_to_delete": ["docs"]`. The template upgrade tool `CentralRepo/scripts/batch_repo_update.py` has `FOLDERS_TO_DELETE = ["docs"]` and `BRANCH = "main"` hardcoded; it enumerates every blob under `docs/`, stages them for deletion in a new tree, and pushes that **directly to `main`**. Anything filed under `docs/` is either invisible to git or destroyed by the next template upgrade. A root-level `plans/` is inert to Hugo (Hugo reads only `content/`, `layouts/`, `static/`, `assets/`, `data/`, `i18n/`, `archetypes/`, `themes/`) and sits outside `folders_to_delete`. All six Hugo workshop repos follow this convention; `plans/README.md` in this repo records the reasoning.

- **CI does NOT use the local `Dockerfile`.** `.github/workflows/static.yml` pulls `public.ecr.aws/k4n6m5h8/fortinet-hugo:latest` (with exponential-backoff retries for ECR `toomanyrequests`), tags it `fortinet-hugo:latest`, and runs it. The `Dockerfile` exists because `repo_upgrade_spec.json` `files_to_copy` syncs it from the template (`batch_repo_update.py` `FILES_TO_COPY` includes `Dockerfile` and `.github/workflows/static.yml`). It is only exercised if someone builds locally, e.g. `docker build --build-arg LOCAL=true --target dev -t hugotester-local .`. **Editing it will not change CI behavior, and the upgrade tool will overwrite your edits on `main`.**

- **The Dockerfile pins CentralRepo to a branch, not a tag:** the `dev` stage does `ADD https://github.com/FortinetCloudCSE/CentralRepo.git#prreviewJune23`, `prod` uses `#main`. Theme changes on those branches land here without a version bump. (Moot for CI, which uses the prebuilt ECR image — but the ECR `:latest` tag is itself a moving target.)

- **`azurerm` is pinned to exactly `=3.0.0`** in `terraform/main.tf` (not `~>`). The HCL is written against 3.x semantics; bumping to 4.x is a migration, not a version bump.

- **Terraform does NOT create the resource group.** `azurevm_linux.tf` reads it: `data "azurerm_resource_group" "resourcegroup" { name = "${var.username}-k8s101-workshop" }`. Every other resource inherits `location` from it. The RG must be created out-of-band first or `apply` fails immediately. `main.tf` contains only `required_providers` + the `provider` block; `variables.tf` declares one variable, `username`, with **no default**, so `-var="username=..."` is mandatory on every command.

- **VM size is `Standard_D16as_v5`** (`azurevm_linux.tf:55`), with `Standard_B2s` commented out just above and the note "increase instance size for FAIG Lab". The two commits immediately preceding the page-bundle migration (`9a5d931` "resizing azure vm", `d4f6ef0` "adjust vm size") were both VM-size changes — if lab steps fail on resource limits, this line is the lever.

- **Lab hostnames follow `<username>-{master,worker}.<region>.cloudapp.azure.com`** (from `domain_name_label = "${var.username}-${each.key}"`). Content hardcodes `$(whoami)-master.eastus.cloudapp.azure.com` and the region `eastus`. Changing the naming scheme or region breaks documented commands.

- **The Jenkinsfile lint is advisory only.** It loops over `content/*/`, greps for `discussion|questions|q&a`, and `echo`s a warning if a directory has none — wrapped in `try/catch` that swallows all exceptions, so it never fails the build. The FortiDevSec SAST stage is **disabled** via `when { expression { false } }`. The pipeline's only real effect is setting a `ci/jenkins/build-status` GitHub commit status.

- **Shortcodes come from the CentralRepo theme (hugo-theme-relearn):** `{{% notice %}}`, `{{< tabs >}}` / `{{% tab title="…" %}}`. Grep existing content before inventing new ones.

- **Page ordering is `weight` in front matter,** not filename. Numeric directory prefixes are cosmetic — note `03_02_k8sindepth/03_01_01_pods/` breaks the prefix convention with no ill effect.

- **`*.md.txt` files are deliberately disabled pages.** Four exist (three in `02_02_k8s_overview/`, one in `03_01_k8sinstall/`). Hugo does not build them, but it **does** publish them as non-page files — they count toward the 25 and are reachable on the live site. Rename to `.md` to re-enable.

- **`content/03_participanttasks/03_02_k8sindepth/test/index.md` has no front matter and is raw shell/YAML.** It builds and publishes as `test.html`. Pre-existing; deleting it would change the 48/25 build baseline.

- **Deploy triggers only on push to `main`** (plus `workflow_dispatch`, which offers `runner_type` and `image_variant: prod|dev` inputs — `dev` swaps in `public.ecr.aws/k4n6m5h8/hugotester:latest`).

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

**File a plan/spec/log**: root-level `plans/NNNN_YYYY-MM-DD_<git-username>_<slug>.md` (plus optional `.log.md`, `.spec.md`). **Not** `docs/plans/` — see the `docs/` gotcha. `NNNN` is a per-repo sequence; the log is optional; on completion, durable facts get promoted into this file and the plan is left to decay. `plans/README.md` has the details.

**Debug a broken published page**: run the CI build command above and diff the log against the known-good baseline (exit 0, 48 pages, 25 non-page files, 3 WARNs). `errorLevel` in `repoConfig.json` is `warning`, so Hugo warnings never fail the build — a page can render wrong with a green CI check. To verify images, extract srcs from `/tmp/out/**/*.html` accounting for unquoted attributes, strip the `/k8s-101-workshop` prefix, and test each path against the output root.
