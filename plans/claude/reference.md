# Reference — Key File Map

> Detail doc for `CLAUDE.md`. Read when you need to locate a file, not for gotchas (`gotchas.md`) or deployment-path mechanics (`deployment-paths.md`).

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
  lint_paths.py                              — deployment-path guardrail; empty vocabulary here (see Deployment paths)
terraform/
  main.tf                — required_providers + provider block ONLY
  variables.tf           — single variable: username (no default)
  azurevm_linux.tf       — RG data source, VNet/subnet/NIC/public IPs, the master+worker VMs
  output.tf              — linuxvm_{master,worker}_FQDN, linuxvm_username, linuxvm_password
.repo_upgrade_version    — "Hugo-v2.1"
repo_upgrade_spec.json   — files_to_copy / files_to_delete / folders_to_delete for the upgrade tool
Dockerfile               — synced by the upgrade tool; NOT used by CI (see gotchas)
Jenkinsfile              — content-lint pipeline; sets a GitHub commit status
.github/workflows/static.yml — build + deploy to Pages on push to main (template-owned, NEVER edit)
.github/workflows/path-lint.yml — runs scripts/lint_paths.py on pull_request
migration_log_dry_run_20260817_193337.csv — page-bundle migrator dry-run audit trail
migration_log_run_20260817_193508.csv     — page-bundle migrator actual-run audit trail
```

There is no `static/`, `assets/`, `layouts/`, or `data/` directory — all of that comes from CentralRepo inside the image.

