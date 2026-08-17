---
title: "Task 1 - Setup Azure Cloud Shell"
weight: 2
---

Azure Cloud Shell is a browser-based command-line environment built into the Azure portal. It includes the Azure CLI and common tools needed for Kubernetes tasks, ensuring a consistent environment for everyone without the need to install tools locally.

#### 1. **Setup your Azure Cloud Shell**

* Login to Azure Cloud Portal [https://portal.azure.com/](https://portal.azure.com/) with the provided login/password

    {{< figure src="cloudshell-01.jpg" alt="cloudshell1" >}}
    {{< figure src="cloudshell-02.jpg" alt="cloudshell2" >}}

* Click the link "Skip for now (14 days until this is required)" do not click the "Next" button

    {{< figure src="cloudshell-03.jpg" alt="cloudshell3" >}}

* Click the "Next" button

    {{< figure src="cloudshell-04.jpg" alt="cloudshell4" >}}

* Click on Cloud Shell icon on the Top Right side of the portal

    {{< figure src="cloudshell-05.jpg" alt="cloudshell5" >}}

* Select **Bash**

    {{< figure src="cloudshell-06.png" alt="cloudshell6" >}}

* Click on **Mount Storage Account**

    {{< figure src="cloudshell-07.png" alt="cloudshell7" >}}
* Select
  * Storage Account Subscription - **Internal-Training**
  * Apply


* Click **Select existing Storage account**, Click Next

    {{< figure src="cloudshell-08.png" alt="cloudshell8" >}}

* in Select Storage account Step, 

   * Subscription: **Internal-Training**
   * Resource Group: Select the Resource group from the drop down: **K8sXX-K8s101-workshop**
   * Storage Account: Use existing storage account from dropdown.
   * File share: Use **cloudshellshare**
   * Click Select

    {{< figure src="cloudshell-09.png" alt="cloudshell9" >}}

 {{< notice warning >}} Please make sure to use the existing ones. you wont be able to create any Resource Group or Storage account
  {{< /notice >}}  

* After 1-2 minutes, You should now have access to Azure Cloud Shell console

    {{< figure src="cloudshell-10.png" alt="cloudshell10" >}}
