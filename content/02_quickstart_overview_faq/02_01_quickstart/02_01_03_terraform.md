---
title: "Task 2 - Run Terraform"
weight: 3
---

### Task 2 - Launch resources using Terraform

All the components required for Lab are deployed through terraform. 


Perform the following steps in your Cloudshell console to create your environment.

1. Clone the Github repo `git clone https://github.com/FortinetCloudCSE/k8s-101-workshop.git`
2. Change directory to the `cd k8s-101-workshop/terraform` folder
3. Run `terraform init`

```sh
git clone https://github.com/FortinetCloudCSE/k8s-101-workshop.git
cd k8s-101-workshop/terraform
terraform init
```

![lab11](../../images/terraform1.png)


4. Set the Terraform environment variables **(check in dedicated the e-mail send to you by the organizers)**:
    
5. Run the following command ` to apply it

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


![lab12](../../images/terraform2.png)
    
6. Terraform deployment takes atleast 10-15 min to complete.

![lab13](../../images/terraformoutput.png)

7. Once Terraform is complete you should see the output. Please copy the output to notepad.

![output](output.png)

8. To print the node VM's login password, you can run this command 

   ```
   terraform output -raw linuxvm_password
   ```

![](linux_passwd.png)
