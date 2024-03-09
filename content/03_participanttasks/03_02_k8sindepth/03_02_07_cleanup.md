---
title: "Clean up"
menuTitle: "Clean up"
weight: 8
---

After completing all tasks with the Self-Managed Kubernetes, use the following command to delete the two Azure VMs:

```bash
cd $HOME/k8s-101-workshop/terraform
terraform destroy -var="username=$(whoami)" --auto-approve
```

