# Deploying the Linux Diagnostics Agent (LAD)

For cases, where you have Azure-hosted Virtual Machines and you need to forward log data to Event Hub, configure and deploy the [Linux Diagnostics Extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/diagnostics-linux?context=%2Fazure%2Fvirtual-machines%2Fcontext%2Fcontext&tabs=azcli) (LAD). This must be done via Azure PowerShell or Azure CLI. Use the following instructions for deploying with PowerShell.

## Configuration File

In the `scripts` folder, create a new file named `config.json` and populate the data:

```json
{
    "subscriptionId": "",
    "storageAccountName": "",
    "storageAccountResourceGroup": "",
    "eventHubResourceGroup": "",
    "eventHubNamespace": "",
    "eventHubName": "",
    "eventHubAuthRuleName": "",
    "vmNames": ["vm1", "vm2"],
    "vmResourceGroup": ""
}
```

## Set the log file path

The sample provded in `publicsettings-lad3.json` and `publicsettings-lad3.json` is pre-configured to forward `/var/log/nginx/access.log` to Event Hub. If you do not have nginx installed on your virtual machine, update the path in the `fileLogs` section to match your environment.

## Deployment Script

Run `ladconfig.ps1` to deploy the Diagnostics Agent to your Virtual Machine.
