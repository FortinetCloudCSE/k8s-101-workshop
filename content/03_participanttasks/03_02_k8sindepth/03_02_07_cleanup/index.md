---
title: "Task 7 - Cleanup"
linkTitle: "Task 7 - Cleanup"
weight: 8
---


{{< notice warning >}}
Only complete this cleanup step if you are finished with the workshop. 

If you plan to continue with other labs like [AI-101](https://fortinetcloudcse.github.io/ai-101/) or [FortiAIGate Workshop](https://fortinetcloudcse.github.io/faig-training-workshop/), skip the cleanup.
{{< /notice >}}

After completing all tasks with the Self-Managed Kubernetes, use the following command to delete the two Azure VMs:

```bash
cd $HOME/k8s-101-workshop/terraform && terraform destroy -var="username=$(whoami)" --auto-approve
```

