---
title: "Task 2 - Run Terraform"
weight: 3
---

### Task 2 - Launch resources using Terraform

All the components required for Lab are deployed through terraform. 

Lab Architecture:

{{< figure src="K8s-workshop-101.png" alt="lab001" >}}

Perform the following steps in your Cloudshell console to create your environment.

1. Clone the Github repo `git clone https://github.com/FortinetCloudCSE/k8s-101-workshop.git`
2. Change directory to the `cd k8s-101-workshop/terraform` folder
3. Run `terraform init`

```sh
git clone https://github.com/FortinetCloudCSE/k8s-101-workshop.git
cd k8s-101-workshop/terraform
terraform init
```

{{< figure src="terraform1.png" alt="lab11" >}}

    
4. Run the following command to apply it

    ```sh
   terraform apply -var="username=$(whoami)" --auto-approve
    ```

    {{% notice style="warning" title="**IF THE COMMAND ABOVE RESULTS IN AN ERROR**" %}} 

You can manually specify your username (found in your Azure Account email) in the command  
If your Workshop Azure account login is se31@ftntxxxxx.onmicrosoft.com, your username is **se31**, and the command to enter is:

```sh
terraform apply  -var='username=se31' --auto-approve
```
    
    {{% /notice %}} 


{{< figure src="terraform2.png" alt="lab12" >}}
    
5. Terraform deployment takes atleast 10-15 min to complete.

{{< figure src="terraformoutput.png" alt="lab13" >}}

6. Once Terraform is complete you should see the output. Please copy the output to notepad.

{{< figure src="output.png" alt="output" >}}

7. To print the node VM's login password, you can run this command 

   ```
   terraform output -raw linuxvm_password
   ```

{{< figure src="linux_passwd.png" >}}
